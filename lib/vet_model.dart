class VetModel {
  String id;
  String name;
  String specialization;
  String experience;
  String location;
  String about;
  String phoneNumber;
  String email;
  String website;
  String imagePath;
  String openingTime;
  String closingTime;
  bool isEmergencyAvailable;

  VetModel({
    this.id = '',
    required this.name,
    required this.specialization,
    required this.experience,
    required this.location,
    this.about = '',
    required this.phoneNumber,
    required this.email,
    required this.website,
    this.imagePath = '',
    required this.openingTime,
    required this.closingTime,
    this.isEmergencyAvailable = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'specialization': specialization,
      'experience': experience,
      'location': location,
      'about': about,
      'phoneNumber': phoneNumber,
      'email': email,
      'website': website,
      'imagePath': imagePath,
      'openingTime': openingTime,
      'closingTime': closingTime,
      'isEmergencyAvailable': isEmergencyAvailable,
    };
  }

  factory VetModel.fromJson(Map<String, dynamic> json) {
    return VetModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      specialization: json['specialization'] ?? '',
      experience: json['experience'] ?? '',
      location: json['location'] ?? '',
      about: json['about'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'] ?? '',
      website: json['website'] ?? '',
      imagePath: json['imagePath'] ?? '',
      openingTime: json['openingTime'] ?? '',
      closingTime: json['closingTime'] ?? '',
      isEmergencyAvailable: json['isEmergencyAvailable'] ?? false,
    );
  }
}
