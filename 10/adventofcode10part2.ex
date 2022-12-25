inputFileName = "input.txt"
{_,_,pixelsCRTCharlist} = File.stream!(inputFileName)
|> Stream.map(&String.trim(&1))
# accumulator contains cycle, X value and accumulated output string at the end of previous command line
# ticks start at cycle 1, this means that first previousCycle has to be 0
# X starts at initial value 1 during first cycle.
|> Enum.reduce({0,1,[]}, fn commandLine, {previousCycle,previousX,pixelsCRT} ->
  {cycleIncrement, addValue} = cond do
    Regex.match?(~r/^noop$/, commandLine) -> {1, 0}
    a = Regex.named_captures(~r/^addx (?<value>.+)$/, commandLine) -> {2, String.to_integer(a["value"])}
  end
  endCycle = previousCycle + cycleIncrement
  endX = previousX + addValue
  newpixelsCRT = 1..cycleIncrement |> Enum.reduce(pixelsCRT,fn inc, pixelsacc ->
    currentPosition = Integer.mod(previousCycle+inc-1,40)
    if previousX-1 <= currentPosition && currentPosition <= previousX+1, do: ['#' | pixelsacc] , else: ['.' | pixelsacc]
  end)

  {endCycle, endX, newpixelsCRT}
end)


displayCRTlines = pixelsCRTCharlist |> Enum.reverse |> Enum.chunk_every(40) |> Enum.map(&(List.to_string(&1)))

IO.inspect(displayCRTlines)
