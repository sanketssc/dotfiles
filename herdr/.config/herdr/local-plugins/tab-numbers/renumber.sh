#!/bin/sh
# Rename every tab to its 1-based position within its workspace; skip tabs already correct.
H="${HERDR_BIN_PATH:-herdr}"
"$H" tab list 2>/dev/null | /usr/bin/env python3 -c '
import json, sys, collections
tabs = json.load(sys.stdin)["result"]
tabs = tabs.get("tabs", tabs)
pos = collections.Counter()
for t in tabs:
    pos[t["workspace_id"]] += 1
    want = str(pos[t["workspace_id"]])
    if t.get("label") != want:
        print(t["tab_id"], want)
' | while read -r id n; do
  "$H" tab rename "$id" "$n" >/dev/null 2>&1
done
