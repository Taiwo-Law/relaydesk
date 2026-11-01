import logging
import os

from flask import Flask, jsonify

app = Flask(__name__)

app.config["RELAYDESK_ENV"] = os.getenv(
    "RELAYDESK_ENV", "development"
)

log_level = os.getenv("LOG_LEVEL", "INFO").upper()
app.logger.setLevel(getattr(logging, log_level, logging.INFO))


@app.route("/")
def home():
    return jsonify(
        {
            "service": "RelayDesk",
            "status": "running",
            "version": "1.0.0"
        }
    )


@app.route("/health")
def health():
    return jsonify(
        {
            "status": "healthy"
        }
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)