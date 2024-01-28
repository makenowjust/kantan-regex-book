class KantanRegex; end

# ANCHOR: base
class KantanRegex::BacktrackVM
  StackBacktrack = Data.define(:pc, :pos)

  def initialize(program, input)
    @program = program
    @input = input
  end

  def exec(start_pos)
    pc = 0
    pos = start_pos
    stack = []

    loop do
      case @program[pc]
      in [:push, backtrack_pc]
        stack << StackBacktrack[backtrack_pc, pos]
        pc += 1
      in [:jump, next_pc]
        pc = next_pc
      in [:char, c]
        if @input[pos] == c
          pc += 1
          pos += 1
        else
          return nil if stack.empty?
          stack.pop => StackBacktrack[pc, pos]
        end
      in [:match]
        return pos
      end
    end
  end

  def self.exec(program, input)
    vm = KantanRegex::BacktrackVM.new(program, input)
    (0...input.size).each do |start_pos|
      end_pos = vm.exec(start_pos)
      return start_pos...end_pos if end_pos
    end
    nil
  end
end
# ANCHOR_END: base
