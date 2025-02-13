import tensorflow as tf
import numpy as np
import json
import os
from pathlib import Path
import random

# Get absolute paths
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_DIR = os.path.join(os.path.dirname(SCRIPT_DIR), "assets", "models")
os.makedirs(MODEL_DIR, exist_ok=True)


def load_metadata():
    """Load the symptoms metadata file"""
    metadata_path = os.path.join(MODEL_DIR, "symptoms_metadata.json")
    try:
        print(f"Looking for metadata file at: {metadata_path}")
        if not os.path.exists(metadata_path):
            raise FileNotFoundError(f"Metadata file not found at {metadata_path}")

        with open(metadata_path, "r") as f:
            return json.load(f)
    except Exception as e:
        print(f"Error loading metadata: {str(e)}")
        raise


def generate_synthetic_data(metadata, samples_per_disease=1000):
    """Generate synthetic training data based on metadata"""
    all_data = []
    all_labels = []
    label_mapping = {}
    current_label = 0

    # Create a combined set of all symptoms
    all_symptoms = set()
    for animal_type in ["dog", "cat"]:
        all_symptoms.update(metadata["symptoms"][animal_type])
    all_symptoms = sorted(
        list(all_symptoms)
    )  # Convert to sorted list for consistent ordering

    print(f"\nTotal unique symptoms across all animals: {len(all_symptoms)}")

    # Create symptom index mapping for quick lookup
    symptom_to_index = {symptom: idx for idx, symptom in enumerate(all_symptoms)}

    for animal_type in ["dog", "cat"]:
        diseases = metadata["diseases"][animal_type]
        print(f"\nProcessing {animal_type} diseases...")
        print(f"Number of diseases: {len(diseases)}")

        for disease in diseases:
            label_mapping[current_label] = f"{animal_type}_{disease['name']}"
            disease_symptoms = set(disease["symptoms"])

            print(f"Generating samples for {disease['name']}...")
            for _ in range(samples_per_disease):
                # Create symptom vector for all possible symptoms
                symptom_vector = np.zeros(len(all_symptoms), dtype=np.float32)

                # Add core symptoms (70-100% chance)
                for symptom in disease_symptoms:
                    if symptom in symptom_to_index:  # Check if symptom exists
                        if random.random() < 0.7:
                            symptom_vector[symptom_to_index[symptom]] = 1.0

                # Add random non-core symptoms (5% chance)
                for symptom in all_symptoms:
                    if symptom not in disease_symptoms and random.random() < 0.05:
                        symptom_vector[symptom_to_index[symptom]] = 1.0

                all_data.append(symptom_vector)
                all_labels.append(current_label)

            current_label += 1

    print(f"\nTotal number of samples: {len(all_data)}")
    print(f"Total number of diseases: {current_label}")
    print(f"Feature vector size: {len(all_symptoms)}")

    # Convert to numpy arrays
    X = np.array(all_data, dtype=np.float32)
    y = np.array(all_labels, dtype=np.int32)

    # Save label mapping and symptom information
    metadata_to_save = {
        "label_mapping": label_mapping,
        "symptoms": all_symptoms,
        "symptom_to_index": symptom_to_index,
    }

    with open(os.path.join(MODEL_DIR, "symptom_label_mapping.json"), "w") as f:
        json.dump(metadata_to_save, f, indent=2)

    return X, y


def create_model(input_dim, num_classes):
    """Create and compile the model"""
    model = tf.keras.Sequential(
        [
            tf.keras.layers.Dense(256, activation="relu", input_shape=(input_dim,)),
            tf.keras.layers.Dropout(0.3),
            tf.keras.layers.Dense(128, activation="relu"),
            tf.keras.layers.Dropout(0.2),
            tf.keras.layers.Dense(64, activation="relu"),
            tf.keras.layers.Dense(num_classes, activation="softmax"),
        ]
    )

    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=0.001),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )

    return model


def train_model():
    """Train the model with synthetic data"""
    print("Loading metadata...")
    metadata = load_metadata()

    print("Generating synthetic training data...")
    X, y = generate_synthetic_data(metadata)

    print(f"Generated {len(X)} training samples for {len(np.unique(y))} diseases")

    # Split the data manually
    indices = np.random.permutation(len(X))
    split_idx = int(len(X) * 0.8)
    train_indices = indices[:split_idx]
    val_indices = indices[split_idx:]

    X_train, y_train = X[train_indices], y[train_indices]
    X_val, y_val = X[val_indices], y[val_indices]

    # Create and train model
    print("Training model...")
    model = create_model(X.shape[1], len(np.unique(y)))

    history = model.fit(
        X_train,
        y_train,
        validation_data=(X_val, y_val),
        epochs=50,
        batch_size=32,
        callbacks=[
            tf.keras.callbacks.EarlyStopping(
                monitor="val_loss", patience=5, restore_best_weights=True
            )
        ],
    )

    # Convert to TFLite
    print("Converting to TFLite format...")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)

    # Set optimization options
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_types = [tf.float32]

    # Ensure consistent input/output shapes
    input_shape = (1, X.shape[1])  # batch_size=1, num_symptoms
    output_shape = (1, len(np.unique(y)))  # batch_size=1, num_diseases

    print(f"Input shape: {input_shape}")
    print(f"Output shape: {output_shape}")

    # Convert and save metadata
    tflite_model = converter.convert()

    # Save the model
    model_path = os.path.join(MODEL_DIR, "symptom_model.tflite")
    with open(model_path, "wb") as f:
        f.write(tflite_model)

    # Save input/output shape information
    shape_info = {
        "input_shape": list(input_shape),
        "output_shape": list(output_shape),
        "input_type": "float32",
        "output_type": "float32",
    }

    with open(os.path.join(MODEL_DIR, "symptom_model_info.json"), "w") as f:
        json.dump(shape_info, f, indent=2)

    print(f"Model saved to {model_path}")
    print(f"Model info saved with shapes: input{input_shape}, output{output_shape}")
    return history


if __name__ == "__main__":
    print("=== Starting Symptom Model Training with Synthetic Data ===")
    history = train_model()
    print("Training completed successfully!")
