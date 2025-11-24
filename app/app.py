import os
from flask import Flask
import mysql.connector
import socket

app = Flask(__name__)

# ORTAM DEĞİŞKENLERİ (Environment Variables)
# Şifreler artık kodun içinde değil, sunucunun beyninde tutulacak!
DB_HOST = os.environ.get('DB_HOST', 'localhost')
DB_USER = os.environ.get('DB_USER', 'admin')
DB_PASSWORD = os.environ.get('DB_PASSWORD', 'password123') # Default değer (Test için)
DB_NAME = os.environ.get('DB_NAME', 'testdb')

@app.route('/')
def hello_world():
    # Hangi Container ID veya IP cevap veriyor?
    container_id = socket.gethostname()
    
    db_status = "Baglanti Bekleniyor..."
    try:
        conn = mysql.connector.connect(
            host=DB_HOST,
            user=DB_USER,
            password=DB_PASSWORD,
            database=DB_NAME,
            connect_timeout=3
        )
        if conn.is_connected():
            db_status = "BAŞARILI! (Veritabanı Bağlantısı Aktif)"
            conn.close()
    except Exception as e:
        db_status = f"HATA: {str(e)}"

    return f"""
    <div style="text-align: center; margin-top: 50px; font-family: Arial;">
        <h1 style="color: #e67e22;">AWS 3-Tier DevOps Project</h1>
        <h3>Container ID / Hostname: <span style="color: blue;">{container_id}</span></h3>
        <hr>
        <p><strong>Database Host:</strong> {DB_HOST}</p>
        <p><strong>Database Durumu:</strong> {db_status}</p>
        <p><em>Versiyon: v1.0 (Dockerized)</em></p>
    </div>
    """

if __name__ == '__main__':
    # Konteyner içinde 80 portundan yayın yap
    app.run(host='0.0.0.0', port=80)
