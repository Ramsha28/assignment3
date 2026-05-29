from flask import Flask, jsonify, request
import mysql.connector
import os
import time

app = Flask(__name__)

def get_db_connection():
    max_retries = 30
    for i in range(max_retries):
        try:
            conn = mysql.connector.connect(
                host=os.environ.get('DB_HOST', 'mysql'),
                user=os.environ.get('DB_USER', 'flaskuser'),
                password=os.environ.get('DB_PASSWORD', 'flaskpass'),
                database=os.environ.get('DB_NAME', 'flaskdb')
            )
            return conn
        except:
            time.sleep(2)
    raise Exception("DB connection failed")

@app.route('/health')
def health():
    return jsonify({"status": "healthy", "service": "flask-api"})

@app.route('/api/items')
def get_items():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM items")
    data = cursor.fetchall()
    return jsonify(data)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
