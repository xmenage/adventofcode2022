defmodule BuildDirTree do
  # acc :: %{:dirsize, :sumsize}

  def process_ls(device, acc) do
    IO.inspect(acc)
    command = IO.read(device, :line)
    IO.puts(command)
    cond do
      # if end of file or command is cd .. , then check if dir size is more than 100000 and if not add it to accumulated value, then return accumulated value
      command == :eof || Regex.match?(~r/^\$ cd \.\./, command) ->
        if acc[:dirsize] > 100000 do
          %{:dirsize => acc[:dirsize], :sumsize => acc[:sumsize]}
        else
          %{:dirsize => acc[:dirsize], :sumsize => acc[:sumsize]+acc[:dirsize]}
        end

      # if line starts with ls, do nothing, just continue to next line in ls
      Regex.match?(~r/^\$ ls/, command) -> process_ls(device, acc)

      # if line starts with dir, do nothing, just continue to next line in ls
      _a = Regex.named_captures(~r/^dir (?<dirname>.+)/, command) ->
        process_ls(device, acc)

      # if line starts with file size, add it to dirsize and continue to next line in ls
      a = Regex.named_captures(~r/^(?<filesize>\d+) (.+)/, command) ->
        filesize = String.to_integer(a["filesize"])
        process_ls(device, %{:dirsize => acc[:dirsize] + filesize, :sumsize => acc[:sumsize]})

      # if line is a cd command with dir name, get its accumulated value and add it to current acc values
      _a = Regex.named_captures(~r/^\$ cd (?<dirname>.+)$/, command) ->
        subdiracc = process_ls(device, %{:dirsize => 0, :sumsize => 0})
        process_ls(device, %{:dirsize => acc[:dirsize] + subdiracc[:dirsize], :sumsize => acc[:sumsize] + subdiracc[:sumsize]})
    end
  end
end


inputFileName = "input.txt"
{_s, f} = File.open(inputFileName)
dirsumresult = BuildDirTree.process_ls(f, %{:dirsize => 0, :sumsize => 0})
IO.puts("final result")
IO.inspect(dirsumresult)
