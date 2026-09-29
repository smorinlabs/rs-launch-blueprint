//! R59 synthesis probe library: the template-owned size+count rotating writer and the
//! enablement resolver, written independently by the synthesizer (not copied from any raw).

use std::ffi::OsString;
use std::fs::{self, File, OpenOptions};
use std::io::{self, Write};
use std::path::{Path, PathBuf};

/// Size-triggered, backup-count-capped append writer. `.1` is the newest backup.
/// Trigger follows py's `RotatingFileHandler.shouldRollover`: rotate before a write that
/// would make the file reach `max_bytes`. Unbuffered; every error is returned, never panics.
pub struct RotatingFile {
    path: PathBuf,
    max_bytes: u64,
    backups: usize,
    file: Option<File>,
    size: u64,
}

fn open_append(path: &Path) -> io::Result<File> {
    OpenOptions::new().append(true).create(true).open(path)
}

fn backup(path: &Path, n: usize) -> PathBuf {
    let mut s = path.as_os_str().to_owned();
    s.push(format!(".{n}"));
    PathBuf::from(s)
}

impl RotatingFile {
    pub fn open(path: impl Into<PathBuf>, max_bytes: u64, backups: usize) -> io::Result<Self> {
        let path = path.into();
        if let Some(parent) = path.parent().filter(|p| !p.as_os_str().is_empty()) {
            let mut b = fs::DirBuilder::new();
            b.recursive(true);
            #[cfg(unix)]
            std::os::unix::fs::DirBuilderExt::mode(&mut b, 0o700);
            b.create(parent)?;
        }
        let file = open_append(&path)?;
        let size = file.metadata()?.len();
        Ok(Self { path, max_bytes, backups, file: Some(file), size })
    }

    fn rotate(&mut self) -> io::Result<()> {
        self.file = None;
        for n in (1..self.backups).rev() {
            match fs::rename(backup(&self.path, n), backup(&self.path, n + 1)) {
                Err(e) if e.kind() != io::ErrorKind::NotFound => return Err(e),
                _ => {}
            }
        }
        fs::rename(&self.path, backup(&self.path, 1))?;
        self.file = Some(open_append(&self.path)?);
        self.size = 0;
        Ok(())
    }
}

impl Write for RotatingFile {
    fn write(&mut self, buf: &[u8]) -> io::Result<usize> {
        let len = buf.len() as u64;
        if self.max_bytes > 0 && self.backups > 0 && self.size > 0 && self.size + len >= self.max_bytes {
            self.rotate()?;
        }
        if self.file.is_none() {
            self.file = Some(open_append(&self.path)?);
            self.size = 0;
        }
        self.file.as_mut().expect("opened above").write_all(buf)?;
        self.size += len;
        Ok(buf.len())
    }

    fn flush(&mut self) -> io::Result<()> {
        self.file.as_mut().map_or(Ok(()), Write::flush)
    }
}

/// flag/env > config > off. `flag`: None = absent, Some(None) = bare `--log-file`,
/// Some(Some(p)) = explicit path. An env var that is present but empty, like a bare flag,
/// selects the default path; an empty config value is off. `default_path` returns None
/// when no State directory is resolvable (the R57 fallback), which makes a bare flag off.
pub fn resolve_log_file(
    flag: Option<Option<PathBuf>>,
    env: Option<OsString>,
    config_file: Option<&Path>,
    default_path: impl FnOnce() -> Option<PathBuf>,
) -> Option<PathBuf> {
    match (flag, env) {
        (Some(Some(p)), _) => Some(p),
        (Some(None), _) => default_path(),
        (None, Some(v)) if v.is_empty() => default_path(),
        (None, Some(v)) => Some(PathBuf::from(v)),
        (None, None) => config_file.filter(|p| !p.as_os_str().is_empty()).map(Path::to_path_buf),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn dflt() -> Option<PathBuf> {
        Some(PathBuf::from("/state/rslbp/rslbp.log"))
    }
    fn p(s: &str) -> PathBuf {
        PathBuf::from(s)
    }

    #[test]
    fn p1_nothing_is_off() {
        assert_eq!(resolve_log_file(None, None, None, dflt), None);
    }
    #[test]
    fn p2_config_path_used() {
        assert_eq!(resolve_log_file(None, None, Some(Path::new("/c.log")), dflt), Some(p("/c.log")));
    }
    #[test]
    fn p3_empty_config_is_off() {
        assert_eq!(resolve_log_file(None, None, Some(Path::new("")), dflt), None);
    }
    #[test]
    fn p4_env_beats_config() {
        assert_eq!(
            resolve_log_file(None, Some("/e.log".into()), Some(Path::new("/c.log")), dflt),
            Some(p("/e.log"))
        );
    }
    #[test]
    fn p5_empty_env_selects_default() {
        assert_eq!(resolve_log_file(None, Some("".into()), Some(Path::new("/c.log")), dflt), dflt());
    }
    #[test]
    fn p6_flag_beats_env() {
        assert_eq!(
            resolve_log_file(Some(Some(p("/f.log"))), Some("/e.log".into()), None, dflt),
            Some(p("/f.log"))
        );
    }
    #[test]
    fn p7_bare_flag_selects_default() {
        assert_eq!(resolve_log_file(Some(None), Some("/e.log".into()), None, dflt), dflt());
    }
    #[test]
    fn p8_bare_flag_without_state_dir_is_off() {
        assert_eq!(resolve_log_file(Some(None), None, None, || None), None);
    }
}
