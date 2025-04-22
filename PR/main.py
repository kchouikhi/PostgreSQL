import yaml
from modules.remote_connector import collect_logs_from_servers
from modules.logger import setup_logger

logger = setup_logger()

if __name__ == "__main__":
    try:
        with open("config.yaml", "r") as f:
            config = yaml.safe_load(f)

        logger.info("Starting log collection process...")
        collect_logs_from_servers(config)
        logger.info("Log collection completed.")
    except Exception as e:
        logger.exception(f"Fatal error: {e}")