max = File.stream!("input.txt")
|> Stream.map(&String.trim(&1))
|> Enum.reduce(%{max: 0, total: 0, listTotals: []},fn s, a ->
    IO.puts(s)
    if String.length(s)>0 do
      x = String.to_integer(s)
      %{a | total:  a.total + x}
    else
      if a[:total] > a[:max] do
        IO.puts("nouveau max #{a[:total]}")
        %{max: a.total, total: 0, listTotals: [a.total | a.listTotals]}
      else
        %{a | total: 0, listTotals: [a.total | a.listTotals]}
      end
    end
  end)
IO.puts("maximum = #{max.max}")
Enum.sort(max.listTotals) |> Enum.slice(-3..-1) |> Enum.sum() |> IO.inspect()
