import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../logic/subnet_calculator.dart';
import '../../models/ip_address.dart';
import '../../models/subnet_info.dart';
import '../../models/subnet_mask.dart';
import '../widgets/result_table.dart';

const _prefsIpKey = 'simple_ip';
const _prefsMaskKey = 'simple_mask';

class SimpleCalculatorTab extends StatefulWidget {
  const SimpleCalculatorTab({super.key});

  @override
  State<SimpleCalculatorTab> createState() => _SimpleCalculatorTabState();
}

class _SimpleCalculatorTabState extends State<SimpleCalculatorTab> {
  final _formKey = GlobalKey<FormState>();
  final _ipController = TextEditingController(text: '192.168.1.10');
  final _maskController = TextEditingController(text: '24');

  SubnetInfo? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _restoreLastInput();
  }

  Future<void> _restoreLastInput() async {
    final prefs = await SharedPreferences.getInstance();
    final ip = prefs.getString(_prefsIpKey);
    final mask = prefs.getString(_prefsMaskKey);
    if (!mounted || ip == null || mask == null) return;
    setState(() {
      _ipController.text = ip;
      _maskController.text = mask;
    });
  }

  Future<void> _rememberInput() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsIpKey, _ipController.text.trim());
    await prefs.setString(_prefsMaskKey, _maskController.text.trim());
  }

  String? _validateIp(String? value) {
    if (value == null || value.trim().isEmpty) return 'Champ requis';
    final text = value.trim();
    // Une saisie combinee "ip/prefixe" est autorisee ici ; le champ masque
    // est alors ignore.
    final ipPart = text.contains('/') ? text.split('/').first : text;
    try {
      Ipv4Address.parse(ipPart);
      return null;
    } on FormatException catch (e) {
      return e.message;
    }
  }

  String? _validateMask(String? value) {
    if (_ipController.text.trim().contains('/')) return null;
    if (value == null || value.trim().isEmpty) return 'Champ requis';
    try {
      SubnetMask.parsePrefix(value.trim());
      return null;
    } on FormatException catch (e) {
      return e.message;
    }
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      try {
        final ipText = _ipController.text.trim();
        _result = ipText.contains('/')
            ? SubnetCalculator.calculateFromCidr(ipText)
            : SubnetCalculator.calculate(
                ipInput: ipText,
                maskInput: _maskController.text,
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
    _ipController.dispose();
    _maskController.dispose();
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
            TextFormField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'Adresse IP',
                hintText: '192.168.1.10 ou 192.168.1.10/24',
                helperText: 'Astuce : vous pouvez saisir directement ip/prefixe',
                border: OutlineInputBorder(),
              ),
              validator: _validateIp,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _maskController,
              decoration: const InputDecoration(
                labelText: 'Masque (ex: 24 ou 255.255.255.0)',
                hintText: '24',
                border: OutlineInputBorder(),
              ),
              validator: _validateMask,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _calculate,
              icon: const Icon(Icons.calculate),
              label: const Text('Calculer'),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (_result != null) ResultTable(info: _result!),
          ],
        ),
      ),
    );
  }
}
