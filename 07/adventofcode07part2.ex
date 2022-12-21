defmodule BuildDirTree do
  # acc :: %{:currentcurrentdirsize, :currentbestresult}

  def process_ls(device, acc, mindirsize) do
    IO.inspect(acc)
    command = IO.read(device, :line)
    IO.puts(command)
    cond do
      # if end of file or command is cd .. , then check if dir size is more than 100000 and if not add it to accumulated value, then return accumulated value
      command == :eof || Regex.match?(~r/^\$ cd \.\./, command) ->
        if acc[:currentbestresult] < mindirsize and acc[:currentdirsize] > acc[:currentbestresult] or (acc[:currentdirsize] >= mindirsize and acc[:currentdirsize] < acc[:currentbestresult]) do
          %{acc | :currentbestresult => acc[:currentdirsize]}
        else
          acc
        end

      # if line starts with ls, do nothing, just continue to next line in ls
      Regex.match?(~r/^\$ ls/, command) -> process_ls(device, acc, mindirsize)

      # if line starts with dir, do nothing, just continue to next line in ls
      _a = Regex.named_captures(~r/^dir (?<dirname>.+)/, command) ->
        process_ls(device, acc, mindirsize)

      # if line starts with file size, add it to currentdirsize and continue to next line in ls
      a = Regex.named_captures(~r/^(?<filesize>\d+) (.+)/, command) ->
        filesize = String.to_integer(a["filesize"])
        process_ls(device, %{acc | :currentdirsize => acc[:currentdirsize] + filesize}, mindirsize)

      # if line is a cd command with dir name, propagate the current best result to the subdir, then continue to next command with the result
      _a = Regex.named_captures(~r/^\$ cd (?<dirname>.+)$/, command) ->
        subdiracc = process_ls(device, %{acc | :currentdirsize => 0}, mindirsize)
        process_ls(device, %{:currentdirsize => acc[:currentdirsize] + subdiracc[:currentdirsize], :currentbestresult => subdiracc[:currentbestresult]}, mindirsize)
    end
  end
end


inputFileName = "input.txt"

# first get the total occupied space, just the sum of all file sizes
totaldirsize = File.stream!(inputFileName)
  |> Enum.reduce(0, fn line, acc ->
    a = Regex.named_captures(~r/^(?<filesize>\d+) (.+)/, line)
    if a do
      acc + String.to_integer(a["filesize"])
    else
      acc
    end
  end)

mindirsize = 30000000 - (70000000 - totaldirsize)

{_s, f} = File.open(inputFileName)
dirsumresult = BuildDirTree.process_ls(f, %{:currentdirsize => 0, :currentbestresult => 0}, mindirsize)

IO.puts(totaldirsize)
IO.puts(mindirsize)

IO.puts("final result")
IO.inspect(dirsumresult)
