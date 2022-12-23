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
  # This one function returns a matrix of 0 and 1, 1 means that the tree is visible from the left
  # Then we will use transpose and reverse to check visibility from all other 3 directions : top, bottom and right
  def visibleFromLeft(matrix) do
    matrix
    |> Enum.map(fn xrow ->
      yrow = xrow |> Enum.reduce(%{:y => [], :xmax => -1}, fn xi, acc ->
        if xi > acc[:xmax] do
          %{:y => acc[:y] ++ [1], :xmax => xi}
        else
          %{acc | :y => acc[:y] ++ [0]}
        end
      end)
      yrow[:y]
    end)
  end

  def transpose(matrix) do
    Enum.zip_with(matrix, &(&1))
  end

  def flipHorizontal(matrix) do
    matrix |> Enum.map(&(Enum.reverse(&1)))
  end
end

left_to_right = matrix |> Matrix.visibleFromLeft |> List.flatten()
IO.puts("left_to_right")
#IO.inspect(left_to_right)

right_to_left = matrix |> Matrix.flipHorizontal |> Matrix.visibleFromLeft |> Matrix.flipHorizontal |> List.flatten()
IO.puts("right_to_left")
#IO.inspect(right_to_left)

top_to_bottom = matrix |> Matrix.transpose |> Matrix.visibleFromLeft |> Matrix.transpose |> List.flatten()
IO.puts("top_to_bottom")
#IO.inspect(top_to_bottom)

bottom_to_top = matrix |> Enum.reverse |> Matrix.transpose |> Matrix.visibleFromLeft |> Matrix.transpose |> Enum.reverse |> List.flatten()
IO.puts("bottom_to_top")
#IO.inspect(bottom_to_top)

all_directions = [left_to_right, right_to_left, top_to_bottom, bottom_to_top] |> Enum.zip_with( &(Enum.max(&1))) |> Enum.sum
IO.puts("all_directions")
IO.inspect(all_directions)
