import random

DEBUG = True
class Card:
    ranks = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K']
    suits = ['Hearts', 'Diamonds', 'Clubs', 'Spades']
    suit_symbols = {'Hearts': '♥', 'Diamonds': '♦', 'Clubs': '♣', 'Spades': '♠'}
    value_symbols = {'A': 'A', '2': '2', '3': '3', '4': '4', '5': '5', '6': '6', '7': '7', '8': '8', '9': '9', '10': '10', 'J': 'J', 'Q': 'Q', 'K': 'K'}

    def __init__(self, suit, rank):
        self.suit = suit
        self.rank = rank

    def __repr__(self):
        return f"{self.value_symbols[self.rank]}{self.suit_symbols[self.suit]}"

class Deck:
    suits = ['Hearts', 'Diamonds', 'Clubs', 'Spades']
    def __init__(self):
        self.cards = [Card(suit, rank) for suit in Card.suits for rank in Card.ranks]
        self.shuffle()

    def shuffle(self):
        random.shuffle(self.cards)


    def deal(self):
        return self.cards.pop()

class FreeCellGame:
    def __init__(self):
        self.deck = Deck()
        self.tableau = [[] for _ in range(8)]
        self.free_cells = [None] * 4
        self.foundations = {suit: [] for suit in Deck.suits}
        self.start_game()

    def start_game(self):
        # Initially deal 7 cards to the first 4 tableau piles and 6 cards to the rest
        for i in range(4):
            self.tableau[i] = [self.deck.deal() for _ in range(7)]
        for i in range(4, 8):
            self.tableau[i] = [self.deck.deal() for _ in range(6)]

    def is_valid_tableau_move(self, card, destination_pile):
        if not destination_pile:
            return True  # Any card can be moved to an empty pile
        top_card = destination_pile[-1]
        # return (card.suit != top_card.suit) and (Card.ranks.index(card.rank) == Card.ranks.index(top_card.rank) - 1)
        return (card.suit != top_card.suit) and (Card.ranks.index(card.rank) < Card.ranks.index(top_card.rank) - 1)

    def move_within_tableau(self, from_pile_index, to_pile_index):
        if DEBUG: 
            print(f"Moving card {self.tableau[from_pile_index][-1]} from pile {from_pile_index} to pile {to_pile_index}")
        if self.tableau[from_pile_index]:
            card_to_move = self.tableau[from_pile_index][-1]
            if self.is_valid_tableau_move(card_to_move, self.tableau[to_pile_index]):
                self.tableau[to_pile_index].append(self.tableau[from_pile_index].pop())
                return True
        return False
    
    def move_to_free_cell(self, from_pile_index, free_cell_index):
        # doesnt seem legal to check index out of range to me.
        if self.free_cells[free_cell_index] is None and self.tableau[from_pile_index]:
            self.free_cells[free_cell_index] = self.tableau[from_pile_index].pop()
            print("SUCCESS")
            return True
        return False

    def move_to_foundation(self, from_pile_index):
        if self.tableau[from_pile_index]:
            card_to_move = self.tableau[from_pile_index][-1]
            foundation_pile = self.foundations[card_to_move.suit]
            if not foundation_pile:
                if card_to_move.rank == 'A':
                    foundation_pile.append(self.tableau[from_pile_index].pop())
                    return True
            else:
                top_card = foundation_pile[-1]
                if Card.ranks.index(card_to_move.rank) == Card.ranks.index(top_card.rank) + 1:
                    foundation_pile.append(self.tableau[from_pile_index].pop())
                    return True
        return False

    def is_winner(self):
        # Check if all foundation piles have a complete set of cards in correct order
        return all(len(pile) == 13 for pile in self.foundations.values())

# Example usage to check initialization
game = FreeCellGame()
print("Tableau:", game.tableau)
print("Free Cells:", game.free_cells)
print("Foundations:", game.foundations)

# Example usage
deck = Deck()
print(deck.cards)  # Check what the deck looks like after shuffling
print(len(deck.cards))