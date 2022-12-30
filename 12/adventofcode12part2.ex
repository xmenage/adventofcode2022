defmodule Main do
  def parseInput(inputFileName) do
    File.stream!(inputFileName)
    |> Stream.map(&String.trim(&1)) |> Enum.map(&(String.to_charlist(&1)))
  end

  def makeEmptyResultMatrix(width, height) do
    emptyRow = for _n <- 1..width, do:  {-1, false, false}
    for _n <- 1..height, do: emptyRow
  end

  # propagate expansion as long as there is no obstacle on the row. This is the heart of the algorithm
  def expandRow(steps, altitude, expandingDirection , inputRow, outputRow) do
    Enum.zip_reduce([inputRow,outputRow],{steps, altitude, false, []}, fn [inputaltitude, {currentsteps, alreadyprocessed, expandDirection}], acc ->
      {previousSteps, previousAltitude, stopExpansion, outputRow} = acc
      newoutputRow = cond do
        # if propagation has already been blocked, then just return current point value, first two elements set to 0 as we won't need this on remainder of enum
        stopExpansion -> {0,0, stopExpansion, [{currentsteps, alreadyprocessed, expandDirection} | outputRow]}
        # if current point has already been expanded, then stop propagation - actually not sure we need this
        # alreadyprocessed -> {0,0, true, [{currentsteps, alreadyprocessed, expandDirection} | outputRow]}
        # if difference of altitude is more than 1, then stop propagation and don't change points on remainder of the row
        abs(inputaltitude-previousAltitude) > 1 -> {0,0,true, [{currentsteps, alreadyprocessed, expandDirection} | outputRow]}
        # if current point has not been touched yet, then propagate steps from previous point, and set processed status to false to have it expanded later.
        # set its future expansion direction perpendicular to current
        currentsteps == -1 -> {previousSteps+1,inputaltitude,false, [{previousSteps+1, false, not expandingDirection} | outputRow]}
        # if current point has already been visited, but number of steps is higher than this new number of steps, then replace and reset expansion status and direction
        previousSteps+1 < currentsteps -> {previousSteps+1,inputaltitude,false, [{previousSteps+1, false, not expandingDirection} | outputRow]}
      end
      Enum.reverse(newoutputRow)
    end)
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

  def propagateForthAndBack(row) do
    for _n <- 1..2, reduce: row do
        rowAcc ->
          {_, rowOut} = rowAcc |> Enum.reduce({{-1, 0}, []}, fn {currentelevation, currentsteps}, {{previouselevation, previoussteps}, outputRow} ->
            cond do
              previouselevation == -1 -> {{currentelevation, currentsteps}, [{currentelevation, currentsteps}]} #first element in the row
              currentelevation > previouselevation + 1 -> {{currentelevation, currentsteps}, [{currentelevation, currentsteps} | outputRow]} #current point elevation is more than 1 above previous point, don't change current point
              previoussteps >= 0 && (currentsteps == -1 || previoussteps+1 < currentsteps) -> {{currentelevation, previoussteps+1}, [{currentelevation, previoussteps+1} | outputRow]} #if previous point has been reached (steps>0) and current point has not been reached or number of steps is higher, then propagate to current point
              true -> {{currentelevation, currentsteps}, [{currentelevation, currentsteps} | outputRow]} #else do nothing, go to next
            end
          end)
          rowOut
    end
  end

  # reuse from day 8
  def transpose(matrix) do
    Enum.zip_with(matrix, &(&1))
  end

  def flipHorizontal(matrix) do
    matrix |> Enum.map(&(Enum.reverse(&1)))
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
