import os

source_root = r"C:\Users\boba4\Box\Zach_repo\Projects\Remote_memory\miniscope data_revision\discrimination\miniscope recordings"
output_file = r"C:\Users\boba4\Desktop\missing_concat_beh_csv.txt"

missing = []

for dirpath, dirnames, filenames in os.walk(source_root):
    if os.path.basename(dirpath) == "My_WebCam":
        # Check if any csv starting with concat_beh exists
        has_csv = any(f.startswith("concat_beh") and f.endswith(".csv") for f in filenames)

        if not has_csv:
            avi_path = os.path.join(dirpath, "concat_beh.avi")
            if os.path.exists(avi_path):
                missing.append(avi_path)
            else:
                print(f"WARNING - no concat_beh.avi either in: {dirpath}")

print(f"\n=== My_WebCam folders missing concat_beh*.csv ===")
print(f"Total: {len(missing)}\n")
for path in missing:
    print(path)

with open(output_file, "w") as f:
    f.write("\n".join(missing))

print(f"\nList saved to: {output_file}")
input("\nPress Enter to close...")