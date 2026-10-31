#!/usr/bin/env python3
import csv, os, subprocess, sys
from pathlib import Path

os.chdir(Path(__file__).resolve().parent.parent)
corpus = Path(os.environ.get("CORPUS", "ecu-corpus"))
me7sum = os.environ.get("ME7SUM", "./me7sum")
err = []

def check(image):
    print(image, flush=True)
    if not Path(image).is_file():
        err.append(f"MISSING {image}")
        return
    proc = subprocess.run([me7sum, str(image)], text=True, capture_output=True)
    if proc.returncode:
        err.append(f"FAIL {image}")
        err.extend(l for l in proc.stdout.splitlines() if any(s in l for s in ("ABORT", "WARNING", "ERROR")))

tsv = corpus / "corpus.tsv"
if tsv.is_file():
    with tsv.open(newline="") as fh:
        rows = csv.DictReader(fh, delimiter="\t")
        missing = {"name", "checksums"} - set(rows.fieldnames or ())
        if missing:
            sys.exit("corpus.tsv: missing " + ", ".join(sorted(missing)))
        for row in rows:
            if row["checksums"] != "ok":
                continue
            name = row["name"]
            part = name.split("-", 1)[0][:9]
            check(corpus / "images" / part / f"{name}.bin")
elif os.environ.get("REQUIRE_CORPUS") == "1":
    sys.exit(f"no corpus at {corpus} and REQUIRE_CORPUS=1 (see BUILD.md)")
else:
    print(f"no corpus at {corpus}, skipping corpus images (see BUILD.md)", file=sys.stderr)

for image in sorted(Path("testdata/modified").glob("*.bin")):
    check(image)
if err:
    sys.exit("\n".join(err))
