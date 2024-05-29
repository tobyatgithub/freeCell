from flask import Flask, render_template, request, redirect, url_for
from game_logic import FreeCellGame

app = Flask(__name__)
game = FreeCellGame()

@app.route('/')
def home():
    my_dict = enumerate(game.tableau)
    return render_template('index.html', game=game, my_dict=my_dict)

@app.route('/start')
def start_game():
    global game
    game = FreeCellGame()  # Reset the game
    return redirect(url_for('home'))

@app.route('/move', methods=['POST'])
def move_card():
    # -1 to match 0 start index to 1 start index
    from_index = int(request.form['from_index']) - 1
    to_index = int(request.form['to_index']) - 1
    move_type = request.form['move_type']
    
    if move_type == 'tableau':
        game.move_within_tableau(from_index, to_index)
    elif move_type == 'free_cell':
        game.move_to_free_cell(from_index, to_index)
    elif move_type == 'foundation':
        game.move_to_foundation(from_index)
    
    return redirect(url_for('home'))