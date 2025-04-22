import os
import winrm
from modules.log_parser import parse_log_file
from modules.opensearch_client import send_to_opensearch
from modules.logger import setup_logger

logger = setup_logger()

def collect_logs_from_servers(config):
    for server in config['servers']:
        host = server['host']
        username = server['username']
        password = server['password']
        log_paths = server['log_paths']

        session = winrm.Session(host, auth=(username, password))

        for log_path in log_paths:
            try:
                logger.info(f"Collecting {log_path} from {host}")
                ps_command = f"type {log_path}"
                result = session.run_ps(ps_command)
                content = result.std_out.decode('utf-8')
                
                events = parse_log_file(log_path, content)
                index_name = os.path.basename(log_path).replace(".log", "").lower()
                send_to_opensearch(index_name, events, config['opensearch'])

            except Exception as e:
                logger.error(f"Error collecting log {log_path} from {host}: {e}")