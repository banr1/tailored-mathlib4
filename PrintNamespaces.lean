/-
Place this file anywhere in your repo, e.g. `Scripts/PrintNamespaces.lean`
Then import your project's root module before calling `#print_namespaces`.
-/
import Lean
import Mathlib

open Lean

/-- `n` のすべての「親」プレフィクス（= namespace 候補）を列挙する。
    例: `A.B.c` → [`A`, `A.B`] -/
partial def parentPrefixes (n : Name) : List Name :=
  if n.isAnonymous then
    []
  else
    let p := n.getPrefix
    if p.isAnonymous then
      []
    else
      parentPrefixes p ++ [p]

/-- 環境内の全定数名から namespace 候補を収集する。 -/
def collectNamespaces (env : Environment) : Std.HashSet Name :=
  Id.run do
    let mut s : Std.HashSet Name := {}
    -- `constants` は Name → ConstantInfo のマップ
    for (n, _) in env.constants.toList do
      for p in parentPrefixes n do
        s := s.insert p
    return s

/-- 集めた namespace を文字列化してソートして返す。 -/
def sortedNamespaceStrings (s : Std.HashSet Name) : List String :=
  let arr := s.toArray.map (·.toString)
  arr.qsort (· < ·) |>.toList

/-- `#print_namespaces` コマンド本体 -/
elab "#print_namespaces" : command => do
  let env ← getEnv
  let ns := sortedNamespaceStrings (collectNamespaces env)
  if ns.isEmpty then
    logInfo "(no namespaces found)"
  else
    -- 1 行ずつ出力（エディタの Messages/Info に表示されます）
    for n in ns do
      logInfo m!"{n}"

/- =========================
   使い方の例
   ========================= -/

-- あなたのプロジェクト全体を読み込む import を置く
-- import MyProject

-- これを有効にすると、読み込まれている全モジュール分の namespace を列挙
-- #print_namespaces

/- =========================
   （任意）プロジェクト固有に絞る簡易フィルタ例
   =========================

もし `MyProject` 配下に限定して表示したい場合は、下の補助関数を使って
`#print_namespaces` 相当の動きを #eval で行う一例です。

#eval do
  let env ← Lean.getEnv
  let wantPrefix : Name := `MyProject
  let all  := collectNamespaces env
  let only := all.toList.filter (fun n => n.isPrefixOf wantPrefix || wantPrefix.isPrefixOf n)
  for n in (only.map (·.toString) |>.qsort (· < ·)) do
    IO.println n
-/

#print_namespaces
