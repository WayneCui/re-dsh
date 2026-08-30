#!/usr/bin/env python3
"""Markdown (zh) -> HTML -> Chrome headless PDF."""
from __future__ import annotations

import argparse
import subprocess
import sys
import tempfile
from pathlib import Path

import markdown
from pygments.formatters import HtmlFormatter

CSS = r"""
:root {
  --ink: #1c1917;
  --rule: #e7e5e4;
  --accent: #1e3a5f;
  --accent-soft: #e8eef5;
  --code-bg: #f6f4f1;
  --link: #1d4ed8;
}
* { box-sizing: border-box; }
html { font-size: 11.5pt; }
body {
  margin: 0;
  color: var(--ink);
  background: #fff;
  font-family: "PingFang SC", "Hiragino Sans GB", "Noto Sans CJK SC", "Source Han Sans SC", "Songti SC", sans-serif;
  line-height: 1.85;
  text-rendering: optimizeLegibility;
  -webkit-font-smoothing: antialiased;
}
article { max-width: 42rem; margin: 0 auto; }
h1 {
  font-size: 2.05rem;
  font-weight: 650;
  letter-spacing: 0.04em;
  line-height: 1.35;
  color: var(--accent);
  margin: 0 0 1.4rem;
  padding-bottom: 0.7rem;
  border-bottom: 2.5px solid var(--accent);
}
h2 {
  font-size: 1.22rem;
  font-weight: 650;
  color: var(--accent);
  line-height: 1.45;
  margin: 2.1rem 0 0.85rem;
  padding: 0.35rem 0 0.35rem 0.75rem;
  border-left: 4px solid var(--accent);
  page-break-after: avoid;
  break-after: avoid;
}
h3 {
  font-size: 1.05rem;
  font-weight: 650;
  margin: 1.5rem 0 0.55rem;
  color: #292524;
  page-break-after: avoid;
}
p { margin: 0.75rem 0; text-align: justify; }
strong { font-weight: 650; color: #0c0a09; }
a { color: var(--link); text-decoration: none; border-bottom: 1px solid rgba(29,78,216,0.25); }
code {
  font-family: "SF Mono", "Menlo", "JetBrains Mono", "PingFang SC", monospace;
  font-size: 0.86em;
  background: var(--code-bg);
  padding: 0.08em 0.32em;
  border-radius: 3px;
  word-break: break-word;
}
pre {
  background: var(--code-bg);
  border: 1px solid var(--rule);
  border-radius: 6px;
  padding: 0.85rem 1rem;
  overflow: hidden;
  line-height: 1.55;
  font-size: 0.82rem;
  page-break-inside: avoid;
  break-inside: avoid;
}
pre code { background: transparent; padding: 0; font-size: inherit; white-space: pre-wrap; word-break: break-all; }
.highlight { background: var(--code-bg); }
.highlight pre { margin: 0; background: transparent; border: 0; padding: 0; }
ul, ol { margin: 0.55rem 0 0.9rem; padding-left: 1.4rem; }
li { margin: 0.22rem 0; }
hr { border: 0; border-top: 1px solid var(--rule); margin: 1.8rem 0; }
.toc {
  background: var(--accent-soft);
  border-radius: 8px;
  padding: 1rem 1.2rem 0.85rem;
  margin: 0 0 1.8rem;
  page-break-inside: avoid;
}
.toc-title {
  margin: 0 0 0.35rem;
  font-weight: 650;
  letter-spacing: 0.18em;
  color: var(--accent);
  font-size: 0.92rem;
}
.toc ul { list-style: none; padding-left: 0; margin: 0; }
.toc li { margin: 0.28rem 0; }
.toc a { color: var(--accent); border-bottom: none; }
@page { size: A4; margin: 18mm 16mm; }
@media print { body { background: #fff; } a { color: inherit; border-bottom: none; } }
"""

CHROME = Path("/Applications/Google Chrome.app/Contents/MacOS/Google Chrome")


def md_to_html(src: Path, title: str) -> str:
    text = src.read_text(encoding="utf-8")
    md = markdown.Markdown(
        extensions=["extra", "codehilite", "toc", "sane_lists"],
        extension_configs={
            "codehilite": {"css_class": "highlight", "guess_lang": False, "linenums": False},
            "toc": {"permalink": False, "toc_depth": "2-2"},
        },
    )
    body = md.convert(text)
    toc = md.toc or ""
    if "</h1>" in body and toc:
        toc_block = f'<nav class="toc"><p class="toc-title">目录</p>{toc}</nav>'
        body = body.replace("</h1>", "</h1>\n" + toc_block, 1)
    pygments_css = HtmlFormatter(style="tango").get_style_defs(".highlight")
    return f"""<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<title>{title}</title>
<style>
{pygments_css}
{CSS}
</style>
</head>
<body>
<article>
{body}
</article>
</body>
</html>
"""


def print_pdf(html_path: Path, pdf_path: Path) -> None:
    if not CHROME.is_file():
        sys.exit(f"Chrome not found: {CHROME}")
    with tempfile.TemporaryDirectory(prefix="chrome-pdf-") as udd:
        cmd = [
            str(CHROME),
            "--headless=new",
            "--disable-gpu",
            "--no-first-run",
            "--no-default-browser-check",
            f"--user-data-dir={udd}",
            "--no-pdf-header-footer",
            "--virtual-time-budget=10000",
            f"--print-to-pdf={pdf_path}",
            f"file://{html_path.resolve()}",
        ]
        subprocess.run(cmd, check=True)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("src", type=Path)
    ap.add_argument("-o", "--output", type=Path)
    ap.add_argument("-t", "--title", default="")
    args = ap.parse_args()
    src = args.src.resolve()
    out = args.output or src.with_suffix(".pdf")
    title = args.title or src.stem
    html = md_to_html(src, title)
    with tempfile.NamedTemporaryFile("w", suffix=".html", delete=False, encoding="utf-8") as f:
        f.write(html)
        html_path = Path(f.name)
    try:
        print_pdf(html_path, out.resolve())
        print(f"Wrote {out} ({out.stat().st_size} bytes)")
    finally:
        html_path.unlink(missing_ok=True)


if __name__ == "__main__":
    main()
