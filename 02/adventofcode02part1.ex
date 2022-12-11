score = File.stream!("input.txt")
|> Stream.map(&String.trim(&1))
|> Enum.reduce(0, fn gameRound, score ->
  IO.puts(gameRound)
  scoreTable = %{
    "A X"=>4, "A Y"=>8, "A Z"=>3,
    "B X"=>1, "B Y"=>5, "B Z"=>9,
    "C X"=>7, "C Y"=>2, "C Z"=>6
    }
  newScore = scoreTable[gameRound]
  score + newScore
end)
IO.puts("score = #{score}")
