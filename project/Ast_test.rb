require_relative 'Ast'
require 'curses'

grid = AST::Grid.new
runtime = AST::Runtime.new(grid)
serializer = AST::Serializer.new
evaluator = AST::Evaluator.new(runtime)

# Random variables for testing
a = AST::Integer.new(1.34)
b = AST::Float.new(1.0)
c = AST::String.new("Hello")
d = AST::CellAddress.new(a, b)
e = AST::Add.new(a, b)
f = AST::FloatToInteger.new(nil, b)
g = AST::Negate.new(nil, a)
h = AST::CellAddress.new(a, AST::Integer.new(2))
i = AST::Lvalue.new(AST::Integer.new(5), AST::Integer.new(3))
k = AST::Boolean.new(true)
l = AST::Boolean.new(false)
n = AST::Max.new(i, AST::Lvalue.new(AST::Integer.new(10), AST::Integer.new(7)))

# Tests for video
puts
puts "Start of video tests:"

# Arithmetic serialization
mod_mul = AST::Multiply.new(AST::Integer.new(7), AST::Integer.new(4))
mod_add = AST::Add.new(mod_mul, AST::Integer.new(3))
j = AST::Modulo.new(mod_add, AST::Integer.new(12))
puts "This is the serialization of Arithmetic example #{j.traverse(serializer)}"
puts "This is the evaluation of Arithmetic example #{j.traverse(evaluator)}"
puts

# Rvalue lookup and shift serialization
left_shift_add = AST::Add.new(AST::Integer.new(1), AST::Integer.new(1))
left_shift_rvalue = AST::Rvalue.new(left_shift_add, AST::Integer.new(4))
left_shift = AST::BitwiseLeftShift.new(left_shift_rvalue, AST::Integer.new(3))
puts "This is the serialization of Rvalue lookup and shift #{left_shift.traverse(serializer)}"
puts

# Rvalue lookup and comparison serialization
left_rvalue = AST::Rvalue.new(AST::Integer.new(0), AST::Integer.new(0))
right_rvalue = AST::Rvalue.new(AST::Integer.new(0), AST::Integer.new(1))
less_than = AST::LessThan.new(left_rvalue, right_rvalue)
puts "This is the serialization of Rvalue lookup and comparison #{less_than.traverse(serializer)}"
puts

# Logic and comparison serialization
greater_than = AST::GreaterThan.new(AST::Float.new(3.3), AST::Float.new(3.2))
not_something = AST::Not.new(nil, greater_than)
puts "This is the serialization of Logic and comparison #{not_something.traverse(serializer)}"
puts "This is the evaluation of Logic and comparison #{not_something.traverse(evaluator)}"
puts

# Sum serialization
left_lvalue = AST::Lvalue.new(AST::Integer.new(1), AST::Integer.new(2))
right_lvalue = AST::Lvalue.new(AST::Integer.new(5), AST::Integer.new(3))
sum = AST::Sum.new(left_lvalue, right_lvalue)
puts "This is the serialization of Sum #{sum.traverse(serializer)}"
# puts "This is the evaluation of Sum #{sum.traverse(evaluator)}"
puts

# Casting
int_to_float = AST::IntegerToFloat.new(nil, AST::Integer.new(7))
division = AST::Divide.new(int_to_float, AST::Integer.new(2))
puts "This is the serialization of Casting #{division.traverse(serializer)}"
puts "This is the evaluation of Casting #{division.traverse(evaluator)}"

# Random tests
puts
puts "Start of random tests:"
puts a.value
puts b.value
puts c.size
puts d.x_var.value
puts d.y_var.value
puts "This is the serializer of a Primitive #{a.traverse(serializer)}"
puts "This is the evaluation of a Primitive #{a.traverse(evaluator)}"
puts "This is the serializer of k Primitive #{k.traverse(serializer)}"
puts "This is the serializer of l Primitive #{l.traverse(serializer)}"
puts "This is the serializer of e Add #{e.traverse(serializer)}"
puts "This is the serializer of f FloatToInteger #{f.traverse(serializer)}"
puts "This is the serializer of g Negate #{g.traverse(serializer)}"
puts "This is the serializer of h CellAddress #{h.traverse(serializer)}"
puts "This is the serializer of i Lvalue #{i.traverse(serializer)}"
puts "This is the serializer of m Max #{n.traverse(serializer)}"
# e = AST::Modulo.new(5, 3)
# puts "this is the evaluation of e Modulo #{e.traverse(evaluator)}"
# puts "This is the evaluation of e Add #{e.traverse(evaluator)}"

# puts "This is the error for serializer #{serializer.serialize_operator(1.0)}" # Uncomment to test
# (works)
# puts "This is the serializer of m Add #{m.traverse(serializer)}" # Will fail because it's the wrong
# # type of node inside of add

# Populates the grid with random values


