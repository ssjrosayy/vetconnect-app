import 'package:flutter/material.dart';
import 'package:vet_connect/pet_records.dart';


class PetProfilePage extends StatelessWidget {
  final String image;
  final String name;
  final String type;
  final String age;
  final String gender;
  final String weight;
  final String color;
  final String breed;

  const PetProfilePage({
    super.key,
    required this.image,
    required this.name,
    required this.type,
    required this.age,
    required this.gender,
    required this.weight,
    required this.color,
    required this.breed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (image != '')
              Image.network(
                image,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                color: Colors.grey[200],
                child: Icon(
                  Icons.pets,
                  size: 100,
                  color: Colors.grey[400],
                ),
              ),
            const SizedBox(height: 16),
            Text(
              name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              type,
              style: const TextStyle(fontSize: 18, color: Colors.purple),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoCard('Age', age),
                _buildInfoCard('Gender', gender),
                _buildInfoCard('Weight', weight),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Additional Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildAdditionalInfo('Color', color),
            _buildAdditionalInfo('Breed', breed),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PetRecordsPage(petId: name),  // Pass any necessary identifier
                    ),
                  );
                },
                child: const Text("Medical Records"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String info) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, color: Colors.purple),
            ),
            const SizedBox(height: 8),
            Text(
              info,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfo(String title, String info) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$title: ',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            info,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
