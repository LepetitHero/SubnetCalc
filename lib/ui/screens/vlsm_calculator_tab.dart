import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../logic/result_formatter.dart';
import '../../logic/vlsm_calculator.dart';
import '../../models/ip_address.dart';
import '../../models/subnet_info.dart';
import '../../models/subnet_mask.dart';
import '../../models/vlsm_allocation.dart';
import '../widgets/result_table.dart';

enum _VlsmMode { equalSplit, hostBased }

const _prefsBaseIpKey = 'vlsm_base_ip';
const _prefsBasePrefixKey = 'vlsm_base_prefix';
const _prefsSubnetCountKey = 'vlsm_subnet_count';
const _prefsHostRowsKey = 'vlsm_host_rows';

class _HostRequirementRow {
  final int id;
  final TextEditingController labelController;
  final TextEditingController hostsController;

  _HostRequirementRow(this.id, {String label = '', String hosts = ''})
      : labelController = TextEditingController(text: label),
        hostsController = TextEditingController(text: hosts);

  void dispose() {
    labelController.dispose();
    hostsController.dispose();
  }
}

class VlsmCalculatorTab extends StatefulWidget {
  const VlsmCalculatorTab({super.key});

  @override
  State<VlsmCalculatorTab> createState() => _VlsmCalculatorTabState();
}

class _VlsmCalculatorTabState extends State<VlsmCalculatorTab> {
  _VlsmMode _mode = _VlsmMode.equalSplit;

  final _formKey = GlobalKey<FormState>();
  final _ipController = TextEditingController(text: '192.168.1.0');
  final _prefixController = TextEditingController(text: '24');
  final _subnetCountController = TextEditingController(text: '4');

  var _nextRowId = 0;
  late List<_HostRequirementRow> _hostRows;

  String? _error;
  List<SubnetInfo>? _equalResults;
  List<VlsmAllocation>? _vlsmResults;

  @override
  void initState() {
    super.initState();
    _hostRows = [
      _HostRequirementRow(_nextRowId++, label: 'Sous-reseau 1', hosts: '50'),
      _HostRequirementRow(_nextRowId++, label: 'Sous-reseau 2', hosts: '20'),
      _HostRequirementRow(_nextRowId++, label: 'Sous-reseau 3', hosts: '10'),
      _HostRequirementRow(_nextRowId++, label: 'Sous-reseau 4', hosts: '2'),
    ];
    _restoreLastInput();
  }

  Future<void> _restoreLastInput() async {
    final prefs = await SharedPreferences.getInstance();
    final ip = prefs.getString(_prefsBaseIpKey);
    final prefix = prefs.getString(_prefsBasePrefixKey);
    final subnetCount = prefs.getString(_prefsSubnetCountKey);
    final hostRows = prefs.getStringList(_prefsHostRowsKey);
    if (!mounted) return;
    setState(() {
      if (ip != null) _ipController.text = ip;
      if (prefix != null) _prefixController.text = prefix;
      if (subnetCount != null) _subnetCountController.text = subnetCount;
      if (hostRows != null && hostRows.isNotEmpty) {
        for (final row in _hostRows) {
          row.dispose();
        }
        _hostRows = [
          for (final entry in hostRows)
            _HostRequirementRow(
              _nextRowId++,
              label: entry.split('|').first,
              hosts: entry.contains('|') ? entry.split('|')[1] : '',
            ),
        ];
      }
    });
  }

  Future<void> _rememberInput() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsBaseIpKey, _ipController.text.trim());
    await prefs.setString(_prefsBasePrefixKey, _prefixController.text.trim());
    await prefs.setString(_prefsSubnetCountKey, _subnetCountController.text.trim());
    await prefs.setStringList(_prefsHostRowsKey, [
      for (final row in _hostRows)
        '${row.labelController.text.trim()}|${row.hostsController.text.trim()}',
    ]);
  }

  (String ip, String prefix) _splitBaseNetwork() {
    final ipText = _ipController.text.trim();
    if (ipText.contains('/')) {
      final parts = ipText.split('/');
      return (parts[0], parts[1]);
    }
    return (ipText, _prefixController.text.trim());
  }

  String? _validateBaseIp(String? value) {
    if (value == null || value.trim().isEmpty) return 'Champ requis';
    final text = value.trim();
    final ipPart = text.contains('/') ? text.split('/').first : text;
    try {
      Ipv4Address.parse(ipPart);
      return null;
    } on FormatException catch (e) {
      return e.message;
    }
  }

  String? _validateBasePrefix(String? value) {
    if (_ipController.text.trim().contains('/')) return null;
    if (value == null || value.trim().isEmpty) return 'Champ requis';
    try {
      SubnetMask.parsePrefix(value.trim());
      return null;
    } on FormatException catch (e) {
      return e.message;
    }
  }

  String? _validateSubnetCount(String? value) {
    if (value == null || value.trim().isEmpty) return 'Champ requis';
    final n = int.tryParse(value.trim());
    if (n == null || n < 1) return 'Entier positif requis';
    return null;
  }

  String? _validateHosts(String? value) {
    if (value == null || value.trim().isEmpty) return 'Requis';
    final n = int.tryParse(value.trim());
    if (n == null || n < 1) return 'Entier > 0';
    return null;
  }

  void _addHostRow() {
    setState(() {
      _hostRows.add(
        _HostRequirementRow(
          _nextRowId++,
          label: 'Sous-reseau ${_hostRows.length + 1}',
        ),
      );
    });
  }

  void _removeHostRow(_HostRequirementRow row) {
    setState(() {
      row.dispose();
      _hostRows.remove(row);
    });
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final (baseIp, basePrefix) = _splitBaseNetwork();
    setState(() {
      _error = null;
      _equalResults = null;
      _vlsmResults = null;
      try {
        if (_mode == _VlsmMode.equalSplit) {
          _equalResults = VlsmCalculator.splitEqual(
            baseIpInput: baseIp,
            basePrefixInput: basePrefix,
            subnetCount: int.parse(_subnetCountController.text.trim()),
          );
        } else {
          final hosts = [
            for (final row in _hostRows) int.parse(row.hostsController.text.trim()),
          ];
          final labels = [
            for (var i = 0; i < _hostRows.length; i++)
              _hostRows[i].labelController.text.trim().isEmpty
                  ? 'Sous-reseau ${i + 1}'
                  : _hostRows[i].labelController.text.trim(),
          ];
          _vlsmResults = VlsmCalculator.allocate(
            baseIpInput: baseIp,
            basePrefixInput: basePrefix,
            requiredHosts: hosts,
            labels: labels,
          );
        }
        _rememberInput();
      } on FormatException catch (e) {
        _error = e.message;
      }
    });
  }

  Future<void> _copyAll() async {
    final text = _equalResults != null
        ? ResultFormatter.csv(_equalResults!)
        : _vlsmResults != null
            ? ResultFormatter.vlsmCsv(_vlsmResults!)
            : null;
    if (text == null) return;
    String message;
    try {
      await Clipboard.setData(ClipboardData(text: text));
      message = 'Tableau copie (CSV)';
    } catch (_) {
      message = 'Copie impossible (acces au presse-papier refuse)';
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    _prefixController.dispose();
    _subnetCountController.dispose();
    for (final row in _hostRows) {
      row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasResults = _equalResults != null || _vlsmResults != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<_VlsmMode>(
              segments: const [
                ButtonSegment(
                  value: _VlsmMode.equalSplit,
                  label: Text('N sous-reseaux egaux'),
                ),
                ButtonSegment(
                  value: _VlsmMode.hostBased,
                  label: Text('Besoins en hotes (VLSM)'),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) => setState(() {
                _mode = selection.first;
                _equalResults = null;
                _vlsmResults = null;
                _error = null;
              }),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'Adresse du reseau de base',
                hintText: '192.168.1.0 ou 192.168.1.0/24',
                helperText: 'Astuce : vous pouvez saisir directement ip/prefixe',
                border: OutlineInputBorder(),
              ),
              validator: _validateBaseIp,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _prefixController,
              decoration: const InputDecoration(
                labelText: 'Prefixe de base (ex: 24 ou 255.255.255.0)',
                hintText: '24',
                border: OutlineInputBorder(),
              ),
              validator: _validateBasePrefix,
            ),
            const SizedBox(height: 12),
            if (_mode == _VlsmMode.equalSplit)
              TextFormField(
                controller: _subnetCountController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de sous-reseaux voulus',
                  hintText: '4',
                  border: OutlineInputBorder(),
                ),
                validator: _validateSubnetCount,
              )
            else ...[
              for (final row in _hostRows)
                Padding(
                  key: ValueKey(row.id),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: row.labelController,
                          decoration: const InputDecoration(
                            labelText: 'Nom',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: row.hostsController,
                          decoration: const InputDecoration(
                            labelText: 'Hotes requis',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          validator: _validateHosts,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        tooltip: 'Retirer cette ligne',
                        onPressed: _hostRows.length > 1
                            ? () => _removeHostRow(row)
                            : null,
                      ),
                    ],
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addHostRow,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter un sous-reseau'),
                ),
              ),
              const SizedBox(height: 4),
            ],
            const SizedBox(height: 12),
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
            if (hasResults)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _copyAll,
                  icon: const Icon(Icons.copy_all_outlined),
                  label: const Text('Copier tout (CSV)'),
                ),
              ),
            if (_equalResults != null)
              for (var i = 0; i < _equalResults!.length; i++) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Text(
                    'Sous-reseau ${i + 1}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ResultTable(info: _equalResults![i]),
              ],
            if (_vlsmResults != null)
              for (final alloc in _vlsmResults!) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Text(
                    '${alloc.label} (besoin : ${alloc.requestedHosts} hotes)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ResultTable(info: alloc.subnet),
              ],
          ],
        ),
      ),
    );
  }
}
