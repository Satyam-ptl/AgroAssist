import 'package:flutter/material.dart';

class CalculatorScreen extends StatefulWidget {
  final Map<String, dynamic> crop;

  const CalculatorScreen({required this.crop, super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final TextEditingController _areaController = TextEditingController();
  String _unit = 'Acres';

  @override
  void dispose() {
    _areaController.dispose();
    super.dispose();
  }

  double _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  double? get _areaInput {
    final text = _areaController.text.trim();
    if (text.isEmpty) {
      return null;
    }
    return double.tryParse(text);
  }

  double get _areaHectares {
    final area = _areaInput ?? 0;
    if (_unit == 'Hectares') {
      return area;
    }
    if (_unit == 'Bigha') {
      return area * 0.165;
    }
    return area * 0.4047;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cropName = (widget.crop['name'] ?? '').toString();
    final season = (widget.crop['season'] ?? '').toString();
    final growthDays = (widget.crop['growth_duration_days'] ?? '').toString();
    final fertilizer = (widget.crop['fertilizer_required'] ?? 'NPK').toString();
    final expectedYieldPerHectare = _toDouble(widget.crop['expected_yield_per_hectare']);
    final waterMmPerWeek = _toDouble(widget.crop['water_required_mm_per_week']);

    final hasArea = (_areaInput ?? 0) > 0;
    final seedsKg = _areaHectares * 25;
    final litresPerWeek = _areaHectares * waterMmPerWeek * 10000 / 1000;
    final litresPerDay = litresPerWeek / 7;
    final fertilizerKg = _areaHectares * 50;
    final splitFertilizer = fertilizerKg / 3;
    final expectedYieldKg = _areaHectares * expectedYieldPerHectare;
    final expectedYieldTonne = expectedYieldKg / 1000;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Input Calculator - $cropName',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.04,
            vertical: size.width * 0.04,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter Your Land Area',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              SizedBox(height: size.width * 0.03),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _areaController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Land Area',
                        hintText: 'e.g. 2.5',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  SizedBox(width: size.width * 0.03),
                  SizedBox(
                    width: 120,
                    child: DropdownButtonFormField<String>(
                      initialValue: _unit,
                      items: const [
                        DropdownMenuItem(value: 'Acres', child: Text('Acres', overflow: TextOverflow.ellipsis, maxLines: 1)),
                        DropdownMenuItem(value: 'Hectares', child: Text('Hectares', overflow: TextOverflow.ellipsis, maxLines: 1)),
                        DropdownMenuItem(value: 'Bigha', child: Text('Bigha', overflow: TextOverflow.ellipsis, maxLines: 1)),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _unit = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: size.width * 0.02),
              const Text(
                '1 Acre = 0.4047 Hectares',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
              const Text(
                '1 Bigha = 0.165 Hectares (varies by region)',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
              SizedBox(height: size.width * 0.04),
              Card(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.04,
                    vertical: size.width * 0.03,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Crop Info',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: size.width * 0.02),
                      _infoRow('Crop', cropName),
                      _infoRow('Season', season),
                      _infoRow('Growth Duration', '$growthDays days'),
                      _infoRow('Expected Yield', '${expectedYieldPerHectare.toStringAsFixed(2)} kg/hectare'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: size.width * 0.04),
              if (hasArea) ...[
                _resultCard(
                  color: Colors.green,
                  title: 'Seeds Required',
                  lines: [
                    '${seedsKg.toStringAsFixed(2)} kg of seeds needed',
                  ],
                ),
                _resultCard(
                  color: Colors.blue,
                  title: 'Water Required',
                  lines: [
                    '${litresPerWeek.toStringAsFixed(2)} litres per week',
                    '${litresPerDay.toStringAsFixed(2)} litres per day',
                  ],
                ),
                _resultCard(
                  color: Colors.orange,
                  title: 'Fertilizer Required',
                  lines: [
                    '${fertilizerKg.toStringAsFixed(2)} kg of $fertilizer needed',
                    'Apply in 3 splits: ${splitFertilizer.toStringAsFixed(2)} kg each time',
                  ],
                ),
                _resultCard(
                  color: Colors.purple,
                  title: 'Expected Yield',
                  lines: [
                    'Expected harvest: ${expectedYieldKg.toStringAsFixed(2)} kg',
                    'Approx. ${expectedYieldTonne.toStringAsFixed(2)} tonnes',
                  ],
                ),
              ],
              SizedBox(height: size.width * 0.04),
              SizedBox(
                width: size.width,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _areaController.clear();
                    setState(() {
                      _unit = 'Acres';
                    });
                  },
                  icon: const Icon(Icons.restart_alt),
                  label: const Text(
                    'Reset',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultCard({
    required Color color,
    required String title,
    required List<String> lines,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withValues(alpha: 0.08),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(fontWeight: FontWeight.w700, color: color),
            ),
            const SizedBox(height: 8),
            ...lines.map(
              (line) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    line,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
