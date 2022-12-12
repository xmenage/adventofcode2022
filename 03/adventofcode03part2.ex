total = File.stream!("input.txt")
  |> Stream.map(&String.trim(&1))
  |> Stream.chunk_every(3)
  |> Enum.reduce(0, fn chunk, acc ->
      [c1, c2, c3] = chunk
      a = String.graphemes(c1) |> Enum.reduce_while(0, fn x, _ ->
        if String.contains?(c2,x) && String.contains?(c3,x), do: {:halt, x}, else: {:cont, 0}
      end)
      <<b::utf8>> = a
      c = if b > 96, do: b-96, else: b-38
      IO.puts("#{a} #{b} #{c}")
      acc + c
  end)
IO.puts("total #{total}")
