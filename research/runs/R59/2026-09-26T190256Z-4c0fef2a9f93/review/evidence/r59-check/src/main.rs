//! R59 synthesis probe scenarios. Usage: r59-check <scenario> <dir> [args...]
//! Every scenario prints `key=value` lines that the evidence scripts assert on.

use std::fs;
use std::io::{self, Write};
use std::panic::{AssertUnwindSafe, catch_unwind};
use std::path::{Path, PathBuf};
use std::sync::Mutex;
use std::time::Instant;

use file_rotate::{ContentLimit, FileRotate, compression::Compression, suffix::AppendCount};
use r59_check::RotatingFile;
use tracing::{debug, info, warn};
use tracing_subscriber::filter::LevelFilter;
use tracing_subscriber::prelude::*;
use tracing_subscriber::{Layer, Registry, fmt, reload};

const PAD: &str = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";
const BACKUPS: usize = 5;

type BoxWriter = Box<dyn Write + Send>;

fn writer(kind: &str, path: &Path, max: u64) -> BoxWriter {
    match kind {
        "owned" => Box::new(RotatingFile::open(path, max, BACKUPS).expect("owned open")),
        "fr-bytes" => Box::new(FileRotate::new(
            path,
            AppendCount::new(BACKUPS),
            ContentLimit::Bytes(max as usize),
            Compression::None,
            None,
        )),
        "fr-surpassed" => Box::new(FileRotate::new(
            path,
            AppendCount::new(BACKUPS),
            ContentLimit::BytesSurpassed(max as usize),
            Compression::None,
            None,
        )),
        other => panic!("unknown writer {other}"),
    }
}

fn file_layer<S>(w: BoxWriter) -> impl Layer<S> + Send + Sync
where
    S: tracing::Subscriber + for<'a> tracing_subscriber::registry::LookupSpan<'a>,
{
    fmt::layer().with_writer(Mutex::new(w)).with_ansi(false).without_time().with_target(false)
}

fn console<S>() -> impl Layer<S> + Send + Sync
where
    S: tracing::Subscriber + for<'a> tracing_subscriber::registry::LookupSpan<'a>,
{
    fmt::layer().with_writer(io::stderr).without_time().with_target(false)
}

fn emit_records(n: usize) {
    for i in 0..n {
        info!("event seq={:06} pad={}", i, PAD);
    }
}

/// Classify every line of a file: a whole record is ` INFO event seq=NNNNNN pad=<PAD>`.
fn scan_file(p: &Path) -> (u64, usize, usize, Option<u64>, Option<u64>) {
    let bytes = fs::read(p).unwrap_or_default();
    let text = String::from_utf8_lossy(&bytes);
    let (mut whole, mut partial, mut first, mut last) = (0, 0, None, None);
    let lines: Vec<&str> = text.split_inclusive('\n').collect();
    for l in &lines {
        let body = l.strip_suffix('\n');
        let seq = body
            .and_then(|b| b.strip_prefix(" INFO event seq="))
            .and_then(|r| r.strip_suffix(&format!(" pad={PAD}")[..]))
            .and_then(|s| s.parse::<u64>().ok());
        match seq {
            Some(s) => {
                whole += 1;
                first.get_or_insert(s);
                last = Some(s);
            }
            None => partial += 1,
        }
    }
    (bytes.len() as u64, whole, partial, first, last)
}

fn scan_dir(dir: &Path, base: &str) {
    let mut names: Vec<String> =
        fs::read_dir(dir).unwrap().filter_map(|e| e.ok()).map(|e| e.file_name().to_string_lossy().into_owned()).collect();
    names.sort();
    println!("files={}", names.join(","));
    let (mut total_whole, mut total_partial) = (0, 0);
    for name in &names {
        let (size, whole, partial, first, last) = scan_file(&dir.join(name));
        total_whole += whole;
        total_partial += partial;
        let suffix = name.strip_prefix(base).unwrap_or(name);
        println!(
            "file[{}] size={} whole={} partial={} first_seq={} last_seq={}",
            if suffix.is_empty() { "base" } else { suffix },
            size,
            whole,
            partial,
            first.map_or("-".into(), |v| v.to_string()),
            last.map_or("-".into(), |v| v.to_string())
        );
    }
    println!("total_whole={total_whole} total_partial={total_partial}");
}

fn main() -> io::Result<()> {
    let args: Vec<String> = std::env::args().collect();
    let scenario = args.get(1).map(String::as_str).unwrap_or("");
    let dir = PathBuf::from(args.get(2).expect("dir"));
    fs::create_dir_all(&dir)?;
    let log = dir.join("rslbp.log");
    match scenario {
        // B: rotation layout and record integrity, 4,096-byte limit, 5 backups.
        "rotate" => {
            let kind = &args[3];
            let n: usize = args[4].parse().unwrap();
            let sub = Registry::default().with(file_layer(writer(kind, &log, 4096)));
            tracing::subscriber::set_global_default(sub).unwrap();
            emit_records(n);
            scan_dir(&dir, "rslbp.log");
        }
        // A: dual-sink floor. Console (stderr) WARN, file DEBUG.
        "floor" => {
            let mode = &args[3];
            let fw = || writer("owned", &log, 10 * 1024 * 1024);
            match mode.as_str() {
                "per-layer" => {
                    // The template's form: a runtime-optional file layer in a Vec<Box<dyn Layer<Registry>>>.
                    let file: Option<Box<dyn Layer<Registry> + Send + Sync>> =
                        Some(file_layer(fw()).with_filter(LevelFilter::DEBUG).boxed());
                    let layers: Vec<Box<dyn Layer<Registry> + Send + Sync>> =
                        std::iter::once(console().with_filter(LevelFilter::WARN).boxed()).chain(file).collect();
                    tracing::subscriber::set_global_default(Registry::default().with(layers)).unwrap();
                }
                "nofile" => {
                    let file: Option<Box<dyn Layer<Registry> + Send + Sync>> = None;
                    let layers: Vec<Box<dyn Layer<Registry> + Send + Sync>> =
                        std::iter::once(console().with_filter(LevelFilter::WARN).boxed()).chain(file).collect();
                    tracing::subscriber::set_global_default(Registry::default().with(layers)).unwrap();
                }
                "global" => {
                    let sub = Registry::default()
                        .with(LevelFilter::WARN)
                        .with(console().with_filter(LevelFilter::WARN))
                        .with(file_layer(fw()).with_filter(LevelFilter::DEBUG));
                    tracing::subscriber::set_global_default(sub).unwrap();
                }
                "json" => {
                    let file = fmt::layer().with_writer(Mutex::new(fw())).with_ansi(false).json();
                    let sub = Registry::default()
                        .with(console().with_filter(LevelFilter::WARN))
                        .with(file.with_filter(LevelFilter::DEBUG));
                    tracing::subscriber::set_global_default(sub).unwrap();
                }
                other => panic!("unknown floor mode {other}"),
            }
            println!("current={}", LevelFilter::current());
            debug!(token_len = 3, "debug-event");
            warn!("warn-event");
            let text = fs::read_to_string(&log).unwrap_or_default();
            for l in text.lines() {
                println!("file_line={l}");
            }
            let json_ok = text.lines().filter(|l| serde_json::from_str::<serde_json::Value>(l).is_ok()).count();
            println!("file_lines={} file_json_lines={}", text.lines().count(), json_ok);
        }
        // E: terminal escape bytes in the file.
        "ansi" => {
            let mode = &args[3];
            let base = fmt::layer().with_writer(Mutex::new(writer("owned", &log, 10 * 1024 * 1024)));
            let layer = if mode == "default" { base } else { base.with_ansi(false) };
            tracing::subscriber::set_global_default(Registry::default().with(layer)).unwrap();
            warn!(user_input = "\u{1b}[31mred\u{1b}[0m", "ansi-event");
            let bytes = fs::read(&log)?;
            println!("esc_bytes={}", bytes.iter().filter(|b| **b == 0x1b).count());
            println!("file_text={}", String::from_utf8_lossy(&bytes).escape_debug());
        }
        // C: records on disk after process::exit(0) (a signal or early-exit path).
        "exit" => {
            let kind = &args[3];
            let n: usize = args[4].parse().unwrap();
            match kind.as_str() {
                "owned" | "fr-surpassed" => {
                    let sub = Registry::default().with(file_layer(writer(kind, &log, 10 * 1024 * 1024)));
                    tracing::subscriber::set_global_default(sub).unwrap();
                    emit_records(n);
                    std::process::exit(0);
                }
                "nonblocking" | "nonblocking-return" => {
                    let (nb, guard) = tracing_appender::non_blocking::NonBlockingBuilder::default()
                        .lossy(false)
                        .finish(RotatingFile::open(&log, 10 * 1024 * 1024, BACKUPS)?);
                    let layer = fmt::layer().with_writer(nb).with_ansi(false).without_time().with_target(false);
                    tracing::subscriber::set_global_default(Registry::default().with(layer)).unwrap();
                    emit_records(n);
                    if kind == "nonblocking" {
                        std::process::exit(0);
                    }
                    drop(guard);
                }
                other => panic!("unknown exit writer {other}"),
            }
        }
        // F1: constructor when the parent directory cannot be created.
        "ctor-fail" => {
            fs::write(dir.join("blocker"), b"a regular file")?;
            let p = dir.join("blocker").join("sub").join("rslbp.log");
            match RotatingFile::open(&p, 4096, BACKUPS) {
                Ok(_) => println!("owned=Ok"),
                Err(e) => println!("owned=Err({:?})", e.kind()),
            }
            let r = catch_unwind(AssertUnwindSafe(|| {
                FileRotate::new(&p, AppendCount::new(BACKUPS), ContentLimit::BytesSurpassed(4096), Compression::None, None)
            }));
            println!("file_rotate_panicked={}", r.is_err());
        }
        // F2: the log path itself is unopenable (it is a directory).
        "unopenable" => {
            fs::create_dir_all(&log)?;
            match RotatingFile::open(&log, 4096, BACKUPS) {
                Ok(_) => println!("owned=Ok"),
                Err(e) => println!("owned=Err({:?})", e.kind()),
            }
            let mut fr = FileRotate::new(&log, AppendCount::new(BACKUPS), ContentLimit::BytesSurpassed(4096), Compression::None, None);
            println!("file_rotate_write={:?}", fr.write(b"0123456789"));
            println!("file_rotate_flush={:?}", fr.flush());
        }
        // F3: the log directory disappears mid-run; `blocked` replaces it with a regular file.
        "dirgone" => {
            let kind = &args[3];
            let variant = &args[4];
            let logs = dir.join("logs");
            let p = logs.join("rslbp.log");
            let mut w = writer(kind, &p, 64);
            w.write_all(b"before-1\n")?;
            fs::remove_dir_all(&logs)?;
            if variant == "blocked" {
                fs::write(&logs, b"blocker")?;
            }
            for i in 0..3 {
                let r = catch_unwind(AssertUnwindSafe(|| w.write(&[b'y'; 80])));
                match r {
                    Err(_) => println!("write[{i}]=PANICKED"),
                    Ok(res) => println!("write[{i}]={:?}", res.map_err(|e| e.kind())),
                }
            }
        }
        // F5: B8 end to end: the owned writer's error surfaces on stderr through the fmt layer,
        // the event is lost, and the program continues to a normal exit.
        "report" => {
            // args[3]: `default` keeps tracing-subscriber's default; `on` sets log_internal_errors(true).
            let logs = dir.join("logs");
            let layer = fmt::layer()
                .with_writer(Mutex::new(writer("owned", &logs.join("rslbp.log"), 64)))
                .with_ansi(false)
                .without_time()
                .with_target(false);
            let layer = if args[3] == "on" { layer.log_internal_errors(true) } else { layer };
            tracing::subscriber::set_global_default(Registry::default().with(layer)).unwrap();
            info!("event seq={:06} pad={}", 0, PAD);
            fs::remove_dir_all(&logs)?;
            info!("event seq={:06} pad={}", 1, PAD);
            info!("event seq={:06} pad={}", 2, PAD);
            println!("continued=true");
        }
        // F4: two writers (two CLI processes' worth) share one path; interleaved writes.
        "shared" => {
            let kind = &args[3];
            let mut a = writer(kind, &log, 400);
            let mut b = writer(kind, &log, 400);
            let (mut panics, mut errs) = (0, 0);
            for i in 0..60 {
                let line = format!(" INFO event seq={:06} pad={}\n", i, PAD);
                let w = if i % 2 == 0 { &mut a } else { &mut b };
                match catch_unwind(AssertUnwindSafe(|| w.write_all(line.as_bytes()))) {
                    Err(_) => panics += 1,
                    Ok(Err(_)) => errs += 1,
                    Ok(Ok(())) => {}
                }
            }
            println!("panics={panics} errors={errs}");
            scan_dir(&dir, "rslbp.log");
        }
        // D: indicative throughput, 100,000 events, 10 MiB limit, text format.
        "bench" => {
            let kind = &args[3];
            let n = 100_000;
            let start = Instant::now();
            if kind == "owned-nonblocking" {
                let (nb, guard) = tracing_appender::non_blocking::NonBlockingBuilder::default()
                    .lossy(false)
                    .finish(RotatingFile::open(&log, 10 * 1024 * 1024, BACKUPS)?);
                let layer = fmt::layer().with_writer(nb).with_ansi(false);
                let _d = tracing::subscriber::set_default(Registry::default().with(layer));
                for i in 0..n {
                    info!(seq = i, pad = PAD, "bench");
                }
                let emit = start.elapsed();
                drop(guard);
                println!("emit_ms={} total_ms={}", emit.as_millis(), start.elapsed().as_millis());
            } else {
                let layer = fmt::layer().with_writer(Mutex::new(writer(kind, &log, 10 * 1024 * 1024))).with_ansi(false);
                let _d = tracing::subscriber::set_default(Registry::default().with(layer));
                for i in 0..n {
                    info!(seq = i, pad = PAD, "bench");
                }
                let t = start.elapsed().as_millis();
                println!("emit_ms={t} total_ms={t}");
            }
        }
        // K (revision 4): the reload sink slot. Installed first with the slot empty (body None,
        // per-layer filter OFF); the file sink is attached after config resolution by reloading
        // the body and modifying the filter. The filter sits outside the swapped body because
        // Handle::reload cannot replace a Filtered layer (reload.rs:289-297, tokio-rs/tracing#1629).
        "slot" => {
            let mode = &args[3];
            type Body = Option<Box<dyn Layer<Registry> + Send + Sync>>;
            let (slot_filter, filter_h) = reload::Layer::<LevelFilter, Registry>::new(LevelFilter::OFF);
            let (slot_body, body_h) = reload::Layer::<Body, Registry>::new(None);
            let layers: Vec<Box<dyn Layer<Registry> + Send + Sync>> = vec![
                console().with_filter(LevelFilter::WARN).boxed(),
                slot_body.with_filter(slot_filter).boxed(),
            ];
            match Registry::default().with(layers).try_init() {
                Ok(()) => println!("try_init=Ok"),
                Err(e) => println!("try_init=Err({e})"),
            }
            println!("current_before={}", LevelFilter::current());
            debug!("pre-attach-debug");
            warn!("pre-attach-warn");
            println!("file_before_attach={}", if log.exists() { "yes" } else { "no" });
            let w = Mutex::new(RotatingFile::open(&log, 10 * 1024 * 1024, BACKUPS)?);
            let body: Box<dyn Layer<Registry> + Send + Sync> = match mode.as_str() {
                "text" => fmt::layer().with_writer(w).with_ansi(false).without_time().with_target(false).boxed(),
                "json" => fmt::layer().with_writer(w).with_ansi(false).json().boxed(),
                other => panic!("unknown slot mode {other}"),
            };
            println!("reload={:?}", body_h.reload(Some(body)).map_err(|e| e.to_string()));
            println!("modify={:?}", filter_h.modify(|f| *f = LevelFilter::DEBUG).map_err(|e| e.to_string()));
            println!("current_after={}", LevelFilter::current());
            debug!(token_len = 3, "post-attach-debug");
            warn!("post-attach-warn");
            let text = fs::read_to_string(&log).unwrap_or_default();
            for l in text.lines() {
                println!("file_line={l}");
            }
            let json_ok = text.lines().filter(|l| serde_json::from_str::<serde_json::Value>(l).is_ok()).count();
            println!("file_lines={} file_json_lines={}", text.lines().count(), json_ok);
        }
        other => panic!("unknown scenario {other:?}"),
    }
    Ok(())
}
