inputFileName = "input.txt"
signal = File.stream!(inputFileName)
|> Enum.map(
  fn line ->
    sigPos = String.to_charlist("AAAAAAAAAAAAA" <> line)
    |> Enum.chunk_every(14,1)
    |> Enum.reduce_while({0,13},
      fn chunk, acc ->
        {counter, lastmatchpos} = acc
        first3 = List.to_string(Enum.take(chunk,13))
        last1 = List.to_string(Enum.take(chunk,-1))
        {_, r} = Regex.compile(last1)
        ismatch = Regex.scan(r,first3, return: :index)
        cond do
          not Enum.empty?(ismatch) ->
            newmatchpos = max(lastmatchpos-1, (ismatch |> List.last |> List.first |> elem(0)))
            {:cont , {counter+1, newmatchpos}}
          lastmatchpos > 0 ->
            {:cont, {counter+1, lastmatchpos-1}}
          true ->
            {:halt, counter+1} |> IO.inspect
        end
      end)
    sigPos
  end)

IO.puts(signal)
