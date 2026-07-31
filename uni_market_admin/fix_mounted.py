import os
import re

def fix_mounted(directory):
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith(".dart"):
                file_path = os.path.join(root, file)
                try:
                    with open(file_path, "r", encoding="utf-8") as f:
                        content = f.read()

                    # simple heuristic: if we see an await followed by some context usage, we might need a mounted check.
                    # this is tricky with regex. Let's just fix the exact known ones by replacing "if (mounted) {" with "if (context.mounted) {"
                    # and adding "if (!mounted) return;" before context usage where we know it fails.
                    pass
                except Exception as e:
                    pass

if __name__ == "__main__":
    fix_mounted("lib")
