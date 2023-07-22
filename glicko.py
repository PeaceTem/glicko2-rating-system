import math

class Glicko2Player:
    def __init__(self, rating=1500, rd=350, volatility=0.06):
        self.rating = rating
        self.rd = rd
        self.volatility = volatility

    def calculate_g(self, rd_j):
        return 1 / math.sqrt(1 + 3 * (self.volatility ** 2) * (rd_j ** 2) / (math.pi ** 2))

    def calculate_expected_outcome(self, other_player):
        g = self.calculate_g(other_player.rd)
        return 1 / (1 + math.exp(-g * (self.rating - other_player.rating)))

    def update_rd(self, d_squared):
        self.rd = math.sqrt(self.rd ** 2 + d_squared)

    def update_rating(self, d_squared, v_squared):
        g = self.calculate_g(self.rd)
        self.rating += g * (d_squared / (1 / v_squared))

    def update_volatility(self, delta_squared):
        self.volatility = math.sqrt(self.volatility ** 2 + delta_squared)

def calculate_d_squared(player, other_player, outcome):
    expected_outcome = player.calculate_expected_outcome(other_player)
    return ((outcome - expected_outcome) ** 2)

def glicko2_rating_system(players, outcomes, tau=0.5):
    tau_squared = tau ** 2
    for player in players:
        v_squared = 1 / (player.volatility ** 2)
        delta_squared_sum = 0

        for other_player, outcome in zip(players, outcomes):
            if other_player != player:
                d_squared = calculate_d_squared(player, other_player, outcome)
                delta_squared_sum += (glicko2.g(other_player.rd) ** 2) * d_squared / (1 - glicko2.calculate_expected_outcome(player, other_player) ** 2)

        delta_squared_sum /= tau_squared

        player.update_rd(delta_squared_sum)
        player.update_volatility(delta_squared_sum)
        player.update_rating(delta_squared_sum, v_squared)

if __name__ == "__main__":
    # Example usage:
    player1 = Glicko2Player(rating=1500, rd=200, volatility=0.06)
    player2 = Glicko2Player(rating=1400, rd=30, volatility=0.06)
    player3 = Glicko2Player(rating=1550, rd=100, volatility=0.06)

    players = [player1, player2, player3]
    outcomes = [1, 0, 0]  # Assuming player1 wins, player2 loses, and player3 loses

    glicko2_rating_system(players, outcomes)

    for player in players:
        print(f"Player Rating: {player.rating:.2f}, RD: {player.rd:.2f}, Volatility: {player.volatility:.4f}")
