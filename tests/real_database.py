"""Read selected facts from the installed QuestieDB; keep generated data temporary."""
import base64
import re
import subprocess
import tempfile
from pathlib import Path
import cbor2

addons = Path('/home/nick/Games/battlenet/drive_c/Program Files (x86)/World of Warcraft/_classic_beta_/Interface/AddOns')
metadata = {}
for line in (addons / 'QuestieDB/QuestieDB_Camelot.toc').open():
    match = re.match(r'## X-(Item|Npc)-(\d+)-(\d+|S): (.*)', line)
    if match:
        metadata[(match[1], int(match[2]), match[3])] = match[4]

def read(kind, ident, field):
    value = metadata.get((kind, ident, str(field)))
    if value and not value.startswith('~'):
        return cbor2.loads(base64.b64decode(value))
    value = metadata.get((kind, ident, 'S'))
    if value and not value.startswith('~'):
        record = cbor2.loads(base64.b64decode(value))
        if isinstance(record, dict):
            return record.get(field)

def lua(value):
    if value is None:
        return 'nil'
    if isinstance(value, bytes):
        value = value.decode()
    if isinstance(value, str):
        return '"' + value.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n') + '"'
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, list):
        return '{' + ','.join(lua(v) for v in value) + '}'
    return '{' + ','.join(f'[{lua(k)}]={lua(v)}' for k, v in value.items()) + '}'

npcs = {}
for ident in {key[1] for key in metadata if key[0] == 'Npc'}:
    spawns = read('Npc', ident, 7)
    if ident in {2163, 3823} or (isinstance(spawns, dict) and (141 in spawns or 148 in spawns or 331 in spawns)):
        npcs[ident] = {'name': read('Npc', ident, 1), 'spawns': spawns, 'minLevel': read('Npc', ident, 4), 'maxLevel': read('Npc', ident, 5)}
items = {ident: read('Item', ident, 2) or [] for ident in [2318, 2934, 2589, 2592, 6889, 5465, 6291, 6303, 6289, 6361, 2672, 769]}
with tempfile.TemporaryDirectory(prefix='trailmats-db-test-') as folder:
    fixture = Path(folder) / 'fixture.lua'
    fixture.write_text('return ' + lua({'npcs': npcs, 'items': items}))
    subprocess.run(['lua5.1', 'tests/real_database.lua', str(fixture), str(addons)], check=True)
