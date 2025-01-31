class VetModel {
  String id; // Add an ID to the model
  String name;
  String description;
  String address;
  String openingTime;
  String website;
  String phone;
  String email;
  String imagePath; 
  bool isEmergencyAvailable;

  VetModel({
    this.id = '', // Default to an empty ID if not provided
    required this.name,
    required this.description,
    required this.address,
    required this.openingTime,
    required this.website,
    required this.phone,
    required this.email,
    required this.imagePath,
    required this.isEmergencyAvailable,
    required String closingTime,
  });

  get closingTime => null;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'address': address,
      'openingTime': openingTime,
      'website': website,
      'phone': phone,
      'email': email,
      'imagePath': imagePath,
      'isEmergencyAvailable': isEmergencyAvailable,
    };
  }

  factory VetModel.fromJson(Map<String, dynamic> json) {
    return VetModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      address: json['address'] ?? '',
      openingTime: json['openingTime'] ?? '',
      website: json['website'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      imagePath: json['imagePath'] ?? '',
      isEmergencyAvailable: json['isEmergencyAvailable'] ?? false,
      closingTime: '',
    );
  }
}
