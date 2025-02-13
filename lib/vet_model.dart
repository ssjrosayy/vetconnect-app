class VetModel {
  final String id;
  final String name;
  final String specialization;
  final String experience;
  final String location;
  final String about;
  final String phoneNumber;
  final String email;
  final String website;
  final String openingTime;
  final String closingTime;
  final String imagePath;
  final bool isEmergencyAvailable;
  final Map<String, Map<String, bool>> availableSlots;

  VetModel({
    this.id = '',
    required this.name,
    required this.specialization,
    required this.experience,
    required this.location,
    required this.about,
    required this.phoneNumber,
    required this.email,
    required this.website,
    required this.openingTime,
    required this.closingTime,
    required this.imagePath,
    required this.isEmergencyAvailable,
    this.availableSlots = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'specialization': specialization,
      'experience': experience,
      'location': location,
      'about': about,
      'phoneNumber': phoneNumber,
      'email': email,
      'website': website,
      'openingTime': openingTime,
      'closingTime': closingTime,
      'imagePath': imagePath,
      'isEmergencyAvailable': isEmergencyAvailable,
      'availableSlots': availableSlots,
    };
  }

  // Alias for toMap() for backward compatibility
  Map<String, dynamic> toJson() => toMap();

  factory VetModel.fromMap(String id, Map<String, dynamic> map) {
    return VetModel(
      id: id,
      name: map['name'] ?? '',
      specialization: map['specialization'] ?? '',
      experience: map['experience'] ?? '',
      location: map['location'] ?? '',
      about: map['about'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      email: map['email'] ?? '',
      website: map['website'] ?? '',
      openingTime: map['openingTime'] ?? '',
      closingTime: map['closingTime'] ?? '',
      imagePath: map['imagePath'] ?? '',
      isEmergencyAvailable: map['isEmergencyAvailable'] ?? false,
      availableSlots: (map['availableSlots'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              (value as Map<String, dynamic>).map(
                (k, v) => MapEntry(k, v as bool),
              ),
            ),
          ) ??
          {},
    );
  }
}
