# 1. Baz İmaj: Python 3.9'un hafif sürümünü kullan (Linux tabanlı)
FROM python:3.9-slim

# 2. Çalışma Dizinini Ayarla
WORKDIR /app

# 3. Gereksinim dosyasını kopyala ve yükle
# (Önce bunu yapıyoruz ki kod değişse bile kütüphaneler tekrar indirilmesin - Cache mantığı)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 4. Uygulama kodlarını kopyala
COPY . .

# 5. Konteynerin dış dünyaya açacağı portu belirt
EXPOSE 80

# 6. Ortam değişkenleri için default değerler (Gerekirse ezilebilir)
ENV DB_HOST=localhost \
    DB_USER=admin \
    DB_PASSWORD=change-me \
    DB_NAME=testdb

# 7. Uygulamayı başlat
CMD ["python", "app.py"]
