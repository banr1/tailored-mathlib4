# Lean Atlas による `RiemannHypothesis` の依存宣言の計算

実行日: 2026-11-21 / Lean `v4.37.0-rc1` / Mathlib fork HEAD `4704f70dd5`（upstream `3eae40f5eb` 相当）
Lean Atlas: `NyxFoundation/lean-atlas` @ `3a81e194db0e6c41a2a8c5286f9e1b4962c3866a`

`RiemannHypothesis` **が依存している** Mathlib の宣言を Lean Atlas で計算した。

## 結論

**`RiemannHypothesis` が推移的に依存する Mathlib 宣言は 8975 個**（定義 3170 / 定理 5805、エッジ 101787 本）。

| 対象 | Lean Atlas そのまま | 構造体のフィールドも追跡 |
| --- | ---: | ---: |
| `RiemannHypothesis` | **8975**（定義 3170 / 定理 5805） | 8984 |
| `riemannZeta` | 8974（定義 3169 / 定理 5805） | 8983（定義 3178 / 定理 5805） |
| `Complex`（structure） | 0 | 551（定義 311 / 定理 240） |
| `Real`（structure） | 0 | 550（定義 310 / 定理 240） |

- 数は対象自身を含まない。Lean core の定数（`Eq`, `HDiv.hDiv`, `Nat.cast` など）と自動生成名
  （`RiemannHypothesis._proof_1` など）は Lean Atlas の仕様により数えない（scope = `Mathlib`）。
- Lean Atlas は inductive/structure について型（`Type`）の依存しか見ず、コンストラクタ（フィールド）の型を追わないため、
  `Complex` / `Real` はそのままだと 0 になる。`ForwardDeps.lean` の `atlas+ctor` モードでフィールドも追跡して補正した。
- `RiemannHypothesis` は `def ... : Prop`（命題であり定理ではない）。定理が 5805 個含まれるのは、
  `riemannZeta` などの**定義の本体**が内部で補題（証明項）を参照しているため。

### 直接依存（15 個）

`riemannZeta`, `Complex`, `Complex.re`, `Complex.instZero`, `Complex.instOne`, `Complex.instAdd`,
`Complex.instMul`, `Complex.instNeg`, `Complex.instNatCast`, `Real`, `Real.instOne`, `Real.instNatCast`,
`Real.instDivInvMonoid`, `DivInvMonoid.toDiv`, `instOfNatAtLeastTwo`

数学的にまとめると **`riemannZeta`・`ℂ`・`ℝ` の 3 つ**。ソースに現れない 2 つは elaboration で入る
（`CheckRHStatement.lean` で `pp.explicit` により確認）:

- `instOfNatAtLeastTwo`: 数値リテラル `2`（`-2 * (n + 1)` の `2 : ℂ` と `1 / 2` の `2 : ℝ`）。
  2 以上のリテラルは `instOfNatAtLeastTwo` 経由で `Nat.cast` から作られる。
- `DivInvMonoid.toDiv`: `1 / 2 : ℝ` の `/`（`Real.instDivInvMonoid` から `Div ℝ` を取り出す）。

### 3 つの関係

- `Complex` の直接依存は `Real` のみ（`ℂ = ℝ × ℝ`）→ `Complex` の 551 = `Real` の 550 + `Real` 自身。
- `Real` の直接依存は `CauSeq.Completion.Cauchy`, `abs`, `Rat.*` 等（`ℝ` = 有理コーシー列の完備化）。
- `ℂ`・`ℝ` の依存はすべて `riemannZeta` の依存に含まれる。
  よって `RiemannHypothesis` の依存 = `riemannZeta` の依存 + `riemannZeta` 自身（8974 + 1 = 8975）。

## 実行手順（コマンド）

全コマンドとその出力・終了コード・所要時間は `session.log` に時系列で記録してある（`$ ` で始まる行がコマンド）。

```bash
# 1. Lean Atlas を Lake 依存として追加（lakefile.lean, 差分は lakefile.diff）
#    Reservoir 形式 `require "NyxFoundation" / "lean-atlas"` は "package not found on Reservoir" で失敗したため git 指定に変更
#    require «lean-atlas» from git "https://github.com/NyxFoundation/lean-atlas" @ "main"
lake update lean-atlas

# 2. Mathlib のビルド済みキャッシュ取得
#    fork の lakefile.lean（Playground 追加）だとキャッシュのルートハッシュが upstream と一致せず 0 件。
#    upstream (HEAD^2) の lakefile.lean / lake-manifest.json を一時的に置いて取得し、元に戻した。
git show HEAD^2:lakefile.lean > lakefile.lean && git show HEAD^2:lake-manifest.json > lake-manifest.json
lake exe cache get            # 9135 files decompressed
# （その後 lean-atlas 追加版の lakefile.lean / lake-manifest.json を復元）

# 3. Lean Atlas のビルド
#    Lean Atlas は Lean v4.28 向けで、v4.37 では `ImportedConsts.toList` が無くビルド失敗。
#    `.toList` → `.toArray` の 2 箇所パッチを当てた（lean-atlas-v4.37-compat.patch）
lake build atlas              # Build completed successfully (70 jobs)
lake build --no-build Mathlib # All targets up-to-date (18293 jobs)

# 4. 依存の計算（Lean Atlas CLI）
lake exe atlas deps RiemannHypothesis lean-atlas-rh/RiemannHypothesis_deps.dot  # 8976 nodes (自身含む), 101787 edges
lake exe atlas deps riemannZeta       lean-atlas-rh/riemannZeta_deps.dot        # 8975 nodes
lake exe atlas deps Complex           lean-atlas-rh/Complex_deps.dot            # 1 node, 0 deps
lake exe atlas deps Real              lean-atlas-rh/Real_deps.dot               # 1 node, 0 deps

# 5. ステートメントの elaboration 結果の確認
lake env lean lean-atlas-rh/CheckRHStatement.lean

# 6. 構造体フィールドも追跡した集計（Lean Atlas の Deps.Core API を利用）
lake env lean --run lean-atlas-rh/ForwardDeps.lean riemannZeta Complex Real RiemannHypothesis
```

## ファイル一覧

| ファイル | 内容 |
| --- | --- |
| `session.log` | 実行した全コマンドと出力・終了コード・所要時間 |
| `<X>_deps.dot` | `lake exe atlas deps <X>` の依存グラフ（Graphviz DOT。エッジは「依存先 -> 依存元」の向き） |
| `atlas_deps_<X>.stdout.txt` | `lake exe atlas deps <X>` の標準出力 |
| `ForwardDeps.lean` / `ForwardDeps.stdout.txt` | 集計スクリプトとその出力 |
| `<X>_forward_atlas.txt` | Lean Atlas そのままの依存宣言一覧（1 行 1 宣言） |
| `<X>_forward_atlas+ctor.txt` | 構造体フィールドも追跡した依存宣言一覧 |
| `CheckRHStatement.lean` / `.stdout.txt` | `RiemannHypothesis` を `pp.explicit` で表示した結果 |
| `lakefile.diff` | `lakefile.lean` への変更 |
| `lean-atlas-v4.37-compat.patch` | `.lake/packages/lean-atlas` への互換パッチ（`lake update` で消えるので再適用が必要） |

## `riemannZeta` の依存から `ℂ`・`ℝ` の依存を除いた 8431 個の分類

構造体のフィールドも追跡した集計（`*_forward_atlas+ctor.txt`）で集合差を取った。

| | 個数 |
| --- | ---: |
| `riemannZeta` の依存 | 8983 |
| `Complex` の依存 ∪ `Real` の依存（`Real` の依存 550 ⊂ `Complex` の依存 551） | 551 |
| 差（`riemannZeta` − (`Complex` ∪ `Real`)） | 8432 |
| さらに `Complex` 自身を除く | **8431** |

```bash
# 集合差（python で計算）→ riemannZeta_minus_Complex_Real.txt
# 各宣言の定義モジュールを取得
lake env lean --run lean-atlas-rh/ModuleOf.lean lean-atlas-rh/riemannZeta_minus_Complex_Real.txt lean-atlas-rh/riemannZeta_minus_Complex_Real_modules.tsv
```

Mathlib の 1 段目のディレクトリで集計し、近いものをまとめた分類:

| # | 分類 | 含むディレクトリ | 個数 | 割合 |
| --- | --- | --- | ---: | ---: |
| 1 | 代数 | `Algebra` 2432 / `RingTheory` 152 / `LinearAlgebra` 130 / `GroupTheory` 47 | 2761 | 32.7% |
| 2 | 順序・論理・集合論 | `Order` 1588 / `Logic` 188 / `SetTheory` 85 | 1861 | 22.1% |
| 3 | 位相 | `Topology` 1110 | 1110 | 13.2% |
| 4 | データ構造 | `Data` 1063（`Set` 347, `Multiset` 199, `Finset` 170 など） | 1063 | 12.6% |
| 5 | 解析・測度論 | `Analysis` 621 / `MeasureTheory` 432 | 1053 | 12.5% |
| 6 | 基本的な数と概念 | `Basic` 458（`ENNReal` 109, `Complex` 82, `Real` 63, `NNReal` 44 など） | 458 | 5.4% |
| 7 | その他 | `Tactic` 104 / `NumberTheory` 16 / `Lean` 5 | 125 | 1.5% |
| | 合計 | | 8431 | 100% |

- ゼータ関数固有の数論部分はわずか 16 個（`LSeries.AbstractFuncEq` 9, `HurwitzZetaEven` 5, `JacobiTheta` 2）。
  大半は代数・順序・位相・集合などの汎用基盤。
- `Tactic` の 104 個は `ring` / `norm_num` などが内部で使う補題（定義本体中の証明から参照される）。
- `Basic` はこのフォーク独自のディレクトリ。`Complex`・`Real` の依存を除いても、その上の演算・補題（`Basic.Complex` 等）は残る。

| ファイル | 内容 |
| --- | --- |
| `riemannZeta_minus_Complex_Real.txt` | 8431 個の宣言一覧 |
| `riemannZeta_minus_Complex_Real_modules.tsv` | 宣言名と定義モジュールの対応 |
| `ModuleOf.lean` | 宣言名 → 定義モジュールを調べるスクリプト |
