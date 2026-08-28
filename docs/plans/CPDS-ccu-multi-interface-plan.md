# CPDS-CCU Multi-Interface Broadcast Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `CPDS-CCU` automatically send every logical CPD message through all eligible IPv4 broadcast interfaces while preserving Windows single-interface behavior.

**Architecture:** Keep one UDP transport per Distribution. The transport owns one broadcast socket per eligible interface, one loopback sender, and one wildcard receiver; Magic, Proto, current-session, stage, and device-identity validation replace ingress-interface filtering on both Windows and Linux. A focused fan-out function isolates partial-failure rules and is directly unit tested.

**Tech Stack:** Go 1.25, standard-library `net`, Proto3, PowerShell build scripts.

---

### Task 1: Requirements and design

**Files:**
- Modify: `docs/requirements/01-CPDS-requirements.md`
- Modify: `docs/requirements/03-CPDS-CPDC-interaction-requirements.md`
- Modify: `README.md`

- [ ] Replace the CCU single-interface startup requirement with automatic per-Distribution enumeration of all eligible IPv4 broadcast interfaces.
- [ ] Specify one loopback copy, shared message identity, wildcard receiving with protocol/session/device validation, partial-interface failure handling, and per-interface 1 Mbit/s behavior.
- [ ] Keep the Windows Wails single-interface behavior explicit.

### Task 2: Failing fan-out and mode tests

**Files:**
- Create: `tests/multi_interface_test.go`

- [ ] Add fake UDP writers and assert that two business writers each receive one copy while loopback receives exactly one.
- [ ] Assert one failed business writer does not fail the logical send, but all failed business writers return an error.
- [ ] Assert Windows and Linux use wildcard UDP receiving without interface control messages, and UDP initialization failures map to `NETWORK_INTERFACE_ERROR`.
- [ ] Assert the CCU launcher enables all-interface mode without defining an `interface` flag and the Windows launcher still passes `InterfaceName`.
- [ ] Run `go test ./tests -run 'Test(Fanout|Ingress|CCULauncher)' -count=1` and confirm failure before implementation.

### Task 3: Interface discovery and UDP fan-out

**Files:**
- Modify: `internal/protocol/interface.go`
- Create: `internal/protocol/interface_slave_linux.go`
- Create: `internal/protocol/interface_slave_other.go`
- Modify: `internal/protocol/udp.go`
- Create: `internal/protocol/fanout.go`

- [ ] Add deterministic all-interface selection using the existing eligibility and IPv4 rules, excluding Linux subordinate interfaces and returning `NETWORK_INTERFACE_ERROR` when none remain.
- [ ] Refactor `UDPTransport` to own a slice of bound broadcast sockets and a set of accepted ingress indices.
- [ ] Implement fan-out so individual interface failures are logged, at least one successful broadcast is sufficient, and loopback is attempted once.
- [ ] Close every successfully created socket exactly once and preserve the existing single-interface constructor.
- [ ] Run the focused tests and confirm they pass.

### Task 4: CCU integration

**Files:**
- Modify: `internal/service/manager.go`
- Modify: `cmd/cpds-ccu/main.go`

- [ ] Add `AllInterfaces` to the manager configuration and choose `NewUDPTransportAll` only for that mode.
- [ ] Remove the CCU `--interface` flag and set `AllInterfaces: true`.
- [ ] Keep `cmd/cpds-desktop` unchanged so Windows remains single-interface.
- [ ] Run all Go tests and `go vet ./...`.

### Task 5: Release verification

**Files:**
- Modify: `build/scripts/build.ps1` only if verification exposes a build issue.

- [ ] Run `build/scripts/test.ps1` and require all Go/Vue tests plus `go vet` to pass.
- [ ] Run `build/scripts/build.ps1` and require both `CPDS.exe` and Linux/amd64 `CPDS-CCU` to build.
- [ ] Inspect build metadata and confirm the Windows target retains Wails production tags and the CCU target is Linux/amd64.
- [ ] Launch the Windows executable and confirm a CPDS window is created and exits cleanly.
