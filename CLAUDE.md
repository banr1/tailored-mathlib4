# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is mathlib4, a comprehensive mathematics library for the Lean 4 theorem prover. It contains formalized mathematics, programming infrastructure, and tactics. The codebase is written in Lean 4 and follows strict style guidelines and naming conventions maintained by the Lean community.

**Key characteristics:**
- Large-scale formal mathematics library (~400k lines in Mathlib.lean)
- Heavy emphasis on type theory and formal verification
- Strong community standards for code style, naming, and documentation
- Uses Lake as the build system (configured in lakefile.lean)
- Currently using Lean toolchain: leanprover/lean4:v4.26.0-rc2

## Repository Structure

```
Mathlib/          Main library organized by mathematical topics
  Algebra/        Algebraic structures (groups, rings, fields, etc.)
  Analysis/       Analysis, calculus, functional analysis
  Topology/       Topological spaces and related structures
  NumberTheory/   Number theory
  CategoryTheory/ Category theory
  LinearAlgebra/  Linear algebra
  Order/          Order theory
  Data/           Data structures and basic types
  Tactic/         Tactics and metaprogramming
  Init.lean       Root import file (imported by virtually all Mathlib files)

Archive/          Formalized competition problems and classical results
Counterexamples/  Counterexamples to potential conjectures
MathlibTest/      Test suite mirroring Mathlib structure
Cache/            Cache management utilities
scripts/          Maintenance and CI scripts
docs/             Documentation files (yaml-based)
```

## Build, Test, and Development Commands

### Essential Commands

**Getting precompiled files (always run first):**
```bash
lake exe cache get
```
This downloads precompiled `.olean` files from a central server. Run this after:
- Cloning the repository
- Updating dependencies
- Updating the toolchain
- When mysterious build errors occur

**Building:**
```bash
lake build                           # Build all of Mathlib
lake build Mathlib.Algebra.Group.Defs  # Build a specific file
lake test                            # Build and run test suite (MathlibTest)
```

**After adding a new file:**
```bash
lake exe mk_all
```
This regenerates the import-only files `Mathlib.lean`, `Archive.lean`, `Counterexamples.lean`, and `Mathlib/Tactic.lean`.

**Linting:**
```bash
lake exe lint-style                  # Run text-based style linters
```

### Cache Management

```bash
lake exe cache get                   # Download cached build files
lake exe cache get!                  # Force re-download even if available locally
lake clean                           # Clean build artifacts
rm -rf .lake                         # Nuclear option for build issues
```

### Other Executables

```bash
lake exe autolabel [PR_NUMBER]       # Add topic label to PR (requires gh CLI)
lake exe check-yaml                  # Verify docs/*.yaml files
lake exe pole                        # Calculate longest build pole
lake exe unused module_1 ... module_n # Analyze unused transitive imports
```

## Lean 4 Code Architecture

### Module System

- Every Lean file starts with `module` keyword (Lean 4.17+)
- Use `public import` for re-exports, regular `import` for dependencies
- Files should import `Mathlib.Init` (directly or indirectly)
- The `Mathlib.Init` file imports linters and is imported by virtually all files

### File Structure

Typical Lean file structure:
```lean
/-
Copyright notice and author information
-/
module

public import Path.To.Dependencies
import Path.To.More.Stuff

/-!
# Main heading

Module docstring describing the file's purpose and contents.

## Main results

* `theorem_name_one`: brief description
* `theorem_name_two`: brief description
-/

-- Actual definitions, theorems, and proofs
```

### Naming Conventions

- **Definitions/theorems/lemmas**: `snake_case` (e.g., `mul_left_cancel`, `continuous_at_id`)
- **Types/structures/classes**: `CamelCase` (e.g., `AddCommGroup`, `TopologicalSpace`)
- **Namespaces**: Mirror directory structure and type names
- Follow the [official naming convention guide](https://leanprover-community.github.io/contribute/naming.html)

### Type Classes and Structures

- Heavy use of type classes for algebraic structures (e.g., `Group`, `Ring`, `Field`)
- Additive vs multiplicative notation via `to_additive` attribute
- Mixin classes for properties (e.g., `IsLeftCancelMul`, `IsCommutative`)
- Structure extension for building hierarchies

### Key Patterns

1. **Definitions come before lemmas**: Define structures/functions first, prove properties after
2. **Minimal imports**: Only import what you need, avoid transitive dependencies
3. **Module docstrings required**: Every file needs a top-level docstring with `/-! ... -/`
4. **Simp lemmas**: Mark appropriate lemmas with `@[simp]` for automation
5. **Namespaces**: Open namespaces sparingly; prefer qualified names

## Coding Style Guidelines

Mathlib has strict style requirements. Key points:

- **Indentation**: 2 spaces, no tabs
- **Line length**: Prefer < 100 characters (linter warns at 1500)
- **No auto implicit**: `autoImplicit` is disabled project-wide
- **Unicode**: Use unicode characters (`→` not `->`, `∀` not `forall`, `ℕ` not `Nat` in doc)
- **Comments**: Use `--` for line comments, `/-  -/` for block comments
- **Module docstrings**: Required at top of every file with `/-! ... -/`

### Documentation Requirements

- All definitions, theorems, and structures must have docstrings
- Use `/-! ... -/` for module docs, `/-- ... -/` for declaration docs
- Include "Main results" section listing key theorems
- Follow the [documentation style guide](https://leanprover-community.github.io/contribute/doc.html)

### Linters

Mathlib enforces many linters automatically:
- `linter.mathlibStandardSet`: Standard mathlib linter set
- `linter.style.header`: File header format
- `linter.style.longFile`: File length warnings
- `linter.pythonStyle`: Python-like style checks
- See `lakefile.lean` for full linter configuration

## Testing

- Place tests in `MathlibTest/`, mirroring the namespace structure
- Test files import the modules they test
- Run `lake test` or `lake build MathlibTest` to execute all tests
- Tests should be focused, fast, and cover typical/edge cases
- Tests use standard Lean 4 syntax (no special test framework)

## Working with Tactics

- Tactics are in `Mathlib/Tactic/`
- Main tactic file: `Mathlib/Tactic.lean` (import-only aggregator)
- Tactic implementations use Lean 4's metaprogramming framework
- Tests for tactics should go in `MathlibTest/` with corresponding names

## Dependencies

Mathlib depends on:
- **batteries**: Standard library extensions
- **Qq**: Quoted expressions library
- **aesop**: Automation tactic
- **proofwidgets**: Interactive widgets (pinned version)
- **importGraph**: Import graph visualization
- **LeanSearchClient**: Search functionality
- **plausible**: Analytics

Update dependencies with:
```bash
lake update                          # Update all
lake update batteries aesop          # Update specific packages
```
Do not use `lake update -Kdoc=on` (documentation handled by CI).

## Git and PR Workflow

### Commit Messages

Follow the imperative mood pattern:
```
feat(Analysis/Normed/Group): add norm lemma
fix(Tactic): improve error message
chore(Algebra): remove unused import
refactor(Data/List): simplify proof
```

Categories: `feat`, `fix`, `refactor`, `chore`, `doc`, `style`, `perf`, `test`

### Pull Requests

- Keep PRs small and focused
- Ensure `lake build` and `lake test` pass before pushing
- Add module docstring or theorem descriptions as needed
- List moves/deletions at bottom of commit message:
  ```
  Moves:
  - Vector.* -> List.Vector.*

  Deletions:
  - Nat.old_lemma
  ```
- Co-authors can be added via git commits or `Co-authored-by:` lines

### Migration to Fork Workflow

Contributors should use fork-based workflow. Use `scripts/migrate_to_fork.py` to migrate existing branches to a fork.

## Scripts and Automation

The `scripts/` directory contains numerous utilities. Key scripts:

**Maintenance:**
- `fix_deprecations.py`: Auto-fix deprecation warnings
- `fix_unused.py`: Replace unused variables with `_`
- `mk_all.lean`: Regenerate import-only files (via `lake exe mk_all`)

**Analysis:**
- `lint-style.lean`, `lint-style.py`: Style checking
- `unused_in_pole.sh`: Analyze unused transitive imports
- `import-graph-report.py`: Transitive import summaries

**CI-related:**
- `lake-build-wrapper.py`: Build wrapper with logging
- `check-title-labels.lean`: Verify PR title format
- `autolabel.lean`: Auto-add topic labels to PRs

## Special Files and Configurations

- **lakefile.lean**: Lake build configuration, defines targets and linter options
- **lean-toolchain**: Specifies exact Lean version
- **Mathlib.lean**: Aggregator importing all Mathlib modules (auto-generated)
- **scripts/nolints.json**: Linter exceptions (should tend toward zero)
- **docs/*.yaml**: Documentation metadata (undergrad.yaml, overview.yaml, etc.)
- **.github/workflows/**: CI pipelines for building, testing, and maintenance

## Common Patterns in Proofs

### Tactic Mode
```lean
theorem foo : ∀ n : ℕ, n + 0 = n := by
  intro n
  rfl
```

### Term Mode
```lean
theorem foo : ∀ n : ℕ, n + 0 = n :=
  fun n => rfl
```

### Common Tactics
- `intro`, `intros`: Introduce hypotheses
- `apply`, `exact`: Apply theorems/hypotheses
- `rfl`, `rflv`: Reflexivity
- `simp`, `simp_all`: Simplification using simp lemmas
- `ring`, `field_simp`: Algebraic normalization
- `omega`: Linear arithmetic
- `aesop`: Automated proof search
- `constructor`: Build structures/inductives
- `cases`, `induction`: Case analysis and induction

## Important Notes

1. **Do not reformat existing code** unless specifically asked
2. **Respect the existing architectural patterns** in each mathematical domain
3. **Minimal changes**: Only modify what's necessary for the task
4. **Avoid over-engineering**: Don't add abstractions/helpers for one-time use
5. **No backwards compatibility hacks**: Remove unused code completely
6. **Check imports**: Run `lake exe cache get` after major changes
7. **Preserve exact indentation**: When editing, match the existing spacing exactly
8. **Follow mathlib conventions**, not general Lean 4 conventions where they differ

## Resources

- [Mathlib documentation](https://leanprover-community.github.io/mathlib4_docs/)
- [Contributing guide](https://leanprover-community.github.io/contribute/index.html)
- [Style guide](https://leanprover-community.github.io/contribute/style.html)
- [Naming conventions](https://leanprover-community.github.io/contribute/naming.html)
- [Documentation style](https://leanprover-community.github.io/contribute/doc.html)
- [Zulip chat](https://leanprover.zulipchat.com/) - `mathlib4` channel for questions
