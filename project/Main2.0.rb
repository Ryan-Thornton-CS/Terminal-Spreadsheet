require 'curses'
require_relative 'Ast'
require_relative 'Interpreter'
require_relative 'Interface'

# Testing
# pre-fill the grid with some random values or not
puts ARGV[0]
grid = AST::Grid.new
runtime = AST::Runtime.new(grid)

# If fill is passed as an argument, fill the grid with random values
if ARGV[0] == "fill"
  random_ints = [AST::Integer.new(10, 0, 0),
                 AST::Integer.new(20, 0, 0),
                 AST::Integer.new(30, 0, 0),
                 AST::Integer.new(40, 0, 0),
                 AST::Integer.new(50, 0, 0),
                 AST::Integer.new(60, 0, 0)]
  random_strings = [AST::String.new("he", 0, 0),
                    AST::String.new("no", 0, 0),
                    AST::String.new("is", 0, 0),
                    AST::String.new("be", 0, 0),
                    AST::String.new("or", 0, 0),
                    AST::String.new("to", 0, 0)]
  random_floats = [AST::Float.new(1.1, 0, 0),
                   AST::Float.new(2.2, 0, 0),
                   AST::Float.new(3.3, 0, 0),
                   AST::Float.new(4.4, 0, 0),
                   AST::Float.new(5.5, 0, 0),
                   AST::Float.new(6.6, 0, 0)]
  random_bools = [AST::Boolean.new(true, 0, 0),
                  AST::Boolean.new(false, 0, 0),
                  AST::Boolean.new(true, 0, 0),
                  AST::Boolean.new(false, 0, 0),
                  AST::Boolean.new(true, 0, 0),
                  AST::Boolean.new(false, 0, 0)]

  # Creates a bunch of cell addresses, cells, values, and assigns them to the grid
  (0..5).each { |x|
    (0..5).each { |y|
      celladdr = AST::CellAddress.new(AST::Integer.new(x, 0, 0),
                                      AST::Integer.new(y, 0, 0))
      cell = AST::Cell.new(random_ints[rand(0..5)], runtime)
      runtime.grid.add_cell(celladdr, cell)
    }
  }
  # So to find say, (2,4) you start from the top and go down 0/1/2 and from the left to the
  # right 0/1/2/3/4.  X is really Y and Y is really X.  So (2,4) is mathematically equivalent to (4,2)
  # Creates a bunch of cell addresses, cells, values, and assigns them to the grid
  (6..10).each { |x|
    (0..5).each { |y|
      celladdr = AST::CellAddress.new(AST::Integer.new(x, 0, 0),
                                      AST::Integer.new(y, 0, 0))
      cell = AST::Cell.new(random_strings[rand(0..5)], runtime)
      runtime.grid.add_cell(celladdr, cell)
    }
  }

  # Creates a bunch of cell addresses, cells, values, and assigns them to the grid
  (6..10).each { |x|
    (6..10).each { |y|
      celladdr = AST::CellAddress.new(AST::Integer.new(x, 0, 0),
                                      AST::Integer.new(y, 0, 0))
      cell = AST::Cell.new(random_floats[rand(0..5)], runtime)
      runtime.grid.add_cell(celladdr, cell)
    }
  }

  # Creates a bunch of cell addresses, cells, values, and assigns them to the grid
  (0..5).each { |x|
    (6..10).each { |y|
      celladdr = AST::CellAddress.new(AST::Integer.new(x, 0, 0),
                                      AST::Integer.new(y, 0, 0))
      cell = AST::Cell.new(random_bools[rand(0..5)], runtime)
      runtime.grid.add_cell(celladdr, cell)
    }
  }

  # Populates some cells with formulas
  # (1 + 2)
  celladdr = AST::CellAddress.new(AST::Integer.new(0, 0, 0),
                                  AST::Integer.new(0, 0, 0))
  cell = AST::Cell.new(AST::Add.new(AST::Integer.new(1, 0, 0),
                                    AST::Integer.new(2, 0, 0), 0, 0), runtime)
  runtime.grid.add_cell(celladdr, cell)

  # (7 * 4 + 3) % 12
  mod_mul = AST::Multiply.new(AST::Integer.new(7, 0, 0), AST::Integer.new(4, 0, 0), 0, 0)
  mod_add = AST::Add.new(mod_mul, AST::Integer.new(3, 0, 0), 0, 0)
  j = AST::Modulo.new(mod_add, AST::Integer.new(12, 0, 0), 0, 0)
  celladdr = AST::CellAddress.new(AST::Integer.new(1, 0, 0),
                                  AST::Integer.new(0, 0, 0))
  cell = AST::Cell.new(j, runtime)
  runtime.grid.add_cell(celladdr, cell)
end

# Creates the interface
interface = Interface.new(runtime)
interface.main_loop