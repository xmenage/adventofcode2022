
# only nine knots in the tail, the head knot is managed separately
startTail = for _n <- 1..9, do: {0,0}

{trailset, _, _} =
File.stream!("input.txt")
|> Stream.map(&String.trim(&1))
|> Stream.map(fn commandLine ->
  [command, steps] = String.split(commandLine)
  [command, String.to_integer(steps)]
end)
# expand each command of n steps into n commands of 1 step
|> Stream.flat_map(fn [command,steps] ->
      move = case command do
        "U" -> {0, 1}
        "D" -> {0, -1}
        "R" -> {1, 0}
        "L" -> {-1, 0}
      end
      for _n <- 1..steps, do: move
    end)
# calculate tail movement for each command.
# I use a MapSet because it will automatically keep only one instance of each position from the last knot in the tail.
|> Enum.reduce({MapSet.new(), {0,0}, startTail}, fn {xm, ym}, {trailSet, {xH,yH}, tail} ->
    newxH = xH + xm
    newyH = yH + ym
    # in the reduce below the accummulator contains the previous knot that just moved and the new position of the tail
    # here we built the new tail position 1 knot at a time
    {_, newTail} = Enum.reduce(tail, {{newxH,newyH}, []}, fn {xT, yT}, {{xK, yK}, accTail} ->
      u = xK-xT
      v = yK-yT
      newT = cond do
        # This cond is new from first part, sometimes, the previous knot will move in diagonal so, both u and v are both 2 or -2
        abs(u) == 2 && abs(v) == 2 -> {xT+round(u/2), yT+round(v/2)}
        abs(u) == 2 -> {xT+round(u/2), yT+v}
        abs(v) == 2 -> {xT+u, yT+round(v/2)}
        true -> {xT, yT}
      end
      {newT, [newT | accTail]}
    end)
  # note that [newT | accTail] builds the tail newTail in reverse order, so we need to reverse it before we pass it to the next knot
  # also, the last knot of the tail is the first in the list newTail
  {MapSet.put(trailSet, List.first(newTail)), {newxH,newyH}, Enum.reverse(newTail)}
end)

IO.inspect("final trailset")
IO.inspect(trailset)
IO.puts(MapSet.size(trailset))
