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
      |> Map.put(:visit_count, 0)
      |> Map.put(:time_visited, 100)
      |> Map.put(:distance, 0)
    end)
    |> Enum.reduce(%{}, fn valve, valve_map -> Map.put(valve_map, valve["valve"],valve) end)
  end

  def get_next_valves(valve_map, valve) do
    get_in(valve_map,[valve, "lead_to"])
  end

  def get_flow_rate(valve_map, valve) do
    get_in(valve_map,[valve, "flow_rate"])
  end

  def get_visited(valve_map, valve) do
    get_in(valve_map,[valve, :visited])
  end

  def update_visited(valve_map, valve) do
    get_and_update_in(valve_map,[valve, :visited], &{&1, true})
  end

  def get_visit_count(valve_map, valve) do
    get_in(valve_map,[valve, :visit_count])
  end

  def update_visit_count(valve_map, valve) do
    get_and_update_in(valve_map,[valve, :visit_count], &{&1, &1+1})
  end

  def get_time_visited(valve_map, valve) do
    get_in(valve_map,[valve, :time_visited])
  end

  def update_time_visited(valve_map, valve, new_time) do
    get_and_update_in(valve_map,[valve, :time_visited], &{&1, new_time})
  end

  def get_distance(_, :racine) do
    -1
  end

  def get_distance(valve_map, valve) do
    get_in(valve_map,[valve, :distance])
  end

  def update_distance(valve_map, valve, distance) do
    get_and_update_in(valve_map,[valve, :distance], &{&1, distance})
  end

  def update_visited_valve(valve_map, valve, new_time) do
    valve_props = valve_map[valve]
    {_, updated_props} =  Map.get_and_update(valve_props, :visited, &{&1, true})
    {_, updated_props} =  Map.get_and_update(updated_props, :visit_count,  &{&1, &1+1})
    {_, updated_props} =  Map.get_and_update(updated_props, :time_visited,  &{&1, new_time})
    {updated_props, %{valve_map | valve => updated_props}}

  end


  def get_next_highest(valve_map, valve) do
    get_next_valves(valve_map, valve)
    |> Enum.reduce({}, fn next_valve, acc ->
      case acc do
        {} -> {next_valve, get_flow_rate(valve_map, next_valve)}
        {acc_valve, acc_flow_rate} ->
          next_flow_rate = get_flow_rate(valve_map, next_valve)
          if acc_flow_rate < next_flow_rate do
            {next_valve, next_flow_rate}
          else
            acc
          end
      end
    end) |> elem(0)
  end

  def get_next_least_visited(valve_map,valve) do
    get_next_valves(valve_map, valve)
    |> Enum.reduce({}, fn next_valve, acc ->
      case acc do
        {} -> {next_valve, get_visit_count(valve_map, next_valve)}
        {acc_valve, acc_visit_count} ->
          next_visit_count = get_visit_count(valve_map, next_valve)
          if next_visit_count < acc_visit_count do
            {next_valve, next_visit_count}
          else
            acc
          end
      end
    end) |> elem(0)
  end

  def get_next_longest_sinced_visited(valve_map,valve) do
    get_next_valves(valve_map, valve)
    |> Enum.reduce({}, fn next_valve, acc ->
      case acc do
        {} -> {next_valve, get_time_visited(valve_map, next_valve)}
        {acc_valve, acc_time_visited} ->
          next_time_visited = get_time_visited(valve_map, next_valve)
          if next_time_visited > acc_time_visited do
            {next_valve, next_time_visited}
          else
            acc
          end
      end
    end) |> elem(0)
  end

  def get_next_most_promising(valve_map, valve, depth) do
    get_next_valves(valve_map, valve)
    |> Enum.reduce({}, fn next_valve, acc ->
      next_best_total = explore(valve_map, next_valve, 0, 30, depth)
      case acc do
        {} -> {next_valve, next_best_total}
        {acc_valve, acc_best_total} -> if next_best_total > acc_best_total do
            {next_valve, next_best_total}
          else
            acc
          end
      end
    end) |> elem(0)
  end

  def explore(valve_map, valve, current_total, remaining_time, remaining_count) when remaining_time <= 0 or remaining_count == 0 do
    # IO.inspect([valve, current_total, remaining_time])
    current_total
  end

  def explore(valve_map, valve, current_total, remaining_time, remaining_count) do
    valve_props = valve_map[valve]
    remaining_count = if !valve_props[:visited], do: remaining_count-1, else: remaining_count
    {remaining_time, new_total} = if valve_props[:visited] || valve_props["flow_rate"] == 0, do: {remaining_time, current_total}, else: {remaining_time-1, current_total + valve_props["flow_rate"]*(remaining_time-1)}
    {valve_props, updated_valve_map} = update_visited_valve(valve_map, valve, remaining_time)
    next_valve = get_next_longest_sinced_visited(updated_valve_map, valve)
    # IO.inspect([valve, new_total, remaining_time, remaining_count, next_valve])
    explore(updated_valve_map, next_valve, new_total , remaining_time-1, remaining_count)
  end


  def parcours(valve_map, valve, current_total, remaining_time, remaining_count) when remaining_time <= 0 or remaining_count == 0 do
    IO.inspect([valve, current_total, remaining_time])
    {valve_map, current_total}
  end

  def parcours(valve_map, valve, current_total, remaining_time, remaining_count) do
    valve_props = valve_map[valve]
    remaining_count = if !valve_props[:visited], do: remaining_count-1, else: remaining_count
    {remaining_time, new_total} = if valve_props[:visited] || valve_props["flow_rate"] == 0, do: {remaining_time, current_total}, else: {remaining_time-1, current_total + valve_props["flow_rate"]*(remaining_time-1)}
    {valve_props, updated_valve_map} = update_visited_valve(valve_map, valve, remaining_time)
    next_valve = get_next_most_promising(updated_valve_map, valve, 2)
    IO.inspect([valve, new_total, remaining_time, remaining_count, next_valve])
    parcours(updated_valve_map, next_valve, new_total , remaining_time-1, remaining_count)
  end

  # this function calculates the shortest path distance from each valve to all other valves.
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

  def distance_matrix(valve_map, start_valve) do
    start_valve_distance_map = Main.distances(valve_map, [{start_valve, :racine}])
    non_zero_flow_valves = list_non_zero_flow_valves(valve_map)
    non_zero_flow_valves
      |> Enum.reduce(%{start_valve => start_valve_distance_map},
        fn valve, distance_matrix ->
          Map.put(distance_matrix,valve, Main.distances(valve_map, [{valve, :racine}]))
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

  def get_total_pressure_release(flow_rate,distance,remaining_time) do
    (remaining_time - distance -1) * flow_rate
  end

  def get_next_highest_flow_to_visit(distance_matrix,valve,remaining_list, remaining_time) do
    remaining_list
    |> Enum.reduce({}, fn next_valve, acc ->
      # reprendre ici, récupérer les infos de next_valve et calculer get_total_pressure_release
      case acc do
        {} -> {next_valve, get_time_visited(valve_map, next_valve)}
        {acc_valve, acc_time_visited} ->
          next_time_visited = get_time_visited(valve_map, next_valve)
          if next_time_visited > acc_time_visited do
            {next_valve, next_time_visited}
          else
            acc
          end
      end
    end) |> elem(0)
  end

  def visit(distance_matrix, valve, remaining_list, current_total, remaining_time) when remaining_time <= 0 or length(remaining_list) == 0 do
    # IO.inspect([valve, current_total, remaining_time])
    current_total
  end

  def visit(distance_matrix, valve, remaining_list, current_total, remaining_time) do

  end



end


input_file_name = "testdata.txt"
valve_map = Main.parse_input(input_file_name) |> IO.inspect(label: "valve_map")
valves_count = Enum.count(valve_map) |> IO.inspect(label: "valves_count")
time_left = 30
Main.parcours(valve_map, "AA", 0, time_left, valves_count)
IO.puts("calcul distances")


distance_matrix = Main.distance_matrix(valve_map, "AA")

Main.summary_distance_matrix(distance_matrix)
