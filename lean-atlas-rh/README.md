# Lean Atlas による `RiemannHypothesis` 依存宣言の計算

実行日: 2026-11-21 / Lean `v4.37.0-rc1` / Mathlib fork HEAD `4704f70dd5`（upstream `3eae40f5eb` 相当）
Lean Atlas: `NyxFoundation/lean-atlas` @ `3a81e194db0e6c41a2a8c5286f9e1b4962c3866a`

## 結論

**Mathlib 内に `RiemannHypothesis` に（直接・推移的に）依存する宣言は 0 個。**

| 対象 | Lean Atlas グラフ (relevant ノード) | Raw グラフ (全定数, 自動生成含む) |
| --- | ---: | ---: |
| `RiemannHypothesis` | **0** | **0** |
| `riemannZeta`（対照実験） | 197 | 314 |

- `RiemannHypothesis` は `Mathlib/NumberTheory/LSeries/RiemannZeta.lean:185` の `def RiemannHypothesis : Prop` で、
  Lean Atlas の relevant ノード（definition）として認識される。
- このモジュールを推移的に import するモジュールは 11190 中 26 個、その中の定数 1332 個を全て検査して依存なし。
- 対照として同じスクリプトで `riemannZeta` を調べると 314 / 197 個の依存宣言が検出されるため、
  0 件はスクリプトの不具合ではなく「Mathlib では RH はまだ仮定としても使われていない」ことを示す。

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

# 4. 逆依存の計算（Lean Atlas の Deps.Core API を利用）
lake env lean --run lean-atlas-rh/RHReverseDeps.lean RiemannHypothesis lean-atlas-rh
# 対照実験
lake env lean --run lean-atlas-rh/RHReverseDeps.lean riemannZeta lean-atlas-rh
```

### `lake exe atlas` CLI をそのまま使わなかった理由

Lean Atlas の CLI には「X に依存する宣言（逆依存）」を出すコマンドがない
（`deps` は順方向依存、`graph-data` は全グラフの JSON 出力）。
`graph-data` を Mathlib 全体に適用すると全ノードについて推移的公理集合を計算するため現実的でない。
そこで `RHReverseDeps.lean` で Lean Atlas のライブラリ関数
（`LeanAtlas.Deps.Core.isRelevantConstant` / `getDirectDepsWithKind` / `classifyConstantDetailed`、
scope = `Mathlib`）を直接呼び、Lean Atlas と同じノード・エッジ定義で逆依存を計算した。

なお最初の版のスクリプトは逆隣接リストを全 Mathlib 定数について構築する際に配列コピーが二次的になり、
3 時間 48 分経っても終わらなかったため中断した（`session.log` に exit 143 として記録）。
現行版は「対象モジュールを推移的に import するモジュールの定数だけ」をメモ化 DFS で判定する方式で、約 95 秒で完了。

## ファイル一覧

| ファイル | 内容 |
| --- | --- |
| `session.log` | 実行した全コマンドと出力・終了コード・所要時間 |
| `RHReverseDeps.lean` | 逆依存計算スクリプト（Lean Atlas API 使用） |
| `RHReverseDeps.stdout.txt` | `RiemannHypothesis` に対する実行結果 |
| `RiemannHypothesis_dependents_atlas.tsv` | Lean Atlas グラフでの依存宣言（ヘッダのみ = 0 件） |
| `RiemannHypothesis_dependents_raw.tsv` | Raw グラフでの依存宣言（ヘッダのみ = 0 件） |
| `control_riemannZeta.stdout.txt` | 対照実験 `riemannZeta` の実行結果 |
| `riemannZeta_dependents_atlas.tsv` / `_raw.tsv` | 対照実験の依存宣言一覧（深さ・type/value 依存種別・モジュール付き） |
| `lakefile.diff` | `lakefile.lean` への変更 |
| `lean-atlas-v4.37-compat.patch` | `.lake/packages/lean-atlas` への互換パッチ（`lake update` で消えるので再適用が必要） |
