import os
import shutil

# --- CONFIGURATION ---
DATASET_DIR = 'dataset'
QUARANTINE_DIR = 'empty_directories'
# ---------------------

def audit():
    if not os.path.exists(DATASET_DIR):
        print(f"Error: '{DATASET_DIR}' not found.")
        return

    print(f"Scanning '{DATASET_DIR}'...\n")
    
    subfolders = [f.path for f in os.scandir(DATASET_DIR) if f.is_dir() and os.path.basename(f.path) != QUARANTINE_DIR]
    stats = []
    
    # 1. Collect Stats
    for folder in subfolders:
        files = [f for f in os.listdir(folder) if f.lower().endswith(('.jpg', '.jpeg', '.png', '.webp'))]
        stats.append({
            'name': os.path.basename(folder),
            'count': len(files),
            'path': folder
        })

    # 2. Sort Ascending
    stats.sort(key=lambda x: x['count'])

    # 3. Print List
    empty_folders = []
    for s in stats:
        if s['count'] == 0:
            print(f"❌ {s['name']}: 0 files")
            empty_folders.append(s['path'])
        else:
            print(f"✅ {s['name']}: {s['count']} files")

    # 4. Summary
    print(f"\n--- Summary ---")
    print(f"Total Folders: {len(stats)}")
    print(f"Empty Folders: {len(empty_folders)}")

    if not empty_folders:
        print("Dataset is clean! No empty folders found.")
        return

    # 5. Action Prompt
    choice = input(f"\nMove {len(empty_folders)} empty folders to '{QUARANTINE_DIR}/'? (y/n): ").strip().lower()
    
    if choice == 'y':
        # 6. Move
        quarantine_path = os.path.join(DATASET_DIR, QUARANTINE_DIR)
        os.makedirs(quarantine_path, exist_ok=True)
        
        for folder in empty_folders:
            folder_name = os.path.basename(folder)
            dest = os.path.join(quarantine_path, folder_name)
            try:
                shutil.move(folder, dest)
                print(f"Moved: {folder_name}")
            except Exception as e:
                print(f"Error moving {folder_name}: {e}")
        
        print("\nCleanup complete.")
    else:
        print("No changes made.")

if __name__ == '__main__':
    audit()
