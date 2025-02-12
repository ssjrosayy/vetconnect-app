import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vet_profile.dart';

class VetProfileService {
  final CollectionReference _vetsCollection =
      FirebaseFirestore.instance.collection('vets');

  Future<void> createOrUpdateProfile(VetProfile profile) async {
    try {
      await _vetsCollection.doc(profile.id).set(
            profile.toMap(),
            SetOptions(merge: true),
          );
    } catch (e) {
      print('Error updating vet profile: $e');
      throw e;
    }
  }

  Future<VetProfile?> getVetProfile(String vetId) async {
    try {
      final doc = await _vetsCollection.doc(vetId).get();
      if (doc.exists) {
        return VetProfile.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      print('Error getting vet profile: $e');
      throw e;
    }
  }
}
