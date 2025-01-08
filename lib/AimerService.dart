import 'package:cloud_firestore/cloud_firestore.dart';
import 'Aimer.dart';

class AimerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _aimerCollection = FirebaseFirestore.instance.collection('aimers');

  // Create a new Aimer
  Future<void> createAimer(Aimer aimer) async {
    try {
      await _aimerCollection.add(aimer.toFirestore());
    } catch (e) {
      print('Error creating Aimer: $e');
    }
  }

  // Read all Aimers
  Future<List<Aimer>> getAllAimers() async {
    try {
      QuerySnapshot querySnapshot = await _aimerCollection.get();
      return querySnapshot.docs
          .map((doc) => Aimer.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting Aimers: $e');
      return [];
    }
  }

  // Update an existing Aimer
  Future<void> updateAimer(String id, Aimer aimer) async {
    try {
      await _aimerCollection.doc(id).update(aimer.toFirestore());
    } catch (e) {
      print('Error updating Aimer: $e');
    }
  }

  // Delete an Aimer
  Future<void> deleteAimer(String id) async {
    try {
      await _aimerCollection.doc(id).delete();
    } catch (e) {
      print('Error deleting Aimer: $e');
    }
  }
}
