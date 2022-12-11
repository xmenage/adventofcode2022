score = File.stream!("input.txt")
|> Stream.map(&String.trim(&1))
|> Enum.reduce(0, fn gameRound, score ->
  IO.puts(gameRound)
  scoreTable = %{
    "A X"=>4, "A Y"=>8, "A Z"=>3,
    "B X"=>1, "B Y"=>5, "B Z"=>9,
    "C X"=>7, "C Y"=>2, "C Z"=>6
    }
  losedrawwinTable = %{
    "A X"=>"A Z", "A Y"=>"A X", "A Z"=>"A Y",
    "B X"=>"B X", "B Y"=>"B Y", "B Z"=>"B Z",
    "C X"=>"C Y", "C Y"=>"C Z", "C Z"=>"C X"
  }
  newScore = scoreTable[losedrawwinTable[gameRound]]
  score + newScore
end)
IO.puts("score = #{score}")
