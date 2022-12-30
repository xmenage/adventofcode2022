inputFileName = "input.txt"

matrix = File.stream!(inputFileName)
  |> Stream.map(&(String.trim(&1)))
  |> Enum.map(fn line ->
    String.to_charlist(line) |> Enum.map(&(List.to_integer([&1])))
  end)

IO.puts("matrix")
#IO.inspect(matrix)

height = length(matrix)
width = length(matrix |> List.first)

IO.puts("width=#{width}, height=#{height}")

defmodule Matrix do

  # calculate score for each tree in a single row, so only 1 dimension
  def visibleTrees(treeHeight, row) do
    row |> Enum.reduce_while(0, fn x, y ->
      if x < treeHeight do
        {:cont, y+1}
      else
        {:halt, y+1}
      end
    end)
  end

  # calculate score for each tree in the whole matrix.
  # Note that output matrix dimensions are smaller -2 than input; we don't keep score for border trees as it always 0
  def scoreByRow(matrix) do
    Enum.slice(matrix, 1..-2)
      |> Enum.map(fn row ->
          row |> Enum.with_index
          |> Enum.slice(1..-2)
          |> Enum.map(fn {xi, i} ->
            right = Enum.slice(row, i+1..-1)
            yright = visibleTrees(xi, right)
            left = Enum.slice(row, 0..i-1) |> Enum.reverse
            yleft = visibleTrees(xi, left)
            yleft*yright
          end)
      end)
  end

  
  def transpose(matrix) do
    Enum.zip_with(matrix, &(&1))
  end

  def flipHorizontal(matrix) do
    matrix |> Enum.map(&(Enum.reverse(&1)))
  end
end

left_to_right = matrix |> Matrix.scoreByRow |> List.flatten()
IO.puts("left_to_right")
#IO.inspect(left_to_right)

top_to_bottom = matrix |> Matrix.transpose |> Matrix.scoreByRow |> Matrix.transpose |> List.flatten()
IO.puts("top_to_bottom")
#IO.inspect(top_to_bottom)

all_directions = [left_to_right, top_to_bottom] |> Enum.zip_with(fn [s1, s2] -> s1 * s2 end) |> Enum.max
IO.puts("all_directions")
IO.inspect(all_directions)
