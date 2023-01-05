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
      if xb1 >= xa2 do
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

row = 2000000

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
  |> IO.inspect(label: "excluded ranges")

excluded_ranges |> Main.sort_intervals_by_first_value()
|> IO.inspect(label: "sorted ranges by first value")

merged_ranges = excluded_ranges
  |> Main.sort_intervals_by_first_value()
  |> Main.merge_overlapping_intervals()
  |> IO.inspect(label: "merged ranges")

number_of_excluded_locations = merged_ranges |> Enum.reduce(0, fn {xa,xb}, current_total -> current_total + xb-xa+1 end)

set_of_beacons = sensor_beacon_pairs
  |> MapSet.new(fn %{:bx => bx, :by => by} -> {bx,by} end)

number_of_beacons_at_excluded_locations = set_of_beacons
  |> Enum.reduce(0, fn {bx,by} , beacon_count ->
    merged_ranges |> Enum.reduce_while(beacon_count, fn {xa,xb}, count ->
      if by == row && bx >= xa && bx <= xb do
        {:halt, count+1}
      else
        {:cont, count}
      end
    end)
  end)
  |> IO.inspect(label: "number of beacons at excluded locations")

IO.puts("number of possible locations on row #{row} is #{number_of_excluded_locations-number_of_beacons_at_excluded_locations}")
