from flask import Flask, jsonify
import os
import psycopg2
import time

app = Flask(__name__)

def get_db_connection():
    conn = psycopg2.connect(
        host=os.getenv('DB_HOST', 'db'),
        port=os.getenv('DB_PORT', '5432'),
        dbname=os.getenv('DB_NAME', os.getenv('POSTGRES_DB', 'lab09')),
        user=os.getenv('DB_USER', os.getenv('POSTGRES_USER', 'lab09')),
        password=os.getenv('DB_PASSWORD', os.getenv('POSTGRES_PASSWORD', '')),
        connect_timeout=5,
    )
    return conn

@app.route('/health')
def health():
    return jsonify(status='ok')

@app.route('/')
def index():
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("CREATE TABLE IF NOT EXISTS visits (count BIGINT);")
        cur.execute("SELECT count FROM visits LIMIT 1;")
        row = cur.fetchone()
        count = row[0] if row else 0
        count += 1
        cur.execute("TRUNCATE visits;")
        cur.execute("INSERT INTO visits (count) VALUES (%s);", (count,))
        conn.commit()
        cur.close()
        conn.close()
        return jsonify(visits=count)
    except Exception as e:
        app.logger.error(f'DB error: {type(e).__name__}')
        return jsonify(error='service unavailable'), 503

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)
