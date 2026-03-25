#!/usr/bin/env bash

hassver="$1"
if [ "$hassver" = "" ]; then
    hassver="dev"
    echo "Fetching Home Assistant branch: $hassVer"
fi

# Update Home Assistant to the latest version
sudo python3 -m pip --disable-pip-version-check install --upgrade git+https://github.com/home-assistant/home-assistant.git@$hassver
# Install requirements for default_config and all configured integrations
sudo python3 -c "
import json, os

base = os.path.dirname(__import__('homeassistant').__file__) + '/components'

# Start with default_config, plus any integrations from the config entries
seeds = ['default_config']
config_entries = '/config/.storage/core.config_entries'
if os.path.exists(config_entries):
    data = json.load(open(config_entries))
    seeds.extend(e.get('domain','') for e in data.get('data',{}).get('entries',[]))

to_visit, visited, reqs = list(seeds), set(), set()
while to_visit:
    comp = to_visit.pop(0)
    if comp in visited: continue
    visited.add(comp)
    mf = os.path.join(base, comp, 'manifest.json')
    if not os.path.exists(mf): continue
    m = json.load(open(mf))
    to_visit.extend(m.get('dependencies', []) + m.get('after_dependencies', []))
    reqs.update(m.get('requirements', []))
print('\n'.join(sorted(reqs)))
" | sudo pip install --disable-pip-version-check -r /dev/stdin
sudo hass --script ensure_config -c /config