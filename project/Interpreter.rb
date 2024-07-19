require_relative 'Ast'
# Define a token abstraction. Model an individual token as its type, source text, and starting and
# ending indices in the source code. You'll need the text and indices to produce useful error
# messages like I found undeclared variable "slar" at index 7.
class Token
  attr_reader :type, :value, :start_index, :end_index

  def initialize(type, value, start, ending)
    @type = type
    @value = value
    @start_index = start
    @end_index = ending
  end
end

# Define a lexer that accepts an expression in text form and tokenizes it into a list of tokens.
class Lexer
  def initialize(source)
    @array_of_source = source
    # checks for if statements and for loops
    new_array = []
    checks_for_if(0, new_array, false, false)
    @array_of_source = new_array
    @source = nil
    @i = 0
    @tokens = []
    @token_so_far = ""

  end

  def has_letter
    @i < @source.length && "a" <= @source[@i] && @source[@i] <= "z"
  end

  def has_number
    @i < @source.length && "0" <= @source[@i] && @source[@i] <= "9"
  end

  def has(c)
    @i < @source.length && @source[@i] == c
  end

  def capture
    @token_so_far += @source[@i]
    @i += 1
  end

  def abandon
    @token_so_far = ""
    @i += 1
  end

  # I laughed at myself for this method, I ended up trying to use recursion and total failed the
  # whole setup of the function.  So now I gotta return in every if statement or it will duplicate
  # multiple lines at a time.... I was tired and left it as is.
  # Ohh, and this method just combines if statements and for loops into one index so I can parse
  # them correctly.
  def checks_for_if(i, new_array, cur_if, cur_for)
    # Base case
    if i == @array_of_source.length
      return
    end

    # Checks for an end statement
    if @array_of_source[i].downcase.include?("end")
      new_array[-1] += " " + @array_of_source[i].downcase
      checks_for_if(i + 1, new_array, cur_if, cur_for)
      return
    end

    # Currently concatenating the strings together for if statements
    if cur_if
      # Checks for an if statement within an if statement
      if @array_of_source[i].downcase.include?("if")
        new_array[-1] += " " + @array_of_source[i].downcase
        checks_for_if(i + 1, new_array, true, false)
        # Checks for an for loop within an if statement
      elsif @array_of_source[i].downcase.include?("for")
        new_array[-1] += " " + @array_of_source[i].downcase
        checks_for_if(i + 1, new_array, false, true)
      else
        new_array[-1] += " " + @array_of_source[i].downcase
        checks_for_if(i + 1, new_array, true, false)
      end
      return
    end

    # Currently concatenating the strings together for for loops
    if cur_for
      # Checks for an if statement within a for loop
      if @array_of_source[i].downcase.include?("if")
        new_array[-1] += " " + @array_of_source[i].downcase
        checks_for_if(i + 1, new_array, true, false)
        # Checks for an for loop within a for loop
      elsif @array_of_source[i].downcase.include?("for")
        new_array[-1] += " " + @array_of_source[i].downcase
        checks_for_if(i + 1, new_array, false, true)
      else
        new_array[-1] += " " + @array_of_source[i].downcase
        checks_for_if(i + 1, new_array, false, true)
      end
      return
    end

    # Checks for an if statement
    if @array_of_source[i].downcase.include?("if")
      new_array.push(@array_of_source[i].downcase)
      checks_for_if(i + 1, new_array, true, cur_for)
      return
    end

    # Checks for a for loop
    if @array_of_source[i].downcase.include?("for")
      new_array.push(@array_of_source[i].downcase)
      checks_for_if(i + 1, new_array, cur_if, true)
      return
    end

    # If it's not an if statement or a for loop
    new_array.push(@array_of_source[i].downcase)
    checks_for_if(i + 1, new_array, cur_if, cur_for)
  end

  def lex
    array_of_tokens = []
    @array_of_source.each { |i|
      @i = 0
      @tokens = []
      @token_so_far = ""
      @source = i
      # It's ugly below here...
      while @i < @source.length
        if has("(")
          capture
          emit_token(:left_parenthesis)
        elsif has(")")
          capture
          emit_token(:right_parenthesis)
        elsif has(",")
          capture
          emit_token(:comma)
        elsif has("!")
          capture
          if has("=")
            capture
            emit_token(:not_equal)
          else
            emit_token(:not)
          end
        elsif has("~")
          capture
          emit_token(:bitwise_not)
        elsif has("*")
          capture
          if has("*")
            capture
            emit_token(:exponent)
          else
            emit_token(:multiply)
          end
        elsif has("/")
          capture
          emit_token(:divide)
        elsif has("%")
          capture
          emit_token(:mod)
        elsif has("+")
          capture
          emit_token(:add)
        elsif has("-")
          capture
          emit_token(:subtract_or_negate)
        elsif has("<")
          capture
          if has("=")
            capture
            emit_token(:less_than_or_equal)
          elsif has("<")
            capture
            emit_token(:left_shift)
          else
            emit_token(:less_than)
          end
        elsif has(">")
          capture
          if has("=")
            capture
            emit_token(:greater_than_or_equal)
          elsif has(">")
            capture
            emit_token(:right_shift)
          else
            emit_token(:greater_than)
          end
        elsif has("^")
          capture
          emit_token(:bitwise_xor)
        elsif has("|")
          capture
          if has("|")
            capture
            emit_token(:or)
          else
            emit_token(:bitwise_or)
          end
        elsif has("&")
          capture
          if has("&")
            capture
            emit_token(:and)
          else
            emit_token(:bitwise_and)
          end
        elsif has("=")
          capture
          if has("=")
            capture
            emit_token(:equal)
          else
            emit_token(:assignment)
          end
        elsif has("#")
          capture
          emit_token(:hash)
        elsif has("[")
          capture
          emit_token(:left_bracket)
        elsif has("]")
          capture
          emit_token(:right_bracket)
        elsif has("$")
          capture
          emit_token(:variable)
        elsif has(".")
          capture
          if has(".")
            capture
            emit_token(:range)
          else
            emit_token(:dot)
          end
        elsif has_number
          while has_number
            capture
          end
          if has(".")
            capture
            while has_number
              capture
            end
            emit_token(:float)
          else
            emit_token(:integer)
          end
        elsif has_letter
          while has_letter
            capture
          end
          if @token_so_far == "int"
            emit_token(:float_to_integer)
          elsif @token_so_far == "float"
            emit_token(:integer_to_float)
          elsif @token_so_far == "max"
            emit_token(:max)
          elsif @token_so_far == "min"
            emit_token(:min)
          elsif @token_so_far == "mean"
            emit_token(:mean)
          elsif @token_so_far == "sum"
            emit_token(:sum)
          elsif @token_so_far == "false"
            emit_token(:false)
          elsif @token_so_far == "true"
            emit_token(:true)
          elsif @token_so_far == "if"
            emit_token(:if)
          elsif @token_so_far == "else"
            emit_token(:else)
          elsif @token_so_far == "end"
            emit_token(:end)
          elsif @token_so_far == "for"
            emit_token(:for)
          elsif @token_so_far == "in"
            emit_token(:in)
          elsif @token_so_far == "then"
            emit_token(:then)
          else
            emit_token(:string)
          end
        else
          abandon
        end
      end
      array_of_tokens.push(@tokens)
    }
    array_of_tokens
  end

  def emit_token(type)
    @tokens.push(Token.new(type, @token_so_far, @i - @token_so_far.length, @i - 1))
    @token_so_far = ""
  end
end

# Define a parser that accepts a list of tokens and assembles an abstract syntax tree using the
# model abstractions you wrote in milestone 1.
class Parser
  attr_accessor :celladdr, :block

  def initialize(tokens, celladdr)
    @array_of_tokens = tokens
    @celladdr = celladdr
    @tokens = @array_of_tokens[0]
    @i = 0
    @syntax_error = false
  end

  def has(type)
    @i < @tokens.size && @tokens[@i].type == type
  end

  def advance
    @syntax_error = false
    @i += 1
    @tokens[@i - 1]
  end

  def parse
    block = []
    @array_of_tokens.each { |i|
      if i.nil?
        next
      end
      @tokens = i
      @i = 0
      @syntax_error = false
      # very first call to transform the tokens into an AST tree
      needs_operator = false
      while @i < @tokens.size
        root = expression
        if root.class == AST::Rvalue || root.class == AST::Lvalue || root.class == AST::Integer ||
          root.class == AST::Float
          if needs_operator
            # Might need to take this out because it's not necessary and "3 4" is valid
            raise "Syntax error, no operator found."
          end
          needs_operator = true
        else
          needs_operator = false
        end
      end
      root
      # appends the root to the block
      block.append(root)
    }
    # Returns a block
    AST::Block.new(block, 0, 0)
  end

  def unit
    if has(:left_parenthesis)
      advance
      index_start = @tokens[@i].start_index
      within = expression
      unless has(:right_parenthesis)
        raise "Syntax error, no right parenthesis found, check after index #{index_start}."
      end
      advance
      within.start_index -= 1
      within.end_index += 1
      within
    elsif has(:subtract_or_negate)
      advance
      number = unit
      if number.is_a?(AST::Integer)
        AST::Integer.new(-number.value, @tokens[@i - 1].start_index, @tokens[@i - 1].end_index)
      elsif number.is_a?(AST::Float)
        AST::Float.new(-number.value, @tokens[@i - 1].start_index, @tokens[@i - 1].end_index)
      else
        AST::Negate.new(nil, number, @tokens[@i - 1].start_index, number.end_index)
      end
    elsif has(:integer)
      advance
      AST::Integer.new(@tokens[@i - 1].value.to_i, @tokens[@i - 1].start_index, @tokens[@i - 1]
                                                                                  .end_index)
    elsif has(:float)
      advance
      AST::Float.new(@tokens[@i - 1].value.to_f, @tokens[@i - 1].start_index, @tokens[@i - 1]
                                                                                .end_index)
    elsif has(:hash)
      advance
      unless has(:left_bracket)
        raise "Syntax error, no left bracket found at #{@tokens[@i].start_index}."
      end
      advance
      index_start = @tokens[@i].start_index
      within = expression
      unless has(:comma)
        raise "Syntax error, no comma found, check after index #{index_start}."
      end
      advance
      index_start = @tokens[@i].start_index
      within2 = expression
      unless has(:right_bracket)
        raise "Syntax error, no right bracket found, check after index #{index_start}."
      end
      advance
      AST::Rvalue.new(within, within2, within.start_index - 2, within2.end_index + 2)
    elsif has(:left_bracket)
      advance
      index_start = @tokens[@i].start_index
      within = unit
      unless has(:comma)
        raise "Syntax error, no comma found, check after index #{index_start}."
      end
      advance
      index_start = @tokens[@i].start_index
      within2 = unit
      unless has(:right_bracket)
        raise "Syntax error, no right bracket found, check after index #{index_start}."
      end
      advance
      AST::Lvalue.new(within, within2, within.start_index - 1, within2.end_index + 2)
    elsif has(:float_to_integer)
      advance
      unless has(:left_parenthesis)
        raise "Syntax error, no left parenthesis found at #{@tokens[@i].start_index}."
      end
      advance
      index_start = @tokens[@i].start_index
      within = expression
      unless has(:right_parenthesis)
        raise "Syntax error, no right parenthesis found, check after index #{index_start}."
      end
      advance
      AST::FloatToInteger.new(nil, within, within.start_index - 1, within.end_index + 1)
    elsif has(:integer_to_float)
      advance
      unless has(:left_parenthesis)
        raise "Syntax error, no left parenthesis found at #{@tokens[@i].start_index}."
      end
      advance
      index_start = @tokens[@i].start_index
      within = expression
      unless has(:right_parenthesis)
        raise "Syntax error, no right parenthesis found, check after index #{index_start}."
      end
      advance
      AST::IntegerToFloat.new(nil, within, within.start_index - 1, within.end_index + 1)
    elsif has(:max)
      advance
      unless has(:left_parenthesis)
        raise "Syntax error, no left parenthesis found at #{@tokens[@i].start_index}."
      end
      advance
      index_start = @tokens[@i].start_index
      within = unit
      unless has(:comma)
        raise "Syntax error, no comma found, check after index #{index_start}."
      end
      advance
      index_start = @tokens[@i].start_index
      within2 = unit
      unless has(:right_parenthesis)
        raise "Syntax error, no right parenthesis found, check after index #{index_start}."
      end
      advance
      AST::Max.new(within, within2, within.start_index - 4, within2.end_index + 2)
    elsif has(:min)
      advance
      unless has(:left_parenthesis)
        raise "Syntax error, no left parenthesis found at #{@tokens[@i].start_index}."
      end
      advance
      index_start = @tokens[@i].start_index
      within = unit
      unless has(:comma)
        raise "Syntax error, no comma found, check after index #{index_start}."
      end
      advance
      index_start = @tokens[@i].start_index
      within2 = unit
      unless has(:right_parenthesis)
        raise "Syntax error, no right parenthesis found, check after index #{index_start}."
      end
      advance
      AST::Min.new(within, within2, within.start_index - 4, within2.end_index + 2)
    elsif has(:mean)
      advance
      unless has(:left_parenthesis)
        raise "Syntax error, no left parenthesis found at #{@tokens[@i].start_index}."
      end
      advance
      index_start = @tokens[@i].start_index
      within = unit
      unless has(:comma)
        raise "Syntax error, no comma found, check after index #{index_start}."
      end
      advance
      index_start = @tokens[@i].start_index
      within2 = unit
      unless has(:right_parenthesis)
        raise "Syntax error, no right parenthesis found, check after index #{index_start}."
      end
      advance
      AST::Mean.new(within, within2, within.start_index - 4, within2.end_index + 2)
    elsif has(:sum)
      advance
      unless has(:left_parenthesis)
        raise "Syntax error, no left parenthesis found at #{@tokens[@i].start_index}."
      end
      advance
      index_start = @tokens[@i].start_index
      within = unit
      unless has(:comma)
        raise "Syntax error, no comma found, check after index #{index_start}."
      end
      advance
      index_start = @tokens[@i].start_index
      within2 = unit
      unless has(:right_parenthesis)
        raise "Syntax error, no right parenthesis found, check after index #{index_start}."
      end
      advance
      AST::Sum.new(within, within2, within.start_index - 4, within2.end_index + 2)
    elsif has(:false)
      advance
      AST::Boolean.new(false, @tokens[@i - 1].start_index, @tokens[@i - 1].end_index)
    elsif has(:true)
      advance
      AST::Boolean.new(true, @tokens[@i - 1].start_index, @tokens[@i - 1].end_index)
    elsif has(:if)
      advance
      unless has(:left_parenthesis)
        raise "Syntax error, no left parenthesis found at #{@tokens[@i].start_index}."
      end
      advance
      index_start = @tokens[@i].start_index
      condition = expression
      unless has(:right_parenthesis)
        raise "Syntax error, no right parenthesis found, check after index #{index_start}."
      end
      advance
      unless has(:then)
        raise "Syntax error, no \"then\" found at #{@tokens[@i].start_index}"
      end
      advance
      block = []
      until has(:else) or has(:end)
        block.append(expression)
      end
      then_block = AST::Block.new(block, block[0].start_index, block[-1].end_index)
      if has(:else)
        advance
        block = []
        until has(:end)
          block.append(expression)
        end
        else_block = AST::Block.new(block, block[0].start_index, block[-1].end_index)
        unless has(:end)
          raise "Syntax error, no \"end\" found at #{@tokens[@i].start_index}"
        end
        advance
        AST::Conditional.new(condition, then_block, else_block, condition.start_index - 2, else_block
                                                                                             .end_index)
      else
        unless has(:end)
          raise "Syntax error, no \"end\" found at #{@tokens[@i].start_index}"
        end
        advance
        AST::Conditional.new(condition, then_block, nil, condition.start_index - 2, then_block.end_index)
      end
    elsif has(:for)
      advance
      unless has(:left_parenthesis)
        raise "Syntax error, no left parenthesis found at #{@tokens[@i].start_index}"
      end
      advance
      index_start = @tokens[@i].start_index
      variable = unit
      unless has(:in)
        raise "Syntax error, no \"in\" found at #{@tokens[@i].start_index}"
      end
      advance
      lower_bound = unit
      unless has(:range)
        raise "Syntax error, no range found at #{@tokens[@i].start_index}"
      end
      advance
      upper_bound = unit
      unless has(:right_parenthesis)
        raise "Syntax error, no right parenthesis found, check after index #{index_start}"
      end
      advance
      block = []
      until has(:end)
        block.append(expression)
      end
      for_block = AST::Block.new(block, block[0].start_index, block[-1].end_index)
      unless has(:end)
        raise "Syntax error, no \"end\" found at #{@tokens[@i].start_index}"
      end
      advance
      AST::ForEachLoop.new(variable, lower_bound, upper_bound, for_block,
                           variable.start_index - 2, for_block.end_index)
    elsif has(:string)
      advance
      if has(:assignment)
        string = AST::String.new(@tokens[@i - 1].value, @tokens[@i - 1].start_index, @tokens[@i - 1]
                                                                                       .end_index)
        advance
        right = expression
        AST::Assignment.new(@celladdr, string, right, string.start_index, right.end_index)
      else
        AST::String.new(@tokens[@i - 1].value, @tokens[@i - 1].start_index, @tokens[@i - 1]
                                                                              .end_index)
      end
    elsif has(:variable)
      advance
      string = unit
      AST::Variable.new(@celladdr, string, string.start_index, string.end_index)
    else
      # Used to catch infinite recursion in the case of an invalid token
      if @syntax_error
        raise "Syntax error, from index #{@tokens[0].start_index} to index #{@tokens[-1]
                                                                               .end_index}" +
                " check brackets, commas, and parentheses."
      end
      @syntax_error = true
      expression
    end
  end

  def unary
    if has(:not)
      advance
      right = unit
      AST::Not.new(nil, right, right.start_index - 1, right.end_index)
    elsif has(:bitwise_not)
      advance
      right = unit
      AST::BitwiseNot.new(nil, right, right.start_index - 1, right.end_index)
    else
      unit
    end
  end

  def exp
    left = unary
    if has(:exponent)
      advance
      right = unary
      left = AST::Exponent.new(left, right, left.start_index, right.end_index)
    end
    left
  end

  def mult
    left = exp
    if has(:multiply)
      advance
      right = exp
      left = AST::Multiply.new(left, right, left.start_index, right.end_index)
    end
    left
  end

  def div
    left = mult
    if has(:divide)
      advance
      right = mult
      left = AST::Divide.new(left, right, left.start_index, right.end_index)
    end
    left
  end

  def mod
    left = div
    if has(:mod)
      advance
      right = div
      left = AST::Modulo.new(left, right, left.start_index, right.end_index)
    end
    left
  end

  def addsub
    left = mod
    if has(:add)
      advance
      right = mod
      left = AST::Add.new(left, right, left.start_index, right.end_index)
    elsif has(:subtract_or_negate)
      advance
      right = mod
      left = AST::Subtract.new(left, right, left.start_index, right.end_index)
    end
    left
  end

  def bitwise
    left = addsub
    if has(:bitwise_and)
      advance
      right = addsub
      left = AST::BitwiseAnd.new(left, right, left.start_index, right.end_index)
    elsif has(:bitwise_or)
      advance
      right = addsub
      left = AST::BitwiseOr.new(left, right, left.start_index, right.end_index)
    elsif has(:bitwise_xor)
      advance
      right = addsub
      left = AST::BitwiseXor.new(left, right, left.start_index, right.end_index)
    elsif has(:left_shift)
      advance
      right = addsub
      left = AST::BitwiseLeftShift.new(left, right, left.start_index, right.end_index)
    elsif has(:right_shift)
      advance
      right = addsub
      left = AST::BitwiseRightShift.new(left, right, left.start_index, right.end_index)
    end
    left
  end

  def relation
    left = bitwise
    if has(:less_than)
      advance
      right = bitwise
      left = AST::LessThan.new(left, right, left.start_index, right.end_index)
    elsif has(:greater_than)
      advance
      right = bitwise
      left = AST::GreaterThan.new(left, right, left.start_index, right.end_index)
    elsif has(:less_than_or_equal)
      advance
      right = bitwise
      left = AST::LessThanOrEqual.new(left, right, left.start_index, right.end_index)
    elsif has(:greater_than_or_equal)
      advance
      right = bitwise
      left = AST::GreaterThanOrEqual.new(left, right, left.start_index, right.end_index)
    elsif has(:equal)
      advance
      right = bitwise
      left = AST::Equal.new(left, right, left.start_index, right.end_index)
    elsif has(:not_equal)
      advance
      right = bitwise
      left = AST::NotEqual.new(left, right, left.start_index, right.end_index)
    end
    left
  end

  def logical
    left = relation
    if has(:and)
      advance
      right = relation
      left = AST::And.new(left, right, left.start_index, right.end_index)
    elsif has(:or)
      advance
      right = relation
      left = AST::Or.new(left, right, left.start_index, right.end_index)
    end
    left
  end

  def expression
    logical
  end

end

