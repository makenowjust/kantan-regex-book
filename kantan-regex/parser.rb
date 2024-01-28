class KantanRegex; end

require_relative './ast.rb'

# ANCHOR: base_util
class KantanRegex::Parser
  def initialize(pattern)
    @pattern = pattern
    @offset = 0
  end
  
  def current_char =@pattern[@offset]
  def end? = @pattern.size <= @offset

  def next_char
    @offset += 1
  end
end
# ANCHOR_END: base_util

# ANCHOR: base_impl
class KantanRegex::Parser
  # 構文解析の開始地点。
  def parse
    tree = parse_choice

    # 最後までちゃんと構文解析したかをチェックする。
    raise 'End-of-string is expected' unless end?
    tree
  end

  # 選択 (`a|b`) を構文解析するメソッド。
  def parse_choice
    children = []
    children << parse_concat

    while current_char == '|'
      next_char
      children << parse_concat
    end

    # `children`が1つしか無い場合は`Choice`を生成しない。
    return children.first if children.size == 1
    KantanRegex::Choice[children]
  end

  # 連接 (`ab`) を構文解析するメソッド。
  def parse_concat
    children = []

    until concat_stop?
      children << parse_repetition
    end

    # `children`が1つしか無い場合は`Concat`を生成しない。
    return children.first if children.size == 1
    KantanRegex::Concat[children]
  end

  # 現在の文字が連接を続けるべきか判定するメソッド。
  def concat_stop? =
    end? || current_char == ')' || current_char == '|'

  # 繰り返し (`a*`, `a+`, `a?`) を構文解析するメソッド。
  def parse_repetition
    child = parse_group

    quantifier =
      case current_char
      when '*' then :star
      when '+' then :plus
      when '?' then :question
      else nil
      end
    return child unless quantifier
    next_char

    KantanRegex::Repetition[child, quantifier]
  end

  # グループ化 (`(a)`) を構文解析するメソッド。
  def parse_group
    return parse_literal if current_char != '('
    next_char

    child = parse_choice

    raise '")" is expected' if current_char != ')'
    next_char

    child
  end

  # 文字リテラルやエスケープ文字を構文解析するメソッド。
  def parse_literal
    if current_char == '\\'
      next_char
      raise 'Missing escaped character' if end?

      value = current_char
      case value
      when '(', ')', '*', '+', '?', '|', '\\'
        next_char
      else
        raise 'Unsupported escaped character'
      end

      return KantanRegex::Literal[value]
    end

    value = current_char
    case value
    when '(', ')', '*', '+', '?', '|', '\\'
      raise 'Invalid literal character'
    else
      next_char
    end

    KantanRegex::Literal[value]
  end
end
# ANCHOR_END: base_impl

# ANCHOR: base_entry
class KantanRegex::Parser
  def self.parse(pattern) =
    KantanRegex::Parser.new(pattern).parse
end
# ANCHOR_END: base_entry