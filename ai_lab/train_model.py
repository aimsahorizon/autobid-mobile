import tensorflow as tf
from tensorflow.keras import layers, models
from tensorflow.keras.applications import MobileNetV3Large
from tensorflow.keras.preprocessing.image import ImageDataGenerator
import os
import datetime
import shutil
from pathlib import Path

# --- CONFIGURATION ---
DATASET_DIR = 'dataset' # Folder structure: dataset/train/class_name/image.jpg
ASSETS_DIR = os.path.join('..', 'assets', 'cars')
IMG_SIZE = (224, 224)
BATCH_SIZE = 32
EPOCHS = 20
LEARNING_RATE = 0.0001
# ---------------------

def prepare_dataset_from_assets():
    """
    Automatically prepares the training dataset from the project's assets/cars directory.
    Flattens the structure: assets/cars/Model/View/Image -> dataset/Model/Image
    """
    if not os.path.exists(ASSETS_DIR):
        print(f"Note: Assets directory '{ASSETS_DIR}' not found. Skipping auto-import.")
        return

    print(f"Found assets directory: {ASSETS_DIR}")
    
    # If dataset already exists and has content, ask or skip? 
    # For now, we'll skip if it looks populated to avoid overwriting manual work.
    if os.path.exists(DATASET_DIR) and len(os.listdir(DATASET_DIR)) > 0:
        print(f"Dataset directory '{DATASET_DIR}' already exists and is not empty. Using existing data.")
        return

    print("Preparing dataset from assets...")
    os.makedirs(DATASET_DIR, exist_ok=True)

    assets_path = Path(ASSETS_DIR)
    
    # Iterate over each car model folder
    for car_model_dir in assets_path.iterdir():
        if not car_model_dir.is_dir():
            continue
            
        # Clean folder name for class label (e.g., "1993 Honda SDX 4WD" -> "1993_Honda_SDX_4WD")
        class_name = car_model_dir.name.replace(' ', '_')
        target_class_dir = os.path.join(DATASET_DIR, class_name)
        os.makedirs(target_class_dir, exist_ok=True)
        
        print(f"Processing class: {class_name}")
        
        # Recursively find all images in subfolders (Front view, Side view, etc.)
        image_count = 0
        for root, _, files in os.walk(car_model_dir):
            for file in files:
                if file.lower().endswith(('.png', '.jpg', '.jpeg', '.webp')):
                    source_file = os.path.join(root, file)
                    
                    # Create unique filename to avoid collisions from different subfolders
                    # e.g. Front_view_img1.jpg
                    parent_folder = os.path.basename(root).replace(' ', '_')
                    new_filename = f"{parent_folder}_{file}"
                    target_file = os.path.join(target_class_dir, new_filename)
                    
                    shutil.copy2(source_file, target_file)
                    image_count += 1
        
        print(f"  - Copied {image_count} images")

    print("Dataset preparation complete.\n")

def train():
    print(f"TensorFlow Version: {tf.__version__}")

    # 1. Data Setup with Augmentation    
    train_datagen = ImageDataGenerator(
        rescale=1./255,
        rotation_range=20,
        width_shift_range=0.2,
        height_shift_range=0.2,
        shear_range=0.2,
        zoom_range=0.2,
        horizontal_flip=True,
        fill_mode='nearest',
        validation_split=0.2
    )

    print("Loading Training Data...")
    train_generator = train_datagen.flow_from_directory(
        DATASET_DIR,
        target_size=IMG_SIZE,
        batch_size=BATCH_SIZE,
        class_mode='categorical',
        subset='training'
    )

    print("Loading Validation Data...")
    validation_generator = train_datagen.flow_from_directory(
        DATASET_DIR,
        target_size=IMG_SIZE,
        batch_size=BATCH_SIZE,
        class_mode='categorical',
        subset='validation'
    )

    num_classes = train_generator.num_classes
    print(f"Detected {num_classes} classes.")
    
    # Save labels to file
    class_indices = train_generator.class_indices
    labels = {v: k for k, v in class_indices.items()}
    with open('labels.txt', 'w') as f:
        for i in range(num_classes):
            f.write(labels[i] + ' ')
    print("Saved labels.txt")

    # 2. Build Model (Transfer Learning)
    base_model = MobileNetV3Large(
        weights='imagenet',
        include_top=False,
        input_shape=(IMG_SIZE[0], IMG_SIZE[1], 3)
    )
    
    # Freeze base model initially
    base_model.trainable = False

    model = models.Sequential([
        base_model,
        layers.GlobalAveragePooling2D(),
        layers.Dropout(0.2),
        layers.Dense(num_classes, activation='softmax')
    ])

    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=LEARNING_RATE),
        loss='categorical_crossentropy',
        metrics=['accuracy']
    )

    # 3. Train
    print("Starting Training...")
    log_dir = "logs/fit/" + datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    tensorboard_callback = tf.keras.callbacks.TensorBoard(log_dir=log_dir, histogram_freq=1)
    
    history = model.fit(
        train_generator,
        steps_per_epoch=train_generator.samples // BATCH_SIZE,
        validation_data=validation_generator,
        validation_steps=validation_generator.samples // BATCH_SIZE,
        epochs=EPOCHS,
        callbacks=[tensorboard_callback]
    )

    # 4. Save Keras Model
    model.save('car_classifier_model.keras')
    print("Model saved as car_classifier_model.keras")

if __name__ == '__main__':
    prepare_dataset_from_assets()
    
    if not os.path.exists(DATASET_DIR):
        print(f"Error: Dataset directory '{DATASET_DIR}' not found.")
        print("Please create a 'dataset' folder with subfolders for each car model.")
        print("Example: dataset/Honda_Civic/image1.jpg")
    else:
        train()
