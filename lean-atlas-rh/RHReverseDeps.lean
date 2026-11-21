/-
Compute all Mathlib declarations that (transitively) depend on a target constant
(default: `RiemannHypothesis`), using Lean Atlas's dependency extraction (`LeanAtlas.Deps.Core`).

Usage (from the repository root):
  lake env lean --run lean-atlas-rh/RHReverseDeps.lean [TARGET] [OUT_DIR]

Two notions are reported:
* Lean Atlas graph: nodes filtered by `isRelevantConstant` (scope = `Mathlib`, user-defined
  definitions/theorems/inductives/axioms), edges from `getDirectDepsWithKind`
  (type dependency vs value-only dependency), exactly as Lean Atlas builds its graph.
* Raw graph (cross-check): every constant in the environment, edges from
  `ConstantInfo.getUsedConstantsAsSet`, with no filtering (includes auto-generated
  constants such as equation lemmas).

Algorithm: only constants in modules that transitively import the target's module can depend
on the target, so we restrict to those, decide "reaches target" by memoized DFS over forward
edges, and then BFS over the (small) reverse graph induced on the dependents for depths.
-/
import LeanAtlas.Deps.Core

open Lean LeanAtlas.Deps.Core LeanAtlas.Config

def say (s : String) : IO Unit := do
  IO.println s; (← IO.getStdout).flush

/-- Memoized "does `n` transitively use `target`?" over raw forward edges. -/
partial def reaches (env : Environment) (inScope : Name → Bool) (target : Name) (n : Name) :
    StateM (Std.HashMap Name Bool) Bool := do
  if n == target then return true
  if !inScope n then return false
  if let some b := (← get)[n]? then return b
  modify (·.insert n false) -- guards against (impossible in practice) cycles
  let some ci := env.find? n | return false
  let mut r := false
  for c in ci.getUsedConstantsAsSet do
    if c != n && (← reaches env inScope target c) then
      r := true
      break
  modify (·.insert n r)
  return r

/-- BFS from `root` over reverse edges restricted to `nodes`; `fwd n` gives n's direct deps. -/
def bfsDepths (nodes : Array Name) (fwd : Name → Array Name) (root : Name) :
    Std.HashMap Name (Nat × Name) := Id.run do
  let mut rev : Std.HashMap Name (Array Name) := {}
  for n in nodes do
    for d in fwd n do
      rev := rev.alter d (fun a? => some ((a?.getD #[]).push n))
  let mut res : Std.HashMap Name (Nat × Name) := {}
  let mut q : Array (Name × Nat) := #[(root, 0)]
  let mut i := 0
  while h : i < q.size do
    let (cur, d) := q[i]
    i := i + 1
    for nxt in rev.getD cur #[] do
      unless res.contains nxt || nxt == root do
        res := res.insert nxt (d + 1, cur)
        q := q.push (nxt, d + 1)
  return res

def modOf (env : Environment) (n : Name) : String :=
  (getModuleFor? env n).map toString |>.getD "?"

unsafe def main (args : List String) : IO UInt32 := do
  let target := stringToName (args.getD 0 "RiemannHypothesis")
  let outDir : System.FilePath := args.getD 1 "lean-atlas-rh"
  initSearchPath (← findSysroot)
  let t0 ← IO.monoMsNow
  let env ← importModules #[{ module := `Mathlib }] {} (trustLevel := 1024)
  say s!"Imported Mathlib in {(← IO.monoMsNow) - t0} ms"
  let some _ := env.find? target
    | IO.eprintln s!"constant {target} not found"; return 1
  let scope : ProjectScope := { projectNamespace := `Mathlib }
  let some tgtIdx := env.getModuleIdxFor? target
    | IO.eprintln s!"module of {target} not found"; return 1
  let tgtMod := env.header.moduleNames[tgtIdx.toNat]!
  say s!"Target: {target} ({classifyConstantDetailed env target false}) in {tgtMod}"
  say s!"Target is a Lean Atlas relevant node: {isRelevantConstant scope env target}"

  -- Modules that transitively import the target's module (moduleNames is topologically sorted).
  let names := env.header.moduleNames
  let data := env.header.moduleData
  let idxOf : Std.HashMap Name Nat := names.size.fold (fun i _ m => m.insert names[i] i) {}
  let mut downstream : Array Bool := Array.replicate names.size false
  downstream := downstream.set! tgtIdx.toNat true
  for i in [0:names.size] do
    for imp in data[i]!.imports do
      if let some j := idxOf[imp.module]? then
        if downstream[j]! then downstream := downstream.set! i true
  let nDown := downstream.foldl (fun a b => if b then a + 1 else a) 0
  say s!"Modules: {names.size} total, {nDown} import {tgtMod} (transitively, incl. itself)"
  let inScope : Name → Bool := fun n =>
    match env.getModuleIdxFor? n with
    | some i => downstream[i.toNat]!
    | none => false

  -- Candidate constants and memoized reachability
  let mut cands : Array Name := #[]
  for i in [0:names.size] do
    if downstream[i]! then cands := cands ++ data[i]!.constNames
  say s!"Candidate constants in downstream modules: {cands.size}"
  let mut memo : Std.HashMap Name Bool := {}
  let mut rawDeps : Array Name := #[]
  for n in cands do
    if n == target then continue
    let (r, m) := (reaches env inScope target n).run memo
    memo := m
    if r then rawDeps := rawDeps.push n
  say s!"[Raw]        transitive dependents: {rawDeps.size}"

  -- Lean Atlas view: relevant nodes only, edges classified type/value
  let atlasNodes := rawDeps.filter (isRelevantConstant scope env)
  let atlasSet : NameSet := atlasNodes.foldl (·.insert ·) ({} : NameSet)
  let inAtlas := fun (c : Name) => c == target || atlasSet.contains c
  let mut kinds : Std.HashMap (Name × Name) String := {}
  let mut atlasFwd : Std.HashMap Name (Array Name) := {}
  for n in atlasNodes do
    let ds := (getDirectDepsWithKind scope env n).filter (inAtlas ·.name)
    atlasFwd := atlasFwd.insert n (ds.map (·.name))
    for d in ds do
      kinds := kinds.insert (n, d.name) (match d.kind with | .typeOnly => "type" | .valueOnly => "value")
  let atlasDepth := bfsDepths atlasNodes (atlasFwd.getD · #[]) target
  let rawSet : NameSet := rawDeps.foldl (·.insert ·) ({} : NameSet)
  let rawFwd := fun (n : Name) =>
    match env.find? n with
    | some ci => ci.getUsedConstantsAsSet.toArray.filter (fun c => c != n && (c == target || rawSet.contains c))
    | none => #[]
  let rawDepth := bfsDepths rawDeps rawFwd target
  say s!"[Lean Atlas] transitive dependents: {atlasNodes.size} (reachable via Lean Atlas edges: {atlasDepth.size})"

  let sortKey := fun (m : Std.HashMap Name (Nat × Name)) (a b : Name) =>
    let da := (m.getD a (1000000, .anonymous)).1
    let db := (m.getD b (1000000, .anonymous)).1
    da < db || (da == db && a.toString < b.toString)
  let atlasSorted := atlasNodes.qsort (sortKey atlasDepth)
  let rawSorted := rawDeps.qsort (sortKey rawDepth)

  let mut tsv := "name\tkind\tdepth\tvia\tedge_kind(name->via)\tmodule\n"
  say "--- Lean Atlas dependents: name [kind] depth, edge kind, module ---"
  for n in atlasSorted do
    let (d, via) := atlasDepth.getD n (0, .anonymous)
    let k := kinds.getD (n, via) "?"
    let kind := classifyConstantDetailed env n false
    tsv := tsv ++ s!"{n}\t{kind}\t{d}\t{via}\t{k}\t{modOf env n}\n"
    say s!"{n}  [{kind}]  depth={d}  {k}-dep on {via}  ({modOf env n})"
  IO.FS.writeFile (outDir / s!"{target}_dependents_atlas.tsv") tsv

  let mut rawTsv := "name\tkind\tdepth\tvia\tlean_atlas_relevant\tmodule\n"
  say "--- Raw dependents: name [kind] depth, via, module ---"
  for n in rawSorted do
    let (d, via) := rawDepth.getD n (0, .anonymous)
    let rel := atlasSet.contains n
    rawTsv := rawTsv ++ s!"{n}\t{classifyConstant env n}\t{d}\t{via}\t{rel}\t{modOf env n}\n"
    say s!"{n}  [{classifyConstant env n}]  depth={d}  via {via}  relevant={rel}  ({modOf env n})"
  IO.FS.writeFile (outDir / s!"{target}_dependents_raw.tsv") rawTsv
  say s!"Total time: {(← IO.monoMsNow) - t0} ms"
  return 0
