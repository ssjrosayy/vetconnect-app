import 'package:flutter/material.dart';
import '../ml/symptom_analyzer.dart';

class SymptomAnalyzerScreen extends StatefulWidget {
  const SymptomAnalyzerScreen({Key? key}) : super(key: key);

  @override
  State<SymptomAnalyzerScreen> createState() => _SymptomAnalyzerScreenState();
}

class _SymptomAnalyzerScreenState extends State<SymptomAnalyzerScreen> {
  final SymptomAnalyzer _analyzer = SymptomAnalyzer();
  String? _selectedAnimal;
  Map<String, bool> _selectedSymptoms = {};
  String _result = '';
  bool _isAnalyzing = false;
  bool _showResult = false;
  String _risk = 'UNKNOWN';

  @override
  void initState() {
    super.initState();
    _initializeAnalyzer();
  }

  Future<void> _initializeAnalyzer() async {
    try {
      print('Starting symptom analyzer initialization...');
      await _analyzer.loadModel();
      print('Symptom analyzer initialized successfully');
      setState(() {
        // Initialize with dog as default
        _selectedAnimal = 'dog';
        _loadSymptoms();
      });
    } catch (e, stackTrace) {
      print('Error initializing symptom analyzer: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize symptom analyzer: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadSymptoms() async {
    if (_selectedAnimal != null) {
      try {
        print('Loading symptoms for $_selectedAnimal');
        final symptoms = _analyzer.getSymptoms(_selectedAnimal!);
        print('Got symptoms: $symptoms');
        setState(() {
          _selectedSymptoms = Map.fromIterable(
            symptoms,
            key: (item) => item as String,
            value: (_) => false,
          );
          print('Updated selected symptoms: $_selectedSymptoms');
        });
      } catch (e) {
        print('Error loading symptoms: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading symptoms: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getRiskColor(String risk) {
    switch (risk.toUpperCase()) {
      case 'CRITICAL':
        return Colors.red;
      case 'HIGH':
        return Colors.orange;
      case 'MEDIUM':
        return Colors.yellow;
      case 'LOW':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildAnimalSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select Your Pet Type',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAnimalCard('Dog', Icons.pets),
                _buildAnimalCard('Cat', Icons.pets),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimalCard(String animal, IconData icon) {
    final isSelected = _selectedAnimal?.toLowerCase() == animal.toLowerCase();

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAnimal = animal.toLowerCase();
          _selectedSymptoms.clear();
          _showResult = false;
          _result = '';
          _risk = 'UNKNOWN';
          _loadSymptoms();
        });
      },
      child: Card(
        elevation: isSelected ? 8 : 2,
        color: isSelected ? Theme.of(context).primaryColor : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(
                icon,
                size: 48,
                color: isSelected ? Colors.white : Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                animal,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSymptomsList() {
    if (_selectedSymptoms.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select Symptoms for your ${_selectedAnimal?.toUpperCase()}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _selectedSymptoms.length,
              itemBuilder: (context, index) {
                final symptom = _selectedSymptoms.keys.elementAt(index);
                return CheckboxListTile(
                  title: Text(
                    symptom.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(fontSize: 16),
                  ),
                  value: _selectedSymptoms[symptom],
                  activeColor: Theme.of(context).primaryColor,
                  onChanged: (bool? value) {
                    setState(() {
                      _selectedSymptoms[symptom] = value ?? false;
                      _showResult = false;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _selectedSymptoms.values.any((selected) => selected)
                  ? _analyzeSymptoms
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isAnalyzing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'ANALYZE SYMPTOMS',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _analyzeSymptoms() async {
    print('Starting symptom analysis...');
    print('Selected animal: $_selectedAnimal');
    print('Selected symptoms: $_selectedSymptoms');

    if (_selectedSymptoms.isEmpty || !_selectedSymptoms.values.any((v) => v)) {
      print('No symptoms selected');
      setState(() {
        _result = 'Please select at least one symptom';
        _risk = 'LOW';
        _showResult = true;
      });
      return;
    }

    try {
      setState(() {
        _isAnalyzing = true;
        _result = 'Analyzing symptoms...';
        _showResult = true;
      });

      print('Calling analyzer.analyzeSymptoms...');
      final result = await _analyzer.analyzeSymptoms(
        _selectedAnimal!,
        Map.from(_selectedSymptoms),
      );
      print('Analysis result: $result');

      if (!mounted) return;

      setState(() {
        _isAnalyzing = false;
        _result = result['details'] ??
            '''Predicted condition: ${result['disease']}
Risk Level: ${result['risk']}
Confidence: ${(result['confidence'] * 100).toStringAsFixed(1)}%''';
        _risk = result['risk'];
        _showResult = true;
      });
      print('Updated state with result: $_result, risk: $_risk');
    } catch (e, stackTrace) {
      print('Error in _analyzeSymptoms: $e');
      print('Stack trace: $stackTrace');
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _result = 'Error analyzing symptoms: $e';
        _risk = 'UNKNOWN';
        _showResult = true;
      });

      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Widget _buildResult() {
    if (!_showResult || _result.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Analysis Result',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getRiskColor(_risk),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _risk,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _result,
              style: const TextStyle(fontSize: 16),
            ),
            if (_risk == 'CRITICAL' || _risk == 'HIGH')
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement emergency contact functionality
                  },
                  icon: const Icon(Icons.emergency),
                  label: const Text('CONTACT EMERGENCY VET'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAnimalSelection(),
          if (_selectedAnimal != null) ...[
            const SizedBox(height: 16),
            _buildSymptomsList(),
          ],
          if (_showResult) ...[
            const SizedBox(height: 16),
            _buildResult(),
          ],
        ],
      ),
    );
  }
}
