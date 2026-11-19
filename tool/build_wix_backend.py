"""Builds wix/backend/http-functions.js: the one file to paste into The Herd's Wix site.

It joins the shared rules (shared/rules.js) and the checker (wix/backend/handlers.src.js),
so the website, the app and Wix all use the same rules. Run from the project folder:

    python3 tool/build_wix_backend.py
"""
import pathlib
import re

root = pathlib.Path(__file__).resolve().parent.parent
rules = (root / "shared/rules.js").read_text(encoding="utf-8")
handlers = (root / "wix/backend/handlers.src.js").read_text(encoding="utf-8")

# Inside the Wix file only the post_ functions are exported; the rules become plain functions.
rules = re.sub(r"^export ", "", rules, flags=re.M)
rules = "\n".join(l for l in rules.splitlines() if not l.startswith("// Rules for Herd") and "build_wix_backend" not in l and "They match the app" not in l)

imports, body = [], []
for line in handlers.splitlines():
    (imports if line.startswith("import ") else body).append(line)

out = "\n".join(
    [
        "// Built by tool/build_wix_backend.py from shared/rules.js and wix/backend/handlers.src.js.",
        "// Paste this whole file into your Wix site as backend/http-functions.js (see wix/README.md).",
        "",
        *imports,
        "",
        "// ── Rules (same as the app and the website) ──",
        rules.strip(),
        "",
        *body,
        "",
    ]
)
(root / "wix/backend/http-functions.js").write_text(out, encoding="utf-8")
print("wrote wix/backend/http-functions.js", len(out), "characters")
