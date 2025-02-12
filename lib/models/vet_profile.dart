class VetProfile {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String specialization;
  final String experience;
  final String clinicAddress;
  final String? imageUrl;
  final bool isAvailable;

  VetProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.specialization,
    required this.experience,
    required this.clinicAddress,
    this.imageUrl,
    this.isAvailable = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'specialization': specialization,
      'experience': experience,
      'clinicAddress': clinicAddress,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
    };
  }

  static VetProfile fromMap(Map<String, dynamic> map, String id) {
    return VetProfile(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      specialization: map['specialization'] ?? '',
      experience: map['experience'] ?? '',
      clinicAddress: map['clinicAddress'] ?? '',
      imageUrl: map['imageUrl'],
      isAvailable: map['isAvailable'] ?? true,
    );
  }
}
