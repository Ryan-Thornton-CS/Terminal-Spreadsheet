require_relative 'Ast'
require_relative 'Interpreter'

grid = AST::Grid.new
runtime = AST::Runtime.new(grid)
serializer = AST::Serializer.new
evaluator = AST::Evaluator.new(runtime)
random_ints = [AST::Integer.new(10, 0, 0), AST::Integer.new(20, 0, 0), AST::Integer.new(30, 0, 0),
               AST::Integer.new(40, 0, 0), AST::Integer.new(50, 0, 0), AST::Integer.new(60, 0, 0)]
random_strings = [AST::String.new("he", 0, 0), AST::String.new("no", 0, 0), AST::String.new("is", 0, 0),
                  AST::String.new("be", 0, 0), AST::String.new("or", 0, 0), AST::String.new("to", 0, 0)]
random_floats = [AST::Float.new(1.1, 0, 0), AST::Float.new(2.2, 0, 0), AST::Float.new(3.3, 0, 0),
                 AST::Float.new(4.4, 0, 0), AST::Float.new(5.5, 0, 0), AST::Float.new(6.6, 0, 0)]
random_bools = [AST::Boolean.new(true, 0, 0), AST::Boolean.new(false, 0, 0), AST::Boolean.new(true, 0, 0),
                AST::Boolean.new(false, 0, 0), AST::Boolean.new(true, 0, 0), AST::Boolean.new(false, 0, 0)]

# Creates a bunch of cell addresses, cells, values, and assigns them to the grid
(0..5).each { |x|
  (0..5).each { |y|
    celladdr = AST::CellAddress.new(AST::Integer.new(x, 0, 0), AST::Integer.new(y, 0, 0))
    cell = AST::Cell.new(random_ints[rand(0..5)], runtime)
    runtime.grid.add_cell(celladdr, cell)
  }
}
# So to find say, (2,4) you start from the top and go down 0/1/2 and from the left to the
# right 0/1/2/3/4.  X is really Y and Y is really X.  So (2,4) is mathematically equivalent to (4,2)
# Creates a bunch of cell addresses, cells, values, and assigns them to the grid
(6..10).each { |x|
  (0..5).each { |y|
    celladdr = AST::CellAddress.new(AST::Integer.new(x, 0, 0), AST::Integer.new(y, 0, 0))
    cell = AST::Cell.new(random_strings[rand(0..5)], runtime)
    runtime.grid.add_cell(celladdr, cell)
  }
}

# Creates a bunch of cell addresses, cells, values, and assigns them to the grid
(6..10).each { |x|
  (6..10).each { |y|
    celladdr = AST::CellAddress.new(AST::Integer.new(x, 0, 0), AST::Integer.new(y, 0, 0))
    cell = AST::Cell.new(random_floats[rand(0..5)], runtime)
    runtime.grid.add_cell(celladdr, cell)
  }
}

# Creates a bunch of cell addresses, cells, values, and assigns them to the grid
(0..5).each { |x|
  (6..10).each { |y|
    celladdr = AST::CellAddress.new(AST::Integer.new(x, 0, 0), AST::Integer.new(y, 0, 0))
    cell = AST::Cell.new(random_bools[rand(0..5)], runtime)
    runtime.grid.add_cell(celladdr, cell)
  }
}

puts "\e[34mStart of video tests independent of grid:\e[0m"
puts
puts "\e[32mArithmetic: (7 * 4 + 3) % 12\e[0m"
# Arithmetic serialization
mod_mul = AST::Multiply.new(AST::Integer.new(7, 0, 0), AST::Integer.new(4, 0, 0), 0, 0)
mod_add = AST::Add.new(mod_mul, AST::Integer.new(3, 0, 0), 0, 0)
j = AST::Modulo.new(mod_add, AST::Integer.new(12, 0, 0), 0, 0)
puts "This is the serialization of Arithmetic example #{j.traverse(serializer)}"
puts "This is the evaluation of Arithmetic example #{j.traverse(evaluator)}"
puts
puts "\e[32mLogic and comparison: !(3.3 > 3.2)\e[0m"
# Logic and comparison serialization
greater_than = AST::GreaterThan.new(AST::Float.new(3.3, 0, 0), AST::Float.new(3.2, 0, 0), 0, 0)
not_something = AST::Not.new(nil, greater_than, 0, 0)
puts "This is the serialization of Logic and comparison #{not_something.traverse(serializer)}"
puts "This is the evaluation of Logic and comparison #{not_something.traverse(evaluator)}"
puts
puts "\e[32mCasting: float(7) / 2\e[0m"
# Casting
int_to_float = AST::IntegerToFloat.new(nil, AST::Integer.new(7, 0, 0), 0, 0)
division = AST::Divide.new(int_to_float, AST::Integer.new(2, 0, 0), 0, 0)
puts "This is the serialization of Casting #{division.traverse(serializer)}"
puts "This is the evaluation of Casting #{division.traverse(evaluator)}"
puts
puts "\e[34mThis is where failures are tested independent of grid\e[0m"
puts
puts "\e[32mType error between statistical functions and non-lvalue arguments: max([1, 2], \"hello\")\e[0m"
left_string = AST::String.new("hello", 0, 0)
left_lvalue = AST::Lvalue.new(AST::Integer.new(1, 0, 0), AST::Integer.new(2, 0, 0), 0, 0)
max = AST::Max.new(left_lvalue, left_string, 0, 0)
begin
  max.traverse(evaluator)
rescue => e
  puts "Type error between statistical functions and non-lvalue arguments:\n\t #{e}"
end
puts
puts "\e[32mType error between operators and incorrect primitives: \"hello\" < 5\e[0m"
less_than = AST::LessThan.new(left_string, AST::Integer.new(5, 0, 0), 0, 0)
begin
  less_than.traverse(evaluator)
rescue => e
  puts "Type error between operators and incorrect primitives:\n\t#{e}"
end
puts
puts "\e[32mType error between operators and non-AST primitives: AST::Add.new(5, [1, 2])\e[0m"
begin
  AST::Add.new(5, left_lvalue, 0, 0).traverse(evaluator)
rescue => e
  puts "Type error between operators and non-AST primitives:\n\t#{e}"
end
puts

puts "\e[34mStart of video tests dependent of grid:\e[0m"
puts
puts "\e[32mShows that the grid actually populates correctly:\e[0m"
# Prints the grid
runtime.print_grid
runtime.grid.clear_grid
puts
puts "\e[32mShows the grid clears and is empty:\e[0m"
runtime.print_grid
puts

# Creates cell addresses to be used in the grid
zero_zero = AST::CellAddress.new(AST::Integer.new(0, 0, 0), AST::Integer.new(0, 0, 0))
two_four = AST::CellAddress.new(AST::Integer.new(2, 0, 0), AST::Integer.new(4, 0, 0))
zero_one = AST::CellAddress.new(AST::Integer.new(0, 0, 0), AST::Integer.new(1, 0, 0))

puts "\e[32mGrid test: Arithmetic: (7 * 4 + 3) % 12\e[0m"
# Arithmetic serialization
runtime.grid.add_cell(zero_zero, AST::Cell.new(j, runtime))
puts "This is the serialization of Arithmetic example from grid: #{runtime.grid.get_cell(zero_zero)
                                                                          .cell_string_representation}"
puts "This is the evaluation of Arithmetic example from grid: #{runtime.grid.get_cell(zero_zero)
                                                                       .cell_value}"
puts
puts "\e[32mGrid test: Rvalue lookup and shift: #[1 + 1, 4] << 3\e[0m"
# Rvalue lookup and shift serialization
runtime.grid.add_cell(two_four, AST::Cell.new(random_ints[0], runtime))
left_shift_add = AST::Add.new(AST::Integer.new(1, 0, 0), AST::Integer.new(1, 0, 0), 0, 0)
left_shift_rvalue = AST::Rvalue.new(left_shift_add, AST::Integer.new(4, 0, 0), 0, 0)
left_shift = AST::BitwiseLeftShift.new(left_shift_rvalue, AST::Integer.new(3, 0, 0), 0, 0)
puts "The cell value of Rvalue is #{runtime.grid.get_cell(two_four).cell_value}"
puts "This is the serialization of Rvalue lookup and shift: #{left_shift.traverse(serializer)}"
puts "This is the evaluation of Rvalue lookup and shift: #{left_shift.traverse(evaluator)}"
puts
puts "\e[32mRvalue lookup and comparison: #[0, 0] < #[0, 1]\e[0m"

# Rvalue lookup and comparison serialization
runtime.grid.add_cell(zero_one, AST::Cell.new(random_ints[0], runtime))
left_rvalue = AST::Rvalue.new(AST::Integer.new(0, 0, 0), AST::Integer.new(0, 0, 0), 0, 0)
right_rvalue = AST::Rvalue.new(AST::Integer.new(0, 0, 0), AST::Integer.new(1, 0, 0), 0, 0)
less_than = AST::LessThan.new(left_rvalue, right_rvalue, 0, 0)
puts "The cell value of left Rvalue is #{left_rvalue.traverse(evaluator)} and the cell value of right Rvalue is #{right_rvalue.traverse(evaluator)}"
puts "This is the serialization of Rvalue lookup and comparison: #{less_than.traverse(serializer)}"
puts "This is the evaluation of Rvalue lookup and comparison: #{less_than.traverse(evaluator)}"
puts
puts "\e[32mSum: sum([1, 2], [5, 3])\e[0m"
# Creates a bunch of cell addresses, cells, values, and assigns them to the grid
(1..5).each { |x|
  (2..3).each { |y|
    celladdr = AST::CellAddress.new(AST::Integer.new(x, 0, 0), AST::Integer.new(y, 0, 0))
    cell = AST::Cell.new(random_ints[rand(0..5)], runtime)
    runtime.grid.add_cell(celladdr, cell)
  }
}
puts "Grid has been populated with random integers from row 1 to 5 and column 2 to 3"
runtime.print_grid
# Sum serialization
right_lvalue = AST::Lvalue.new(AST::Integer.new(5, 0, 0), AST::Integer.new(3, 0, 0), 0, 0)
sum = AST::Sum.new(left_lvalue, right_lvalue, 0, 0)
puts "The left lvalue is #{left_lvalue.traverse(evaluator)} and the right lvalue is #{right_lvalue.traverse(evaluator)}"
puts "This is the serialization of Sum: #{sum.traverse(serializer)}"
puts "This is the evaluation of Sum: #{sum.traverse(evaluator)}"
puts

# INTERPRETER TESTS BELOW HERE
# Arithmetic: (5 + 2) * 3 % 4
# Rvalue lookup and shift: #[0, 0] + 3
# Rvalue lookup and comparison: #[1 - 1, 0] < #[1 * 1, 1]
# Logic and comparison: (5 > 3) && !(2 > 8)
# Sum: 1 + sum([0, 0], [2, 1])
# Casting: float(10) / 4.0

arithmetic_string = "(5 + 2) * 3 % 4"
rvalue_lookup_shift_string = "#[0, 0] + 3"
rvalue_lookup_comparison_string = "#[1 - 1, 0] < #[1 * 1, 1]"
logic_comparison_string = "(5 > 3) && !(2 > 8)"
sum_string = "1 + sum([0, 0], [2, 1])"
casting_string = "float(10) / 4.0"

puts "\e[32m#{Lexer.new(arithmetic_string).lex.inject("") { |cur, token| cur + token.value }} \e[0m"
p Lexer.new(arithmetic_string).lex.inject("") { |cur, token| cur + token.type.to_s + " " }.strip
puts
puts "\e[32m#{Lexer.new(rvalue_lookup_shift_string).lex.inject("") { |cur, token| cur + token.value }} \e[0m"
p Lexer.new(rvalue_lookup_shift_string).lex.inject("") { |cur, token| cur + token.type.to_s + " " }.strip
puts
puts "\e[32m#{Lexer.new(rvalue_lookup_comparison_string).lex.inject("") { |cur, token| cur + token.value }} \e[0m"
p Lexer.new(rvalue_lookup_comparison_string).lex.inject("") { |cur, token| cur + token.type.to_s + " " }.strip
puts
puts "\e[32m#{Lexer.new(logic_comparison_string).lex.inject("") { |cur, token| cur + token.value }} \e[0m"
p Lexer.new(logic_comparison_string).lex.inject("") { |cur, token| cur + token.type.to_s + " " }.strip
puts
puts "\e[32m#{Lexer.new(sum_string).lex.inject("") { |cur, token| cur + token.value }} \e[0m"
p Lexer.new(sum_string).lex.inject("") { |cur, token| cur + token.type.to_s + " " }.strip
puts
puts "\e[32m#{Lexer.new(casting_string).lex.inject("") { |cur, token| cur + token.value }} \e[0m"
p Lexer.new(casting_string).lex.inject("") { |cur, token| cur + token.type.to_s + " " }.strip
puts
arith = Parser.new(Lexer.new(arithmetic_string).lex).parse
rval_shift = Parser.new(Lexer.new(rvalue_lookup_shift_string).lex).parse
rval_comp = Parser.new(Lexer.new(rvalue_lookup_comparison_string).lex).parse
logic_comp = Parser.new(Lexer.new(logic_comparison_string).lex).parse
sum = Parser.new(Lexer.new(sum_string).lex).parse
cast = Parser.new(Lexer.new(casting_string).lex).parse

puts "\e[32mTraverse of arithmetic: \e[0m"
p arith.traverse(serializer)
puts
puts "\e[32mTraverse of rval_shift: \e[0m"
p rval_shift.traverse(serializer)
puts
puts "\e[32mTraverse of rval_comp: \e[0m"
p rval_comp.traverse(serializer)
puts
puts "\e[32mTraverse of logic_comp: \e[0m"
p logic_comp.traverse(serializer)
puts
puts "\e[32mTraverse of sum: \e[0m"
p sum.traverse(serializer)
puts
puts "\e[32mTraverse of cast: \e[0m"
p cast.traverse(serializer)
puts
puts "\e[32mError handling: no right parenthesis\e[0m"
begin
  puts Parser.new(Lexer.new("(5 + 2 * 3 % 4").lex).parse
rescue => e
  puts "#{e}"
end
puts
puts "\e[32mError handling: no left parenthesis\e[0m"
begin
  puts Parser.new(Lexer.new("5 + 2 * 3 % 4)").lex).parse
rescue => e
  puts "#{e}"
end
puts
puts "\e[32mError handling: no right bracket\e[0m"
begin
  puts Parser.new(Lexer.new("#[5 + 2, 3 * 3 % 4").lex).parse
rescue => e
  puts "#{e}"
end
puts
puts "\e[32mError handling: no left bracket\e[0m"
begin
  puts Parser.new(Lexer.new("#5 + 2, 3] * 3 % 4").lex).parse
rescue => e
  puts "#{e}"
end
puts
puts "\e[32mError handling: no operator\e[0m"
begin
  puts Parser.new(Lexer.new("3 4").lex).parse
rescue => e
  puts "#{e}"
end