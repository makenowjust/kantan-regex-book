# ANCHOR: base
require_relative './ast.rb'
require_relative './parser.rb'
require_relative './backtrack_vm.rb'
require_relative './compiler.rb'

class KantanRegex
  def initialize(pattern)
    @program = Compiler.compile(Parser.parse(pattern))
  end

  def match(input)
    BacktrackVM.exec(@program, input)
  end
end
# ANCHOR_END: base
