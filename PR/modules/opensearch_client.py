from opensearchpy import OpenSearch

def send_to_opensearch(index_name, events, config):
    client = OpenSearch(
        hosts=[{'host': config['host'], 'port': config['port']}],
        http_auth=(config['username'], config['password']),
        use_ssl=config.get('use_ssl', False),
        verify_certs=False
    )

    for event in events:
        client.index(index=index_name, body=event)