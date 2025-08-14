from flask import Flask, jsonify, request
from flask_cors import CORS
from typing import Dict, List
import secrets

app = Flask(__name__)
CORS(app)

# Simple in-memory store
class GameState:
    def __init__(self, entry_fee: int = 0) -> None:
        self.numbers_called: List[int] = []
        self.total_numbers: int = 0
        self.entry_fee: int = entry_fee
        self.prize_pool: int = 0
        self.is_active: bool = True

    def to_dict(self) -> Dict:
        return {
            "numbers_called": list(self.numbers_called),
            "total_numbers": int(self.total_numbers),
            "entry_fee": int(self.entry_fee),
            "prize_pool": int(self.prize_pool),
            "is_active": bool(self.is_active),
        }

games: Dict[str, GameState] = {}

@app.get("/health")
def health():
    return jsonify({"status": "ok"})

@app.post("/games")
def create_game():
    data = request.get_json(silent=True) or {}
    owner = (data.get("owner") or "").strip()
    entry_fee = int(data.get("entry_fee") or 0)

    if not owner:
        return jsonify({"detail": "owner is required"}), 400
    if owner in games:
        return jsonify({"detail": "Game already exists for this owner"}), 400

    games[owner] = GameState(entry_fee=entry_fee)
    return jsonify(games[owner].to_dict())

@app.get("/games/<owner>")
def get_game(owner: str):
    if owner not in games:
        return jsonify({"detail": "Game not found"}), 404
    return jsonify(games[owner].to_dict())

@app.post("/games/<owner>/call-number")
def call_number(owner: str):
    if owner not in games:
        return jsonify({"detail": "Game not found"}), 404

    game = games[owner]
    if not game.is_active:
        return jsonify({"detail": "Game is not active"}), 400
    if game.total_numbers >= 75:
        game.is_active = False
        return jsonify({"detail": "Game is complete"}), 400

    called_mask = [False] * 76  # 1..75
    for n in game.numbers_called:
        called_mask[n] = True

    base_candidate = secrets.randbelow(75) + 1
    chosen = None
    for offset in range(75):
        candidate = ((base_candidate - 1 + offset) % 75) + 1
        if not called_mask[candidate]:
            chosen = candidate
            break

    if chosen is None:
        game.is_active = False
        return jsonify(game.to_dict())

    game.numbers_called.append(chosen)
    game.total_numbers += 1
    if game.total_numbers == 75:
        game.is_active = False

    return jsonify(game.to_dict())

if __name__ == "__main__":
    # For local development convenience
    app.run(host="0.0.0.0", port=8000, debug=True)