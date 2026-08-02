import os
import re

def fix_deprecations(directory):
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith(".dart"):
                file_path = os.path.join(root, file)
                try:
                    with open(file_path, "r", encoding="utf-8") as f:
                        content = f.read()

                    modified = False

                    # Replace .withOpacity(x) with .withValues(alpha: x)
                    new_content, count = re.subn(r'\.withOpacity\(([^)]+)\)', r'.withValues(alpha: \1)', content)
                    if count > 0:
                        modified = True

                    # Replace .background with .surface
                    new_content, count2 = re.subn(r'\.background', r'.surface', new_content)
                    if count2 > 0:
                        modified = True
                    
                    if modified:
                        with open(file_path, "w", encoding="utf-8") as f:
                            f.write(new_content)
                        print(f"Updated {file_path}")
                except Exception as e:
                    print(f"Error processing {file_path}: {e}")

if __name__ == "__main__":
    fix_deprecations("lib")
