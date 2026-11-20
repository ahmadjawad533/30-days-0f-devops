# Minimal Flask application

from flask import Flask, jsonify
import os

app = Flask(__name__)

APP_VERSION = os.getenv('APP_VERSION', 'dev')

@app.route('/')
def index():
    return jsonify(message='Hello from Day 07 lab')

@app.route('/health')
def health():
    return jsonify(status='ok')

@app.route('/version')
def version():
    return jsonify(version=APP_VERSION)

if __name__ == '__main__':
    # Development server – used only by Dockerfile.naive
    app.run(host='0.0.0.0', port=8000)
