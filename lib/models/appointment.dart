import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String id;
  final String vetId;
  final String petOwnerId;
  final String petId;
  final DateTime appointmentDate;
  final String status; // 'pending', 'confirmed', 'cancelled'
  final String? notes;

  Appointment({
    required this.id,
    required this.vetId,
    required this.petOwnerId,
    required this.petId,
    required this.appointmentDate,
    required this.status,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'vetId': vetId,
      'petOwnerId': petOwnerId,
      'petId': petId,
      'appointmentDate': Timestamp.fromDate(appointmentDate),
      'status': status,
      'notes': notes,
    };
  }

  static Appointment fromMap(Map<String, dynamic> map, String id) {
    return Appointment(
      id: id,
      vetId: map['vetId'],
      petOwnerId: map['petOwnerId'],
      petId: map['petId'],
      appointmentDate: (map['appointmentDate'] as Timestamp).toDate(),
      status: map['status'],
      notes: map['notes'],
    );
  }
}
