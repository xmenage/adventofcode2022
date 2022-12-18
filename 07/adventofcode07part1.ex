# match commande cd
Regex.run(~r/^\$ cd (.+)/, "$ cd fdoif")
# est-ce la commande pour remonter au directory supérieur
".." =~ ~r/\.{2}/

# match le nom de sous dir après un ls
Regex.run(~r/^dir (.+)/, "dir jjgpvcqv")

# match un nom de fichier et sa taille
Regex.run(~r/^(\d+) (.+)/, "127603 gpcpgfh.gtw")


inputFileName = "testdata.txt"
File.stream!(inputFileName)
  |> Enum.reduce(%{:size => 0, :subdirs => %{}},
  fn line, tree ->
    IO.puts(line)
    cond do
      a = Regex.named_captures(~r/^\$ cd (?<dirname>.+)$/, line) -> IO.inspect(a)
      Regex.match?(~r/^\$ ls/, line) -> tree
      a = Regex.named_captures(~r/^dir (?<dirname>.+)/, line) -> IO.inspect(a)
      a = Regex.named_captures(~r/^(?<filesize>\d+) (.+)/, line) -> IO.inspect(a)
      true -> IO.inspect("no match")
    end
    tree
  end)
