import argparse, json
p = argparse.ArgumentParser()
p.add_argument("--format", choices=["json"], required=True)
args = p.parse_args()
print(json.dumps({"records": [{"id": 7, "state": "ready"}]}))
