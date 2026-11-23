import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/gear_item.dart';

class WeightCalcScreen extends StatefulWidget {
  const WeightCalcScreen({super.key});

  @override
  State<WeightCalcScreen> createState() => _WeightCalcScreenState();
}

class _WeightCalcScreenState extends State<WeightCalcScreen> {
  List<GearItem> _gears = [];
  final Set<int> _selectedGearIds = {};
  final double _maxSafeWeight = 20.0;

  @override
  void initState() {
    super.initState();
    _loadGears();
  }

  Future<void> _loadGears() async {
    final gears = await DatabaseHelper.instance.getAllGears();
    setState(() => _gears = gears);
  }

  double get _totalWeight {
    return _gears
        .where((gear) => _selectedGearIds.contains(gear.id))
        .fold(0.0, (sum, item) => sum + item.weightKg);
  }

  @override
  Widget build(BuildContext context) {
    final bool isOverweight = _totalWeight > _maxSafeWeight;
    final bool isWarning =
        _totalWeight >= 15.0 && _totalWeight <= _maxSafeWeight;

    Color statusColor = Colors.green;
    String statusMessage = 'Beban Aman & Ideal untuk Pendakian';

    if (isOverweight) {
      statusColor = Colors.red;
      statusMessage = 'PERINGATAN: Beban Melebihi Batas Aman Carrier (20 kg)!';
    } else if (isWarning) {
      statusColor = Colors.orange;
      statusMessage = 'Perhatian: Beban Mendekati Batas Aman Carrier.';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Weight Calculator'),
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _selectedGearIds.clear()),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              border: Border.all(color: statusColor, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'Estimasi Total Bobot Bawaan',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_totalWeight.toStringAsFixed(1)} kg / ${_maxSafeWeight.toStringAsFixed(0)} kg',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: (_totalWeight / _maxSafeWeight).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[300],
                  color: statusColor,
                  minHeight: 10,
                ),
                const SizedBox(height: 10),
                Text(
                  statusMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _gears.length,
              itemBuilder: (context, index) {
                final gear = _gears[index];
                final isChecked = _selectedGearIds.contains(gear.id);
                return CheckboxListTile(
                  activeColor: const Color(0xFF1B4332),
                  title: Text(
                    gear.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('Kategori: ${gear.category}'),
                  secondary: Chip(label: Text('${gear.weightKg} kg')),
                  value: isChecked,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true && gear.id != null) {
                        _selectedGearIds.add(gear.id!);
                      } else {
                        _selectedGearIds.remove(gear.id);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
