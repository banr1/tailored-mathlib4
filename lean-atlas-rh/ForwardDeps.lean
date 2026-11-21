/-
Forward (transitive) dependencies of given constants, using Lean Atlas's filters
(`LeanAtlas.Deps.Core.getDirectDepsFiltered` / `isRelevantConstant`, scope = `Mathlib`).

Two modes are reported for each target:
* `atlas`   : exactly Lean Atlas's `deps` semantics (an inductive/structure contributes only the
              constants in its type, e.g. `Type`, so structure fields are NOT followed).
* `atlas+ctor` : same, but an inductive/structure additionally depends on the constants used in
              the types of its constructors (i.e. its fields), so that e.g. `Complex` → `Real`.

Usage (from the repository root):
  lake env lean --run lean-atlas-rh/ForwardDeps.lean riemannZeta Complex Real
-/
import LeanAtlas.Deps.Core

open Lean LeanAtlas.Deps.Core LeanAtlas.Config

def say (s : String) : IO Unit := do
  IO.println s; (← IO.getStdout).flush

def directDeps (scope : ProjectScope) (env : Environment) (withCtors : Bool) (n : Name) :
    Array Name := Id.run do
  let mut ds := getDirectDepsFiltered scope env n
  if withCtors then
    if let some (.inductInfo ii) := env.find? n then
      for ctor in ii.ctors do
        if let some ci := env.find? ctor then
          for c in ci.type.getUsedConstantsAsSet do
            if c != n && isRelevantConstant scope env c && !ds.contains c then
              ds := ds.push c
  return ds

/-- Transitive closure (excluding the root itself). -/
def closure (scope : ProjectScope) (env : Environment) (withCtors : Bool) (root : Name) :
    NameSet := Id.run do
  let mut seen : NameSet := {}
  let mut stack : Array Name := #[root]
  while h : stack.size > 0 do
    let cur := stack.back
    stack := stack.pop
    for d in directDeps scope env withCtors cur do
      unless seen.contains d || d == root do
        seen := seen.insert d
        stack := stack.push d
  return seen

def countKinds (env : Environment) (s : NameSet) : Nat × Nat :=
  s.foldl (fun (d, t) n => if classifyConstant env n == "theorem" then (d, t + 1) else (d + 1, t)) (0, 0)

unsafe def main (args : List String) : IO UInt32 := do
  let targets := (if args.isEmpty then ["riemannZeta", "Complex", "Real"] else args).map stringToName
  initSearchPath (← findSysroot)
  let env ← importModules #[{ module := `Mathlib }] {} (trustLevel := 1024)
  let scope : ProjectScope := { projectNamespace := `Mathlib }
  let mut unions : Array NameSet := #[{}, {}]
  for t in targets do
    let some _ := env.find? t | say s!"{t}: not found"; continue
    say s!"== {t} ({classifyConstantDetailed env t false}) =="
    for (mode, withCtors, idx) in [("atlas", false, 0), ("atlas+ctor", true, 1)] do
      let s := closure scope env withCtors t
      let (d, th) := countKinds env s
      say s!"  [{mode}] dependencies: {s.size} (definitions {d}, theorems {th})"
      unions := unions.set! idx (s.foldl (·.insert ·) unions[idx]!)
      IO.FS.writeFile s!"lean-atlas-rh/{t}_forward_{mode}.txt"
        (String.intercalate "\n" (s.toList.map toString |>.toArray.qsort (· < ·)).toList ++ "\n")
    let direct := directDeps scope env true t
    say s!"  direct (atlas+ctor): {direct.toList}"
  say s!"== union of all targets: atlas {unions[0]!.size}, atlas+ctor {unions[1]!.size} =="
  return 0
