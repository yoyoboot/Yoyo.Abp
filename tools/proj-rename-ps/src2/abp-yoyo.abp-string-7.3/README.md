```powershell
./run.ps1 -Src "D:\dev\abp-fx\aspnetboilerplate-v7-pk"
```

## Governance config

This engine now reads its compatibility package surface and generation metadata from `config/`:

- `library-profile-33-compat.json`
- `test-profile-33-compat.json`
- `version-generations.json`
- `legacy-package-exclusions.json`

Do not change package-surface or generation behavior by editing `run.ps1` directly. Update the manifests and matching tests first.

## 注意！
aspnet-core-demo目录下的项目需要自己手动改