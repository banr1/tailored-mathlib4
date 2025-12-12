/-
Copyright (c) 2025 Claude Code Contributors. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Claude Code
-/
module

import Mathlib.Order.CompleteBooleanAlgebra
import Mathlib.Data.Set.Lattice

/-!
# Frame（完備Heyting代数）の具体例

このファイルでは、Frameの具体例を実装し、それぞれがFrameの条件を満たすことを証明します。

## Frameとは

Frame（フレーム、完備Heyting代数）は、次の性質を持つ順序構造です：

1. **完備束（CompleteLattice）**：任意の部分集合に対して上限（⨆）と下限（⨅）が存在する
2. **Heyting代数（HeytingAlgebra）**：含意演算 `a ⇨ b`（Heyting含意）が定義される
3. **無限分配律**：`a ⊓ (⨆ i, b i) = ⨆ i, (a ⊓ b i)` が成立する

この無限分配律が最も重要な性質で、これによりFrameは位相空間論や点なしトポロジーで
中心的な役割を果たします。

## 主な例

このファイルでは以下の具体例を示します：

* `frameExampleProp`：命題の束 `Prop` がFrameであることの確認
* `frameExampleSet`：べき集合 `Set α` がFrameであることの説明

## 参考

Frame の理論的背景については、以下を参照：
- 位相空間の開集合全体は常にFrameを形成する
- 任意の完備Boolean代数はFrameである
- Frameは点なしトポロジー（pointless topology）の基礎となる
-/

section BasicExamples

/-! ### 例1：命題の束 Prop

命題の束 `Prop` は、論理積 `∧` を meet、論理和 `∨` を join とする完備束です。
Heyting含意は論理含意 `→` に対応します。

`Prop`において：
- ⊓（meet）は論理積 ∧
- ⊔（join）は論理和 ∨
- ⊤（top）は True
- ⊥（bottom）は False
- ⨆（sup）は存在量化 ∃
- ⨅（inf）は全称量化 ∀
- ⇨（Heyting implication）は論理含意 →
-/

/-- `Prop` はすでにFrameのインスタンスを持っています。
無限分配律を確認してみましょう：`P ∧ (∃ i, Q i) ↔ ∃ i, (P ∧ Q i)` -/
example : Order.Frame Prop := inferInstance

/-- 命題における無限分配律の具体例

この定理は、「P かつ（あるiについてQ iが成り立つ）」が
「ある i について（P かつ Q i が成り立つ）」と同値であることを示しています。

これは直観的に明らかですが、まさにFrameの無限分配律の例です。
-/
theorem prop_infinite_distributive_law (P : Prop) (Q : ℕ → Prop) :
    P ∧ (∃ i, Q i) ↔ ∃ i, (P ∧ Q i) := by
  constructor
  · intro ⟨hP, ⟨i, hQi⟩⟩
    exact ⟨i, hP, hQi⟩
  · intro ⟨i, hP, hQi⟩
    exact ⟨hP, ⟨i, hQi⟩⟩

/-- より一般的な形の無限分配律 -/
theorem prop_frame_law {ι : Type*} (P : Prop) (Q : ι → Prop) :
    P ∧ (∃ i, Q i) ↔ ∃ i, (P ∧ Q i) := by
  constructor
  · intro ⟨hP, ⟨i, hQi⟩⟩
    exact ⟨i, hP, hQi⟩
  · intro ⟨i, hP, hQi⟩
    exact ⟨hP, ⟨i, hQi⟩⟩

end BasicExamples

section SetExample

/-! ### 例2：べき集合 Set α

`Set α` はFrameの最も重要かつ直観的な例です。
これは位相空間の開集合系の抽象化となっています。

`Set α`において：
- ⊓（meet）は集合の交わり ∩
- ⊔（join）は集合の合併 ∪
- ⊤（top）は全体集合 univ
- ⊥（bottom）は空集合 ∅
- ⨆（sup）は和集合 ⋃
- ⨅（inf）は共通部分 ⋂
- ⇨（Heyting implication）は補集合的演算（s ⇨ t = sᶜ ∪ t）

無限分配律は：`A ∩ (⋃ᵢ Bᵢ) = ⋃ᵢ (A ∩ Bᵢ)` となります。
これは集合論の基本的な等式です！
-/

variable {α : Type*}

/-- `Set α` はCompleteDistribLatticeであり、したがってFrameです -/
example : Order.Frame (Set α) := inferInstance

/-- べき集合における無限分配律の明示的な証明

この定理は、集合 A と集合族 s = {B₁, B₂, B₃, ...} に対して、
  A ∩ (B₁ ∪ B₂ ∪ B₃ ∪ ...) = (A ∩ B₁) ∪ (A ∩ B₂) ∪ (A ∩ B₃) ∪ ...
が成り立つことを示しています。

これは集合論で頻繁に使う性質ですが、実はFrameの無限分配律そのものです。
-/
theorem set_infinite_distributive_law (A : Set α) (s : Set (Set α)) :
    A ∩ ⋃₀ s = ⋃ B ∈ s, A ∩ B := by
  ext x
  simp only [Set.mem_inter_iff, Set.mem_iUnion, Set.mem_sUnion]
  constructor
  · intro ⟨hA, ⟨B, hBs, hxB⟩⟩
    exact ⟨B, hBs, hA, hxB⟩
  · intro ⟨B, hBs, hA, hxB⟩
    exact ⟨hA, ⟨B, hBs, hxB⟩⟩

/-- 添字付き族の場合の無限分配律 -/
theorem set_iInf_iSup_law {ι : Type*} (A : Set α) (B : ι → Set α) :
    A ∩ ⋃ i, B i = ⋃ i, (A ∩ B i) := by
  ext x
  simp only [Set.mem_inter_iff, Set.mem_iUnion]
  constructor
  · intro ⟨hA, ⟨i, hBi⟩⟩
    exact ⟨i, hA, hBi⟩
  · intro ⟨i, hA, hBi⟩
    exact ⟨hA, ⟨i, hBi⟩⟩

/-- 具体例：自然数における無限分配律

具体的な集合を使った例を見てみましょう。
10以下の自然数と、各nに対する区間 [n, n+3) の和集合との交わりを考えます。
-/
example : {x : ℕ | x ≤ 10} ∩ (⋃ n : ℕ, {x | n ≤ x ∧ x < n + 3}) =
    ⋃ n : ℕ, ({x : ℕ | x ≤ 10} ∩ {x | n ≤ x ∧ x < n + 3}) := by
  -- これは無限分配律の直接的な応用です
  exact set_iInf_iSup_law _ _

end SetExample

/-! ## まとめ

このファイルでは、Frameの以下の具体例を見てきました：

1. **Prop**：命題の束
   - 論理演算がFrame構造を持つ
   - 無限分配律は `P ∧ (∃ i, Q i) ↔ ∃ i, (P ∧ Q i)` という形

2. **Set α**：べき集合
   - 最も直観的で重要な例
   - 無限分配律は `A ∩ (⋃ i, B i) = ⋃ i, (A ∩ B i)` という形
   - 位相空間の開集合系の一般化

これらの例から、Frameの本質的な性質である**無限分配律**
`a ⊓ (⨆ i, b i) = ⨆ i, (a ⊓ b i)` が、日常的に使う数学的構造で
自然に現れることが分かります。

### さらなる例

Mathlibには他にも以下のような重要なFrameの例があります：

- **任意の完備Boolean代数** `CompleteBooleanAlgebra α`
  - すべての完備Boolean代数は自動的にFrameです

- **位相空間の開集合全体** （Topology.Opens モジュール）
  - これがFrameの最も重要な応用例です
  - 点なしトポロジー（pointless topology）の基礎

- **下方閉集合** `LowerSet α` （Order.LowerSet モジュール）
  - 領域理論で重要な役割を果たします
  - すでにMathlibでFrameインスタンスが定義されています

### Frameの重要性

Frameは以下の分野で重要です：

1. **位相空間論**：開集合系がFrameを成す
2. **点なしトポロジー**：点を使わずにトポロジーを定義
3. **構成的数学**：Heyting代数は直観主義論理のモデル
4. **領域理論**：プログラム意味論の基礎

無限分配律は、これらの応用において本質的な役割を果たします。
-/
