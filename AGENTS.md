# Repository Guidelines

## Project Structure & Module Organization
- Core library lives in `Mathlib/`, following the standard mathlib4 hierarchy (e.g. `Algebra/`, `Topology/`, `Analysis/`).
- Supporting libraries include `Archive/`, `Counterexamples/`, `Cache/`, `LongestPole/`, `docs/`, and `MathlibTest/`.
- Top-level entry files such as `Mathlib.lean`, `Archive.lean`, `Counterexamples.lean`, and `docs.lean` assemble common imports.

## Build, Test, and Development Commands
- `lake exe cache get` – fetch precompiled `.olean` files; run after updating the toolchain or dependencies.
- `lake build` – build `Mathlib` and all configured libraries with the standard mathlib options.
- `lake test` (or `lake build MathlibTest`) – build and run the main test suite.
- `lake exe lint-style` – run text-based style linters defined in `scripts/`.

## Coding Style & Naming Conventions
- Lean 4 code with 2-space indentation, no tabs; keep lines reasonably short.
- Follow mathlib naming: definitions/lemmas in `snake_case`, types/structures in `CamelCase`, namespaces mirroring directory paths.
- Start files with a module docstring and minimal imports; prefer extending existing APIs over introducing ad-hoc duplicates.

## Testing Guidelines
- Place tests in `MathlibTest/`, mirroring the namespace of the code under test when practical.
- Before pushing, run `lake test` (or `lake build MathlibTest`) and ensure it succeeds.
- For new definitions or tactics, add focused tests that cover typical and edge cases; keep tests small and fast.

## Commit & Pull Request Guidelines
- Use short, structured commit messages, e.g. `feat(Analysis/Normed/Group): add norm lemma` or `chore(Tactic): improve error message`.
- Write messages in the imperative, describing what the change does.
- PRs should include a concise description, affected modules, any breaking changes, and links to related issues or discussions.
- Prefer small, focused PRs over broad refactors; keep `lake build` and tests passing at each step.

## Agent-Specific Instructions
- Automated tools should respect the existing layout, avoid mass reformatting, and limit edits to the minimal necessary files.
- Do not introduce new build systems; use `lake` and the existing `lakefile.lean` configuration.
