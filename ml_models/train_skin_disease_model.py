import tensorflow as tf
import numpy as np
import os
import json
from pathlib import Path
from tensorflow.keras.applications import MobileNetV2
import cv2
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter
import sys

# Define skin diseases for each animal type
SKIN_DISEASES = {
    "dog": [
        {"name": "Mange", "patterns": ["scaly", "red_patches", "hair_loss"]},
        {"name": "Hot Spots", "patterns": ["red_inflamed", "moist", "hair_loss"]},
        {"name": "Ringworm", "patterns": ["circular", "scaly", "red_edge"]},
        {
            "name": "Allergic Dermatitis",
            "patterns": ["red_patches", "bumps", "inflammation"],
        },
    ],
    "cat": [
        {
            "name": "Feline Acne",
            "patterns": ["black_spots", "red_bumps", "inflammation"],
        },
        {"name": "Ear Mites", "patterns": ["dark_debris", "inflammation", "scratches"]},
        {"name": "Ringworm", "patterns": ["circular", "scaly", "hair_loss"]},
        {
            "name": "Allergic Dermatitis",
            "patterns": ["red_patches", "scabs", "hair_loss"],
        },
    ],
}

# Create models directory
MODEL_DIR = os.path.join("..", "assets", "models")
os.makedirs(MODEL_DIR, exist_ok=True)


def create_base_skin_texture(size=(224, 224)):
    """Create a base skin texture"""
    texture = np.random.rand(*size) * 0.3 + 0.7  # Light colored base
    texture = cv2.GaussianBlur(texture, (7, 7), 0)
    return texture


def create_pattern(pattern_type, size=(224, 224)):
    """Create different disease patterns"""
    pattern = np.zeros(size)

    if pattern_type == "scaly":
        # Create scaly pattern with random polygons
        for _ in range(20):
            x = np.random.randint(0, size[0])
            y = np.random.randint(0, size[1])
            points = np.random.randint(0, size[0], (6, 2))
            cv2.fillPoly(pattern, [points], 1)

    elif pattern_type == "red_patches":
        # Create red, inflamed-looking patches
        for _ in range(5):
            x = np.random.randint(0, size[0])
            y = np.random.randint(0, size[1])
            radius = np.random.randint(20, 50)
            cv2.circle(pattern, (x, y), radius, 1, -1)

    elif pattern_type == "hair_loss":
        # Create patches of hair loss
        for _ in range(3):
            x = np.random.randint(0, size[0])
            y = np.random.randint(0, size[1])
            axes = (np.random.randint(30, 70), np.random.randint(30, 70))
            angle = np.random.randint(0, 360)
            cv2.ellipse(pattern, (x, y), axes, angle, 0, 360, 1, -1)

    elif pattern_type == "circular":
        # Create circular lesions (like ringworm)
        for _ in range(3):
            x = np.random.randint(0, size[0])
            y = np.random.randint(0, size[1])
            radius = np.random.randint(30, 60)
            cv2.circle(pattern, (x, y), radius, 1, 2)

    elif pattern_type == "bumps":
        # Create small bumps
        for _ in range(50):
            x = np.random.randint(0, size[0])
            y = np.random.randint(0, size[1])
            radius = np.random.randint(2, 5)
            cv2.circle(pattern, (x, y), radius, 1, -1)

    elif pattern_type == "inflammation":
        # Create diffuse inflammation
        pattern = cv2.GaussianBlur(np.random.rand(*size), (15, 15), 0)
        pattern = (pattern > 0.7).astype(np.float32)

    return pattern


def generate_synthetic_image(disease, animal_type):
    """Generate a synthetic image for a specific skin disease"""
    # Create base texture
    base = create_base_skin_texture()

    # Create RGB image
    image = np.stack([base, base, base], axis=-1)

    # Add disease-specific patterns
    for pattern_type in disease["patterns"]:
        pattern = create_pattern(pattern_type)

        if pattern_type in ["red_patches", "inflammation"]:
            # Add redness
            image[:, :, 0] = np.maximum(image[:, :, 0], pattern * 0.8)  # Red channel
            image[:, :, 1:] = np.minimum(
                image[:, :, 1:], 1 - pattern * 0.3
            )  # Reduce green/blue
        elif pattern_type in ["scaly", "hair_loss"]:
            # Modify texture
            image = image * (1 - pattern * 0.3)
        elif pattern_type == "circular":
            # Add ringworm-like patterns
            image = image * (1 - pattern * 0.2)
            image[:, :, 0] = np.maximum(
                image[:, :, 0], pattern * 0.6
            )  # Add redness to rings

    # Add noise and blur for realism
    noise = np.random.normal(0, 0.05, image.shape)
    image = np.clip(image + noise, 0, 1)
    image = cv2.GaussianBlur(image, (3, 3), 0)

    return (image * 255).astype(np.uint8)


def create_dataset(num_samples_per_class=100):
    """Create synthetic dataset for training"""
    X = []
    y = []
    label_mapping = {}
    current_label = 0

    for animal_type, diseases in SKIN_DISEASES.items():
        for disease in diseases:
            print(
                f"Generating {num_samples_per_class} samples for {animal_type} - {disease['name']}"
            )
            label_mapping[current_label] = f"{animal_type}_{disease['name']}"

            for _ in range(num_samples_per_class):
                image = generate_synthetic_image(disease, animal_type)
                X.append(image)
                y.append(current_label)

            current_label += 1

    # Save label mapping
    with open(os.path.join(MODEL_DIR, "skin_disease_metadata.json"), "w") as f:
        json.dump(
            {"diseases": SKIN_DISEASES, "label_mapping": label_mapping}, f, indent=2
        )

    return np.array(X), np.array(y)


def create_and_train_model():
    """Create and train the model"""
    print("Generating synthetic dataset...")
    X, y = create_dataset(num_samples_per_class=100)

    # Split into training and validation sets
    indices = np.random.permutation(len(X))
    split_idx = int(len(X) * 0.8)
    train_indices = indices[:split_idx]
    val_indices = indices[split_idx:]

    X_train, y_train = X[train_indices], y[train_indices]
    X_val, y_val = X[val_indices], y[val_indices]

    # Create model
    print("Creating model...")
    base_model = MobileNetV2(
        input_shape=(224, 224, 3), include_top=False, weights="imagenet"
    )
    base_model.trainable = False

    model = tf.keras.Sequential(
        [
            base_model,
            tf.keras.layers.GlobalAveragePooling2D(),
            tf.keras.layers.Dense(128, activation="relu"),
            tf.keras.layers.Dropout(0.2),
            tf.keras.layers.Dense(len(np.unique(y)), activation="softmax"),
        ]
    )

    # Compile model
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=0.001),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )

    # Train model
    print("Training model...")
    history = model.fit(
        X_train,
        y_train,
        validation_data=(X_val, y_val),
        epochs=10,
        batch_size=32,
        callbacks=[
            tf.keras.callbacks.EarlyStopping(
                monitor="val_loss", patience=3, restore_best_weights=True
            )
        ],
    )

    # Convert to TFLite
    print("Converting model to TFLite...")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    tflite_model = converter.convert()

    # Save model
    with open(os.path.join(MODEL_DIR, "skin_disease_model.tflite"), "wb") as f:
        f.write(tflite_model)

    return history


if __name__ == "__main__":
    print("=== Starting Skin Disease Model Training with Synthetic Data ===")
    try:
        history = create_and_train_model()
        print("\nTraining completed successfully!")
        print("\nModel performance metrics:")
        print(f"Final training accuracy: {history.history['accuracy'][-1]:.2f}")
        print(f"Final validation accuracy: {history.history['val_accuracy'][-1]:.2f}")
    except Exception as e:
        print(f"\nError during training: {str(e)}")
        sys.exit(1)
