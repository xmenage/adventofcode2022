total = File.stream!("04/input.txt")
  |> Stream.map(&String.trim(&1))
  |> Enum.reduce(0, fn line, acc ->
      [[xs1],[ys1],[xs2],[ys2]]=Regex.scan(~r/[[:digit:]]+/,line)
      x1 = String.to_integer(xs1)
      y1 = String.to_integer(ys1)
      x2 = String.to_integer(xs2)
      y2 = String.to_integer(ys2)

      IO.puts("#{x1} #{y1} #{x2} #{y2}")
      acc + if (x2-x1)*(y2-y1) <= 0, do: 1, else: 0
  end)


  
IO.puts("total #{total}")