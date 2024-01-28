# ANCHOR: base
class KantanRegex
  # 文字リテラル・エスケープ文字に対応する抽象構文木のデータ型。
  Literal = Data.define(:value)

  # 繰り返しに対応する抽象構文木のデータ型。
  Repetition = Data.define(:child, :quantifier)

  # 選択に対応する抽象構文木のデータ型。
  Choice = Data.define(:children)

  # 連接に対応する抽象構文木のデータ型。
  Concat = Data.define(:children)
end
# ANCHOR_END: base
