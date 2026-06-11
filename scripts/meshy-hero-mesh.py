#!/usr/bin/env python3
"""Meshy.ai → decimated OBJ pipeline for Eternity City hero meshes.

Input image requirements:
  - Single object, clean/solid background (see docs/visual-ref/city-concept/EternityTower.png)
  - Store concept art in docs/visual-ref/city-concept/
  - Output name follows landmark key, e.g. SkyRailPlaza-18k.obj

Usage:
  python3 scripts/meshy-hero-mesh.py docs/visual-ref/city-concept/<image>.png <LandmarkName>
  python3 scripts/meshy-hero-mesh.py --dry-run docs/visual-ref/city-concept/foo.png SkyRailPlaza
  python3 scripts/meshy-hero-mesh.py --decimate-only /tmp/meshy-raw.obj EternityTower

API key: bridge/.env → MESHY_API_KEY (never commit; never log the value).

Deps:
  pip install requests trimesh fast-simplification networkx

Meshy API (docs.meshy.ai, verified 2026-06-11):
  POST https://api.meshy.ai/openapi/v1/image-to-3d
  GET  https://api.meshy.ai/openapi/v1/image-to-3d/{id}
"""
from __future__ import annotations

import argparse
import base64
import json
import mimetypes
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parent.parent
BRIDGE_ENV = ROOT / "bridge" / ".env"
OUT_DIR = ROOT / "assets" / "City"
TMP_DIR = Path("/tmp")

MESHY_BASE = "https://api.meshy.ai"
CREATE_PATH = "/openapi/v1/image-to-3d"
MAX_FACES = 19_000
MIN_FACES_QUALITY = 12_000
FACE_BUDGET_ROBLOX = 21_000

POLL_INTERVAL_SEC = 8
POLL_TIMEOUT_SEC = 20 * 60


def eprint(*args: object) -> None:
    print(*args, file=sys.stderr)


def load_api_key() -> str:
    if not BRIDGE_ENV.is_file():
        raise SystemExit(f"Missing {BRIDGE_ENV} — add MESHY_API_KEY=... (see bridge/.env.example)")
    for line in BRIDGE_ENV.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        if key.strip() == "MESHY_API_KEY":
            value = value.strip().strip('"').strip("'")
            if value and value not in {"replace-me", "your-meshy-api-key"}:
                return value
    raise SystemExit("MESHY_API_KEY not set in bridge/.env — create key at meshy.ai → Settings → API Keys")


def image_to_data_uri(path: Path) -> str:
    mime, _ = mimetypes.guess_type(str(path))
    if mime not in {"image/png", "image/jpeg", "image/jpg"}:
        raise SystemExit(f"Unsupported image type for {path} — use .png or .jpg")
    raw = path.read_bytes()
    b64 = base64.b64encode(raw).decode("ascii")
    return f"data:{mime};base64,{b64}"


def meshy_request(method: str, path: str, api_key: str, body: dict[str, Any] | None = None) -> dict[str, Any]:
    url = f"{MESHY_BASE}{path}"
    data = None if body is None else json.dumps(body).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=data,
        method=method,
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise SystemExit(f"Meshy API HTTP {exc.code}: {detail[:500]}") from exc


def create_image_to_3d_task(api_key: str, image_uri: str, *, dry_run: bool) -> str:
    if dry_run:
        fake_id = "dry-run-task-00000000-0000-0000-0000-000000000001"
        print(f"[dry-run] would POST {CREATE_PATH} ai_model=latest should_texture=false target_formats=[obj]")
        return fake_id

    payload = {
        "image_url": image_uri,
        "ai_model": "latest",
        "should_texture": False,
        "target_formats": ["obj"],
    }
    resp = meshy_request("POST", CREATE_PATH, api_key, payload)
    task_id = resp.get("result")
    if not task_id:
        raise SystemExit(f"Meshy create task: unexpected response: {resp}")
    print(f"Meshy task created: {task_id}")
    return str(task_id)


def poll_task(api_key: str, task_id: str, *, dry_run: bool) -> dict[str, Any]:
    if dry_run:
        print("[dry-run] would poll GET /openapi/v1/image-to-3d/{id} until SUCCEEDED")
        return {
            "id": task_id,
            "status": "SUCCEEDED",
            "progress": 100,
            "model_urls": {"obj": "dry-run://not-a-real-url"},
        }

    deadline = time.time() + POLL_TIMEOUT_SEC
    while time.time() < deadline:
        task = meshy_request("GET", f"{CREATE_PATH}/{task_id}", api_key)
        status = task.get("status", "UNKNOWN")
        progress = task.get("progress", 0)
        print(f"  status={status} progress={progress}%")
        if status == "SUCCEEDED":
            return task
        if status in {"FAILED", "CANCELED", "EXPIRED"}:
            err = task.get("task_error", {})
            raise SystemExit(f"Meshy task {status}: {err}")
        time.sleep(POLL_INTERVAL_SEC)
    raise SystemExit(f"Meshy task timed out after {POLL_TIMEOUT_SEC}s")


def download_file(url: str, dest: Path, *, dry_run: bool) -> Path:
    dest.parent.mkdir(parents=True, exist_ok=True)
    if dry_run:
        print(f"[dry-run] would download → {dest}")
        return dest
    req = urllib.request.Request(url, headers={"User-Agent": "utopia-meshy-pipeline/1.0"})
    with urllib.request.urlopen(req, timeout=300) as resp:
        dest.write_bytes(resp.read())
    size_mb = dest.stat().st_size / (1024 * 1024)
    print(f"Downloaded {dest.name} ({size_mb:.1f} MB) → {dest}")
    return dest


def bounds_str(mesh: Any) -> str:
    b = mesh.bounds
    ext = mesh.extents
    return f"bounds min={b[0].tolist()} max={b[1].tolist()} extents={ext.tolist()}"


def detect_up_axis(vertices: Any) -> str:
    import numpy as np

    v = np.asarray(vertices, dtype=np.float64)
    if len(v) == 0:
        return "Y"
    mins = v.min(axis=0)
    maxs = v.max(axis=0)
    spans = maxs - mins
    top_slices = {}
    for axis, name in enumerate("XYZ"):
        lo = mins[axis] + spans[axis] * 0.9
        count = int((v[:, axis] >= lo).sum())
        top_slices[name] = count
    # Spire/tip: fewest verts in top 10% slice
    return min(top_slices, key=top_slices.get)


def fix_up_axis_if_needed(mesh: Any) -> tuple[Any, str | None]:
    import numpy as np

    axis = detect_up_axis(mesh.vertices)
    if axis == "Y":
        return mesh, None
    if axis == "Z":
        v = np.asarray(mesh.vertices, dtype=np.float64).copy()
        # Z-up → Y-up: v' = [x, z, -y]
        new_v = np.column_stack([v[:, 0], v[:, 2], -v[:, 1]])
        mesh.vertices = new_v
        return mesh, "rotated Z-up → Y-up (v=[x,z,-y])"
    return mesh, f"warning: dominant top slice axis={axis} (no auto-fix)"


def decimate_mesh(src: Path, name: str, out_path: Path) -> dict[str, Any]:
    import numpy as np
    import fast_simplification as fs
    import trimesh

    raw = trimesh.load(src, force="mesh")
    if not isinstance(raw, trimesh.Trimesh):
        raise SystemExit(f"Expected Trimesh from {src}, got {type(raw)}")

    before_faces = len(raw.faces)
    before_bounds = bounds_str(raw)

    mesh, rot_note = fix_up_axis_if_needed(raw)

    vertices = np.asarray(mesh.vertices, dtype=np.float32)
    faces = np.asarray(mesh.faces, dtype=np.int32)

    def cull_components(tr: trimesh.Trimesh) -> trimesh.Trimesh:
        comps = tr.split(only_watertight=False)
        big = [c for c in comps if c.area > 0.01]
        if not big:
            return tr
        return trimesh.util.concatenate(big) if len(big) > 1 else big[0]

    # target_reduction = fraction of faces REMOVED (fast_simplification API)
    if before_faces <= MAX_FACES:
        best = cull_components(mesh)
        ratio = 0.0
    else:
        keep_ratio = MAX_FACES / before_faces
        ratio = min(0.98, max(0.0, 1.0 - keep_ratio))
        best = None
        for _ in range(12):
            ov, of = fs.simplify(vertices, faces, ratio)
            out = cull_components(trimesh.Trimesh(ov, of, process=False))
            face_count = len(out.faces)
            best = out
            if face_count <= MAX_FACES:
                if face_count >= MIN_FACES_QUALITY or ratio <= 0.01:
                    break
                ratio -= 0.02  # less aggressive (keep more geometry)
                continue
            ratio += 0.02  # more aggressive

    if best is None:
        raise SystemExit("Decimation failed — no geometry remaining")

    after_faces = len(best.faces)
    if after_faces > FACE_BUDGET_ROBLOX:
        raise SystemExit(f"Face count {after_faces} exceeds Roblox budget {FACE_BUDGET_ROBLOX}")

    out_path.parent.mkdir(parents=True, exist_ok=True)
    best.export(out_path)

    comps_final = best.split(only_watertight=False)
    big_final = [c for c in comps_final if c.area > 0.01]

    report = {
        "name": name,
        "src": str(src),
        "out": str(out_path),
        "ratio_final": ratio,
        "faces_before": before_faces,
        "faces_after": after_faces,
        "bounds_before": before_bounds,
        "bounds_after": bounds_str(best),
        "components_after": len(big_final),
        "rotation": rot_note,
    }
    return report


def print_decimate_report(report: dict[str, Any]) -> None:
    print("── Decimate report ──")
    print(f"  landmark:     {report['name']}")
    print(f"  faces:        {report['faces_before']} → {report['faces_after']} (target ≤{MAX_FACES})")
    print(f"  ratio:        {report['ratio_final']}")
    print(f"  components:   {report['components_after']} (want ≥1 main)")
    print(f"  bounds before: {report['bounds_before']}")
    print(f"  bounds after:  {report['bounds_after']}")
    if report.get("rotation"):
        print(f"  up-axis fix:   {report['rotation']}")
    if report["components_after"] < 1:
        print("  WARNING: no substantial components after cull")


def print_next_steps(name: str, out_path: Path) -> None:
    print("\n── Next steps (Cowork / Studio) ──")
    print(f"  1. Open Roblox Studio → Avatar tab → 3D Importer")
    print(f"  2. Import: {out_path}")
    print("  3. Upload to Roblox ✓ → copy rbxassetid://...")
    print(f"  4. GameConfig.HeroMeshes.{name}.MeshId = \"rbxassetid://...\"")
    print("  5. Optional: clone into ServerStorage.HeroMeshes.<Name>")
    print(f"  6. rojo build && Studio F5 — check HeroMeshActive includes {name}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Meshy image-to-3D → decimated hero mesh OBJ")
    parser.add_argument("image", type=Path, help="Concept image (.png/.jpg) or raw OBJ with --decimate-only")
    parser.add_argument("landmark", help="Landmark key, e.g. SkyRailPlaza → SkyRailPlaza-18k.obj")
    parser.add_argument("--dry-run", action="store_true", help="Mock Meshy API; skip download (decimate needs --decimate-only)")
    parser.add_argument(
        "--decimate-only",
        action="store_true",
        help="Skip Meshy API; decimate existing OBJ (image arg = source OBJ path)",
    )
    parser.add_argument("--keep-raw", action="store_true", help="Keep /tmp raw download (default: delete after decimate)")
    args = parser.parse_args()

    name = args.landmark.strip()
    if not name or any(c in name for c in "/\\"):
        raise SystemExit("Landmark name must be a simple key (e.g. EternityTower)")

    out_path = OUT_DIR / f"{name}-18k.obj"

    if args.decimate_only:
        src = args.image
        if not src.is_file():
            raise SystemExit(f"Source OBJ not found: {src}")
        report = decimate_mesh(src, name, out_path)
        print_decimate_report(report)
        print_next_steps(name, out_path)
        return 0

    image_path = args.image
    if not image_path.is_file():
        raise SystemExit(f"Image not found: {image_path}")

    api_key = "" if args.dry_run else load_api_key()
    if args.dry_run:
        print(f"[dry-run] input image: {image_path} (format check skipped)")
        image_uri = "data:image/png;base64,DRYRUN"
    else:
        image_uri = image_to_data_uri(image_path)
        print(f"Input image: {image_path} ({image_path.stat().st_size // 1024} KB)")
    print(f"Output:      {out_path}")

    task_id = create_image_to_3d_task(api_key, image_uri, dry_run=args.dry_run)
    task = poll_task(api_key, task_id, dry_run=args.dry_run)

    if args.dry_run:
        print("\n[dry-run] Pipeline structure OK — use without --dry-run + real MESHY_API_KEY to generate.")
        print("          Or test decimate: --decimate-only assets/City/<existing>.obj <Name>")
        return 0

    model_urls = task.get("model_urls") or {}
    obj_url = model_urls.get("obj")
    if not obj_url:
        raise SystemExit(f"No OBJ URL in task response. model_urls keys: {list(model_urls)}")

    raw_path = TMP_DIR / f"meshy-{name}-raw.obj"
    download_file(obj_url, raw_path, dry_run=False)

    report = decimate_mesh(raw_path, name, out_path)
    print_decimate_report(report)

    if not args.keep_raw:
        try:
            raw_path.unlink(missing_ok=True)
            print(f"Removed raw file: {raw_path}")
        except OSError as exc:
            eprint(f"Could not remove {raw_path}: {exc}")

    print_next_steps(name, out_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
