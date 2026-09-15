"""Logging + file-change manifest utilities."""
import datetime, hashlib, json, sys
from pathlib import Path

try:
    from .config import LOG_DIR
except ImportError:
    from config import LOG_DIR

LOG_FILE = LOG_DIR / "pipeline.log"
MANIFEST = LOG_DIR / "file_manifest.json"
CHANGELOG = LOG_DIR / "CHANGELOG.md"


def log(msg: str, level: str = "INFO") -> None:
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    line = f"[{ts}] {level.upper():7} {msg}"
    print(line, file=sys.stderr)
    with LOG_FILE.open("a", encoding="utf-8") as f:
        f.write(line + "\n")


def sha1(path: Path) -> str:
    h = hashlib.sha1()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def file_manifest() -> None:
    """Record sha1 + size + mtime of every raw source and every output file."""
    try:
        from .config import DATA_DIR, ANALYTICS_DIR, REPORT_DIR
    except ImportError:
        from config import DATA_DIR, ANALYTICS_DIR, REPORT_DIR
    entries = {}
    for base in (DATA_DIR, ANALYTICS_DIR, REPORT_DIR):
        if not base.exists():
            continue
        for p in sorted(base.rglob("*")):
            if p.is_file():
                st = p.stat()
                entries[str(p.relative_to(Path(__file__).resolve().parents[2]))] = {
                    "sha1": sha1(p), "bytes": st.st_size,
                    "mtime": datetime.datetime.fromtimestamp(st.st_mtime).isoformat(),
                }
    with MANIFEST.open("w", encoding="utf-8") as f:
        json.dump(entries, f, indent=2, sort_keys=True)


def bump_changelog(entry: str) -> None:
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with CHANGELOG.open("a", encoding="utf-8") as f:
        f.write(f"## {ts}\n- {entry}\n")