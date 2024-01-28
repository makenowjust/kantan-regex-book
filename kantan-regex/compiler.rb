class KantanRegex; end

require_relative './ast.rb'

# ANCHOR: base
class KantanRegex::Compiler
  def initialize
    @program = []
  end

  attr_reader :program

  # 命令を`program`に追加するメソッド。
  # `insn`はinstructionの略。
  # 返り値は追加した命令の`program`上のインデックス。
  def insn(*insn)
    index = @program.size
    @program << insn
    index
  end

  def compile_root(tree)
    compile(tree)
    insn :match
  end

  private def compile(tree)
    case tree
    in KantanRegex::Literal[value]
      insn :char, value
    in KantanRegex::Repetition[child, :star]
      push_index = insn(:push, nil) # まだジャンプ先が分からないのでひとまず`nil`を入れている
      compile child
      insn :jump, push_index
      @program[push_index][1] = @program.size
    in KantanRegex::Repetition[child, :plus]
      start_index = @program.size
      compile child
      insn :push, @program.size + 2
      insn :jump, start_index
    in KantanRegex::Repetition[child, :question]
      push_index = insn(:push, nil) # まだジャンプ先が分からないのでひとまず`nil`を入れている
      compile child
      @program[push_index][1] = @program.size
    in KantanRegex::Choice[children]
      jump_indices = []
      children.each_with_index do |child, i|
        is_last = i == children.size - 1
        unless is_last
          push_index = insn(:push, nil) # まだジャンプ先が分からないのでひとまず`nil`を入れている
        end
        compile child
        unless is_last
          jump_index = insn(:jump, nil) # まだジャンプ先が分からないのでひとまず`nil`を入れている
          jump_indices << jump_index
          @program[push_index][1] = @program.size
        end
      end
      jump_indices.each do |jump_index|
        @program[jump_index][1] = @program.size
      end
    in KantanRegex::Concat[children]
      children.each { compile _1 }
    end
  end

  def self.compile(tree)
    compiler = KantanRegex::Compiler.new
    compiler.compile_root(tree)
    compiler.program
  end
end
# ANCHOR_END: base