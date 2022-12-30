defmodule Main do
  def parseInput(inputFileName) do
    File.stream!(inputFileName)
    |> Stream.map(&String.trim(&1)) |> Enum.map(&(String.to_charlist(&1)))
  end

  def createResultMatrix(inputMatrix) do
    inputMatrix |> Enum.map(fn row ->
      row |> Enum.map(fn elevation ->
        cond do
          elevation >= ?a && elevation <= ?z -> {elevation, -1}
          elevation == ?S -> {?a, 0}
          elevation == ?E -> {?z, -1}
        end
      end)
    end)
  end

  # This is the main part of the algorithm : scan a row both ways and propagate number of steps when possible,
  # increment number of steps at each step.
  def propagateForthAndBack(row) do
    for _n <- 1..2, reduce: row do
        rowAcc ->
          {_, rowOut} = rowAcc |> Enum.reduce({{-1, 0}, []}, fn {currentelevation, currentsteps}, {{previouselevation, previoussteps}, outputRow} ->
            cond do
              #first element in the row (accumulator is initiated with negative -1 elevation)
              previouselevation == -1 -> {{currentelevation, currentsteps}, [{currentelevation, currentsteps}]}
              #if current point elevation is more than 1 above previous point, don't change current point
              currentelevation > previouselevation + 1 -> {{currentelevation, currentsteps}, [{currentelevation, currentsteps} | outputRow]}
              #if previous point has been reached (steps>0) and current point has not been reached or number of steps is higher, then propagate to current point
              previoussteps >= 0 && (currentsteps == -1 || previoussteps+1 < currentsteps) -> {{currentelevation, previoussteps+1}, [{currentelevation, previoussteps+1} | outputRow]}
              #otherwise don't change current point
              true -> {{currentelevation, currentsteps}, [{currentelevation, currentsteps} | outputRow]} #else do nothing, go to next
            end
          end)
          rowOut
    end
  end

  def transpose(matrix) do
    Enum.zip_with(matrix, &(&1))
  end

end

inputFileName = "input.txt"
inputMatrix = Main.parseInput(inputFileName)
IO.inspect(inputMatrix)

height = length(inputMatrix)
width = inputMatrix |> List.first |> length()
IO.puts("width= #{width}, height= #{height}")

resultMatrix = Main.createResultMatrix(inputMatrix)

# 1..50 range is just a guess, it just needs to be enough to find the path to point E.
result = for _n <- 1..50, reduce: resultMatrix do
  tempMatrix ->
    rowScan = tempMatrix |> Enum.map(fn row ->
    Main.propagateForthAndBack(row)
    end)

    columnScan = rowScan |> Main.transpose |> Enum.map(fn row ->
      Main.propagateForthAndBack(row)
    end) |> Main.transpose

    columnScan
  end

# draw matrix showing points that have been reached
stepsMatrix = result |> Enum.map(fn row ->
  row |> Enum.map(fn {_, steps} -> if steps >= 0, do: '*', else: '.' end) |> IO.inspect([limit: :infinity, charlists: :as_charlists])
end)
# IO.inspect(stepsMatrix, [label: "stepsMatrix", limit: :infinity, charlists: :as_charlists])

# find End point from input matrix and extract number of steps from output matrix
indexEndPoint = inputMatrix |> List.flatten |> Enum.find_index(&(&1 == ?E))
{_, stepsToEndPoint} = result |> List.flatten() |> Enum.at(indexEndPoint)
IO.puts("index end point : #{indexEndPoint}, stepsToEndPoint= #{stepsToEndPoint}")
