defmodule Main do
  def parse_input(input_file_Name) do
    File.stream!(input_file_Name)
    |> Stream.map(&String.trim(&1))
    |> Enum.map(fn input_line ->
      Regex.split(~r/ -> /, input_line)
      |> Enum.map(fn input_point_string ->
        [x_string, y_string] = Regex.split(~r/,/, input_point_string)
        {String.to_integer(x_string), String.to_integer(y_string)}
      end)
    end)
  end

  def complete_path_straight_lines(path_definition) do
    path_definition |> Enum.reduce([],fn point, acc ->
      if length(acc) == 0 do
        [point]
      else
        {x1, y1} = point
        [{x2,y2} | tail] = acc
        if x1 != x2 do
          Enum.map(x1..x2,&({&1,y1})) ++ tail
        else
          Enum.map(y1..y2,&({x1,&1})) ++ tail
        end
      end
    end)
  end

  def transpose(matrix) do
    Enum.zip_with(matrix, &(&1))
  end

  def drop_sand(rock_grouped_by_rows, point) do
    {x,y} = point
    p1 = rock_grouped_by_rows[y+1][x]
    p2 = rock_grouped_by_rows[y+1][x-1]
    p3 = rock_grouped_by_rows[y+1][x+1]
    cond do
      p1 == :air -> drop_sand(rock_grouped_by_rows, {x,y+1})
      p2 == :air -> drop_sand(rock_grouped_by_rows, {x-1,y+1})
      p3 == :air -> drop_sand(rock_grouped_by_rows, {x+1,y+1})
      true -> point
    end
  end

  def update_matrix(current_matrix, point) do
    {x,y} = point
    {_, updated_matrix} = current_matrix |> Map.get_and_update(y, fn row ->
        {_ , updated_row} = row |> Map.get_and_update(x, fn current_val -> {current_val, :sand} end)
        {row, updated_row}
      end )
    updated_matrix
  end

  def display_matrix(matrix, symbols) when is_map(matrix) do
    matrix |> Enum.sort(fn {x1,_},{x2,_} -> x1 <= x2 end) |> Enum.each(fn {_,row} ->
      row |> Enum.sort(fn {x1,_},{x2,_} -> x1 <= x2 end) |> Enum.map(fn {_,value} -> symbols[value] end) |> IO.inspect([limit: :infinity, charlists: :as_charlists])
    end)
  end

end


input_file_Name = "input.txt"
path_definition_list = Main.parse_input(input_file_Name)
rock_unit_list = path_definition_list
  |> Enum.map(&(Main.complete_path_straight_lines(&1)))
  |> List.flatten
  # |> Enum.sort(fn {_,y1}, {_,y2} -> y1 <= y2 end)

{xmin,ymin} = rock_unit_list |> Enum.reduce(fn {x, y}, {xmin, ymin} ->
  {(if x < xmin, do: x, else: xmin), (if y < ymin, do: y, else: ymin)}
end)

{xmax,ymax} = rock_unit_list |> Enum.reduce(fn {x, y}, {xmax, ymax} ->
  {(if x > xmax, do: x, else: xmax), (if y > ymax, do: y, else: ymax)}
end)


{xmin,ymin} |> IO.inspect(label: "upper left rock")
{xmax,ymax} |> IO.inspect(label: "lower right rock")


air_row = (xmin-1)..(xmax+1) |> Map.new(&({&1,:air}))
rock_row = (xmin-1)..(xmax+1) |> Map.new(&({&1,:rock}))
empty_matrix = 0..(ymax+1) |> Map.new(&({&1,air_row}))

rock_grouped_by_rows = rock_unit_list
  |> Enum.group_by(fn {_,y} -> y end, fn {x,_} -> x end)
  |> Enum.reduce(empty_matrix, fn {y, xlist}, current_matrix ->
    xlist_clean = xlist |> Enum.sort() |> Enum.dedup()
    rocks = rock_row |> Map.take(xlist_clean)
    {_, updated_matrix} = current_matrix |> Map.get_and_update(y,fn current_row -> {current_row, Map.merge(current_row, rocks)} end)
    updated_matrix
  end)

# range 1..1100 has been adjusted after finding the answer of 1068
# The loop displays sand count as soon as it starts overflowing.
# Then the answer is the sand count when it first overflows minus 1 => 1069 - 1 = 1068
sand_heap = for n <- 1..1100, reduce: rock_grouped_by_rows do
  rock_matrix ->
    {x,y} = Main.drop_sand(rock_matrix, {500,0})
    if y < ymax do
      Main.update_matrix(rock_matrix, {x,y})
    else
      IO.puts("sand overflow at count #{n}")
      rock_matrix
    end
end

draw_symbols = %{:air => '.', :rock => '#', :sand => 'o', :fall => '|'}
IO.puts("filled with sand")
Main.display_matrix(sand_heap,draw_symbols)
