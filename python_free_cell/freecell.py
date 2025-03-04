import random
import streamlit as st

# Define the card and deck classes
class Card:
    suits = ['Hearts', 'Diamonds', 'Clubs', 'Spades']
    values = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K']
    suit_symbols = {'Hearts': '♥', 'Diamonds': '♦', 'Clubs': '♣', 'Spades': '♠'}
    value_symbols = {'A': 'A', '2': '2', '3': '3', '4': '4', '5': '5', '6': '6', '7': '7', '8': '8', '9': '9', '10': '10', 'J': 'J', 'Q': 'Q', 'K': 'K'}

    def __init__(self, suit, value):
        self.suit = suit
        self.value = value

    def __repr__(self):
        return f"{self.value_symbols[self.value]}{self.suit_symbols[self.suit]}"

class Deck:
    def __init__(self):
        self.cards = [Card(suit, value) for suit in Card.suits for value in Card.values]
        random.shuffle(self.cards)

    def deal(self):
        return self.cards.pop()

# Initialize game state
if 'deck' not in st.session_state:
    st.session_state.deck = Deck()
if 'columns' not in st.session_state:
    st.session_state.columns = [[] for _ in range(8)]
if 'free_cells' not in st.session_state:
    st.session_state.free_cells = [None for _ in range(4)]
if 'foundations' not in st.session_state:
    st.session_state.foundations = {suit: [] for suit in Card.suits}

# Deal cards to columns if game is not yet started
if 'game_started' not in st.session_state:
    for i in range(52):
        st.session_state.columns[i % 8].append(st.session_state.deck.deal())
    st.session_state.game_started = True

# Display game state
st.title("FreeCell Game")

st.subheader("Columns")
cols = st.columns(8)
for i, column in enumerate(st.session_state.columns):
    with cols[i]:
        st.write(f"Column {i+1}")
        st.write(", ".join(map(str, column)))

st.subheader("Free Cells")
free_cell_cols = st.columns(4)
for i, cell in enumerate(st.session_state.free_cells):
    with free_cell_cols[i]:
        st.write(f"Free Cell {i+1}")
        st.write(cell if cell else "Empty")

st.subheader("Foundations")
foundation_cols = st.columns(4)
for i, (suit, cards) in enumerate(st.session_state.foundations.items()):
    with foundation_cols[i]:
        st.write(suit)
        st.write(", ".join(map(str, cards)))

# Move cards between columns (simplified)
st.subheader("Move Card")
from_col = st.selectbox("From Column", range(1, 9))
to_col = st.selectbox("To Column", range(1, 9))
if st.button("Move"):
    if st.session_state.columns[from_col - 1]:
        card = st.session_state.columns[from_col - 1].pop()
        st.session_state.columns[to_col - 1].append(card)
        st.experimental_rerun()

# Move card to free cell
st.subheader("Move Card to Free Cell")
from_col_fc = st.selectbox("From Column to Free Cell", range(1, 9), key="fc_from_col")
to_free_cell = st.selectbox("To Free Cell", range(1, 5))
if st.button("Move to Free Cell"):
    if st.session_state.columns[from_col_fc - 1] and st.session_state.free_cells[to_free_cell - 1] is None:
        card = st.session_state.columns[from_col_fc - 1].pop()
        st.session_state.free_cells[to_free_cell - 1] = card
        st.experimental_rerun()

# Move card from free cell to column
st.subheader("Move Card from Free Cell to Column")
from_free_cell = st.selectbox("From Free Cell", range(1, 5), key="from_fc")
to_col_fc = st.selectbox("To Column from Free Cell", range(1, 9), key="fc_to_col")
if st.button("Move from Free Cell to Column"):
    if st.session_state.free_cells[from_free_cell - 1] is not None:
        card = st.session_state.free_cells[from_free_cell - 1]
        st.session_state.free_cells[from_free_cell - 1] = None
        st.session_state.columns[to_col_fc - 1].append(card)
        st.experimental_rerun()