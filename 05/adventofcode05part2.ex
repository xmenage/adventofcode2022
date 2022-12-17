# part2 : very simple, just removed the Enum.reverse in line 30

inputFileName = "input.txt"
stackLines = File.stream!(inputFileName)
|> Enum.reduce_while([],fn x, acc ->
  if Regex.match?(~r/^$/,x), do: {:halt, acc}, else: {:cont, [x] ++ acc}
end)
|> Enum.drop(1)

IO.puts(stackLines)

stackHeight = length(stackLines)

emptyStacks = [[],[],[], [],[],[], [],[],[]]
initialStacks = stackLines |> Enum.reduce(emptyStacks,fn line, stacks ->
  line |> String.graphemes() |> Enum.drop(1) |> Enum.take_every(4)
  |> Enum.zip_reduce(stacks,[],fn newCrate,currentStack, newStacks ->
    newStacks ++ (if newCrate != " " , do: [[newCrate] ++ currentStack], else: [currentStack]) end)
end)

IO.inspect(initialStacks)

stacksOfCrates = File.stream!(inputFileName)
|> Stream.drop(stackHeight + 2)
|> Stream.map(fn commandLine -> Regex.named_captures(~r/^move (?<move>\d+) from (?<from>\d) to (?<to>\d)$/, commandLine) end)
|> Enum.reduce(initialStacks,fn command, lastStacks ->
  move = String.to_integer(command["move"])
  from = String.to_integer(command["from"])-1
  to = String.to_integer(command["to"])-1
  fromStack = Enum.at(lastStacks,from) |> Enum.take(move) |> IO.inspect
  List.update_at(lastStacks,from,&Enum.drop(&1,move)) |>  List.update_at(to, &(fromStack ++ &1)) |> IO.inspect
end)

IO.inspect(["final stack ",stacksOfCrates])

topCrates = stacksOfCrates |> Enum.map(&(List.first(&1," ")))

IO.inspect(["top crates ",topCrates])
