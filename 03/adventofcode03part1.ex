total = File.stream!("input.txt")
  |> Stream.map(&String.trim(&1))
  |> Enum.reduce(0, fn rucksack, acc ->
      {left, right} = String.split_at(rucksack, trunc(String.length(rucksack)/2))
      a = String.graphemes(left) |> Enum.reduce_while(0, fn x, _ ->
        if String.contains?(right,x), do: {:halt, x}, else: {:cont, 0}
      end)
      <<b::utf8>> = a
      c = if b > 96, do: b-96, else: b-38
      IO.puts("#{left} #{right} #{a} #{b} #{c}")
      acc + c
  end)
IO.puts("total #{total}")
