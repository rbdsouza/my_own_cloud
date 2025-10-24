FROM python:3.11-slim as build

RUN apt-get update && apt-get install -y --no-install-recommends build-essential pkg-config libatlas-base-dev && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

FROM python:3.11-slim

RUN useradd -r -u 1000 edgebox && mkdir -p /app && chown -R edgebox:edgebox /app

WORKDIR /app
COPY --from=build /usr/local/lib/python3.11 /usr/local/lib/python3.11
COPY --from=build /usr/local/bin /usr/local/bin
COPY app.py ./
RUN mkdir -p /app/data && chown -R edgebox:edgebox /app

USER edgebox

ENV UVICORN_HOST=0.0.0.0
ENV UVICORN_PORT=8080

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8080"]
