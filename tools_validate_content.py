import json
from pathlib import Path

root = Path('.')
def load(rel):
    return json.loads((root / rel).read_text())

reagents = {x['id'] for x in load('data/reagents/reagents.json')['reagents']}
recipes = load('data/recipes/recipes.json')['recipes']
recipe_ids = {x['id'] for x in recipes}
characters = {x['id'] for x in load('data/characters/characters.json')['characters']}
orders = load('data/orders/orders.json')['orders']
locations = load('data/world/locations.json')['locations']
location_ids = {x['id'] for x in locations}
shop = load('data/config/shop.json')
dialogues = load('data/dialogue/dialogues.json')['dialogues']
errors=[]
for r in recipes:
    for key in ('a','b'):
        if r[key] not in reagents: errors.append(f"recipe {r['id']}: missing reagent {r[key]}")
for o in orders:
    if o['recipe'] not in recipe_ids: errors.append(f"order {o['id']}: missing recipe {o['recipe']}")
    if o['client'] not in characters: errors.append(f"order {o['id']}: missing client {o['client']}")
for l in locations:
    for item in l.get('gather',[]):
        if item not in reagents: errors.append(f"location {l['id']}: missing reagent {item}")
for cid in dialogues:
    if cid not in characters: errors.append(f"dialogue: missing character {cid}")
for item in shop['items']:
    if item['id'] not in reagents: errors.append(f"shop: missing reagent {item['id']}")
for u in shop['upgrades']:
    if u['price'] < 0: errors.append(f"upgrade {u['id']}: negative price")
if 'village' not in location_ids: errors.append('world: village missing')
if errors:
    for e in errors: print('ERROR',e)
    raise SystemExit(1)
print(f'Content QA: {len(reagents)} reagents, {len(recipes)} recipes, {len(orders)} orders, {len(characters)} characters, {len(locations)} locations')
print('ALL CONTENT REFERENCES VALID')
