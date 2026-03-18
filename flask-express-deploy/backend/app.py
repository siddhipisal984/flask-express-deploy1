from flask import Flask, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

@app.route('/')
def home():
    return jsonify({"message": "Flask Backend is running!", "status": "ok"})

@app.route('/api/data')
def data():
    return jsonify({"items": ["item1", "item2", "item3"], "source": "flask-backend"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
