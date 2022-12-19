defmodule BuildDirTree do

  def process_cd(device, dirlist) do
    IO.inspect(["dirlist",dirlist])
    command = IO.read(device, :line)
    IO.puts(command)
    cond do
      command == :eof -> dirlist

      Regex.match?(~r/^\$ ls/, command) -> process_cd(device, dirlist)

      Regex.match?(~r/^\$ cd \.\./, command) ->
        IO.inspect(["cd ..", dirlist])
        dirlist

      a = Regex.named_captures(~r/^dir (?<dirname>.+)/, command) ->
        IO.inspect(a)
        newdirlist = Map.put(dirlist, a["dirname"], %{})
        process_cd(device, newdirlist)

      _a = Regex.named_captures(~r/^(?<filesize>\d+) (.+)/, command) -> process_cd(device, dirlist)

      a = Regex.named_captures(~r/^\$ cd (?<dirname>.+)$/, command) ->
        %{dirlist | a["dirname"] => process_cd(device, %{})}
    end
  end
end

inputFileName = "testdata.txt"
{_s, f} = File.open(inputFileName)
BuildDirTree.process_cd(f, %{"/" => %{}}) |> IO.inspect
