require 'curses'
require_relative 'Ast'
require_relative 'Interpreter'

# TLDR OF THIS CLASS: I HATE CURSES WITH A PASSION
class Interface
  attr_accessor :runtime, :max_x_val_screen, :max_y_val_screen
  $cell_width = 20
  $column_offset = 3
  $row_offset = 2
  $center_offset = 13

  def initialize(runtime)
    # Runtime stores the runtime of the program and the grid
    @runtime = runtime
    # Initializes the screen
    Curses.init_screen
    # Gets the width and height of the screen
    @width, @height = Curses.cols, Curses.lines
    # Creates the windows
    @left_panel = Curses::Window.new(@height, @width / 2, 0, 0)
    @right_top_panel = Curses::Window.new(@height / 2, @width / 2, 0, @width / 2)
    @right_bottom_panel = Curses::Window.new(@height / 2, @width / 2, @height / 2, @width / 2)
    # Makes the right panels non-interactable until needed
    @right_bottom_panel.nodelay = true
    @right_top_panel.nodelay = true
    # Turns on keypad mode
    @left_panel.keypad = true
    @right_top_panel.keypad = true
    # Sets current cell for the left panel
    @cur_cell_left = [0, 0]
    @cur_cell_top_right = [1, 1]
    @cur_cursor_left_panel = [$row_offset, $center_offset]
    # Gets the max x and y values of the grid that can fit in the window
    @max_x_val_screen = (@width / 2 - $column_offset) / $cell_width
    @max_y_val_screen = @height / 2 - 1
    # Used to keep track of the current grid range for the left panel
    @cur_grid_range_top_left = [0, 0]
    @cur_grid_range_bottom_right = [@max_x_val_screen - 1, @max_y_val_screen - 1]
    # Updates left panel
    update_left_panel
    # Updates the grid data
    update_grid_data
    # Updates the right panels
    update_right_panel
    # Refreshes the windows
    @left_panel.refresh
    @right_top_panel.refresh
    @right_bottom_panel.refresh
    # Sets curses to non echo mode because we start in the left panel
    Curses.noecho
    Curses.raw
  end

  # Main loop for left panel
  def main_loop
    active = true
    loop do
      # Update cursor position
      @left_panel.setpos(@cur_cursor_left_panel[0], @cur_cursor_left_panel[1])
      # Gets the input from the left
      left_input = @left_panel.getch
      # Ctrl-q keys, quits the program
      if left_input == 17
        Curses.close_screen
        break
      end
      # Handles the input from the left panel
      # The case statements arent very portable and I should probably use the curses constants, but
      # some of those constants are the wrong values.
      case left_input
        # Enter key - makes the right top panel editable and allows the user to change the value
        # of the cell
      when 13
        # Make left panel read-only
        @left_panel.nodelay = true
        # Make right top panel editable
        @right_top_panel.nodelay = false
        # Turns off left panels keypad mode
        @left_panel.keypad = false
        # Turns off Curses noecho and raw mode
        Curses.echo
        Curses.noraw
        # Current string in the right top panel
        celladdr = AST::CellAddress.new(AST::Integer.new(@cur_cell_left[0], 0, 0),
                                        AST::Integer.new(@cur_cell_left[1], 0, 0))
        cell = @runtime.grid.grid[celladdr]
        block = []
        # If the cell is not in the grid, the current string is empty
        if cell.nil?
          cur_string = ""
        else
          # If the cell is a primitive, the primitive value is the current string, else the formula
          # is the current string
          if cell.cell_root_node.is_a?(AST::Primitive)
            cur_string = cell.cell_string_representation
            block.append(cell.cell_string_representation)
          elsif cell.cell_root_node.is_a?(AST::Block)
            index = 1
            cell.cell_root_node.statements.each do |statement|
              if statement.nil?
                next
              end
              if index == 1
                cur_string = statement.traverse(AST::Serializer.new)
              end
              @right_top_panel.setpos(index, 1)
              @right_top_panel.addstr(statement.traverse(AST::Serializer.new))
              block.append(statement.traverse(AST::Serializer.new))
              index += 1
            end
          else
            cur_string = "=" + cell.cell_string_representation
            block.append(cell.cell_string_representation)
          end
        end
        # Sets the cursor position of the right top panel to the end of the current string
        # updates right panel's box
        create_box(@right_top_panel, @height / 2, @width / 2)
        # updates cur_cell_top_right
        if not cur_string.nil?
          @cur_cell_top_right[1] += cur_string.length
        else
          @cur_cell_top_right[1] = 1
          cur_string = ""
        end
        @right_top_panel.setpos(@cur_cell_top_right[0], @cur_cell_top_right[1])
        # Main loop for the right top panel
        loop do
          # Gets the input from the left and right panels
          right_top_input = @right_top_panel.getch
          # Handles the input from the right top panel
          case right_top_input
            # Any letter or number and any special characters
          when String
            # If the string is a letter or number, add it to the current string
            if right_top_input.match?(/[a-zA-Z0-9]/)
              # If the current string is less than the width of the window, add the character to
              # the current string
              if cur_string.length < @width / 2 - 1
                @cur_cell_top_right[1] += 1
                cur_string += right_top_input
                # If the block is empty, add the current string to the block
                if block[@cur_cell_top_right[0] - 1].nil?
                  block.append(cur_string)
                else
                  block[@cur_cell_top_right[0] - 1] = cur_string
                end
              end
              # If string is other than a letter or number
            else
              # updates the cursor position and cell position
              if cur_string.length < @width / 2 - 1
                @cur_cell_top_right[1] += 1
                cur_string += right_top_input
                # If the block is empty, add the current string to the block
                if block[@cur_cell_top_right[0] - 1].nil?
                  block[@cur_cell_top_right[0] - 1] = cur_string
                else
                  block[@cur_cell_top_right[0] - 1] = cur_string
                end
              end
            end
            # Ctrl-q keys, quits the program
          when 17
            Curses.close_screen
            active = false
            break
            # Tab key
          when 9
            # Updates current cell in the grid with the current string if it's valid
            begin
              # Takes off the equal sign if it's there and parses the string
              if cur_string[0] == "="
                cur_string = cur_string.slice!(1..-1)
                block[@cur_cell_top_right[0] - 1] = cur_string
              end
              # If the cell is not in the grid, create a new cell
              if @runtime.grid.grid[celladdr].nil?
                @runtime.grid.add_cell(celladdr, AST::Cell.new(Parser.new(Lexer.new(block).lex,
                                                                          celladdr).parse, @runtime))
              else
                # If the cell is in the grid, update the cell's formula
                @runtime.grid.get_cell(celladdr).cell_root_node = Parser.new(Lexer.new(block)
                                                                                  .lex, celladdr).parse
              end
              # Updates the right panel
              update_right_panel
              # If parser fails, display an error message
            rescue => error
              puts error
              @right_bottom_panel.clear
              create_box(@right_bottom_panel, @height / 2, @width / 2)
              @right_bottom_panel.setpos(1, 1)
              @right_bottom_panel.addstr("Error: #{error}")
              create_box(@right_bottom_panel, @height / 2, @width / 2)
              @right_bottom_panel.refresh
            end
            # Make left panel interactive again and set curse back into noecho mode and raw mode
            @left_panel.nodelay = false
            Curses.noecho
            Curses.raw
            # Make right top panel read-only
            @right_top_panel.nodelay = true
            # Resets the cursor position of the right top panel
            @cur_cell_top_right = [1, 1]
            # Refreshes the grid
            create_grid(@left_panel, @height, @width / 2, @cur_grid_range_top_left[0],
                        @cur_grid_range_top_left[1])
            # Lazy rescue because I had an error and I didn't know what caused it
            begin
              # Updates left panel
              update_left_panel
            rescue => error
              puts error
              @right_bottom_panel.clear
              create_box(@right_bottom_panel, @height / 2, @width / 2)
              @right_bottom_panel.setpos(1, 1)
              @right_bottom_panel.addstr("Error: #{error}")
              create_box(@right_bottom_panel, @height / 2, @width / 2)
              @right_bottom_panel.refresh
            end
            # Sets the cursor position of the left panel
            @left_panel.setpos(@cur_cursor_left_panel[0], @cur_cursor_left_panel[1])
            # sets left panel back to keypad mode
            @left_panel.keypad = true
            break
            # If Enter is hit in echo mode, it makes sure to not overwrite stuff
          when 10
            if @cur_cell_top_right[0] + 1 < @height / 2 - 1
              # Updates the right top panels cur cell position
              @cur_cell_top_right[0] += 1
              @cur_cell_top_right[1] = 1
              # If cursor hits the bottom wrap around to the top
            else
              # Updates the right top panels cur cell position
              @cur_cell_top_right[0] = 1
              # For some reason I have to update the grid BECAUSE IT DISAPPEARS IF USER SPAMS ENTER....
              # I hate curses!!!!
              update_left_panel
            end
            cur_string = ""
            block.append(cur_string)
            # refreshes grid data
            update_grid_data
            # refreshes right top panel
            create_box(@right_top_panel, @height / 2, @width / 2)
            # Backspace key
          when 8
            # updates the cursor position and cell position
            if cur_string.length > 0
              @cur_cell_top_right[1] -= 1
              @right_top_panel.setpos(@cur_cell_top_right[0], @cur_cell_top_right[1])
              cur_string = cur_string.chop
              block[@cur_cell_top_right[0] - 1] = cur_string
            end
          when nil
            # Does nothing because nodealy is set to true
          else
            # Clears and updates left panel because text written bleeds over for some reason.....
            # I hate Curses
            update_left_panel
            @left_panel.setpos(@cur_cursor_left_panel[0], @cur_cursor_left_panel[1])
          end
          # Updates all of the text in the right top panel
          @right_top_panel.clear
          create_box(@right_top_panel, @height / 2, @width / 2)
          row = 1
          block.each do |string|
            @right_top_panel.setpos(row, 1)
            @right_top_panel.addstr(string)
            row += 1
          end
          @right_top_panel.refresh
          @right_top_panel.setpos(@cur_cell_top_right[0], @cur_cell_top_right[1])
        end
        # Right arrow key
      when 60421
        # updates the cursor position and cell position
        if (@cur_cell_left[0] + 1) % @max_x_val_screen != 0
          @cur_cursor_left_panel[1] += $cell_width
          @cur_cell_left[0] += 1
          # If the cursor is at the end of the screen, update the grid with the next set of cells
        else
          @left_panel.clear
          # Updates grid with next set of cells
          create_grid(@left_panel, @height, @width / 2, @cur_cell_left[0] + 1,
                      @cur_grid_range_top_left[1])
          @cur_cursor_left_panel[1] = $center_offset
          @cur_cell_left[0] += 1
          # Updates the current grid range
          @cur_grid_range_top_left = [@cur_grid_range_top_left[0] + @max_x_val_screen,
                                      @cur_grid_range_top_left[1]]
          @cur_grid_range_bottom_right = [@cur_grid_range_bottom_right[0] + @max_x_val_screen,
                                          @cur_grid_range_bottom_right[1]]
          # Updates the grid data
          update_grid_data
        end
        # Updates the right panels
        update_right_panel
        # Updates the cursor for the left panel
        @left_panel.setpos(@cur_cursor_left_panel[0], @cur_cursor_left_panel[1])
        # Left arrow key
      when 60420
        # updates the cursor position and cell position
        if (@cur_cell_left[0] - 1) % @max_x_val_screen != @max_x_val_screen - 1 and
          @cur_cell_left[0] - 1 >= 0
          @cur_cursor_left_panel[1] -= $cell_width
          @cur_cell_left[0] - 1 >= 0 ? @cur_cell_left[0] -= 1 : @cur_cell_left[0]
          # If the cursor is at the beginning of the screen, update the grid with the previous set
          # of cells
        else
          # Stops from going into negative values
          if @cur_cell_left[0] - 1 > 0
            @left_panel.clear
            # Updates grid with the previous set of cells
            create_grid(@left_panel, @height, @width / 2, @cur_cell_left[0] - @max_x_val_screen,
                        @cur_grid_range_top_left[1])
            @cur_cursor_left_panel[1] = $center_offset + ($cell_width * (@max_x_val_screen - 1))
            @cur_cell_left[0] -= 1
            # Updates the current grid range
            @cur_grid_range_top_left = [@cur_grid_range_top_left[0] - @max_x_val_screen,
                                        @cur_grid_range_top_left[1]]
            @cur_grid_range_bottom_right = [@cur_grid_range_bottom_right[0] - @max_x_val_screen,
                                            @cur_grid_range_bottom_right[1]]
            # Updates the grid data
            update_grid_data
          end
        end
        # Updates the right panels
        update_right_panel
        # Updates the cursor for the left panel
        @left_panel.setpos(@cur_cursor_left_panel[0], @cur_cursor_left_panel[1])
        # Up arrow key
      when 60419
        # updates the cursor position and cell position
        if (@cur_cell_left[1] - 1) % @max_y_val_screen != @max_y_val_screen - 1 and
          @cur_cell_left[1] - 1 >= 0
          @cur_cursor_left_panel[0] -= $row_offset
          @cur_cell_left[1] - 1 >= 0 ? @cur_cell_left[1] -= 1 : @cur_cell_left[1]
        else
          if @cur_cell_left[1] - 1 > 0
            @left_panel.clear
            # Updates grid with the previous set of cells
            create_grid(@left_panel, @height, @width / 2, @cur_grid_range_top_left[0],
                        @cur_cell_left[1] - @max_y_val_screen)
            @cur_cursor_left_panel[0] = $row_offset + ($row_offset * (@max_y_val_screen - 1))
            @cur_cell_left[1] -= 1
            # Updates the current grid range
            @cur_grid_range_top_left = [@cur_grid_range_top_left[0],
                                        @cur_grid_range_top_left[1] - @max_y_val_screen]
            @cur_grid_range_bottom_right = [@cur_grid_range_bottom_right[0],
                                            @cur_grid_range_bottom_right[1] - @max_y_val_screen]
            # Updates the grid data
            update_grid_data
          end
        end
        # Updates the right panels
        update_right_panel
        # Updates the cursor for the left panel
        @left_panel.setpos(@cur_cursor_left_panel[0], @cur_cursor_left_panel[1])
        # Down arrow key
      when 60418
        # updates the cursor position and cell position
        if (@cur_cell_left[1] + 1) % @max_y_val_screen != 0
          @cur_cursor_left_panel[0] += $row_offset
          @cur_cell_left[1] += 1
        else
          @left_panel.clear
          # Updates grid with next set of cells
          create_grid(@left_panel, @height, @width / 2, @cur_grid_range_top_left[0],
                      @cur_cell_left[1] + 1)
          @cur_cursor_left_panel[0] = $row_offset
          @cur_cell_left[1] += 1
          # Updates the current grid range
          @cur_grid_range_top_left = [@cur_grid_range_top_left[0],
                                      @cur_grid_range_top_left[1] + @max_y_val_screen]
          @cur_grid_range_bottom_right = [@cur_grid_range_bottom_right[0],
                                          @cur_grid_range_bottom_right[1] + @max_y_val_screen]
          # Updates the grid data
          update_grid_data
        end
        # Updates the right panels
        update_right_panel
        # Updates the cursor for the left panel
        @left_panel.setpos(@cur_cursor_left_panel[0], @cur_cursor_left_panel[1])
      else
        # Does nothing if the input is not recognized
      end
      @left_panel.refresh
      @right_top_panel.refresh
      @right_bottom_panel.refresh
      break unless active
    end
  end

  # Creates a grid in the window, after this method, I can safely say, I HATE CURSES WITH A PASSION
  # or I NEED TO BE TAUGHT HOW TO USE CURSES
  def create_grid(window, rows, columns, start_x = 0, start_y = 0)
    # The maximum amount of cells that can fit vertically in the window
    max_cells_v = 0
    # The maximum amount of cells that can fit horizontally in the window
    max_cells_h = (columns - $column_offset) / $cell_width
    # draw the horizontal lines
    ($column_offset...columns).each do |column|
      # My complicated way of drawing the x's on the top of the grid
      if column - $column_offset != 0 and (column - $column_offset) % 10 == 0 and
        (column - $column_offset) % $cell_width != 0 and
        max_cells_h > (column - $column_offset) / $cell_width
        window.setpos(0, column)
        window.addstr("#{column / $cell_width + start_x}")
      end
      (1...rows).each do |row|
        # Draws the horizontal lines across the window starting at an offset of 1 column and
        # skipping every other row
        if max_cells_h > (column - $column_offset) / $cell_width and row % $row_offset != 0
          window.setpos(row, column)
          window.addstr("\u2500")
          # Updates the max vertical cells that can fit in the window
          max_cells_v = row
        end
      end
    end
    # draw the vertical lines
    (1...rows - 1).each do |row|
      if row % $row_offset == 0
        ($column_offset...columns).each do |column|
          # Draws the vertical lines every 20 cells starting at an offset of the third column
          # and ending at the last column that can fit 20 cells.  Only draws the vertical lines
          # on the even rows
          if (column - $column_offset) % $cell_width == 0 and max_cells_h >= column / $cell_width
            window.setpos(row, column)
            window.addstr("\u2502")
          end
        end
      else
        ($column_offset...columns).each do |column|
          # Draws the vertical lines every 20 cells starting at an offset of the third column
          # and ending at the last column that can fit 20 cells.  Only draws the vertical lines
          # on the even rows
          if (column - $column_offset) % $cell_width == 0 and max_cells_h >= column / $cell_width
            # If top row draw 252C ┬
            if row == 1
              window.setpos(row, column)
              window.addstr("\u252C")
            else
              # If not top row draw 253C ┼
              window.setpos(row, column)
              window.addstr("\u253C")
            end
          end
        end
      end
      # If bottom row draw 2534 ┴
      if row == max_cells_v or row + 1 == max_cells_v
        ($column_offset...columns).each do |column|
          if (column - $column_offset) % $cell_width == 0 and max_cells_h >= column / $cell_width
            window.setpos(max_cells_v, column)
            window.addstr("\u2534")
          end
        end
      end
      # Adds y values to the left of the grid
      if row % $row_offset == 0
        window.setpos(row, 0)
        window.addstr("#{row / 2 - 1 + start_y}")
      end
      # Draws the borders of the cells at the start of the row
      window.setpos(row, $column_offset)
      window.addstr("\u2502")
      # Draws the borders of the cells at the end of the row
      if max_cells_h * $cell_width + $column_offset < columns
        window.setpos(row, max_cells_h * $cell_width + $column_offset)
        window.addstr("\u2502")
      else
        window.setpos(row, max_cells_h * $cell_width)
        window.addstr("\u2502")
      end
    end
    # Draw the corners
    if max_cells_h * $cell_width + $column_offset < columns
      draw_corners(window, max_cells_v + 1, max_cells_h * $cell_width + 4, true)
    else
      draw_corners(window, max_cells_v + 1, max_cells_h * $cell_width + 1, true)
    end
  end

  # Creates a box around the window
  def create_box(window, rows, columns)
    # draw the horizontal lines
    (0...columns).each do |column|
      window.setpos(0, column)
      window.addstr("\u2500")
      window.setpos(rows - 1, column)
      window.addstr("\u2500")
    end
    # draw the vertical lines
    (0...rows).each do |row|
      window.setpos(row, 0)
      window.addstr("\u2502")
      window.setpos(row, columns - 1)
      window.addstr("\u2502")
    end
    # Draw the corners
    draw_corners(window, rows, columns)
  end

  def draw_corners(window, rows, columns, grid = false)
    # Draw the corners
    # top left
    grid ? window.setpos(1, $column_offset) : window.setpos(0, 0)
    window.addstr("\u250C")
    # top right
    grid ? window.setpos(rows - 1, $column_offset) : window.setpos(rows - 1, 0)
    window.addstr("\u2514")
    # bottom left
    grid ? window.setpos(1, columns - 1) : window.setpos(0, columns - 1)
    window.addstr("\u2510")
    # bottom right
    window.setpos(rows - 1, columns - 1)
    window.addstr("\u2518")
  end

  def update_grid_data
    # loops the 2d array of the current grid range
    (@cur_grid_range_top_left[0]..@cur_grid_range_bottom_right[0]).each do |x|
      (@cur_grid_range_top_left[1]..@cur_grid_range_bottom_right[1]).each do |y|
        # Used to look up the cell in the grid
        celladdr = AST::CellAddress.new(AST::Integer.new(x, 0, 0),
                                        AST::Integer.new(y, 0, 0))
        # If the cell is not in grid, skip it
        if @runtime.grid.grid[celladdr].nil?
          next
        end
        # Gets the cell from the grid
        cell = @runtime.grid.grid[celladdr]
        # Sets the position of the cell in the left panel.  I use the x value of $column_offset + 1
        # because I want as much space as possible for the cell value
        @left_panel.setpos($row_offset + ((y % @max_y_val_screen) * $row_offset),
                           $column_offset + 1 + ((x % @max_x_val_screen) * $cell_width))
        # Adds the value of the cell to the left panel
        @left_panel.addstr(cell.cell_value.to_s)
      end
    end
  end

  # Updates both top right and bottom right panels.  The bottom right panel is read only and shows
  # the cell's primitive value or an error message. The top right panel is editable and shows the
  # cell's formula.
  def update_right_panel
    # Clears the top right panel
    @right_top_panel.clear
    # Clears the bottom right panel
    @right_bottom_panel.clear
    # Sets the position of the cursor in the top right panel
    @right_top_panel.setpos(1, 1)
    # Updates the top right panel with the current cell's formula
    celladdr = AST::CellAddress.new(AST::Integer.new(@cur_cell_left[0], 0, 0),
                                    AST::Integer.new(@cur_cell_left[1], 0, 0))
    # If the cell is not in the grid, display an error message
    if @runtime.grid.grid[celladdr].nil?
      # Sets the position of the cursor in the bottom right panel
      @right_bottom_panel.setpos(1, 1)
      # Updates the bottom right panel with an error message
      @right_bottom_panel.addstr("Cell is empty")
    else
      cell = @runtime.grid.grid[celladdr]
      # Updates the top right panel with the current cell's formula
      # If the cell is a primitive, display the primitive value and if the cell is a formula,
      # display the formula with an equal sign in front of it
      if cell.cell_root_node.is_a?(AST::Primitive)
        @right_top_panel.addstr(cell.cell_string_representation)
      elsif cell.cell_root_node.is_a?(AST::Block)
        index = 1
        cell.cell_root_node.statements.each do |statement|
          if statement.nil?
            next
          end
          @right_top_panel.setpos(index, 1)
          @right_top_panel.addstr(statement.traverse(AST::Serializer.new))
          index += 1
        end
      else
        @right_top_panel.addstr("=" + cell.cell_string_representation)
      end
      # Sets the position of the cursor in the bottom right panel
      @right_bottom_panel.setpos(1, 1)
      # Updates the bottom right panel with the current cell's primitive value
      @right_bottom_panel.addstr(cell.cell_value.to_s)
    end
    # Creates a box around the top right panel
    create_box(@right_top_panel, @height / 2, @width / 2)
    # Creates a box around the bottom right panel
    create_box(@right_bottom_panel, @height / 2, @width / 2)
    # Refreshes the top right panel
    @right_top_panel.refresh
    # Refreshes the bottom right panel
    @right_bottom_panel.refresh
  end

  def update_left_panel
    @left_panel.clear
    create_grid(@left_panel, @height, @width / 2, @cur_grid_range_top_left[0],
                @cur_grid_range_top_left[1])
    update_grid_data
    @left_panel.refresh
  end
end
