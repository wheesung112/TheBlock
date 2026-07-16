# Large Asset Publish Design

## Goal

Publish the current Unity project to `origin/main` without corrupting assets, while satisfying GitHub's regular Git object and push-size limits.

## Constraints

- Preserve Unity `.meta` files and GUIDs.
- Keep an external backup of every file changed by lossy processing.
- Do not directly edit Unity binary `TerrainData` serialization.
- Keep every regular Git object below 100 MiB and the regular Git push below 2 GiB.
- Preserve all current user work unless a file is intentionally replaced by its optimized equivalent.
- Use Unity Editor `6000.0.23f1`, matching `ProjectSettings/ProjectVersion.txt`, for asset validation.

## Approach

Use a hybrid optimization strategy:

1. Back up affected assets outside the repository.
2. Downscale committed 4096x4096 PNG files larger than 50 MiB to 2048x2048 using a deterministic high-quality resampler. Preserve alpha channels and file paths so Unity GUID references remain unchanged.
3. Track TerrainData and other large binary assets with Git LFS instead of rewriting their binary contents. Include `.asset` files only when they exceed the regular Git threshold; include large `.png`, `.exr`, `.hdr`, `.fbx`, and similar binary files when needed to keep the Git pack under the push limit.
4. Rewrite the single unpushed `Texture Test` commit so large historical blobs are no longer present as regular Git objects.
5. Inspect the mixed working tree before staging. Preserve intended renames, additions, deletions, and modifications, and scan script/config additions for credentials.
6. Validate file decodability, Git LFS pointer coverage, Git object sizes, and the Unity project in batch mode.
7. Commit using the repository Lore commit protocol, push `main`, then verify that local and remote `main` resolve to the same commit.

## Image Processing Rules

- Only resize source PNGs that are both 4096x4096 and larger than 50 MiB.
- Output resolution is 2048x2048.
- Preserve PNG format, alpha, color mode where supported, filename, and `.meta` sidecar.
- Do not modify normal-map semantics or Unity importer settings.
- Reject an output if it cannot be decoded, has unexpected dimensions, loses an existing alpha channel, or is not smaller than its input.
- Restore the original from backup on any failed validation.

## Terrain and Large Binary Rules

- Do not byte-edit or externally resample TerrainData `.asset` files.
- Route the two known oversized TerrainData files through Git LFS.
- Route any remaining blob at or above 100 MiB through Git LFS or exclude it when it is generated/disposable and already covered by repository policy.
- Do not delete third-party assets merely to reduce repository size.

## Validation

- Every resized PNG opens successfully and reports 2048x2048 dimensions.
- Existing alpha presence is unchanged.
- `git lfs fsck` succeeds.
- No regular Git blob in the outgoing history is 100 MiB or larger.
- Estimated/generated regular Git pack is below 2 GiB.
- Unity batch-mode project open completes without asset import or serialization errors attributable to the conversion.
- No secrets are added from the untracked scripts or configuration files.
- `git status`, outgoing commit contents, and remote commit ID are reviewed after push.

## Rollback

Keep timestamped originals outside the repository until the remote verification succeeds. If image or Unity validation fails, restore only the affected files and repeat validation before any commit or push.
