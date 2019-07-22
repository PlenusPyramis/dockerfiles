% for mac, config in [(mac, config) for mac, config in clients.items() if config.get("enabled", False)]:
${mac.replace('-',':')},${config['hostname']},${config['ip_address']},${config.get('lease_time','24h')}
% endfor
