//! Owned GCRA rate-limiting store and Axum middleware (`R74`, `OV-17`).
//!
//! Emits IETF standard `RateLimit`, `RateLimit-Policy`, and ceiling `Retry-After` headers
//! (never proprietary `X-RateLimit-*` headers), isolates client IPs via `ConnectInfo<SocketAddr>`,
//! keeps operational probes reachable while a caller IP is throttled, and fails open on store
//! saturation or lock poisoning.

use std::collections::HashMap;
use std::net::{IpAddr, SocketAddr};
use std::num::NonZeroU32;
use std::str::FromStr;
use std::sync::{Arc, Mutex, Once};
use std::time::{Duration, Instant};

use axum::Router;
use axum::extract::{ConnectInfo, Request, State};
use axum::http::{HeaderName, HeaderValue, header};
use axum::middleware::{self, Next};
use axum::response::{IntoResponse, Response};
use thiserror::Error;

use crate::problems::WebError;
use crate::settings::DEFAULT_PROBLEM_BASE_URI;

/// Default sustained rate limit per client IP (`10/second`, `R74`).
pub const DEFAULT_RATE_LIMIT_PER_IP: &str = "10/second";

/// Default burst capacity paired with [`DEFAULT_RATE_LIMIT_PER_IP`] (`20`, `R74`).
pub const DEFAULT_RATE_LIMIT_BURST: u32 = 20;

/// Default maximum client IP buckets retained in [`InMemoryRateLimitStore`] (`R74`).
pub const DEFAULT_RATE_LIMIT_MAX_ENTRIES: usize = 10_000;

/// Standard IETF `RateLimit` header name (`R74`).
pub const RATE_LIMIT_HEADER: HeaderName = HeaderName::from_static("ratelimit");

/// Standard IETF `RateLimit-Policy` header name (`R74`).
pub const RATE_LIMIT_POLICY_HEADER: HeaderName = HeaderName::from_static("ratelimit-policy");

/// Standard HTTP `Retry-After` header name (`R74`).
pub const RETRY_AFTER_HEADER: HeaderName = header::RETRY_AFTER;

/// Ceiling-rounded integer seconds for `Retry-After` (`>= 1`, never truncates below true wait, `R74`).
#[must_use]
pub const fn retry_after_seconds(wait: Duration) -> u64 {
    let secs = wait.as_secs();
    let ceil = if wait.subsec_nanos() > 0 {
        secs.saturating_add(1)
    } else {
        secs
    };
    if ceil == 0 { 1 } else { ceil }
}

/// Error returned when parsing a [`RateLimitPolicy`] string fails (`R74`).
#[derive(Debug, Clone, PartialEq, Eq, Error)]
pub enum PolicyParseError {
    /// Input did not match `<count>/<unit>`.
    #[error("expected '<count>/<unit>' syntax")]
    InvalidFormat,
    /// Rate count was zero, negative, or non-numeric.
    #[error("rate count must be a positive integer")]
    InvalidCount,
    /// Time unit was not one of `second`/`minute`/`hour`/`day` (or short aliases).
    #[error("unsupported period unit '{0}'")]
    InvalidUnit(String),
}

/// GCRA rate-limit policy specifying sustained rate, period window, and independent burst ceiling
/// (`R74`).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct RateLimitPolicy {
    rate: NonZeroU32,
    period: Duration,
    burst: NonZeroU32,
}

impl Default for RateLimitPolicy {
    fn default() -> Self {
        let rate = NonZeroU32::new(10).unwrap_or(NonZeroU32::MIN);
        let burst = NonZeroU32::new(DEFAULT_RATE_LIMIT_BURST).unwrap_or(NonZeroU32::MIN);
        Self {
            rate,
            period: Duration::from_secs(1),
            burst,
        }
    }
}

impl RateLimitPolicy {
    /// Override the independent burst capacity while keeping sustained `rate` and `period`.
    #[must_use]
    pub const fn with_burst(mut self, burst: NonZeroU32) -> Self {
        self.burst = burst;
        self
    }

    /// Sustained request count permitted per [`Self::period`].
    #[must_use]
    pub const fn rate(&self) -> NonZeroU32 {
        self.rate
    }

    /// Reference period window.
    #[must_use]
    pub const fn period(&self) -> Duration {
        self.period
    }

    /// Maximum burst size admitted instantaneously.
    #[must_use]
    pub const fn burst(&self) -> NonZeroU32 {
        self.burst
    }

    /// GCRA emission interval `T = period / rate`.
    #[must_use]
    pub fn emission_interval(&self) -> Duration {
        self.period / self.rate.get()
    }

    /// IETF `RateLimit-Policy` Structured-Field value (`"default";q=<rate>;w=<period_secs>`).
    #[must_use]
    pub fn policy_header_value(&self) -> String {
        format!(
            "\"default\";q={};w={}",
            self.rate.get(),
            self.period.as_secs()
        )
    }
}

impl FromStr for RateLimitPolicy {
    type Err = PolicyParseError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let trimmed = s.trim();
        let Some((raw_count, raw_unit)) = trimmed.split_once('/') else {
            return Err(PolicyParseError::InvalidFormat);
        };
        if raw_unit.contains('/') {
            return Err(PolicyParseError::InvalidFormat);
        }
        let count: u32 = raw_count
            .trim()
            .parse()
            .map_err(|_| PolicyParseError::InvalidCount)?;
        let rate = NonZeroU32::new(count).ok_or(PolicyParseError::InvalidCount)?;
        let period = match raw_unit.trim().to_ascii_lowercase().as_str() {
            "s" | "sec" | "second" => Duration::from_secs(1),
            "m" | "min" | "minute" => Duration::from_secs(60),
            "h" | "hr" | "hour" => Duration::from_secs(3_600),
            "d" | "day" => Duration::from_secs(86_400),
            other => return Err(PolicyParseError::InvalidUnit(other.to_owned())),
        };
        Ok(Self {
            rate,
            period,
            burst: rate,
        })
    }
}

/// Client identity key bucketing GCRA rate-limit state (`R74`).
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum RateLimitKey {
    /// Per-client-IP bucket derived from `ConnectInfo<SocketAddr>`.
    Ip(IpAddr),
    /// Fallback shared bucket used when `ConnectInfo` is absent (e.g. `oneshot` tests).
    Global,
}

/// Result of a single GCRA admission check (`R74`).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct RateLimitDecision {
    /// `true` if the request is admitted; `false` if throttled (`429`).
    pub allowed: bool,
    /// Remaining instantaneous burst tokens after this decision.
    pub remaining: u32,
    /// Ceiling-rounded seconds until the bucket recovers.
    pub reset_seconds: u64,
    /// Ceiling-rounded `Retry-After` seconds when denied (`None` when admitted).
    pub retry_after_seconds: Option<u64>,
}

/// Driven port for evaluating GCRA rate limits (`R74`).
pub trait RateLimitStore: Send + Sync {
    /// Evaluate `key` against `policy` at monotonic instant `now`.
    fn check(
        &self,
        key: &RateLimitKey,
        policy: &RateLimitPolicy,
        now: Instant,
    ) -> RateLimitDecision;
}

impl<T: RateLimitStore + ?Sized> RateLimitStore for Arc<T> {
    fn check(
        &self,
        key: &RateLimitKey,
        policy: &RateLimitPolicy,
        now: Instant,
    ) -> RateLimitDecision {
        (**self).check(key, policy, now)
    }
}

/// Process-local, bounded in-memory GCRA [`RateLimitStore`] (`R74`, `OV-17`).
///
/// Fails open without panicking when saturated at `max_entries` or if its lock is poisoned.
#[derive(Debug)]
pub struct InMemoryRateLimitStore {
    max_entries: usize,
    entries: Mutex<HashMap<RateLimitKey, Instant>>,
}

impl Default for InMemoryRateLimitStore {
    fn default() -> Self {
        Self::new(DEFAULT_RATE_LIMIT_MAX_ENTRIES)
    }
}

impl InMemoryRateLimitStore {
    /// Create a bounded in-memory GCRA store tracking at most `max_entries` distinct keys.
    #[must_use]
    pub fn new(max_entries: usize) -> Self {
        Self {
            max_entries: max_entries.max(1),
            entries: Mutex::new(HashMap::new()),
        }
    }

    /// Return the current number of tracked client buckets.
    #[must_use]
    pub fn len(&self) -> usize {
        self.entries
            .lock()
            .map(|guard| guard.len())
            .unwrap_or_default()
    }

    /// Return `true` when no client buckets are currently tracked.
    #[must_use]
    pub fn is_empty(&self) -> bool {
        self.len() == 0
    }
}

impl RateLimitStore for InMemoryRateLimitStore {
    fn check(
        &self,
        key: &RateLimitKey,
        policy: &RateLimitPolicy,
        now: Instant,
    ) -> RateLimitDecision {
        let emission = policy.emission_interval();
        let burst = policy.burst().get();
        let burst_tolerance = emission.saturating_mul(burst.saturating_sub(1));

        let Ok(mut map) = self.entries.lock() else {
            tracing::warn!("rate-limit store lock poisoned; failing open");
            return RateLimitDecision {
                allowed: true,
                remaining: burst.saturating_sub(1),
                reset_seconds: 1,
                retry_after_seconds: None,
            };
        };

        if !map.contains_key(key) && map.len() >= self.max_entries {
            map.retain(|_, tat| *tat > now);
            if map.len() >= self.max_entries {
                return RateLimitDecision {
                    allowed: true,
                    remaining: burst.saturating_sub(1),
                    reset_seconds: 1,
                    retry_after_seconds: None,
                };
            }
        }

        let tat = map.get(key).copied().unwrap_or(now);
        // Underflow-safe GCRA check: `tat - burst_tolerance <= now` <=> `tat <= now + burst_tolerance`.
        let limit_instant = now + burst_tolerance;
        if tat <= limit_instant {
            let new_tat = tat.max(now) + emission;
            map.insert(key.clone(), new_tat);

            let full_capacity_instant = limit_instant + emission;
            let headroom = full_capacity_instant.saturating_duration_since(new_tat);
            let emission_nanos = emission.as_nanos().max(1);
            let remaining = u32::try_from(headroom.as_nanos() / emission_nanos).unwrap_or(u32::MAX);
            let reset_seconds = retry_after_seconds(new_tat.saturating_duration_since(now));

            RateLimitDecision {
                allowed: true,
                remaining,
                reset_seconds,
                retry_after_seconds: None,
            }
        } else {
            let wait = tat.saturating_duration_since(limit_instant);
            let retry = retry_after_seconds(wait);
            let reset_seconds = retry_after_seconds(tat.saturating_duration_since(now));

            RateLimitDecision {
                allowed: false,
                remaining: 0,
                reset_seconds,
                retry_after_seconds: Some(retry),
            }
        }
    }
}

#[derive(Clone)]
struct RateLimitState {
    store: Arc<dyn RateLimitStore>,
    policy: RateLimitPolicy,
    problem_base_uri: String,
    policy_header: HeaderValue,
}

static MISSING_CONNECT_INFO_WARN: Once = Once::new();

fn is_probe_path(path: &str) -> bool {
    matches!(path, "/healthz" | "/readyz" | "/metrics")
}

async fn rate_limit_middleware(
    State(rl): State<RateLimitState>,
    req: Request,
    next: Next,
) -> Response {
    let path = req.uri().path();
    if is_probe_path(path) {
        return next.run(req).await;
    }

    let key = match req.extensions().get::<ConnectInfo<SocketAddr>>() {
        Some(ConnectInfo(addr)) => RateLimitKey::Ip(addr.ip()),
        None => {
            MISSING_CONNECT_INFO_WARN.call_once(|| {
                tracing::warn!(
                    "ConnectInfo<SocketAddr> missing on request; falling back to shared global rate-limit bucket"
                );
            });
            RateLimitKey::Global
        }
    };

    let decision = rl.store.check(&key, &rl.policy, Instant::now());
    let rl_value = HeaderValue::from_str(&format!(
        "\"default\";r={};t={}",
        decision.remaining, decision.reset_seconds
    ));

    if !decision.allowed {
        let retry = decision.retry_after_seconds.unwrap_or(1);
        let mut err = WebError::rate_limited(&rl.problem_base_uri, path);
        if let Ok(hv) = HeaderValue::from_str(&retry.to_string()) {
            err = err.with_header(RETRY_AFTER_HEADER, hv);
        }
        if let Ok(hv) = rl_value {
            err = err.with_header(RATE_LIMIT_HEADER, hv);
        }
        err = err.with_header(RATE_LIMIT_POLICY_HEADER, rl.policy_header.clone());
        return err.into_response();
    }

    let mut res = next.run(req).await;
    if let Ok(hv) = rl_value {
        res.headers_mut().insert(RATE_LIMIT_HEADER, hv);
    }
    res.headers_mut()
        .insert(RATE_LIMIT_POLICY_HEADER, rl.policy_header.clone());
    res
}

/// Install GCRA rate limiting on `router` using [`DEFAULT_PROBLEM_BASE_URI`] (`R74`).
pub fn install_rate_limit(
    router: Router,
    store: Arc<dyn RateLimitStore>,
    policy: RateLimitPolicy,
) -> Router {
    install_rate_limit_with_base(router, store, policy, DEFAULT_PROBLEM_BASE_URI)
}

/// Install GCRA rate limiting on `router` with an explicit RFC 9457 `problem_base_uri` (`R74`).
pub fn install_rate_limit_with_base(
    router: Router,
    store: Arc<dyn RateLimitStore>,
    policy: RateLimitPolicy,
    problem_base_uri: &str,
) -> Router {
    let policy_header = HeaderValue::from_str(&policy.policy_header_value())
        .unwrap_or_else(|_| HeaderValue::from_static("\"default\";q=10;w=1"));
    let state = RateLimitState {
        store,
        policy,
        problem_base_uri: problem_base_uri.to_owned(),
        policy_header,
    };
    router.layer(middleware::from_fn_with_state(state, rate_limit_middleware))
}

#[cfg(test)]
mod tests {
    use std::sync::Arc;
    use std::time::Instant;

    use super::{InMemoryRateLimitStore, RateLimitKey, RateLimitPolicy, RateLimitStore};

    #[test]
    fn poisoned_mutex_fails_open_without_panicking() {
        let store = Arc::new(InMemoryRateLimitStore::new(4));
        let clone = Arc::clone(&store);
        let _ = std::thread::spawn(move || {
            let _guard = clone.entries.lock().unwrap();
            panic!("intentional poison");
        })
        .join();

        let decision = store.check(
            &RateLimitKey::Global,
            &RateLimitPolicy::default(),
            Instant::now(),
        );
        assert!(decision.allowed);
        assert_eq!(store.len(), 0);
    }
}
