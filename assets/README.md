# assets/ — kho model gốc (.glb) cho map

Quy chuẩn, thư mục, đặt tên và **asset sheet** (danh sách model cần làm theo zone): [`docs/ASSET_GUIDELINES.md`](../docs/ASSET_GUIDELINES.md).
Point trong map → file: [`asset_manifest.json`](asset_manifest.json).

- `environment/`, `props/`, `creatures/`: model **thật** (AI 3D / library, đã cleanup) — commit qua Git LFS.
- `_procedural/`: bản tạm dựng bằng `python blender/scripts/make_assets.py` (gitignore, sinh lại được).
  File thật cùng tên luôn thắng bản procedural.
