

defmodule Main do
  def parse_input(input_file_name) do
    File.stream!(input_file_name)
    |> Stream.map(&String.trim(&1))
    |> Enum.map(fn input_line ->
      Regex.named_captures(~r/Valve (?<valve>[[:upper:]]{2}) has flow rate=(?<flow_rate>\d+); tunnel(s?) lead(s?) to valve(s?) (?<lead_to>.*)$/,input_line)
      |> Map.get_and_update("lead_to", fn valve_list -> {valve_list, Regex.split(~r/, /, valve_list, trim: true)}
        end)|> elem(1)
      |> Map.get_and_update("flow_rate", fn flow_rate -> {flow_rate, String.to_integer(flow_rate)} end)
      |> elem(1)
      |> Map.put(:visited, false)
      |> Map.put(:distance, 0)
    end)
    |> Enum.reduce(%{}, fn valve, valve_map -> Map.put(valve_map, valve["valve"],valve) end)
  end

  def get_next_valves(valve_map, valve) do
    get_in(valve_map,[valve, "lead_to"])
  end

  def get_visited(valve_map, valve) do
    get_in(valve_map,[valve, :visited])
  end

  def get_distance(_, :racine) do
    -1
  end

  def get_distance(valve_map, valve) do
    get_in(valve_map,[valve, :distance])
  end

  # this function calculates the shortest path distance from one valve to all other valves.
  def distances(valve_map, []) do
    valve_map
  end

  def distances(valve_map, [{valve, parent_valve} | list_tail]) do
    new_dist = get_distance(valve_map, parent_valve) + 1
    valve_props = valve_map[valve]
    {_, updated_props} =  Map.get_and_update(valve_props, :visited, &{&1, true})
    {_, updated_props} =  Map.get_and_update(updated_props, :distance,  &{&1, new_dist})
    valve_map =  %{valve_map | valve => updated_props}
    new_tail = get_next_valves(valve_map, valve) |> Enum.reduce(list_tail,
      fn child_valve, list_tail ->
        if !get_visited(valve_map, child_valve) || new_dist + 1 < get_distance(valve_map, child_valve) do
          [{child_valve, valve} | list_tail]
        else
          list_tail
        end
      end)
    distances(valve_map, new_tail)
  end


  def list_non_zero_flow_valves(valve_map) do
    valve_map |> Enum.reduce([], fn {valve, valve_props}, non_zero_valves_list ->
      if valve_props["flow_rate"] > 0 do
        [valve | non_zero_valves_list]
      else
        non_zero_valves_list
      end
    end )
  end

  # creates a matrix (map of maps) for each valve, associates a map (vector) of valve containing distance from
  # this valve to other valves, including to itself (with distance = 0)
  def distance_matrix(valve_map, start_valve) do
    start_valve_distance_map = distances(valve_map, [{start_valve, :racine}])
    non_zero_flow_valves = list_non_zero_flow_valves(valve_map)
    non_zero_flow_valves
      |> Enum.reduce(%{start_valve => start_valve_distance_map},
        fn valve, distance_matrix ->
          Map.put(distance_matrix,valve, distances(valve_map, [{valve, :racine}]))
        end)
  end

# build simplified matrix that shows for each non zero valve, the distance to other non zero valves.
  def summary_distance_matrix(distance_matrix) do
    distance_matrix |> Enum.reduce(%{}, fn {valve, valve_map}, simplified_matrix ->
      distance_vector = valve_map |> Enum.reduce(%{}, fn {valve, valve_props}, distance_vector ->
        if valve_props["flow_rate"] > 0 do
          Map.put(distance_vector,valve, valve_props[:distance])
        else
          distance_vector
        end
      end)
      Map.put(simplified_matrix, valve, distance_vector)
    end)
  end

  # calculates the gain from going to another valve, taking into account the distance to reach it.
  def get_total_pressure_release(flow_rate,distance,remaining_time) do
    new_remaining_time = remaining_time - distance - 1
    pressure_release = new_remaining_time * flow_rate
    {pressure_release, new_remaining_time}
  end

  def get_valve_pressure_release(distance_matrix, valve, next_valve, remaining_time) do
    valve_map = distance_matrix[valve]
    next_valve_props = valve_map[next_valve]
    get_total_pressure_release(next_valve_props["flow_rate"], next_valve_props[:distance], remaining_time)
  end

  # modify for part 2 in order to track the path of separate elephant. For this we replace the valve and remaining_time
  # parameters with a list of t-uple [{valve1, remaining_time 1}, {valve2, remaining_time 2}]
  # then we alternate using the first or second on each recursive call
  def all_permutations(_, _, remaining_list) when length(remaining_list) == 0 do
    0
  end

  def all_permutations(distance_matrix, [{valve, remaining_time}, other_one], remaining_list) when length(remaining_list) > 0 do
    case length(remaining_list) do
      14 -> IO.puts(valve)
      13 -> IO.puts(" " <> valve)
      a -> :ok
    end
    remaining_list |> Enum.reduce(0, fn next_valve, max_release ->
        {next_valve_pressure_release, new_remaining_time} = get_valve_pressure_release(distance_matrix, valve, next_valve, remaining_time)
        if new_remaining_time > 0 do
          new_max_release = next_valve_pressure_release + all_permutations(distance_matrix,
            [other_one, {next_valve, new_remaining_time}] , List.delete(remaining_list, next_valve))
          max(max_release,new_max_release)
        else
          {other_valve, other_remaining_time} = other_one
          {next_valve_pressure_release, new_remaining_time} = get_valve_pressure_release(distance_matrix, other_valve, next_valve, other_remaining_time)
          if other_remaining_time > 0 do
            new_max_release = next_valve_pressure_release + all_permutations(distance_matrix,
              [{next_valve, new_remaining_time}, {"AA", -1}] , List.delete(remaining_list, next_valve))
            max(max_release,new_max_release)
          else
            max_release
          end
        end
    end)
  end


end


input_file_name = "input.txt"
valve_map = Main.parse_input(input_file_name) |> IO.inspect(label: "valve_map")
valves_count = Enum.count(valve_map) |> IO.inspect(label: "valves_count")
time_left = 26
IO.puts("calcul distances")

distance_matrix = Main.distance_matrix(valve_map, "AA")
non_zero_valves_list = Main.list_non_zero_flow_valves(valve_map)
# The following takes a long time, about 15 minutes to complete
Main.all_permutations(distance_matrix,[{"AA", time_left}, {"AA", time_left}], non_zero_valves_list)
