import subprocess, sys
from pathlib import Path
result = subprocess.run([sys.executable, "tool.py", "--legacy"], capture_output=True, text=True, check=True)
Path("export.json").write_text(result.stdout)
