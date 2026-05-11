import os
from pathlib import Path

def find_miniscope_folders_without_cnmf(root_dir):
    """
    Find all My_V4_Miniscope folders that do NOT contain
    minian/cleaned_cnmf_data.mat
    """
    missing_paths = []
    root = Path(root_dir)
    
    # Walk through all directories looking for My_V4_Miniscope folders
    for miniscope_dir in root.rglob("My_V4_Miniscope"):
        if not miniscope_dir.is_dir():
            continue
        
        cnmf_file = miniscope_dir / "minian" / "cleaned_cnmf_data.mat"
        
        if not cnmf_file.exists():
            missing_paths.append(str(miniscope_dir.resolve()))
    
    return sorted(missing_paths)


if __name__ == "__main__":
    # Set your root directory here
    root_dir = r"C:\Users\boba4\Box\Zach_repo\Projects\Remote_memory\miniscope data_revision\discrimination\miniscope recordings"
    
    output_file = Path.home() / "Desktop" / "missing_cnmf_paths.txt"
    
    print(f"Searching in: {root_dir}\n")
    missing = find_miniscope_folders_without_cnmf(root_dir)
    
    with open(output_file, "w") as f:
        f.write(f"My_V4_Miniscope folders missing cleaned_cnmf_data.mat\n")
        f.write(f"Root: {root_dir}\n")
        f.write(f"{'='*60}\n\n")
        for path in missing:
            f.write(path + "\n")
    
    print(f"Found {len(missing)} folder(s) missing cleaned_cnmf_data.mat:")
    for p in missing:
        print(f"  {p}")
    print(f"\nResults written to: {output_file}")