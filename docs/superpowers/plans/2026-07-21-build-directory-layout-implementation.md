# CPDS Build Directory Layout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move CPDS build scripts and generated artifacts into the approved `build/` hierarchy while preserving `.tools/`, existing artifacts, and runtime data, then remove the emptied legacy directories.

**Architecture:** Keep source and runtime behavior unchanged. Build and test entry points move to `build/scripts/`, generated applications move to `build/dist/bin/`, and three reserved directories are tracked with `.gitkeep`; all active path references follow the new layout.

**Tech Stack:** PowerShell, Windows batch, Go tests, npm/Vite, Git

---

### Task 1: Lock the New Layout with a Failing Test

**Files:**
- Modify: `tests/build_script_test.go`
- Test: `tests/build_script_test.go`

- [ ] **Step 1: Add a repository-root helper and point the existing tests at the new script directory**

Replace the duplicated `runtime.Caller` blocks with this helper:

```go
func repositoryRoot(t *testing.T) string {
	t.Helper()
	_, currentFile, _, ok := runtime.Caller(0)
	if !ok {
		t.Fatal("locate test file")
	}
	return filepath.Clean(filepath.Join(filepath.Dir(currentFile), ".."))
}
```

Use these paths in the existing tests:

```go
scriptPath := filepath.Join(repositoryRoot(t), "build", "scripts", "build.ps1")
batchPath := filepath.Join(repositoryRoot(t), "build", "scripts", "build.bat")
```

- [ ] **Step 2: Add a layout regression test**

```go
func TestBuildDirectoryLayout(t *testing.T) {
	root := repositoryRoot(t)
	buildScriptPath := filepath.Join(root, "build", "scripts", "build.ps1")
	contents, err := os.ReadFile(buildScriptPath)
	if err != nil {
		t.Fatalf("read organized build script: %v", err)
	}
	if !strings.Contains(string(contents), `build\dist\bin`) {
		t.Fatal("build output must use build/dist/bin")
	}

	for _, path := range []string{
		filepath.Join(root, "build", "compiler", ".gitkeep"),
		filepath.Join(root, "build", "dist", "install", ".gitkeep"),
		filepath.Join(root, "build", "dist", "config", ".gitkeep"),
	} {
		if _, err := os.Stat(path); err != nil {
			t.Fatalf("required directory placeholder %s: %v", path, err)
		}
	}

	for _, oldPath := range []string{
		filepath.Join(root, "scripts"),
		filepath.Join(root, "build", "bin"),
	} {
		if _, err := os.Stat(oldPath); !os.IsNotExist(err) {
			t.Fatalf("legacy directory must be removed: %s", oldPath)
		}
	}
}
```

- [ ] **Step 3: Run the focused tests and verify RED**

Run:

```powershell
go test ./tests -run 'TestBuild' -count=1
```

Expected: FAIL because `build/scripts/build.ps1` and the reserved directory placeholders do not exist yet.

### Task 2: Move the Tracked Scripts and Create Reserved Directories

**Files:**
- Move: `scripts/build.bat` → `build/scripts/build.bat`
- Move and modify: `scripts/build.ps1` → `build/scripts/build.ps1`
- Move and modify: `scripts/test.ps1` → `build/scripts/test.ps1`
- Create: `build/compiler/.gitkeep`
- Create: `build/dist/install/.gitkeep`
- Create: `build/dist/config/.gitkeep`
- Modify: `.gitignore`

- [ ] **Step 1: Move `build.bat` unchanged**

Its PowerShell invocation remains relative to the batch file:

```bat
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0build.ps1"
```

- [ ] **Step 2: Move and update `build.ps1`**

Set the repository root two levels above the script and use the new output directory:

```powershell
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

Push-Location (Join-Path $root 'frontend')
try {
    npm ci
    if ($LASTEXITCODE -ne 0) { throw 'npm ci failed.' }
    npm test
    if ($LASTEXITCODE -ne 0) { throw 'Frontend tests failed.' }
    npm run build
    if ($LASTEXITCODE -ne 0) { throw 'Frontend build failed.' }
}
finally {
    Pop-Location
}

Push-Location $root
try {
    go test ./...
    if ($LASTEXITCODE -ne 0) { throw 'Go tests failed.' }
    New-Item -ItemType Directory -Force -Path 'build\dist\bin' | Out-Null
    go build -tags 'desktop,production' -trimpath -ldflags '-w -s -H windowsgui' -o 'build\dist\bin\CPDS.exe' .\cmd\cpds-desktop
    if ($LASTEXITCODE -ne 0) { throw 'CPDS.exe build failed.' }

    $previousGOOS = $env:GOOS
    $previousGOARCH = $env:GOARCH
    $previousCGO = $env:CGO_ENABLED
    try {
        $env:GOOS = 'linux'
        $env:GOARCH = 'amd64'
        $env:CGO_ENABLED = '0'
        go build -trimpath -o 'build\dist\bin\CPDS-CCU' .\cmd\cpds-ccu
        if ($LASTEXITCODE -ne 0) { throw 'CPDS-CCU build failed.' }
    }
    finally {
        $env:GOOS = $previousGOOS
        $env:GOARCH = $previousGOARCH
        $env:CGO_ENABLED = $previousCGO
    }
}
finally {
    Pop-Location
}
```

- [ ] **Step 3: Move and update `test.ps1`**

Only the two relative roots change:

```powershell
Push-Location (Join-Path $PSScriptRoot '..\..\frontend')
```

and:

```powershell
Push-Location (Join-Path $PSScriptRoot '..\..')
```

All test and build commands remain unchanged.

- [ ] **Step 4: Add the three `.gitkeep` files and update ignore rules**

Keep `/.tools/` unchanged and replace:

```gitignore
/build/bin/
```

with:

```gitignore
/build/dist/bin/
```

### Task 3: Preserve Existing Artifacts and Remove the Legacy Directories

**Files:**
- Move ignored file: `build/bin/CPDS.exe` → `build/dist/bin/CPDS.exe`
- Move ignored file: `build/bin/CPDS-CCU` → `build/dist/bin/CPDS-CCU`
- Move ignored directory: `build/bin/runtime` → `build/dist/bin/runtime`
- Remove empty directory: `scripts/`
- Remove empty directory: `build/bin/`

- [ ] **Step 1: Resolve and validate all source and destination paths**

Use explicit absolute paths under `D:\CPD\CPDS`. Confirm every source exists, every destination is within `D:\CPD\CPDS\build\dist\bin`, and no destination already exists with different content.

- [ ] **Step 2: Create `build/dist/bin` and move each known entry explicitly**

```powershell
New-Item -ItemType Directory -Force -Path 'D:\CPD\CPDS\build\dist\bin' | Out-Null
Move-Item -LiteralPath 'D:\CPD\CPDS\build\bin\CPDS.exe' -Destination 'D:\CPD\CPDS\build\dist\bin\CPDS.exe'
Move-Item -LiteralPath 'D:\CPD\CPDS\build\bin\CPDS-CCU' -Destination 'D:\CPD\CPDS\build\dist\bin\CPDS-CCU'
Move-Item -LiteralPath 'D:\CPD\CPDS\build\bin\runtime' -Destination 'D:\CPD\CPDS\build\dist\bin\runtime'
```

- [ ] **Step 3: Verify each old directory is empty before deleting it**

```powershell
if ((Get-ChildItem -Force -LiteralPath 'D:\CPD\CPDS\build\bin').Count -ne 0) { throw 'build/bin is not empty' }
if ((Get-ChildItem -Force -LiteralPath 'D:\CPD\CPDS\scripts').Count -ne 0) { throw 'scripts is not empty' }
```

- [ ] **Step 4: Delete only the two confirmed-empty directories**

```powershell
Remove-Item -LiteralPath 'D:\CPD\CPDS\build\bin'
Remove-Item -LiteralPath 'D:\CPD\CPDS\scripts'
```

Do not use `-Recurse`. If either directory is not empty, stop without deleting it.

### Task 4: Update Active Documentation and Path References

**Files:**
- Modify: `README.md`
- Modify: `docs/plans/CPDS-ccu-multi-interface-plan.md`
- Modify: `docs/plans/CPDS-windows-network-interface-ui-plan.md`
- Modify: `docs/superpowers/plans/2026-07-21-cpds-ccu-audio-implementation.md`
- Modify: `docs/superpowers/plans/2026-07-21-hide-device-id-implementation.md`

- [ ] **Step 1: Update user-facing commands**

Replace root script invocations with:

```powershell
.\build\scripts\test.ps1
.\build\scripts\build.ps1
```

- [ ] **Step 2: Update CPDS plan references**

Use `build/scripts/build.ps1`, `build/scripts/test.ps1`, and `build/dist/bin/CPDS.exe` / `build/dist/bin/CPDS-CCU` wherever those documents describe current CPDS paths.

Do not change `docs/requirements/02-CPDC-requirements.md` references to CPDC's own `scripts/build-audio.ps1`.

### Task 5: Verify, Synchronize the Index, and Commit

**Files:**
- Test: `tests/build_script_test.go`
- Verify: all files changed in Tasks 1–4

- [ ] **Step 1: Run the focused tests and verify GREEN**

```powershell
go test ./tests -run 'TestBuild' -count=1
```

Expected: PASS.

- [ ] **Step 2: Run the complete validation script from its new path**

```powershell
.\build\scripts\test.ps1
```

Expected: all frontend tests, frontend production build, Go tests, and `go vet` pass.

- [ ] **Step 3: Run the real build from its new path**

```powershell
.\build\scripts\build.ps1
```

Expected: `build/dist/bin/CPDS.exe` and `build/dist/bin/CPDS-CCU` exist and are non-empty.

- [ ] **Step 4: Verify the filesystem contract**

Confirm:

- `.tools/` still exists with the same files.
- `build/compiler/`, `build/dist/install/`, and `build/dist/config/` contain only `.gitkeep`.
- `build/dist/bin/runtime/` retains the existing log and upload files.
- `scripts/` and `build/bin/` do not exist.

- [ ] **Step 5: Scan active references and check the diff**

Run targeted `rg` checks over README, tests, `docs/plans`, and the two existing CPDS implementation plans. CPDC-specific `scripts/build-audio.ps1` and the migration design's historical-path discussion are valid exceptions.

```powershell
git diff --check
codegraph sync
codegraph status
```

Expected: no diff errors and CodeGraph reports the index is up to date.

- [ ] **Step 6: Commit only the directory-layout changes**

Stage the explicitly listed scripts, tests, placeholders, ignore rule, README, referenced plans, and this implementation plan. Do not stage unrelated existing CPDS feature changes.

```powershell
git commit -m "build: organize CPDS build directories"
```
