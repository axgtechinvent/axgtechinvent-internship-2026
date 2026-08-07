FROM python:3.10-slim
WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENV APP_PORT=5000
EXPOSE ${APP_PORT}

CMD ["gunicorn", "-b", "0.0.0.0:5000", "run:app"]