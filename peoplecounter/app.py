import asyncio
import os
import signal
from contextlib import asynccontextmanager
from datetime import datetime

import cv2
import psycopg
from psycopg.rows import dict_row
from fastapi import FastAPI
from fastapi.responses import JSONResponse

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://micro:changeme@postgres:5432/microdb")
LINE_POSITION = float(os.getenv("LINE_POSITION", "0.5"))
COUNT_INTERVAL = int(os.getenv("COUNT_INTERVAL", "30"))

capture = cv2.VideoCapture(0)
if not capture.isOpened():
    print("Warning: Unable to open video device /dev/video0.")
background_subtractor = cv2.createBackgroundSubtractorMOG2(history=500, varThreshold=16, detectShadows=True)

people_count = 0
lock = asyncio.Lock()


def _connect():
    return psycopg.AsyncConnection.connect(DATABASE_URL, autocommit=True)


async def init_db():
    async with await _connect() as conn:
        async with conn.cursor() as cur:
            await cur.execute(
                """
                CREATE TABLE IF NOT EXISTS counts (
                    id SERIAL PRIMARY KEY,
                    observed_at TIMESTAMP NOT NULL,
                    count INTEGER NOT NULL
                )
                """
            )


async def store_count(count: int):
    async with await _connect() as conn:
        async with conn.cursor() as cur:
            await cur.execute(
                "INSERT INTO counts (observed_at, count) VALUES (%s, %s)",
                (datetime.utcnow(), count),
            )


async def producer():
    global people_count
    while True:
        ret, frame = capture.read()
        if not ret:
            await asyncio.sleep(1)
            continue

        mask = background_subtractor.apply(frame)
        _, thresh = cv2.threshold(mask, 200, 255, cv2.THRESH_BINARY)
        contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        height = frame.shape[0]
        line_y = int(height * LINE_POSITION)

        detected = 0
        for contour in contours:
            if cv2.contourArea(contour) < 1500:
                continue
            x, y, w, h = cv2.boundingRect(contour)
            centroid_y = y + h // 2
            if centroid_y < line_y < centroid_y + h:
                detected += 1

        if detected:
            async with lock:
                people_count += detected

        await asyncio.sleep(0.1)


async def flusher():
    global people_count
    while True:
        await asyncio.sleep(COUNT_INTERVAL)
        async with lock:
            if people_count == 0:
                continue
            count = people_count
            people_count = 0
        try:
            await store_count(count)
        except Exception as exc:  # noqa: BLE001
            print(f"Failed to store count: {exc}")


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    producer_task = asyncio.create_task(producer())
    flusher_task = asyncio.create_task(flusher())
    try:
        yield
    finally:
        producer_task.cancel()
        flusher_task.cancel()
        capture.release()


app = FastAPI(title="EdgeBox People Counter", lifespan=lifespan)


@app.get("/")
async def root():
    return {"service": "peoplecounter", "status": "OK"}


@app.get("/metrics")
async def metrics():
    async with await _connect() as conn:
        async with conn.cursor(row_factory=dict_row) as cur:
            await cur.execute("SELECT observed_at, count FROM counts ORDER BY observed_at DESC LIMIT 100")
            data = await cur.fetchall()
    total = sum(item["count"] for item in data)
    return JSONResponse({"total": total, "samples": data})


@app.get("/counts")
async def history():
    async with await _connect() as conn:
        async with conn.cursor(row_factory=dict_row) as cur:
            await cur.execute("SELECT observed_at, count FROM counts ORDER BY observed_at DESC LIMIT 1000")
            data = await cur.fetchall()
    return JSONResponse(data)


def shutdown_handler(signum, frame):  # noqa: ANN001, D401
    raise SystemExit(0)


signal.signal(signal.SIGTERM, shutdown_handler)
signal.signal(signal.SIGINT, shutdown_handler)
