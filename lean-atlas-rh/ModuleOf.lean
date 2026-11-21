/-
Map each declaration name (one per line in IN_FILE) to the module that defines it.

Usage (from the repository root):
  lake env lean --run lean-atlas-rh/ModuleOf.lean IN_FILE OUT_TSV
-/
import LeanAtlas.Config.Types

open Lean LeanAtlas.Config

unsafe def main (args : List String) : IO UInt32 := do
  let [inFile, outFile] := args | IO.eprintln "usage: ModuleOf IN_FILE OUT_TSV"; return 1
  initSearchPath (← findSysroot)
  let env ← importModules #[{ module := `Mathlib }] {} (trustLevel := 1024)
  let names := (← IO.FS.lines inFile).filter (· ≠ "")
  let mut out := "name\tmodule\n"
  for s in names do
    let m := (getModuleFor? env (stringToName s)).map toString |>.getD "?"
    out := out ++ s!"{s}\t{m}\n"
  IO.FS.writeFile outFile out
  IO.println s!"wrote {names.size} rows to {outFile}"
  return 0
