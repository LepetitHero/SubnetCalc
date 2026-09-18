import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../logic/result_formatter.dart';
import '../../models/ip_address.dart';
import '../../models/ip_classification.dart';
import '../../models/subnet_info.dart';

class ResultTable extends StatelessWidget {
  final SubnetInfo info;

  const ResultTable({super.key, required this.info});

  Future<void> _copy(BuildContext context) async {
    String message;
    try {
      await Clipboard.setData(
        ClipboardData(text: ResultFormatter.plainText(info)),
      );
      message = 'Resultat copie';
    } catch (_) {
      message = 'Copie impossible (acces au presse-papier refuse)';
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = <MapEntry<String, String>>[
      MapEntry('Adresse IP', info.ip.toString()),
      MapEntry('Prefixe', '/${info.prefixLength}'),
      MapEntry('Masque de sous-reseau', info.subnetMask.toString()),
      MapEntry('Masque generique (wildcard)', info.wildcardMask.toString()),
      MapEntry('Adresse reseau', info.networkAddress.toString()),
      MapEntry('Adresse de broadcast', info.broadcastAddress.toString()),
      MapEntry(
        'Premiere adresse utilisable',
        info.firstUsable?.toString() ?? '-',
      ),
      MapEntry(
        'Derniere adresse utilisable',
        info.lastUsable?.toString() ?? '-',
      ),
      MapEntry('Hotes utilisables', info.usableHostCount.toString()),
      MapEntry('Adresses totales', info.totalAddresses.toString()),
      MapEntry('Classe', info.classification.ipClass.label),
      MapEntry('Portee', info.classification.scope),
    ];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Resultat',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_outlined),
                  tooltip: 'Copier le resultat',
                  onPressed: () => _copy(context),
                ),
              ],
            ),
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        row.key,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        row.value,
                        style: const TextStyle(
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Vue binaire'),
                childrenPadding: const EdgeInsets.only(bottom: 8),
                children: [
                  _BinaryRow(label: 'Adresse IP', address: info.ip, prefixLength: info.prefixLength),
                  _BinaryRow(label: 'Masque', address: info.subnetMask, prefixLength: info.prefixLength),
                  _BinaryRow(
                    label: 'Adresse reseau',
                    address: info.networkAddress,
                    prefixLength: info.prefixLength,
                  ),
                  _BinaryRow(
                    label: 'Broadcast',
                    address: info.broadcastAddress,
                    prefixLength: info.prefixLength,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Affiche une adresse en binaire, avec les bits de partie reseau en gras et
/// colores differemment des bits de partie hote.
class _BinaryRow extends StatelessWidget {
  final String label;
  final Ipv4Address address;
  final int prefixLength;

  const _BinaryRow({
    required this.label,
    required this.address,
    required this.prefixLength,
  });

  @override
  Widget build(BuildContext context) {
    final dotted = address.toBinaryDotted();
    final colorScheme = Theme.of(context).colorScheme;

    // Reconstruit la chaine pointee en coloriant chaque bit selon sa position
    // reelle (index en ignorant les points) par rapport au prefixe.
    final spans = <TextSpan>[];
    var bitIndex = 0;
    for (var i = 0; i < dotted.length; i++) {
      final char = dotted[i];
      if (char == '.') {
        spans.add(const TextSpan(text: '.'));
        continue;
      }
      final isNetworkBit = bitIndex < prefixLength;
      spans.add(
        TextSpan(
          text: char,
          style: TextStyle(
            color: isNetworkBit ? colorScheme.primary : colorScheme.tertiary,
            fontWeight: isNetworkBit ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      );
      bitIndex++;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 4,
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style.copyWith(
                      fontFamily: 'monospace',
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                children: spans,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
