


{trailset, _, _} = File.stream!("input.txt")
|> Stream.map(&String.trim(&1))
|> Enum.map(fn commandLine ->
  [command, steps] = String.split(commandLine)
  [command, String.to_integer(steps)]
end)
|> Enum.flat_map(fn [command,steps] ->
  move = case command do
    "U" -> {0, 1}
    "D" -> {0, -1}
    "R" -> {1, 0}
    "L" -> {-1, 0}
  end
  for _n <- 1..steps, do: move
end) |> IO.inspect()
|> Enum.reduce({MapSet.new(), {0,0}, {0,0}}, fn {xm, ym}, {trailSet, {xH,yH}, {xT,yT}} ->
  newxH = xH + xm
  newyH = yH + ym
  u = newxH-xT
  v = newyH-yT
  newT = cond do
    abs(u) == 2 ->
      {xT+round(u/2),yT+v}
    abs(v) == 2 ->
      {xT+u, yT+round(v/2)}
    true -> {xT,yT}
  end
  {MapSet.put(trailSet, newT), {newxH,newyH}, newT}
end)
IO.inspect(trailset)
IO.puts(MapSet.size(trailset))
