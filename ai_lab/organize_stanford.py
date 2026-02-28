import scipy.io
import os
import shutil
import tarfile

# --- CONFIGURATION ---
# These are the standard filenames when you download Stanford Cars
TRAIN_IMAGES_DIR = 'cars_train'
TEST_IMAGES_DIR = 'cars_test'
DEVKIT_DIR = 'devkit'
OUTPUT_DIR = 'dataset'
# ---------------------

def reorganize():
    print("1. Checking files...")
    if not os.path.exists(TRAIN_IMAGES_DIR) or not os.path.exists(DEVKIT_DIR):
        print("Error: Could not find 'cars_train' or 'devkit' folders.")
        print("Make sure you uploaded and unzipped the dataset!")
        return

    # Load metadata (Car names)
    print("2. Loading metadata...")
    meta_path = os.path.join(DEVKIT_DIR, 'cars_meta.mat')
    cars_meta = scipy.io.loadmat(meta_path)
    class_names = [c[0] for c in cars_meta['class_names'][0]]
    
    # Create output structure
    if os.path.exists(OUTPUT_DIR):
        shutil.rmtree(OUTPUT_DIR)
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    # Process Training Data
    print("3. Organizing Training Data...")
    train_annos_path = os.path.join(DEVKIT_DIR, 'cars_train_annos.mat')
    train_annos = scipy.io.loadmat(train_annos_path)['annotations'][0]

    count = 0
    for anno in train_annos:
        fname = anno['fname'][0]
        label_idx = anno['class'][0][0] - 1 # 1-based to 0-based
        label_name = class_names[label_idx]
        
        # Clean folder name (e.g. "Audi A5 Sedan 2012" -> "Audi_A5_Sedan_2012")
        safe_label = label_name.replace(' ', '_').replace('/', '-')
        
        # Source & Dest
        src = os.path.join(TRAIN_IMAGES_DIR, fname)
        dst_folder = os.path.join(OUTPUT_DIR, safe_label)
        dst = os.path.join(dst_folder, fname)
        
        os.makedirs(dst_folder, exist_ok=True)
        shutil.copy(src, dst)
        count += 1
        
        if count % 1000 == 0:
            print(f"   Processed {count} images...")

    # Process Test Data (Optional: Stanford test set has NO labels in public release usually)
    # The standard 'cars_test' folder often lacks labels in the public .mat file.
    # We usually just split the training set 80/20 in our training script.
    # So we will ONLY organize the 'train' folder which has labels.
    
    print(f"Done! Organized {count} images into '{OUTPUT_DIR}/'.")
    print("You can now zip this 'dataset' folder or use it directly.")

if __name__ == '__main__':
    reorganize()
