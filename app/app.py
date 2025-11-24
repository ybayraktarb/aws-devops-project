import os
import socket
import mysql.connector
from flask import Flask

app = Flask(__name__)

# --- ORTAM DEĞİŞKENLERİ ---
DB_HOST = os.environ.get('DB_HOST', 'localhost')
DB_USER = os.environ.get('DB_USER', 'admin')
DB_PASSWORD = os.environ.get('DB_PASSWORD', 'password123')
DB_NAME = os.environ.get('DB_NAME', 'testdb')

# İstenilen ECR Depo Adresi
ECR_REPOSITORY_URI = "083880123527.dkr.ecr.us-east-1.amazonaws.com/my-flask-app"

@app.route('/')
def hello_world():
    # Hangi Container ID veya IP cevap veriyor?
    container_id = socket.gethostname()

    db_status = "Bağlantı Bekleniyor..."
    status_color = "orange"

    # Veritabanı Bağlantı Testi
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
            status_color = "green"
            conn.close()
    except Exception as e:
        # Hata mesajını basitleştirerek göster
        db_status = f"HATA: Veritabanına ulaşılamadı. ({str(e)})"
        status_color = "red"

    # HTML Çıktısı
    return f"""
    <div style="text-align: center; margin-top: 50px; font-family: Arial, sans-serif;">
        <h1 style="color: #333;">Bulut Tabanlı Flask Uygulaması ☁️</h1>
        
        <div style="margin: 20px auto; padding: 20px; background-color: #f4f4f4; border-radius: 10px; max-width: 600px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);">
            
            <h3>Sunucu Bilgisi</h3>
            <p><strong>Container ID / Hostname:</strong> <br> {container_id}</p>
            
            <hr style="border: 0; border-top: 1px solid #ddd; margin: 20px 0;">
            
            <h3>Veritabanı Durumu</h3>
            <p style="color: {status_color}; font-weight: bold;">{db_status}</p>
            
            <hr style="border: 0; border-top: 1px solid #ddd; margin: 20px 0;">
            
            <h3>AWS ECR Hedef Depo</h3>
            <div style="background-color: #2d2d2d; color: #00ff00; padding: 10px; border-radius: 5px; font-family: monospace; word-break: break-all;">
                {ECR_REPOSITORY_URI}
            </div>
            <p style="font-size: 0.8em; color: #666; margin-top: 5px;">(Bu adres uygulamanın push edileceği yerdir)</p>
            
        </div>
    </div>
    """

if __name__ == "__main__":
    # Docker içinde dışarıdan erişilebilmesi için host='0.0.0.0' olmalı
    app.run(host='0.0.0.0', port=5000)
