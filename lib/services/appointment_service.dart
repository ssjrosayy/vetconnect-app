import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment.dart';

class AppointmentService {
  final CollectionReference _appointmentsCollection =
      FirebaseFirestore.instance.collection('appointments');

  Future<String> createAppointment(Appointment appointment) async {
    try {
      final docRef = await _appointmentsCollection.add(appointment.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating appointment: $e');
      throw e;
    }
  }

  Future<void> updateAppointmentStatus(
      String appointmentId, String status) async {
    try {
      await _appointmentsCollection.doc(appointmentId).update({
        'status': status,
      });
    } catch (e) {
      print('Error updating appointment status: $e');
      throw e;
    }
  }

  Stream<List<Appointment>> getVetAppointments(String vetId) {
    return _appointmentsCollection
        .where('vetId', isEqualTo: vetId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Appointment.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }

  Stream<List<Appointment>> getPetOwnerAppointments(String petOwnerId) {
    return _appointmentsCollection
        .where('petOwnerId', isEqualTo: petOwnerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Appointment.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }
}
