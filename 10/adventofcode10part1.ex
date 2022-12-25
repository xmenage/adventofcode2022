inputFileName = "input.txt"
finalSignalStrength = File.stream!(inputFileName)
|> Stream.map(&String.trim(&1))
# accumulator contains cycle, X value and accumulated signal strength at the end of previous command line
|> Enum.reduce({0,1,0}, fn commandLine, {previousCycle,previousX,previousSignalStrength} ->
  {cycleIncrement, addValue} = cond do
    Regex.match?(~r/^noop$/, commandLine) -> {1, 0}
    a = Regex.named_captures(~r/^addx (?<value>.+)$/, commandLine) -> {2, String.to_integer(a["value"])}
  end
  endCycle = previousCycle + cycleIncrement
  endX = previousX + addValue
  previousCycleDivRemainder = Integer.mod(previousCycle, 40)
  endCycleDivRemainder = Integer.mod(endCycle, 40)
  addSignalStrength = if previousCycleDivRemainder < 20 && endCycleDivRemainder >= 20 do
    d = Integer.floor_div(endCycle,40)
    roundCycle = d*40+20
    IO.puts("#{roundCycle} #{roundCycle*previousX}")
    roundCycle*previousX
  else
    0
  end
  {endCycle, endX, previousSignalStrength+addSignalStrength}
end)

IO.inspect(finalSignalStrength)
