# 1. Baz İmaj
FROM python:3.9-slim

# 2. Çalışma Dizinini Ayarla
WORKDIR /app

# 3. Gereksinimleri Yükle
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 4. Kodları Kopyala
COPY . .

# 5. Port Ayarı (Terraform Target Group ile uyumlu: 5000)
EXPOSE 5000

# 6. Default Env (Test için)
ENV DB_HOST=localhost \
    DB_USER=root \
    DB_PASSWORD=password \
    DB_NAME=testdb

# 7. Flask Uygulamasını Başlat (Host 0.0.0.0 önemli!)
CMD ["python", "app.py"]
