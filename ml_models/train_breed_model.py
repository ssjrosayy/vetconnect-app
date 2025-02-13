import tensorflow as tf
import numpy as np
import os
import sys
import tarfile
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.preprocessing.image import ImageDataGenerator
import json
import requests
from PIL import Image
from pathlib import Path
import shutil
import zipfile
from sklearn.preprocessing import LabelEncoder
import cv2

# Define breeds for each animal type
BREEDS = {
    "dog": [
        "Labrador Retriever",
        "German Shepherd",
        "Golden Retriever",
        "Bulldog",
        "Beagle",
        "Rottweiler",
        "Poodle",
        "Yorkshire Terrier",
        "Boxer",
        "Dachshund",
        "Great Dane",
        "Doberman",
        "Siberian Husky",
        "Chihuahua",
        "Shih Tzu",
        "Pug",
    ],
    "cat": [
        "Persian",
        "Siamese",
        "Maine Coon",
        "Ragdoll",
        "Bengal",
        "British Shorthair",
        "Russian Blue",
        "Sphynx",
        "Abyssinian",
        "American Shorthair",
        "Scottish Fold",
        "Birman",
        "Oriental Shorthair",
        "Devon Rex",
        "Himalayan",
        "Burmese",
    ],
}

# Define directory structure
MODELS_DIR = r"C:\Users\hp\OneDrive\Desktop\vcgit\vetconnect-app\assets\models"
os.makedirs(MODELS_DIR, exist_ok=True)

# Get absolute paths
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
MODELS_DIR = os.path.join(os.path.dirname(SCRIPT_DIR), "assets", "models")

# Constants
MODEL_DIR = os.path.join("..", "assets", "models")
DATASET_ROOT = r"C:\Users\hp\Downloads\dataset"
DOG_DATASET_PATH = os.path.join(DATASET_ROOT, "dog breed", "images")
CAT_DATASET_PATH = os.path.join(DATASET_ROOT, "cat breed", "images")
IMAGE_SIZE = (224, 224)
BATCH_SIZE = 32


# Add debug function
def debug_info():
    print("\n=== Debug Information ===")
    print(f"Script location: {os.path.abspath(__file__)}")
    print(f"Current working directory: {os.getcwd()}")
    print(f"Models directory: {MODELS_DIR}")
    print(f"Directory exists: {os.path.exists(MODELS_DIR)}")
    print("=== End Debug Info ===\n")


def ensure_directories():
    try:
        if not os.path.exists(MODELS_DIR):
            print(f"Creating directory: {MODELS_DIR}")
            os.makedirs(MODELS_DIR)
            print("Directory created successfully")
        else:
            print(f"Directory already exists: {MODELS_DIR}")
    except Exception as e:
        print(f"Error creating directory: {str(e)}")
        raise


def create_model(num_classes):
    """Create and compile the model with improved architecture"""
    # Use EfficientNetB0 as base model (better performance than MobileNetV2)
    base_model = tf.keras.applications.EfficientNetB0(
        input_shape=(224, 224, 3), include_top=False, weights="imagenet"
    )

    # First train with base model frozen
    base_model.trainable = False

    # Add custom classification layers
    model = tf.keras.Sequential(
        [
            base_model,
            tf.keras.layers.GlobalAveragePooling2D(),
            tf.keras.layers.BatchNormalization(),
            tf.keras.layers.Dense(512, activation="relu"),
            tf.keras.layers.Dropout(0.5),
            tf.keras.layers.Dense(256, activation="relu"),
            tf.keras.layers.Dropout(0.3),
            tf.keras.layers.Dense(num_classes, activation="softmax"),
        ]
    )

    # Use a lower learning rate
    optimizer = tf.keras.optimizers.Adam(learning_rate=0.0001)

    model.compile(
        optimizer=optimizer,
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )

    return model, base_model


def create_training_data():
    print("Creating synthetic training data...")
    num_breeds = sum(len(breeds) for breeds in BREEDS.values())
    num_samples = 100 * num_breeds

    X = np.random.rand(num_samples, 224, 224, 3)
    y = np.zeros((num_samples, num_breeds))

    current_index = 0
    for breeds in BREEDS.values():
        for _ in range(len(breeds)):
            y[current_index : current_index + 100, current_index // 100] = 1
            current_index += 100

    print(f"Created {num_samples} synthetic samples")
    return X, y


def train_and_save_model():
    try:
        print("\nInitializing model...")
        base_model = MobileNetV2(
            input_shape=(224, 224, 3),
            include_top=False,
            weights=None,  # Faster for testing
        )

        # Calculate total number of breeds
        num_breeds = sum(len(breeds) for breeds in BREEDS.values())

        model = tf.keras.Sequential(
            [
                base_model,
                tf.keras.layers.GlobalAveragePooling2D(),
                tf.keras.layers.Dense(128, activation="relu"),
                tf.keras.layers.Dense(
                    num_breeds, activation="softmax"
                ),  # Add softmax activation
            ]
        )

        print("Compiling model...")
        model.compile(
            optimizer="adam",
            loss="categorical_crossentropy",  # Changed from sparse_categorical_crossentropy
            metrics=["accuracy"],
        )

        X, y = create_training_data()

        print("Training model...")
        model.fit(X, y, epochs=1, batch_size=32, verbose=1)

        # Save metadata first
        metadata_path = os.path.join(MODELS_DIR, "breed_metadata.json")
        print(f"\nSaving metadata to {metadata_path}")
        with open(metadata_path, "w") as f:
            json.dump(BREEDS, f, indent=2)
        print("✓ Metadata saved")

        # Save model
        model_path = os.path.join(MODELS_DIR, "breed_model.tflite")
        print(f"Converting and saving model to {model_path}")
        converter = tf.lite.TFLiteConverter.from_keras_model(model)
        tflite_model = converter.convert()

        with open(model_path, "wb") as f:
            f.write(tflite_model)
        print("✓ Model saved")

        return True

    except Exception as e:
        print(f"Error during training: {str(e)}")
        return False


def test_file_creation():
    """Test if we can create files in the models directory"""
    try:
        # Create test file
        test_file = os.path.join(MODELS_DIR, "test.txt")
        with open(test_file, "w") as f:
            f.write("test")
        print(f"✓ Successfully created test file: {test_file}")

        # Read test file
        with open(test_file, "r") as f:
            content = f.read()
        print(f"✓ Successfully read test file content: {content}")

        return True
    except Exception as e:
        print(f"✗ Failed to create/read test file: {str(e)}")
        return False


def create_and_save_model():
    try:
        # Create simple model for testing
        model = tf.keras.Sequential(
            [
                tf.keras.layers.Dense(64, activation="relu", input_shape=(224, 224, 3)),
                tf.keras.layers.Dense(32, activation="relu"),
                tf.keras.layers.Dense(
                    len(BREEDS["dog"]) + len(BREEDS["cat"]) + len(BREEDS["cattle"])
                ),
            ]
        )

        # Compile model
        model.compile(optimizer="adam", loss="categorical_crossentropy")

        # Create small synthetic dataset
        X = np.random.rand(10, 224, 224, 3)
        y = np.random.rand(
            10, len(BREEDS["dog"]) + len(BREEDS["cat"]) + len(BREEDS["cattle"])
        )

        # Quick train
        print("Training model...")
        model.fit(X, y, epochs=1)

        # Save metadata
        metadata_path = os.path.join(MODELS_DIR, "breed_metadata.json")
        print(f"Saving metadata to {metadata_path}")
        with open(metadata_path, "w") as f:
            json.dump(BREEDS, f, indent=2)
        print("✓ Metadata saved")

        # Save model
        model_path = os.path.join(MODELS_DIR, "breed_model.tflite")
        print(f"Saving model to {model_path}")
        converter = tf.lite.TFLiteConverter.from_keras_model(model)
        tflite_model = converter.convert()

        with open(model_path, "wb") as f:
            f.write(tflite_model)
        print("✓ Model saved")

        return True

    except Exception as e:
        print(f"Error during training: {str(e)}")
        return False


def download_and_extract_dataset():
    """Download and extract the Stanford Dogs and Oxford-IIIT Pet datasets"""
    # Stanford Dogs Dataset
    stanford_url = "http://vision.stanford.edu/aditya86/ImageNetDogs/images.tar"
    oxford_url = "https://www.robots.ox.ac.uk/~vgg/data/pets/data/images.tar.gz"

    datasets_dir = Path("datasets")
    datasets_dir.mkdir(exist_ok=True)

    for url in [stanford_url, oxford_url]:
        filename = url.split("/")[-1]
        filepath = datasets_dir / filename

        if not filepath.exists():
            print(f"Downloading {filename}...")
            response = requests.get(url, stream=True)
            with open(filepath, "wb") as f:
                for chunk in response.iter_content(chunk_size=8192):
                    f.write(chunk)

        print(f"Extracting {filename}...")
        if filename.endswith(".tar.gz"):
            with tarfile.open(filepath, "r:gz") as tar:
                tar.extractall(path=datasets_dir)
        elif filename.endswith(".tar"):
            with tarfile.open(filepath, "r") as tar:
                tar.extractall(path=datasets_dir)


def preprocess_image(image_path, target_size=(224, 224)):
    """Load and preprocess an image"""
    img = tf.keras.preprocessing.image.load_img(image_path, target_size=target_size)
    img_array = tf.keras.preprocessing.image.img_to_array(img)
    img_array = tf.keras.applications.mobilenet_v2.preprocess_input(img_array)
    return img_array


def create_dataset():
    """Create training and validation datasets"""
    train_data = []
    train_labels = []
    val_data = []
    val_labels = []

    datasets_dir = Path("datasets")

    # Process Stanford Dogs Dataset
    stanford_dir = datasets_dir / "Images"
    if stanford_dir.exists():
        print("Processing Stanford Dogs Dataset...")
        for breed_dir in stanford_dir.iterdir():
            if breed_dir.is_dir():
                breed_name = breed_dir.name.split("-")[1].replace("_", " ")
                # Only process if breed is in our BREEDS list
                if breed_name in BREEDS["dog"]:
                    images = list(breed_dir.glob("*.jpg"))

                    # Split into train and validation
                    split_idx = int(len(images) * 0.8)
                    train_images = images[:split_idx]
                    val_images = images[split_idx:]

                    # Process training images
                    for img_path in train_images:
                        try:
                            img_array = preprocess_image(str(img_path))
                            train_data.append(img_array)
                            train_labels.append(f"dog_{breed_name}")
                        except Exception as e:
                            print(f"Error processing {img_path}: {e}")

                    # Process validation images
                    for img_path in val_images:
                        try:
                            img_array = preprocess_image(str(img_path))
                            val_data.append(img_array)
                            val_labels.append(f"dog_{breed_name}")
                        except Exception as e:
                            print(f"Error processing {img_path}: {e}")

    # Process Oxford-IIIT Pet Dataset
    oxford_dir = datasets_dir / "oxford-iiit-pet" / "images"
    if oxford_dir.exists():
        print("Processing Oxford-IIIT Pet Dataset...")
        for img_path in oxford_dir.glob("*.jpg"):
            breed_name = img_path.stem.split("_")[0].replace("_", " ")
            # Check if it's a cat breed in our BREEDS list
            if breed_name in BREEDS["cat"]:
                try:
                    img_array = preprocess_image(str(img_path))
                    if np.random.random() < 0.8:  # 80% for training
                        train_data.append(img_array)
                        train_labels.append(f"cat_{breed_name}")
                    else:  # 20% for validation
                        val_data.append(img_array)
                        val_labels.append(f"cat_{breed_name}")
                except Exception as e:
                    print(f"Error processing {img_path}: {e}")

    if not train_data:
        raise Exception("No valid breed images found in the datasets")

    return (
        np.array(train_data),
        np.array(train_labels),
        np.array(val_data),
        np.array(val_labels),
    )


def train_model():
    """Train the model with improved training process"""
    print("Starting model training...")

    # Create data augmentation layer
    data_augmentation = tf.keras.Sequential(
        [
            tf.keras.layers.RandomFlip("horizontal"),
            tf.keras.layers.RandomRotation(0.2),
            tf.keras.layers.RandomZoom(0.2),
            tf.keras.layers.RandomBrightness(0.2),
            tf.keras.layers.RandomContrast(0.2),
        ]
    )

    # Load and preprocess data
    train_data, train_labels, val_data, val_labels = create_dataset()

    # Create label encoder
    label_encoder = LabelEncoder()
    train_labels_encoded = label_encoder.fit_transform(train_labels)
    val_labels_encoded = label_encoder.transform(val_labels)

    # Save label mapping
    label_mapping = {i: label for i, label in enumerate(label_encoder.classes_)}

    # Create model
    model, base_model = create_model(len(label_mapping))

    # First phase: Train with frozen base model
    print("Phase 1: Training top layers...")
    history1 = model.fit(
        data_augmentation(train_data),
        train_labels_encoded,
        validation_data=(val_data, val_labels_encoded),
        epochs=20,
        batch_size=32,
        callbacks=[
            tf.keras.callbacks.EarlyStopping(
                monitor="val_accuracy", patience=5, restore_best_weights=True
            )
        ],
    )

    # Second phase: Fine-tune the base model
    print("Phase 2: Fine-tuning EfficientNet layers...")
    base_model.trainable = True

    # Freeze batch norm layers
    for layer in base_model.layers:
        if isinstance(layer, tf.keras.layers.BatchNormalization):
            layer.trainable = False

    # Recompile with lower learning rate
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=0.00001),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )

    # Train again
    history2 = model.fit(
        data_augmentation(train_data),
        train_labels_encoded,
        validation_data=(val_data, val_labels_encoded),
        epochs=10,
        batch_size=16,
        callbacks=[
            tf.keras.callbacks.EarlyStopping(
                monitor="val_accuracy", patience=3, restore_best_weights=True
            )
        ],
    )

    # Convert to TFLite with better quantization
    print("Converting to TFLite format...")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_types = [tf.float32]

    # Add metadata about input requirements
    converter.target_spec.supported_ops = [
        tf.lite.OpsSet.TFLITE_BUILTINS,
        tf.lite.OpsSet.SELECT_TF_OPS,
    ]

    tflite_model = converter.convert()

    # Save the model and metadata
    model_path = os.path.join(MODEL_DIR, "breed_model.tflite")
    with open(model_path, "wb") as f:
        f.write(tflite_model)

    metadata = {
        "breeds": BREEDS,
        "label_mapping": label_mapping,
        "input_shape": [224, 224, 3],
        "preprocessing": {"rescale": "1./255", "resized_size": 224},
    }

    with open(os.path.join(MODEL_DIR, "breed_metadata.json"), "w") as f:
        json.dump(metadata, f, indent=2)

    print(f"Model saved to {model_path}")
    return history1, history2


def load_and_preprocess_dataset():
    """Load and preprocess the dataset from the specified folder structure"""
    breeds = {"dog": [], "cat": []}
    images = []
    labels = []
    label_mapping = {}
    current_label = 0

    # Process dog breeds
    print("\nProcessing dog breeds...")
    for breed_folder in os.listdir(DOG_DATASET_PATH):
        breed_path = os.path.join(DOG_DATASET_PATH, breed_folder)
        if os.path.isdir(breed_path):
            breeds["dog"].append(breed_folder)
            label_mapping[current_label] = f"dog_{breed_folder}"
            print(f"Processing dog breed: {breed_folder}")

            for img_file in os.listdir(breed_path):
                if img_file.lower().endswith((".png", ".jpg", ".jpeg")):
                    img_path = os.path.join(breed_path, img_file)
                    try:
                        img = cv2.imread(img_path)
                        if img is not None:
                            img = cv2.resize(img, IMAGE_SIZE)
                            img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
                            img = img.astype(np.float32) / 255.0
                            images.append(img)
                            labels.append(current_label)
                    except Exception as e:
                        print(f"Error processing {img_path}: {e}")
            current_label += 1

    # Process cat breeds
    print("\nProcessing cat breeds...")
    for breed_folder in os.listdir(CAT_DATASET_PATH):
        breed_path = os.path.join(CAT_DATASET_PATH, breed_folder)
        if os.path.isdir(breed_path):
            breeds["cat"].append(breed_folder)
            label_mapping[current_label] = f"cat_{breed_folder}"
            print(f"Processing cat breed: {breed_folder}")

            for img_file in os.listdir(breed_path):
                if img_file.lower().endswith((".png", ".jpg", ".jpeg")):
                    img_path = os.path.join(breed_path, img_file)
                    try:
                        img = cv2.imread(img_path)
                        if img is not None:
                            img = cv2.resize(img, IMAGE_SIZE)
                            img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
                            img = img.astype(np.float32) / 255.0
                            images.append(img)
                            labels.append(current_label)
                    except Exception as e:
                        print(f"Error processing {img_path}: {e}")
            current_label += 1

    # Save breed metadata
    metadata = {"breeds": breeds, "label_mapping": label_mapping}
    os.makedirs(MODEL_DIR, exist_ok=True)
    with open(os.path.join(MODEL_DIR, "breed_metadata.json"), "w") as f:
        json.dump(metadata, f, indent=2)

    return np.array(images), np.array(labels), len(label_mapping)


if __name__ == "__main__":
    print("=== Starting Breed Model Training with Real Data (Dogs and Cats) ===")
    try:
        history = train_model()
        print("\nTraining completed successfully!")
        print("\nModel performance metrics:")
        print(f"Final training accuracy: {history[0].history['accuracy'][-1]:.2f}")
        print(
            f"Final validation accuracy: {history[0].history['val_accuracy'][-1]:.2f}"
        )
    except Exception as e:
        print(f"\nError during training: {str(e)}")
        sys.exit(1)
