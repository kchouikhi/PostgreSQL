import re

def parse_log_file(file_path, content):
    events = []
    lines = content.splitlines()

    for line in lines:
        match = re.search(r'(?P<date>\\d{4}-\\d{2}-\\d{2})\\s+(?P<level>[A-Z]+)\\s+(?P<msg>.+)', line)
        if match:
            events.append(match.groupdict())

    return events