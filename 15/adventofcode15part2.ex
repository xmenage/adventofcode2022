defmodule Main do
  def parse_input(input_file_Name) do
    File.stream!(input_file_Name)
    |> Stream.map(&String.trim(&1))
    |> Enum.map(fn input_line ->
      Regex.named_captures(~r/Sensor at x=(?<sx>-?\d+), y=(?<sy>-?\d+): closest beacon is at x=(?<bx>-?\d+), y=(?<by>-?\d+)/,input_line)
      |> Enum.into(%{}, fn {k, v} -> {String.to_atom(k), String.to_integer(v)} end)
    end)
  end

  def sort_intervals_by_first_value(list_of_intervals) do
    list_of_intervals |> Enum.sort(fn {x1,_}, {x2,_} -> x1 < x2 end)
  end

  def merge_overlapping_intervals(sorted_list_of_intervals) do
    [{xa1,xb1} | tail] = sorted_list_of_intervals
    if length(tail) > 0 do
      [{xa2,xb2} | tail] = tail
      if xb1 >= xa2-1 do
        merge_overlapping_intervals([{xa1, max(xb1,xb2)} | tail])
      else
        [{xa1,xb1} | merge_overlapping_intervals([{xa2,xb2} | tail])]
      end
    else
      [{xa1,xb1}]
    end
  end

end

input_file_Name = "input.txt"
sensor_beacon_pairs = Main.parse_input(input_file_Name)
  |> IO.inspect([label: "input sensor beacon data"])

{xmin,xmax} = sensor_beacon_pairs |> Enum.reduce(nil, fn pair, result ->
  %{:sx => sx, :bx => bx} = pair
    if result do
    {result_xmin, result_xmax} = result
    {Enum.min([result_xmin, sx, bx]), Enum.max([result_xmax, sx, bx]) }
  else
    {min(sx,bx), max(sx,bx)}
  end
end )

{xmin,xmax} |> IO.inspect(label: "xmin xmax")


for row <- 0..4000000 do
  excluded_ranges = sensor_beacon_pairs
    |> Enum.map(fn pair ->
      dt = abs(pair.bx - pair.sx) + abs(pair.by - pair.sy)
      dy = abs(row - pair.sy)
      if dt >= dy do
        {pair.sx - (dt-dy), pair.sx + (dt-dy)}
      else
        :none
      end
    end)
    |> Enum.filter(&(&1 != :none))
    # |> IO.inspect(label: "excluded ranges")

  set_of_beacons = sensor_beacon_pairs
    |> MapSet.new(fn %{:bx => bx, :by => by} -> {bx,by} end)

  interval_beacons_on_same_row = set_of_beacons |> Enum.reduce([],fn {bx,by}, interval_list ->
    if by == row do
      [{bx,bx} | interval_list]
    else
      interval_list
    end
  end)
  #  |> IO.inspect(label: "interval_beacons_on_same_row")

   excluded_ranges = excluded_ranges ++ interval_beacons_on_same_row

   merged_ranges = excluded_ranges
   |> Main.sort_intervals_by_first_value()
   |> Main.merge_overlapping_intervals()
  #  |> IO.inspect(label: "merged ranges")

  # This display the only row that has two separate interval of excluded locations, leaving just one space
  # in between. You need to finish the calculation of the coordinate of the remaining space between those two
  # ranges, and multiply x by 4000000 and add row number
   if length(merged_ranges)>1 do
    IO.puts("row #{row}")
    IO.inspect(merged_ranges)
   end
end
