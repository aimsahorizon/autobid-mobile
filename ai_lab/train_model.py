import tensorflow as tf
from tensorflow.keras import layers, models
from tensorflow.keras.applications import MobileNetV3Large
from tensorflow.keras.preprocessing.image import ImageDataGenerator
import os
import datetime

# --- CONFIGURATION ---
DATASET_DIR = 'dataset' # Folder structure: dataset/train/class_name/image.jpg
IMG_SIZE = (224, 224)
BATCH_SIZE = 32
EPOCHS = 20
LEARNING_RATE = 0.0001
# ---------------------

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
            f.write(labels[i] + '
')
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
    if not os.path.exists(DATASET_DIR):
        print(f"Error: Dataset directory '{DATASET_DIR}' not found.")
        print("Please create a 'dataset' folder with subfolders for each car model.")
        print("Example: dataset/Honda_Civic/image1.jpg")
    else:
        train()
