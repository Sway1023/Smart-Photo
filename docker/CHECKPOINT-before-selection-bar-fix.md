# Checkpoint: before selection bar layout fix

Created before implementing the selection bar / topbar layout plan.

## Rollback selection bar plan only

After the layout fix commit(s), to undo **only** those changes while keeping this checkpoint:

```powershell
cd d:\AWOL\immich
git log --oneline -5
# Find commits after this checkpoint, then:
git revert <selection-bar-fix-commit-hash>
```

Or reset to this checkpoint (discards all commits after it):

```powershell
git reset --hard <checkpoint-commit-hash>
```

## Rollback everything to pre-checkpoint

```powershell
git reset --hard <checkpoint-commit-hash>
```

Note: `docker/import/test/` test images are not in git (local only).
