#!/usr/bin/env python3
"""
Modifies appearances.dat: sets item 44780's sprite ID to 599628.
Usage: python edit_appearance.py
"""

import os
import sys
import subprocess
import shutil

SCRIPT_DIR    = os.path.dirname(os.path.abspath(__file__))
PROTO_FILE    = os.path.join(SCRIPT_DIR, "src", "protobuf", "appearances.proto")
PROTOC        = os.path.join(SCRIPT_DIR, "vcpkg_installed", "x64-windows", "tools", "protobuf", "protoc.exe")
APPEARANCES   = os.path.join(SCRIPT_DIR, "data", "items", "appearances.dat")
BACKUP        = APPEARANCES + ".bak2"

if len(sys.argv) != 3:
    print("Usage: python edit_appearance.py <item_id> <sprite_id>")
    print("Example: python edit_appearance.py 44780 599628")
    sys.exit(1)

ITEM_ID       = int(sys.argv[1])
NEW_SPRITE_ID = int(sys.argv[2])

# ── 1. Generate pb2 ──────────────────────────────────────────────────────────
pb2_path = os.path.join(SCRIPT_DIR, "appearances_pb2.py")
result = subprocess.run(
    [PROTOC,
     f"--proto_path={os.path.dirname(PROTO_FILE)}",
     f"--python_out={SCRIPT_DIR}",
     PROTO_FILE],
    capture_output=True, text=True
)
if result.returncode != 0:
    print("protoc error:", result.stderr)
    sys.exit(1)

sys.path.insert(0, SCRIPT_DIR)
import appearances_pb2 as pb2

# ── 2. Load appearances.dat ───────────────────────────────────────────────────
with open(APPEARANCES, "rb") as f:
    data = f.read()

appearances = pb2.Appearances()
appearances.ParseFromString(data)

# ── 3. Find item 44780 and update sprite ─────────────────────────────────────
found = False
for obj in appearances.object:
    if obj.id == ITEM_ID:
        found = True
        for fg in obj.frame_group:
            if fg.HasField("sprite_info"):
                old = list(fg.sprite_info.sprite_id)
                del fg.sprite_info.sprite_id[:]
                fg.sprite_info.sprite_id.append(NEW_SPRITE_ID)
                print(f"Item {ITEM_ID}: sprite_id {old} -> [{NEW_SPRITE_ID}]")
        break

if not found:
    print(f"ERROR: item {ITEM_ID} not found in appearances.dat")
    sys.exit(1)

# ── 4. Backup and save ───────────────────────────────────────────────────────
shutil.copy2(APPEARANCES, BACKUP)
print(f"Backup saved to {BACKUP}")

with open(APPEARANCES, "wb") as f:
    f.write(appearances.SerializeToString())

print(f"appearances.dat updated successfully.")
