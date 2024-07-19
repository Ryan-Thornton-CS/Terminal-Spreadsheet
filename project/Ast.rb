# This file contains the abstract syntax tree for the GridKid language.
# The classes are organized into the following categories:
# 1. Base primitive classes.
# 2. Logic class, arithmetic class, and operators class.
# 3. Statistical functions: max, min, mean, and sum.
# 4. Lvalue and rvalues.
# 5. Grid class and Cell class.

# Start of Ast.rb.
module AST

  # TODO: Figure out a more concise way to represent this.
  # Block of code that contains multiple statements.
  class Block
    attr_accessor :statements, :start_index, :end_index

    def initialize(statements, start_index, end_index)
      # Either conditional statements or loop statements.
      # Array of statements. first index is the condition, next index is the value if condition
      # is true, then another condition, then value, etc.
      # So, [proportion = #[2, 4] + 1, amount = sum([5, 8], [9, 8]), proportion * amount]

      # Block statements are essentially just chunks of code.
      @statements = statements
      @start_index = start_index
      @end_index = end_index
    end

    def traverse(visitor)
      visitor.visit_block(self)
    end
  end

  class Assignment
    attr_accessor :cell, :name, :value, :start_index, :end_index

    def initialize(cell, name, value, start_index, end_index)
      @cell = cell
      # Left side of the assignment or the name of the variable.
      @name = name
      # Right side of the assignment.
      @value = value
      @start_index = start_index
      @end_index = end_index
    end

    def traverse(visitor)
      visitor.visit_assignment(self)
    end
  end

  class Variable
    attr_accessor :cell, :name, :start_index, :end_index

    def initialize(cell, name, start_index, end_index)
      @cell = cell
      @name = name
      @start_index = start_index
      @end_index = end_index
    end

    def traverse(visitor)
      visitor.visit_variable(self)
    end
  end

  class Conditional
    attr_accessor :condition, :value, :else_value, :start_index, :end_index

    def initialize(condition, value, else_value, start_index, end_index)
      @condition = condition
      @value = value
      @else_value = else_value
      @start_index = start_index
      @end_index = end_index
    end

    def traverse(visitor)
      visitor.visit_conditional(self)
    end
  end

  class ForEachLoop
    attr_accessor :variable, :lower_range, :upper_range, :block, :start_index, :end_index

    def initialize(variable, lower_range, upper_range, block, start_index, end_index)
      @variable = variable
      @lower_range = lower_range
      @upper_range = upper_range
      @block = block
      @start_index = start_index
      @end_index = end_index
    end

    # TODO: FINISH THIS
    def traverse(visitor)
      visitor.visit_for_each_loop(self)
    end
  end

  # Start of base primitive classes.
  class Primitive
    attr_accessor :value, :start_index, :end_index

    def initialize(value, start_index, end_index)
      @value = value
      @start_index = start_index
      @end_index = end_index
    end

    # This method is used to traverse a node and serialize it within the
    # AST.
    def traverse(visitor)
      visitor.visit_primitive(self)
    end
  end

  class Integer < Primitive
  end

  class Float < Primitive
  end

  class Boolean < Primitive
  end

  class String < Primitive
    def size
      @value.size
    end
  end

  # This class is only allowed to use Ast Primitive.
  # This class will also be hashed and compared to other CellAddress objects as it's the key
  # to the Grid class's memory structure.
  # So to find say, (2,4) you start from the top and go down 0/1/2 and from the left to the
  # right 0/1/2/3/4
  class CellAddress
    attr_accessor :x_var, :y_var

    def initialize(x_var, y_var)
      @x_var = x_var
      @y_var = y_var
    end

    # This method is used to traverse a node and serialize it within the
    # AST.
    def traverse(visitor)
      visitor.visit_cell_address(self)
    end

    def hash
      [self.x_var.value, self.y_var.value].hash
    end

    def eql?(other)
      self.x_var.value == other.x_var.value and self.y_var.value == other.y_var.value
    end
  end

  # End of base primitive classes.

  # Start of logic class, arithmetic class, and operators class.
  class Operator
    attr_accessor :left, :right, :start_index, :end_index

    def initialize(left, right, start_index, end_index)
      @left = left
      @right = right
      @start_index = start_index
      @end_index = end_index
    end

    # This method is used to traverse a node to either serialize or evaluate it in the
    # AST.
    def traverse(visitor)
      visitor.visit_operator(self)
    end
  end

  # Start of arithmetic operators.
  class Add < Operator
  end

  class Subtract < Operator
  end

  class Multiply < Operator
  end

  class Divide < Operator
  end

  class Modulo < Operator
  end

  class Exponent < Operator
  end

  class Negate < Operator
  end

  # End of arithmetic operators.

  # Start of logical operators.
  class And < Operator
  end

  class Or < Operator
  end

  class Not < Operator
  end

  # End of logical operators.

  # Start of bitwise operators.
  class BitwiseAnd < Operator
  end

  class BitwiseOr < Operator
  end

  class BitwiseXor < Operator
  end

  class BitwiseNot < Operator
  end

  class BitwiseLeftShift < Operator
  end

  class BitwiseRightShift < Operator
  end

  # End of bitwise operators.

  # Start of relational operators.
  class Equal < Operator
  end

  class NotEqual < Operator
  end

  class LessThan < Operator
  end

  class LessThanOrEqual < Operator
  end

  class GreaterThan < Operator
  end

  class GreaterThanOrEqual < Operator
  end

  # End of relational operators.

  # Start of casting operators.
  class FloatToInteger < Operator
  end

  class IntegerToFloat < Operator
  end

  # End of casting operators.

  # Start of statistical functions: max, min, mean, and sum.
  # These classes are only allowed to use AST lvalues where left is the
  # top-left cell and right is the bottom-right cell to compute the values of all
  # the cells within the square formed by the two cells.
  class StatisticalFunction
    attr_accessor :left, :right, :start_index, :end_index

    def initialize(left, right, start_index, end_index)
      @left = left
      @right = right
      @start_index = start_index
      @end_index = end_index
    end

    # This method is used to traverse a node to either serialize or evaluate it in the
    # AST.
    def traverse(visitor)
      visitor.visit_statistical_function(self)
    end
  end

  class Max < StatisticalFunction
  end

  class Min < StatisticalFunction
  end

  class Mean < StatisticalFunction
  end

  class Sum < StatisticalFunction
  end

  # End of statistical functions: max, min, mean, and sum.

  # Start of lvalues and rvalues.
  # Lvalue only cares about the cell's address.
  # This class is only allowed to use Ast primitives.
  # LVALUES ARE THE ADDRESS OF A CELL AND IF TWO ADDRESS ARE EQUAL THEN THEY ARE THE SAME CELL
  class Lvalue
    attr_accessor :x_var, :y_var, :start_index, :end_index

    def initialize(x_var, y_var, start_index, end_index)
      @x_var = x_var
      @y_var = y_var
      @start_index = start_index
      @end_index = end_index
    end

    # This method is used to traverse a node to either serialize or evaluate it in the
    # AST.
    def traverse(visitor)
      visitor.visit_lvalue(self)
    end
  end

  # Rvalue only care about the cell's value.
  # This class is only allowed to use Ast primitives.
  # RVALUES COMPARE THE VALUE OF A VARIABLE TO THE VALUE OF ANOTHER VARIABLE
  class Rvalue
    attr_accessor :x_var, :y_var, :start_index, :end_index

    def initialize(x_var, y_var, start_index, end_index)
      @x_var = x_var
      @y_var = y_var
      @start_index = start_index
      @end_index = end_index
    end

    # This method is used to traverse a node to either serialize or evaluate it in the
    # AST.
    def traverse(visitor)
      visitor.visit_rvalue(self)
    end
  end

  # End of lvalues and rvalues.

  # Start of Grid class, Cell class, and Runtime class.
  class Runtime
    attr_reader :grid, :variables

    def initialize(grid)
      @grid = grid
      @variables = {}
    end

    # This method prints a grid equivalent to the one in the grid class.
    def print_grid
      (0..grid.largest_x).each { |x|
        (0..grid.largest_y).each { |y|
          if grid.get_cell(CellAddress.new(AST::Integer.new(x, 0, 0),
                                           AST::Integer.new(y, 0, 0))) == nil
            print "\e[33m00 \e[0m"
            next
          end
          print "\e[33m#{grid.get_cell(CellAddress.new(AST::Integer.new(x, 0, 0),
                                                       AST::Integer.new(y, 0, 0))).cell_value} \e[0m"
        }
        puts
      }
    end
  end

  # This is the representation of the grid.  It contains a hash of cells.
  # The key is the cell's address and the value is the cell object.
  class Grid
    attr_reader :grid, :largest_x, :largest_y

    def initialize
      @grid = {}
      # default size of the grid
      @largest_x = 100
      @largest_y = 100
    end

    # The cell_address is an actual CellAddress object and the cell is a Cell object.
    def add_cell(cell_address, cell)
      unless cell_address.is_a?(AST::CellAddress) and cell.is_a?(AST::Cell)
        raise "Invalid AST operators, CellAddress or Cell allowed only"
      end
      @grid[cell_address] = cell
      @largest_x = [cell_address.x_var.value, @largest_x].max
      @largest_y = [cell_address.y_var.value, @largest_y].max
    end

    def get_cell(cell_address)
      unless cell_address.is_a?(AST::CellAddress)
        raise "Invalid AST operators, CellAddress only allowed"
      end
      @grid[cell_address]
    end

    def remove_cell(cell_address)
      unless cell_address.is_a?(AST::CellAddress)
        raise "Invalid AST operators, CellAddress only allowed"
      end
      @grid.delete(cell_address)
    end

    def clear_grid
      @grid.clear
      @largest_x = 10
      @largest_y = 10
    end

  end

  # This is a representation of a cell within the grid.  It contains the cells above, below, left,
  # and right of it.  It also contains the cell's value.
  class Cell
    attr_accessor :cell_value, :cell_root_node, :cell_string_representation, :runtime, :runtime2

    def initialize(cell_root_node, runtime)
      @cell_root_node = cell_root_node
      @runtime = runtime
      @runtime2 = AST::Runtime.new(@runtime.grid)
      # @cell_value = cell_root_node.traverse(Evaluator.new(runtime))
      # @cell_string_representation = cell_root_node.traverse(Serializer.new)
    end

    # This method gets the cell_value in real time.
    def cell_value
      @cell_root_node.traverse(Evaluator.new(@runtime2))
    end

    def cell_string_representation
      @cell_root_node.traverse(Serializer.new)
    end

    def update_cell_value
      @cell_value = @cell_root_node.traverse(Evaluator.new(@runtime))
    end

    def update_cell_string_representation
      @cell_string_representation = @cell_root_node.traverse(Serializer.new)
    end

  end

  # End of Grid class and Cell class.

  # Start of Serializer class.
  class Serializer
    def initialize
    end

    def visit_block(block)
      block_string = " "
      block.statements.each { |statement|
        if statement.nil?
          next
        end
        block_string += statement.traverse(self) + "\n "
      }
      block_string
    end

    def visit_assignment(assignment)
      "#{assignment.name.traverse(self)} = #{assignment.value.traverse(self)}"
    end

    def visit_variable(variable)
      "$#{variable.name.traverse(self)}"
    end

    def visit_conditional(conditional)
      if conditional.else_value.nil?
        "if#{conditional.condition.traverse(self)} then\n #{conditional.value.traverse(self)
        }end"
      else
        "if#{conditional.condition.traverse(self)} then\n#{conditional.value.traverse(self)
        }else\n#{conditional.else_value.traverse(self)}end"
      end
    end

    def visit_for_each_loop(for_each_loop)
      "for(#{for_each_loop.variable.traverse(self)} in " +
        "#{for_each_loop.lower_range.traverse(self)}.." +
        "#{for_each_loop.upper_range.traverse(self)})\n" +
        "#{for_each_loop.block.traverse(self)}end"
    end

    def visit_primitive(primitive)
      primitive.value.to_s
    end

    def visit_cell_address(cell_address)
      "[#{cell_address.x_var.value}, #{cell_address.y_var.value}]"
    end

    def visit_lvalue(lvalue)
      "[#{lvalue.x_var.traverse(self)}, #{lvalue.y_var.traverse(self)}]"
    end

    def visit_rvalue(rvalue)
      "#[#{rvalue.x_var.traverse(self)}, #{rvalue.y_var.traverse(self)}]"
    end

    def visit_operator(operator)
      operator_string = ""
      single_primitive = false

      case operator
      when AST::Add
        operator_string = "+"
      when AST::Subtract
        operator_string = "-"
      when AST::Multiply
        operator_string = "*"
      when AST::Divide
        operator_string = "/"
      when AST::Modulo
        operator_string = "%"
      when AST::Exponent
        operator_string = "**"
      when AST::Negate
        operator_string = "-"
        single_primitive = true
      when AST::And
        operator_string = "&&"
      when AST::Or
        operator_string = "||"
      when AST::Not
        operator_string = "!"
        single_primitive = true
      when AST::BitwiseAnd
        operator_string = "&"
      when AST::BitwiseOr
        operator_string = "|"
      when AST::BitwiseXor
        operator_string = "^"
      when AST::BitwiseNot
        operator_string = "~"
      when AST::BitwiseLeftShift
        operator_string = "<<"
      when AST::BitwiseRightShift
        operator_string = ">>"
      when AST::Equal
        operator_string = "=="
      when AST::NotEqual
        operator_string = "!="
      when AST::LessThan
        operator_string = "<"
      when AST::LessThanOrEqual
        operator_string = "<="
      when AST::GreaterThan
        operator_string = ">"
      when AST::GreaterThanOrEqual
        operator_string = ">="
      when AST::FloatToInteger
        operator_string = "int"
        single_primitive = true
      when AST::IntegerToFloat
        operator_string = "float"
        single_primitive = true
      else
        # raise "Invalid AST operator type."
      end

      # Handles the case where the operator only has one right primitive.
      if single_primitive
        "#{operator_string}(#{operator.right.traverse(self)})"
      else
        # Handles the case where the operator has both left and right primitives.
        "(#{operator.left.traverse(self)} #{operator_string} #{operator.right.traverse(self)})"
      end
    end

    def visit_statistical_function(statistical_function)
      case statistical_function
      when AST::Max
        "max(#{statistical_function.left.traverse(self)}, #{statistical_function.right.traverse(self)})"
      when AST::Min
        "min(#{statistical_function.left.traverse(self)}, #{statistical_function.right.traverse(self)})"
      when AST::Mean
        "mean(#{statistical_function.left.traverse(self)}, #{statistical_function.right.traverse(self)})"
      when AST::Sum
        "sum(#{statistical_function.left.traverse(self)}, #{statistical_function.right.traverse(self)})"
      else
        # not used
      end
    end
  end

  # End of Serializer class.

  # Start of Evaluator class.
  class Evaluator
    attr_reader :runtime

    def initialize(runtime)
      @runtime = runtime
    end

    # TODO: Implement figuring out block statements.
    def visit_block(block)
      last_statement = nil
      # traverses through each statement in the block.
      block.statements.each { |statement|
        if statement.nil?
          next
        end
        last_statement = statement.traverse(self)
      }
      # returns the last statement in the block.
      last_statement
    end

    def visit_assignment(assignment)
      if assignment.name.is_a?(AST::String) and assignment.value.is_a?(AST::Operator) or
        assignment.value.is_a?(AST::Primitive) or assignment.value.is_a?(AST::StatisticalFunction) or
        assignment.value.is_a?(AST::Rvalue) or assignment.value.is_a?(AST::Lvalue) or
        assignment.value.is_a?(AST::Variable)
        # assigns the variable as the key and the value as the value in the variables hash in the
        @runtime.variables[assignment.name.traverse(self)] = assignment.value.traverse(self)
      else
        raise "Invalid AST assignment"
      end
    end

    def visit_variable(variable)
      if variable.cell.is_a?(AST::CellAddress) and variable.name.is_a?(AST::String)
        # returns the value of the variable in the cell location cell object.
        @runtime.variables[variable.name.traverse(self)]
      else
        raise "Invalid AST variable"
      end
    end

    def visit_conditional(conditional)
      if conditional.condition.is_a?(AST::Operator) and conditional.value.is_a?(AST::Block)
        if conditional.condition.traverse(self)
          conditional.value.traverse(self)
        else
          if conditional.else_value.nil?
            return
          end
          conditional.else_value.traverse(self)
        end
      else
        raise "Invalid AST conditional"
      end
    end

    def visit_for_each_loop(for_each_loop)
      if for_each_loop.variable.is_a?(AST::String) and
        for_each_loop.lower_range.is_a?(AST::Lvalue) and
        for_each_loop.upper_range.is_a?(AST::Lvalue) and for_each_loop.block.is_a?(AST::Block)
        lower_range = for_each_loop.lower_range
        upper_range = for_each_loop.upper_range
        final_value = "error"
        # loops through the range of the for each loop.
        (lower_range.x_var.value..upper_range.x_var.value).each { |i|
          (lower_range.y_var.value..upper_range.y_var.value).each { |j|
            # gets the value of the cell in the grid at the current location.
            loop_variable = @runtime.grid.get_cell(CellAddress.new(AST::
                Integer.new(i, 0, 0), AST::
                Integer.new(j, 0, 0))).cell_value
            # assigns the loop variable to the variable in the variables hash.
            @runtime.variables[for_each_loop.variable.traverse(self)] = loop_variable
            # traverses through the block of code in the for each loop.
            block_val = for_each_loop.block.traverse(self)
            unless block_val.nil?
              final_value = block_val
            end
          }
        }
        final_value
      else
        raise "Invalid AST for each loop"
      end
    end

    def visit_primitive(primitive)
      case primitive
      when AST::Integer
        primitive.value.to_i
      when AST::Float
        primitive.value.to_f
      when AST::Boolean
        primitive.value
      when AST::String
        primitive.value
      else
        raise "Invalid AST primitive"
      end
    end

    # Evaluates all operators in the AST depending on what they are.
    def visit_operator(operator)

      # Type checks every operator to make sure they follow AST convention and raises an error if
      # they do not.
      begin
        case operator
        when AST::Add
          operator.left.traverse(self) + operator.right.traverse(self)
        when AST::Subtract
          operator.left.traverse(self) - operator.right.traverse(self)
        when AST::Multiply
          operator.left.traverse(self) * operator.right.traverse(self)
        when AST::Divide
          operator.left.traverse(self) / operator.right.traverse(self)
        when AST::Modulo
          operator.left.traverse(self) % operator.right.traverse(self)
        when AST::Exponent
          operator.left.traverse(self) ** operator.right.traverse(self)
        when AST::Negate
          -(operator.right.traverse(self))
        when AST::And
          operator.left.traverse(self) && operator.right.traverse(self)
        when AST::Or
          operator.left.traverse(self) || operator.right.traverse(self)
        when AST::Not
          !(operator.right.traverse(self))
        when AST::BitwiseAnd
          operator.left.traverse(self) & operator.right.traverse(self)
        when AST::BitwiseOr
          operator.left.traverse(self) | operator.right.traverse(self)
        when AST::BitwiseXor
          operator.left.traverse(self) ^ operator.right.traverse(self)
        when AST::BitwiseNot
          ~(operator.right.traverse(self))
        when AST::BitwiseLeftShift
          operator.left.traverse(self) << operator.right.traverse(self)
        when AST::BitwiseRightShift
          operator.left.traverse(self) >> operator.right.traverse(self)
        when AST::Equal
          operator.left.traverse(self) == operator.right.traverse(self)
        when AST::NotEqual
          operator.left.traverse(self) != operator.right.traverse(self)
        when AST::LessThan
          operator.left.traverse(self) < operator.right.traverse(self)
        when AST::LessThanOrEqual
          operator.left.traverse(self) <= operator.right.traverse(self)
        when AST::GreaterThan
          operator.left.traverse(self) > operator.right.traverse(self)
        when AST::GreaterThanOrEqual
          operator.left.traverse(self) >= operator.right.traverse(self)
        when AST::FloatToInteger
          (operator.right.traverse(self)).to_i
        when AST::IntegerToFloat
          (operator.right.traverse(self)).to_f
        else
          raise "Invalid AST operator"
        end
      rescue => e
        raise "Type error found in AST operator: \n\tOriginated from -> #{e}"
      end
    end

    # SUM/MEAN/MAX/MIN VALUES OF THE CELLS IN THAT RECTANGLE/SQUARE.
    # For lvalues x_var = column, y_var = row, column is from up to down, row is from left to right
    def visit_statistical_function(statistical_function)

      if statistical_function.is_a?(AST::StatisticalFunction) and not
      statistical_function.left.is_a?(AST::Lvalue) or not
      statistical_function.right.is_a?(AST::Lvalue)
        raise "Invalid left or right node within the AST statistical function"
      end

      # Each statistical function runs the same way, it loops through the cells in the grid and
      # finds the max, min, mean, or sum of the cells in the square formed by the two cells.
      case statistical_function
      when AST::Max
        max = 0
        # The outer loop is for the columns and the inner loop is for the rows.
        (statistical_function.left.x_var.value..statistical_function.right.x_var.value).each { |i|
          (statistical_function.left.y_var.value..statistical_function.right.y_var.value).each { |j|
            max = [max, self.runtime.grid.get_cell(CellAddress.new(AST::Integer.new(i, 0, 0),
                                                                   AST::Integer.new(j, 0, 0)))
                            .cell_value].max
          }
        }
        max
      when AST::Min
        min = 0
        (statistical_function.left.x_var.value..statistical_function.right.x_var.value).each { |i|
          (statistical_function.left.y_var.value..statistical_function.right.y_var.value).each { |j|
            min = [min, self.runtime.grid.get_cell(CellAddress.new(AST::Integer.new(i, 0, 0),
                                                                   AST::Integer.new(j, 0, 0)))
                            .cell_value].min
          }
        }
        min
      when AST::Mean
        sum = 0
        count = 0
        (statistical_function.left.x_var.value..statistical_function.right.x_var.value).each { |i|
          (statistical_function.left.y_var.value..statistical_function.right.y_var.value).each { |j|
            sum += self.runtime.grid.get_cell(CellAddress.new(AST::Integer.new(i, 0, 0),
                                                              AST::Integer.new(j, 0, 0))).cell_value
            count += 1
          }
        }
        sum / count
      when AST::Sum
        sum = 0
        (statistical_function.left.x_var.value..statistical_function.right.x_var.value).each { |i|
          (statistical_function.left.y_var.value..statistical_function.right.y_var.value).each { |j|
            sum += self.runtime.grid.get_cell(CellAddress.new(AST::Integer.new(i, 0, 0),
                                                              AST::Integer.new(j, 0, 0))).cell_value
          }
        }
        sum
      else
        raise "Invalid AST statistical function"
      end
    end

    def visit_rvalue(rvalue)
      lookup_cell = CellAddress.new(AST::Integer.new(rvalue.x_var.traverse(self), 0, 0),
                                    AST::Integer.new(rvalue.y_var.traverse(self), 0, 0))
      self.runtime.grid.get_cell(lookup_cell).cell_value
    end

    def visit_lvalue(lvalue)
      lookup_cell = CellAddress.new(AST::Integer.new(lvalue.x_var.traverse(self), 0, 0),
                                    AST::Integer.new(lvalue.y_var.traverse(self), 0, 0))
      self.runtime.grid.get_cell(lookup_cell).cell_value
    end
  end
end

# End of Evaluator class.
# End of Ast.rb.
