

defmodule Monkey do
  defstruct stolenItems: [], operation: "+", testdivisor: 1, throwtoiftrue: "", throwtoiffalse: "", inspectcount: 0

end


defmodule Main do
  def parseInput(inputFileName) do
    parseResult = File.stream!(inputFileName)
    |> Stream.map(&String.trim(&1))
    |> Enum.reduce({"a", %{}}, fn commandLine, acc ->
      IO.puts("commandLine #{commandLine}")
      {currentMonkeyId, monkeyMap} = acc
      cond do
        a = Regex.named_captures(~r/Monkey (?<monkeyid>\d):/, commandLine) ->
          monkeyId = a["monkeyid"]
          newMonkey = %Monkey{}
          {monkeyId, Map.put(monkeyMap, monkeyId, newMonkey)}

        a = Regex.run(~r/Starting items: (.*)/, commandLine, [capture: :all_but_first]) ->
          itemsList = Regex.scan(~r/(\p{N}+)/, List.first(a), [capture: :all_but_first]) |> List.flatten |> Enum.map(&(String.to_integer(&1)))
          currentMonkey = monkeyMap[currentMonkeyId]
          {currentMonkeyId, %{monkeyMap | currentMonkeyId => Map.put(currentMonkey, :stolenItems, itemsList)}}

        a = Regex.run(~r/Operation: new = old ([\+|\*]) (old|\d+)/, commandLine, [capture: :all_but_first]) ->
          [opsign, opparam] = a
          currentMonkey = monkeyMap[currentMonkeyId]
          operation = case opsign do
            "+" -> &(&1 + String.to_integer(opparam))
            "*" -> cond do
              opparam == "old" -> &(&1*&1)
              true -> &(&1 * String.to_integer(opparam))
            end
          end
          IO.puts("Operation(14) #{operation.(14)}")
          {currentMonkeyId, %{monkeyMap | currentMonkeyId => %{currentMonkey | :operation => operation}}}

        a = Regex.run(~r/Test: divisible by (\d+)/, commandLine, [capture: :all_but_first]) ->
          [testdivisor] = a
          currentMonkey = monkeyMap[currentMonkeyId]
          {currentMonkeyId, %{monkeyMap | currentMonkeyId => %{currentMonkey | :testdivisor => String.to_integer(testdivisor)}}}

        a = Regex.run(~r/If true: throw to monkey (\d+)/, commandLine, [capture: :all_but_first]) ->
          [throwtoiftrue] = a
          currentMonkey = monkeyMap[currentMonkeyId]
          {currentMonkeyId, %{monkeyMap | currentMonkeyId => %{currentMonkey | :throwtoiftrue => throwtoiftrue}}}

        a = Regex.run(~r/If false: throw to monkey (\d+)/, commandLine, [capture: :all_but_first]) ->
          [throwtoiffalse] = a
          currentMonkey = monkeyMap[currentMonkeyId]
          {currentMonkeyId, %{monkeyMap | currentMonkeyId => %{currentMonkey | :throwtoiffalse => throwtoiffalse}}}

        true -> acc
      end

    end)
    parseResult
  end

  def monkeyInspectAndThrow(currentMonkeyId, monkeyMap) do
    IO.puts("process monkey #{currentMonkeyId}")
    currentMonkey = monkeyMap[currentMonkeyId]
    currentMonkeyItems = currentMonkey.stolenItems
    {_, newMonkeyMap} = currentMonkeyItems |> Enum.reduce({currentMonkeyId, monkeyMap}, fn item, acc ->
      {currentMonkeyId, monkeyMap} = acc
      currentMonkey = monkeyMap[currentMonkeyId]
      %{:operation => operation, :testdivisor => testdivisor, :throwtoiftrue => throwtoiftrue, :throwtoiffalse => throwtoiffalse} = currentMonkey
      worryLevel = Integer.floor_div(operation.(item),3)
      throwToMonkeyID = if Integer.mod(worryLevel,testdivisor) == 0, do: throwtoiftrue, else: throwtoiffalse
      IO.puts("throw #{worryLevel} at monkey #{throwToMonkeyID}")
      throwToMonkey = monkeyMap[throwToMonkeyID]
      throwToMonkeyItems = throwToMonkey.stolenItems ++ [worryLevel]
      {currentMonkeyId, %{monkeyMap | throwToMonkeyID => (%{throwToMonkey | :stolenItems => throwToMonkeyItems})}}
    end)
    newcurrentMonkey = %{currentMonkey | :stolenItems => [], :inspectcount => currentMonkey.inspectcount + length(currentMonkeyItems)}
    newMonkeyMap = %{newMonkeyMap | currentMonkeyId => newcurrentMonkey}
    newMonkeyMap
  end
end

parseResult = Main.parseInput("input.txt")
IO.inspect(parseResult)
IO.puts("")
{_, monkeyMap} = parseResult
monkeyIdList = Map.keys(monkeyMap) |> Enum.sort
itemSwappingFinal = for n <- 1..20, reduce: monkeyMap do
  monkeyMap -> monkeyIdList |> Enum.reduce(monkeyMap, fn monkeyId, monkeyMap ->
  Main.monkeyInspectAndThrow(monkeyId, monkeyMap)
end)
end
IO.puts("resultat monkey business")
IO.inspect(itemSwappingFinal)
# then just find manually the two highest values from the output and multiply them with regular calculator.
