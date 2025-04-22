import logging
from logging.handlers import RotatingFileHandler
import os

def setup_logger():
    os.makedirs("logs", exist_ok=True)
    logger = logging.getLogger("log_collector")
    logger.setLevel(logging.INFO)

    handler = RotatingFileHandler("logs/collector.log", maxBytes=5*1024*1024, backupCount=3)
    formatter = logging.Formatter("%(asctime)s - %(levelname)s - %(message)s")
    handler.setFormatter(formatter)

    if not logger.hasHandlers():
        logger.addHandler(handler)

    return logger
