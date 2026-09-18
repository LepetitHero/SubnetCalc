import '../models/ip_classification.dart';
import '../models/subnet_info.dart';
import '../models/vlsm_allocation.dart';

/// Mise en forme texte/CSV des resultats, pour le copier-coller.
class ResultFormatter {
  const ResultFormatter._();

  static const _headers = [
    'Adresse IP',
    'Prefixe',
    'Masque',
    'Wildcard',
    'Adresse reseau',
    'Broadcast',
    'Premiere utilisable',
    'Derniere utilisable',
    'Hotes utilisables',
    'Adresses totales',
    'Classe',
    'Portee',
  ];

  static List<String> _row(SubnetInfo info) => [
        info.ip.toString(),
        '/${info.prefixLength}',
        info.subnetMask.toString(),
        info.wildcardMask.toString(),
        info.networkAddress.toString(),
        info.broadcastAddress.toString(),
        info.firstUsable?.toString() ?? '-',
        info.lastUsable?.toString() ?? '-',
        '${info.usableHostCount}',
        '${info.totalAddresses}',
        info.classification.ipClass.label,
        info.classification.scope,
      ];

  static String plainText(SubnetInfo info) {
    final rows = _row(info);
    return [
      for (var i = 0; i < _headers.length; i++) '${_headers[i]} : ${rows[i]}',
    ].join('\n');
  }

  static String csv(List<SubnetInfo> subnets, {List<String>? labels}) {
    final headers = [if (labels != null) 'Nom', ..._headers];
    final lines = <String>[headers.join(',')];
    for (var i = 0; i < subnets.length; i++) {
      final row = _row(subnets[i]);
      lines.add([if (labels != null) labels[i], ...row].join(','));
    }
    return lines.join('\n');
  }

  static String vlsmCsv(List<VlsmAllocation> allocations) {
    final headers = ['Nom', 'Hotes demandes', ..._headers];
    final lines = <String>[headers.join(',')];
    for (final alloc in allocations) {
      final row = _row(alloc.subnet);
      lines.add([alloc.label, '${alloc.requestedHosts}', ...row].join(','));
    }
    return lines.join('\n');
  }
}
