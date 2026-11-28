//! Optional OS keychain [`CredentialStore`] implementation backed by `keyring-core` (`R56`).
//!
//! Compiled only when the root crate's `keychain` feature is enabled. Uses `apple-native-keyring-store`
//! on macOS/iOS and `zbus-secret-service-keyring-store` (pure-Rust crypto) on other Unix targets.

use std::fmt;
use std::sync::Arc;

use keyring_core::Entry;
use keyring_core::api::CredentialStoreApi;
use rs_launch_blueprint_core::{AuthError, CredentialStore, CredentialWarning, Token};
use zeroize::Zeroize;

/// OS-keychain-backed [`CredentialStore`] using `keyring-core` (`R56`).
pub struct KeychainCredentialStore {
    store: Arc<keyring_core::CredentialStore>,
    service: String,
    user: String,
}

impl fmt::Debug for KeychainCredentialStore {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.debug_struct("KeychainCredentialStore")
            .field("service", &self.service)
            .field("user", &self.user)
            .finish_non_exhaustive()
    }
}

impl KeychainCredentialStore {
    /// Construct a [`KeychainCredentialStore`] backed by any concrete `keyring-core` store
    /// (for example, `keyring_core::mock::Store` in tests or a platform native store).
    #[must_use]
    pub fn with_store<S>(store: Arc<S>, service: impl Into<String>, user: impl Into<String>) -> Self
    where
        S: CredentialStoreApi + Send + Sync + 'static,
    {
        let erased: Arc<keyring_core::CredentialStore> = store;
        Self {
            store: erased,
            service: service.into(),
            user: user.into(),
        }
    }

    /// Construct a [`KeychainCredentialStore`] backed by the target platform's native keychain.
    pub fn native(service: impl Into<String>, user: impl Into<String>) -> Result<Self, AuthError> {
        #[cfg(any(target_os = "macos", target_os = "ios"))]
        {
            let store = apple_native_keyring_store::keychain::Store::new().map_err(|err| {
                AuthError::StoreUnavailable {
                    detail: format!("failed to initialize Apple Keychain store: {err}"),
                }
            })?;
            Ok(Self::with_store(store, service, user))
        }

        #[cfg(all(unix, not(any(target_os = "macos", target_os = "ios"))))]
        {
            let store = zbus_secret_service_keyring_store::Store::new().map_err(|err| {
                AuthError::StoreUnavailable {
                    detail: format!("failed to initialize Secret Service store: {err}"),
                }
            })?;
            Ok(Self::with_store(store, service, user))
        }

        #[cfg(not(unix))]
        {
            let _ = (service, user);
            Err(AuthError::StoreUnavailable {
                detail: "no native keychain store is configured for this target".to_owned(),
            })
        }
    }

    fn entry(&self) -> Result<Entry, AuthError> {
        Entry::new_in_store(&self.store, &self.service, &self.user).map_err(|err| {
            AuthError::StoreUnavailable {
                detail: format!("keychain entry initialization failed: {err}"),
            }
        })
    }
}

impl CredentialStore for KeychainCredentialStore {
    fn load(&self) -> Result<(Option<Token>, Vec<CredentialWarning>), AuthError> {
        let entry = self.entry()?;
        match entry.get_password() {
            Ok(mut secret) => {
                let trimmed = secret.trim_end_matches(['\r', '\n']).to_owned();
                secret.zeroize();
                let token = (!trimmed.is_empty()).then(|| Token::new(trimmed));
                Ok((token, Vec::new()))
            }
            Err(keyring_core::Error::NoEntry) => Ok((None, Vec::new())),
            Err(err) => Err(AuthError::StoreUnavailable {
                detail: format!("failed to read credential from keychain: {err}"),
            }),
        }
    }

    fn save(&self, token: &Token) -> Result<(), AuthError> {
        let entry = self.entry()?;
        entry
            .set_password(token.expose_secret())
            .map_err(|err| AuthError::StoreUnavailable {
                detail: format!("failed to store credential in keychain: {err}"),
            })
    }

    fn delete(&self) -> Result<bool, AuthError> {
        let entry = self.entry()?;
        match entry.delete_credential() {
            Ok(()) => Ok(true),
            Err(keyring_core::Error::NoEntry) => Ok(false),
            Err(err) => Err(AuthError::StoreUnavailable {
                detail: format!("failed to delete credential from keychain: {err}"),
            }),
        }
    }
}
