import argparse
import json
import os
import sys
import time

import pandas as pd
from confluent_kafka import Producer


def parse_args():
    p = argparse.ArgumentParser(description="CSV -> Kafka")
    p.add_argument("--file", default="/data/train.csv", help="путь к CSV")
    p.add_argument("--topic", default=os.getenv("KAFKA_TOPIC", "transactions"))
    p.add_argument("--bootstrap", default=os.getenv("KAFKA_BOOTSTRAP_SERVERS", "localhost:9096"))
    p.add_argument("--chunksize", type=int, default=50_000, help="строк CSV за одно чтение")
    p.add_argument("--limit", type=int, default=None, help="отправить только первые N строк")
    return p.parse_args()


def main():
    args = parse_args()
    producer = Producer({
        "bootstrap.servers": args.bootstrap,
        "linger.ms": 50,
        "batch.num.messages": 10_000,
        "compression.type": "lz4",
        "queue.buffering.max.messages": 500_000,
    })

    failed = 0

    def on_delivery(err, _msg):
        nonlocal failed
        if err is not None:
            failed += 1

    sent, started = 0, time.time()
    for chunk in pd.read_csv(args.file, chunksize=args.chunksize, dtype=str, keep_default_na=False):
        if args.limit is not None:
            chunk = chunk.iloc[: max(args.limit - sent, 0)]
            if chunk.empty:
                break
        for col in ["amount", "lat", "lon", "population_city", "merchant_lat", "merchant_lon", "post_code", "target"]:
            if col in chunk.columns:
                chunk[col] = pd.to_numeric(chunk[col], errors="coerce")
        chunk = chunk.astype(object).where(chunk.notna(), None)

        for record in chunk.to_dict(orient="records"):
            while True:
                try:
                    producer.produce(args.topic, value=json.dumps(record, ensure_ascii=False), on_delivery=on_delivery)
                    break
                except BufferError:
                    producer.poll(0.5)
            sent += 1
        producer.poll(0)
        rate = sent / max(time.time() - started, 1e-9)
        print(f"sent {sent:,} rows ({rate:,.0f} rows/s)", file=sys.stderr, flush=True)

    producer.flush()
    print(f"done: {sent:,} rows sent to '{args.topic}', delivery errors: {failed}", flush=True)
    if failed:
        sys.exit(1)


if __name__ == "__main__":
    main()
