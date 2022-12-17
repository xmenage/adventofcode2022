inputFileName = "input.txt"
signal = File.stream!(inputFileName)
|> Enum.map(
  fn line ->
    sigPos = String.to_charlist("AAA" <> line) |> IO.inspect
    |> Enum.chunk_every(4,1) |> IO.inspect
    |> Enum.reduce_while({0,3},
      fn chunk, acc ->
        {counter, lastmatchpos} = acc
        first3 = List.to_string(Enum.take(chunk,3))
        last1 = List.to_string(Enum.take(chunk,-1))
        {_, r} = Regex.compile(last1)
        ismatch = Regex.scan(r,first3, return: :index) |> IO.inspect
        cond do
          not Enum.empty?(ismatch) ->
            newmatchpos = max(lastmatchpos-1, (ismatch |> List.last |> List.first |> elem(0)))
            {:cont , {counter+1, newmatchpos}} |> IO.inspect
          lastmatchpos > 0 ->
            {:cont, {counter+1, lastmatchpos-1}} |> IO.inspect
          true ->
            IO.puts([first3, " ", last1])
            {:halt, counter+1} |> IO.inspect
        end
      end)
    sigPos
  end)

IO.puts(signal)
