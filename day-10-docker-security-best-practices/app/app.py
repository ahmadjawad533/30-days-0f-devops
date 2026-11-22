from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route('/')
def index():
    return jsonify(message='Hello from Day 10 lab')

@app.route('/health')
def health():
    return jsonify(status='ok')

@app.route('/whoami')
def whoami():
    return jsonify(uid=os.getuid())

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)
