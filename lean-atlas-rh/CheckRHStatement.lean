import Mathlib.NumberTheory.LSeries.RiemannZeta

-- `RiemannHypothesis` の本体を、暗黙引数・インスタンスをすべて表示して確認する
set_option pp.explicit true in
#print RiemannHypothesis

-- 各サブ式がどの定数を使うかを個別に確認
set_option pp.explicit true in
#check ((1 / 2 : ℝ))
set_option pp.explicit true in
#check (fun n : ℕ => (-2 * (n + 1) : ℂ))
