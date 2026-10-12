"""检查仓库内 Markdown 相对链接是否都存在。用法: python check-links.py <仓库根目录>"""
import os, re, sys

root = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
pat = re.compile(r"\[[^\]]*\]\(([^)]+)\)")
bad = 0
checked = 0

for dirpath, dirnames, filenames in os.walk(root):
    dirnames[:] = [d for d in dirnames if d not in {".git", "node_modules"}]
    for fn in filenames:
        if not fn.endswith(".md"):
            continue
        fp = os.path.join(dirpath, fn)
        rel_fp = os.path.relpath(fp, root)
        text = open(fp, encoding="utf-8").read()
        for m in pat.finditer(text):
            target = m.group(1).strip()
            if target.startswith(("http://", "https://", "mailto:", "#")):
                continue
            target = target.split("#", 1)[0]
            if not target:
                continue
            checked += 1
            resolved = os.path.normpath(os.path.join(dirpath, target))
            if not os.path.exists(resolved):
                bad += 1
                print(f"BROKEN  {rel_fp}  ->  {target}")

print(f"\nchecked={checked} broken={bad} root={root}")
