defmodule Main do
  def parseInput(inputFileName) do
    File.stream!(inputFileName)
    |> Stream.map(&String.trim(&1))
    |> Stream.map(&(String.to_charlist(&1)))
    |> Enum.reduce([], fn inputLine, listofpackets ->
      if length(inputLine) > 0 do
        {parsed_list, _} = parse_elements(inputLine)
        [parsed_list | listofpackets]
      else
        listofpackets
      end
    end)
  end

  def parse_integer(input_line) do
    [c | line_tail] = input_line
    cond do
      c >= ?0 && c <= ?9 -> {next_digits, remainder_tail} = parse_integer(line_tail)
        {[c | next_digits],remainder_tail}
      c == ?, || c == ?] -> {[], input_line}
    end
  end

  def parse_elements(input_line) do
    [c | line_tail] = input_line

    cond do

      c >= ?0 && c <= ?9 ->
        {digit_list, remainder_tail} = parse_integer(input_line)
        integer_element = List.to_integer(digit_list)
        [c | remainder_tail] = remainder_tail
        cond do
          c == ?, ->
            {next_elements, remainder_tail} = parse_elements(remainder_tail)
            {[integer_element | next_elements], remainder_tail}

          c == ?] -> {[integer_element], remainder_tail}
        end

      c == ?] -> {[], line_tail}

      c == ?[ ->
        {list_element, remainder_tail} = parse_elements(line_tail)
        if length(remainder_tail)>0 do
          [c | remainder_tail] = remainder_tail
          cond do
            c == ?, ->
              {next_elements, remainder_tail} = parse_elements(remainder_tail)
              {[list_element | next_elements], remainder_tail}

            c == ?] -> {[list_element], remainder_tail}
          end
        else
          {list_element,[]}
        end
    end
  end

  def compare_lists(pair) do
    [left, right] = pair
    compare_lists(left,right)
  end

  def compare_lists(left, right) do
    IO.inspect([left, right], charlists: :as_lists)
    cond do

      is_integer(left) && is_integer(right) -> if left == right, do: :cont, else: left < right

      is_integer(left) && is_list(right) -> compare_lists([left], right)

      is_list(left) && is_integer(right) -> compare_lists(left, [right])

      length(left) == 0 && length(right) == 0 -> :cont

      length(left) == 0 -> true

      length(right) == 0 -> false

      true ->
        [left_first | left_tail] = left
        [right_first | right_tail] = right
        result = compare_lists(left_first,right_first)
        if  result == :cont, do: compare_lists(left_tail, right_tail), else: result
    end
  end

end


inputFileName = "input.txt"
listofpackets = Main.parseInput(inputFileName)
listofpackets = listofpackets ++ [[[2]], [[6]]]
listofpackets |> IO.inspect([label: "output parsed list", charlists: :as_lists])


sortedlistofpackets = listofpackets |> Enum.sort(&Main.compare_lists(&1,&2))
sortedlistofpackets |> IO.inspect([label: "sorted list of packets", charlists: :as_lists])

indexdivider1 = (sortedlistofpackets |> Enum.find_index(&(Main.compare_lists(&1,[[2]]) == :cont)))+1
indexdivider2 = (sortedlistofpackets |> Enum.find_index(&(Main.compare_lists(&1,[[6]]) == :cont)))+1
IO.puts("decoder key = #{indexdivider1*indexdivider2}")
