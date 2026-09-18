import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../logic/subnet_calculator.dart';
import '../../logic/supernet_calculator.dart';
import '../../models/subnet_info.dart';
import '../widgets/result_table.dart';

const _prefsNetworksKey = 'supernet_networks';

class _NetworkRow {
  final int id;
  final TextEditingController controller;

  _NetworkRow(this.id, {String value = ''})
      : controller = TextEditingController(text: value);

  void dispose() => controller.dispose();
}

class SupernetCalculatorTab extends StatefulWidget {
  const SupernetCalculatorTab({super.key});

  @override
  State<SupernetCalculatorTab> createState() => _SupernetCalculatorTabState();
}

class _SupernetCalculatorTabState extends State<SupernetCalculatorTab> {
  final _formKey = GlobalKey<FormState>();

  var _nextRowId = 0;
  late List<_NetworkRow> _rows;

  SubnetInfo? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _rows = [
      _NetworkRow(_nextRowId++, value: '192.168.0.0/24'),
      _NetworkRow(_nextRowId++, value: '192.168.1.0/24'),
      _NetworkRow(_nextRowId++, value: '192.168.2.0/24'),
      _NetworkRow(_nextRowId++, value: '192.168.3.0/24'),
    ];
    _restoreLastInput();
  }

  Future<void> _restoreLastInput() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_prefsNetworksKey);
    if (!mounted || saved == null || saved.length < 2) return;
    setState(() {
      for (final row in _rows) {
        row.dispose();
      }
      _rows = [for (final value in saved) _NetworkRow(_nextRowId++, value: value)];
    });
  }

  Future<void> _rememberInput() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsNetworksKey,
      [for (final row in _rows) row.controller.text.trim()],
    );
  }

  String? _validateNetwork(String? value) {
    if (value == null || value.trim().isEmpty) return 'Champ requis';
    try {
      SubnetCalculator.calculateFromCidr(value.trim());
      return null;
    } on FormatException catch (e) {
      return e.message;
    }
  }

  void _addRow() {
    setState(() {
      _rows.add(_NetworkRow(_nextRowId++));
    });
  }

  void _removeRow(_NetworkRow row) {
    setState(() {
      row.dispose();
      _rows.remove(row);
    });
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      try {
        _result = SupernetCalculator.summarize(
          [for (final row in _rows) row.controller.text.trim()],
        );
        _error = null;
        _rememberInput();
      } on FormatException catch (e) {
        _result = null;
        _error = e.message;
      }
    });
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Reseaux a regrouper (format ip/prefixe)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final row in _rows)
              Padding(
                key: ValueKey(row.id),
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: row.controller,
                        decoration: const InputDecoration(
                          hintText: '192.168.1.0/24',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: _validateNetwork,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      tooltip: 'Retirer ce reseau',
                      onPressed: _rows.length > 2 ? () => _removeRow(row) : null,
                    ),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addRow,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un reseau'),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _calculate,
              icon: const Icon(Icons.merge_type),
              label: const Text('Regrouper (supernetting)'),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (_result != null) ...[
              Text(
                'Plus petit bloc englobant tous les reseaux ci-dessus :',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              ResultTable(info: _result!),
            ],
          ],
        ),
      ),
    );
  }
}
