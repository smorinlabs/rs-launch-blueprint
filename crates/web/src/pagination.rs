//! First-party opaque base64 cursor pagination (`R72`, REST API Design Standard §6).
//!
//! Uses `URL_SAFE_NO_PAD` base64 cursors, deterministic ascending ID ordering, strict `422`
//! bounds enforcement (never silently clamped), and `next_cursor: null` on the final page.

use std::num::NonZeroU32;

use axum::extract::{FromRef, FromRequestParts};
use axum::http::StatusCode;
use axum::http::request::Parts;
use base64::Engine as _;
use base64::engine::general_purpose::URL_SAFE_NO_PAD;
use rs_launch_blueprint_core::ErrorCode;
use serde::{Deserialize, Serialize};
use thiserror::Error;

use crate::problems::{FieldError, WebError, parse_query_pairs};
use crate::settings::WebSettings;

/// Default page size when `limit` query parameter is omitted (`R72`).
pub const DEFAULT_PAGE_LIMIT: u32 = 50;

/// Maximum permitted page size (`R72`).
pub const MAX_PAGE_LIMIT: u32 = 100;

/// Configured default and maximum pagination limits attached to [`crate::AppState`] (`R72`).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct PaginationLimits {
    /// Default page size when `limit` is omitted (`50`).
    pub default_limit: NonZeroU32,
    /// Inclusive upper bound for `limit` (`100`).
    pub max_limit: NonZeroU32,
}

impl Default for PaginationLimits {
    fn default() -> Self {
        Self {
            default_limit: NonZeroU32::new(DEFAULT_PAGE_LIMIT).unwrap_or(NonZeroU32::MIN),
            max_limit: NonZeroU32::new(MAX_PAGE_LIMIT).unwrap_or(NonZeroU32::MIN),
        }
    }
}

/// Validated positive page size within [`PaginationLimits`] (`R72`).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Limit(NonZeroU32);

impl Limit {
    /// Return the numeric limit value.
    #[must_use]
    pub const fn get(self) -> u32 {
        self.0.get()
    }

    /// Return the limit as `usize` for slice operations.
    #[must_use]
    pub const fn as_usize(self) -> usize {
        self.0.get() as usize
    }
}

/// Validated cursor pagination request extracted from query parameters (`R72`).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PageRequest {
    /// Requested (or default) page size.
    pub limit: Limit,
    /// Decoded exclusive lower-bound resource ID when `cursor` was supplied.
    pub cursor: Option<String>,
}

/// Error returned when decoding an opaque pagination cursor fails (`R72`).
#[derive(Debug, Clone, PartialEq, Eq, Error)]
pub enum CursorError {
    /// Cursor string was empty.
    #[error("cursor must not be empty")]
    Empty,
    /// Cursor failed URL-safe unpadded base64 decoding.
    #[error("cursor is not valid base64")]
    InvalidBase64,
    /// Decoded cursor bytes were not valid non-empty UTF-8.
    #[error("cursor is not valid UTF-8")]
    InvalidUtf8,
}

/// Encode a resource identifier as an opaque URL-safe unpadded base64 cursor (`R72`).
#[must_use]
pub fn encode_cursor(id: &str) -> String {
    URL_SAFE_NO_PAD.encode(id.as_bytes())
}

/// Decode an opaque pagination cursor back into its underlying resource identifier (`R72`).
pub fn decode_cursor(cursor: &str) -> Result<String, CursorError> {
    if cursor.is_empty() {
        return Err(CursorError::Empty);
    }
    let bytes = URL_SAFE_NO_PAD
        .decode(cursor.as_bytes())
        .map_err(|_| CursorError::InvalidBase64)?;
    String::from_utf8(bytes).map_err(|_| CursorError::InvalidUtf8)
}

/// Standard cursor-paginated list response envelope (`R72`, REST R6.1).
///
/// `next_cursor` is intentionally serialized as `null` (never omitted) when there are no further
/// pages.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ListResponse<T> {
    /// Page items in deterministic ascending order.
    pub items: Vec<T>,
    /// Opaque cursor for the next page, or `null` when this page is the last.
    pub next_cursor: Option<String>,
}

/// Deterministically sort `items` by `key_fn`, apply cursor filtering, and slice one page (`R72`).
#[must_use]
pub fn paginate_slice<T, F>(mut items: Vec<T>, req: &PageRequest, key_fn: F) -> ListResponse<T>
where
    F: Fn(&T) -> &str,
{
    items.sort_by(|a, b| key_fn(a).cmp(key_fn(b)));

    let filtered: Vec<T> = match req.cursor.as_deref() {
        Some(after) => items
            .into_iter()
            .filter(|item| key_fn(item) > after)
            .collect(),
        None => items,
    };

    let limit = req.limit.as_usize();
    if filtered.len() > limit {
        let mut page = filtered;
        page.truncate(limit);
        let next_cursor = page.last().map(|last| encode_cursor(key_fn(last)));
        ListResponse {
            items: page,
            next_cursor,
        }
    } else {
        ListResponse {
            items: filtered,
            next_cursor: None,
        }
    }
}

/// Axum extractor parsing and validating `limit` and `cursor` query parameters (`R72`).
///
/// Rejects `stream` (`400`), malformed `limit`/`cursor` (`400`), and out-of-range `limit` (`422`
/// without clamping).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Pagination(pub PageRequest);

impl<S> FromRequestParts<S> for Pagination
where
    S: Send + Sync,
    PaginationLimits: FromRef<S>,
    WebSettings: FromRef<S>,
{
    type Rejection = WebError;

    async fn from_request_parts(parts: &mut Parts, state: &S) -> Result<Self, Self::Rejection> {
        let limits = PaginationLimits::from_ref(state);
        let settings = WebSettings::from_ref(state);
        let path = parts.uri.path().to_owned();
        let base_uri = &settings.problem_base_uri;

        let raw_query = parts.uri.query().unwrap_or("");
        let pairs = parse_query_pairs(raw_query).map_err(|()| {
            WebError::framework(
                StatusCode::BAD_REQUEST,
                "invalid_query_parameter",
                ErrorCode::Usage,
                "Query string contains invalid percent-encoding.",
                base_uri,
                Some(&path),
            )
        })?;

        let mut raw_limit: Option<String> = None;
        let mut raw_cursor: Option<String> = None;

        for (k, v) in pairs {
            match k.as_str() {
                "stream" => {
                    return Err(WebError::framework(
                        StatusCode::BAD_REQUEST,
                        "streaming_not_supported",
                        ErrorCode::Usage,
                        "The 'stream' query parameter is not supported on this endpoint.",
                        base_uri,
                        Some(&path),
                    ));
                }
                "limit" => {
                    if raw_limit.is_some() {
                        return Err(WebError::framework(
                            StatusCode::BAD_REQUEST,
                            "invalid_query_parameter",
                            ErrorCode::Usage,
                            "Duplicate 'limit' query parameter.",
                            base_uri,
                            Some(&path),
                        ));
                    }
                    raw_limit = Some(v.unwrap_or_default());
                }
                "cursor" => {
                    if raw_cursor.is_some() {
                        return Err(WebError::framework(
                            StatusCode::BAD_REQUEST,
                            "invalid_query_parameter",
                            ErrorCode::Usage,
                            "Duplicate 'cursor' query parameter.",
                            base_uri,
                            Some(&path),
                        ));
                    }
                    raw_cursor = Some(v.unwrap_or_default());
                }
                _ => {}
            }
        }

        let limit = match raw_limit {
            None => Limit(limits.default_limit),
            Some(s) => {
                let parsed = s.parse::<u32>().map_err(|_| {
                    WebError::framework(
                        StatusCode::BAD_REQUEST,
                        "invalid_query_parameter",
                        ErrorCode::Usage,
                        "Query parameter 'limit' must be a base-10 integer.",
                        base_uri,
                        Some(&path),
                    )
                })?;
                match NonZeroU32::new(parsed) {
                    Some(nz) if nz.get() <= limits.max_limit.get() => Limit(nz),
                    _ => {
                        return Err(WebError::framework(
                            StatusCode::UNPROCESSABLE_ENTITY,
                            "validation_failed",
                            ErrorCode::Usage,
                            format!(
                                "Query parameter 'limit' must be between 1 and {}.",
                                limits.max_limit
                            ),
                            base_uri,
                            Some(&path),
                        )
                        .with_errors(vec![FieldError {
                            pointer: "/limit".to_owned(),
                            code: "out_of_range".to_owned(),
                            detail: format!("Must be between 1 and {}.", limits.max_limit),
                        }]));
                    }
                }
            }
        };

        let cursor = match raw_cursor {
            None => None,
            Some(s) => Some(decode_cursor(&s).map_err(|_| {
                WebError::framework(
                    StatusCode::BAD_REQUEST,
                    "invalid_cursor",
                    ErrorCode::Usage,
                    "Query parameter 'cursor' is malformed.",
                    base_uri,
                    Some(&path),
                )
            })?),
        };

        Ok(Self(PageRequest { limit, cursor }))
    }
}
