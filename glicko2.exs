defmodule Glicko2Player do

  # import :lists, only: [hd: 1]


  defstruct rating: 1500, rd: 350, volatility: 0.06

  def calculate_g(rd_j) do
    1 / :math.sqrt(1 + 3 * :math.pow(0.06, 2) * (rd_j ** 2) / (:math.pi() ** 2))
  end

  def calculate_expected_outcome(player, other_player) do
    g = calculate_g(other_player.rd)
    1 / (1 + :math.exp(-g * (player.rating - other_player.rating)))
  end

  def update_rd(%Glicko2Player{rd: rd} = player, d_squared) do
    new_rd = :math.sqrt(rd ** 2 + d_squared)
    %{player | rd: new_rd}
  end

  def update_rating(%Glicko2Player{rating: rating} = player, d_squared, v_squared) do
    g = calculate_g(player.rd)
    new_rating = rating + g * (d_squared / (1 / v_squared))
    %{player | rating: new_rating}
  end

  def update_volatility(%Glicko2Player{volatility: volatility} = player, delta_squared) do
    new_volatility = :math.sqrt(volatility ** 2 + delta_squared)
    %{player | volatility: new_volatility}
  end
end

defmodule Glicko2 do

  alias Glicko2Player

  def calculate_d_squared(player, other_player, outcome) do
    expected_outcome = Glicko2Player.calculate_expected_outcome(player, other_player)
    (outcome - expected_outcome) ** 2
  end

  def glicko2_rating_system(players, outcomes, tau \\ 0.5) do
    tau_squared = tau ** 2
    players =
      Enum.reduce(players, players, fn player, acc ->
        v_squared = 1 / (player.volatility ** 2)
        delta_squared_sum =
          Enum.reduce(acc, 0, fn other_player, sum ->
            if other_player != player do
              d_squared = calculate_d_squared(player, other_player, hd(outcomes))
              delta_squared_sum = sum + (Glicko2Player.calculate_g(other_player.rd) ** 2) * d_squared / (1 - Glicko2Player.calculate_expected_outcome(player, other_player) ** 2)
              {tl, List.first(tl)} = Enum.split(outcomes, 1)
              tl
            else
              {tl, List.first(tl)} = Enum.split(outcomes, 1)
              sum
            end
          end)

          delta_squared_sum = delta_squared_sum / tau_squared

        player
        |> Glicko2Player.update_rd(delta_squared_sum)
        |> Glicko2Player.update_volatility(delta_squared_sum)
        |> Glicko2Player.update_rating(delta_squared_sum, v_squared)
      end)

    players
  end
end


defmodule Glicko2Algorithm do
# Example usage:
  def work do
    player1 = %Glicko2Player{}
    player2 = %Glicko2Player{rating: 1400, rd: 30}
    player3 = %Glicko2Player{rating: 1550, rd: 100}

    players = [player1, player2, player3]
    outcomes = [1, 0, 0]  # Assuming player1 wins, player2 loses, and player3 loses

    players = Glicko2.glicko2_rating_system(players, outcomes)

    Enum.each(players, fn player ->
      IO.puts("Player Rating: #{player.rating}, RD: #{player.rd}, Volatility: #{player.volatility}")
    end)

  end

end


Glicko2Algorithm.work()
