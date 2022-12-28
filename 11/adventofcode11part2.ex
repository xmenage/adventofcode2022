

defmodule Monkey do
  defstruct stolenItems: [], operation: "+", testdivisor: 1, throwtoiftrue: "", throwtoiffalse: "", inspectcount: 0

end


defmodule Main do
  def parseInput(inputFileName) do
    parseResult = File.stream!(inputFileName)
    |> Stream.map(&String.trim(&1))
    |> Enum.reduce({"a", %{}}, fn commandLine, acc ->
      # IO.puts("commandLine #{commandLine}")
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


  def monkeyInspectAndThrow(currentMonkeyId, monkeyMap, globaldivisor) do
    currentMonkey = monkeyMap[currentMonkeyId]
    currentMonkeyItems = currentMonkey.stolenItems
    {_, newMonkeyMap} = currentMonkeyItems |> Enum.reduce({currentMonkeyId, monkeyMap}, fn item, acc ->
      {currentMonkeyId, monkeyMap} = acc
      currentMonkey = monkeyMap[currentMonkeyId]
      %{:operation => operation, :testdivisor => testdivisor, :throwtoiftrue => throwtoiftrue, :throwtoiffalse => throwtoiffalse} = currentMonkey
      worryLevel = Integer.mod(operation.(item),globaldivisor)
      throwToMonkeyID = if Integer.mod(worryLevel,testdivisor) == 0, do: throwtoiftrue, else: throwtoiffalse
      throwToMonkey = monkeyMap[throwToMonkeyID]
      throwToMonkeyItems = [worryLevel | throwToMonkey.stolenItems]
      {currentMonkeyId, %{monkeyMap | throwToMonkeyID => (%{throwToMonkey | :stolenItems => throwToMonkeyItems})}}
    end)
    newcurrentMonkey = %{currentMonkey | :stolenItems => [], :inspectcount => currentMonkey.inspectcount + length(currentMonkeyItems)}
    newMonkeyMap = %{newMonkeyMap | currentMonkeyId => newcurrentMonkey}
    newMonkeyMap
  end

  # the 3 functions below are not needed, I just created them while searching for the solution.
  # just keeping them as it was a first experiment of the for, reduce:
  def createMonkeyAutomaton(monkeyMap) do
    monkeyMap |> Enum.reduce(%{}, fn {monkeyId, monkey}, acc ->
      %{:operation => operation, :testdivisor => testdivisor, :throwtoiftrue => throwtoiftrue, :throwtoiffalse => throwtoiffalse} = monkey
      inspectAndThrow = fn worryLevel ->
        newWorryLevel = operation.(worryLevel)
        throwToMonkeyID = if Integer.mod(worryLevel,testdivisor) == 0, do: throwtoiftrue, else: throwtoiffalse
        {throwToMonkeyID, newWorryLevel}
      end
      Map.put(acc, monkeyId, inspectAndThrow)
    end)
  end

  def itemswappingpath(startWorryLevel, startMonkeyId, monkeyMap) do
    initRemainderLog = monkeyMap |> Enum.reduce(%{}, fn {_, monkey}, acc ->
      Map.put(acc, monkey.testdivisor, [])
    end)
    for _n <- 1..400, reduce: {startWorryLevel, startMonkeyId, initRemainderLog} do
      acc ->
        {currentWorryLevel, currentMonkeyId, remainderLog} = acc
        currentMonkey = monkeyMap[currentMonkeyId]
        %{:operation => operation, :testdivisor => testdivisor, :throwtoiftrue => throwtoiftrue, :throwtoiffalse => throwtoiffalse} = currentMonkey
        nextWorryLevel = operation.(currentWorryLevel)
        divremainder = Integer.mod(nextWorryLevel,testdivisor)
        # IO.puts("monkeyId #{currentMonkeyId} mod #{testdivisor} = #{divremainder}")
        {nextMonkeyID, nextWorryLevel} = if divremainder == 0, do: {throwtoiftrue, nextWorryLevel}, else: {throwtoiffalse, nextWorryLevel}
        nextRemainderLog = %{remainderLog | testdivisor => remainderLog[testdivisor] ++ [divremainder]}
        {nextWorryLevel, nextMonkeyID, nextRemainderLog}

    end
  end

  def applyMonkeyAutomaton(startMonkeyId, startWorryLevel, monkeyAutomaton, repeatn) do
    initcountTracker = Map.keys(monkeyAutomaton) |> Enum.reduce(%{}, fn monkeyId, countTracker -> Map.put(countTracker, monkeyId, 0) end )
    for _n <- 1..repeatn, reduce: {{startMonkeyId, startWorryLevel}, initcountTracker} do
      acc ->
        {{currentMonkeyId, currentWorryLevel}, countTracker} = acc
        nextStep = monkeyAutomaton[currentMonkeyId].(currentWorryLevel)
        newcountTracker = %{countTracker | currentMonkeyId => countTracker[currentMonkeyId]+1}
        {nextStep, newcountTracker}

    end
  end

end

parseResult = Main.parseInput("input.txt")
# IO.inspect(parseResult)
# IO.puts("")
{_, monkeyMap} = parseResult
globaldivisor = monkeyMap |> Enum.reduce(1, fn {_,monkey}, acc ->
  acc * monkey.testdivisor
end)

monkeyIdList = Map.keys(monkeyMap) |> Enum.sort
itemSwappingFinal = for n <- 1..10000, reduce: monkeyMap do
  monkeyMap -> monkeyIdList |> Enum.reduce(monkeyMap, fn monkeyId, monkeyMap ->
  Main.monkeyInspectAndThrow(monkeyId, monkeyMap,globaldivisor)
end)
end

# {_, _, itemSwappingFinal} = Main.itemswappingpath(299,"1", monkeyMap)


IO.puts("resultat monkey business")
IO.inspect(itemSwappingFinal, [limit: :infinity, charlists: :as_lists] )
# read output and find the two highest values manually then use calculator to multiply.

# monkeyAutomaton = Main.createMonkeyAutomaton(monkeyMap)
# IO.inspect(monkeyAutomaton)

# itemRun = Main.applyMonkeyAutomaton("0", 79, monkeyAutomaton,1000)
# IO.inspect(itemRun)
