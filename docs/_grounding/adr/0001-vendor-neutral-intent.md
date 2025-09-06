# ADR 0001: Vendor‑Neutral Network Intent as Source of Truth

Status: Accepted
Date: 2025-09-05

Context
- We manage a small mesh (hetzner, laptop, wsl) with multiple vendors (Tailscale primary, WireGuard fallback).

Decision
- Treat `infra/policy/intent/network.yaml` as the canonical, vendor‑neutral policy.
- Generate implementation artifacts via `infra/policy/intent/generate.sh` into `infra/policy/generated/`.
- Protect grounding docs (`docs/_grounding/*`) from agent modification.

Consequences
- Single place to review policy changes.
- Repeatable generation and auditability.
- Clear separation of human guidance vs. generated state.
