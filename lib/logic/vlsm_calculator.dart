import '../models/ip_address.dart';
import '../models/subnet_info.dart';
import '../models/subnet_mask.dart';
import '../models/vlsm_allocation.dart';
import 'bit_math.dart';
import 'subnet_calculator.dart';

/// Splitting a base network into several subnets.
class VlsmCalculator {
  const VlsmCalculator._();

  /// Divise le reseau de base en [subnetCount] sous-reseaux de taille egale.
  static List<SubnetInfo> splitEqual({
    required String baseIpInput,
    required String basePrefixInput,
    required int subnetCount,
  }) {
    if (subnetCount < 1) {
      throw const FormatException(
        'Le nombre de sous-reseaux doit etre au moins 1',
      );
    }
    final basePrefix = SubnetMask.parsePrefix(basePrefixInput);
    final baseIp = Ipv4Address.parse(baseIpInput);
    final baseNetwork = baseIp & SubnetMask.fromPrefix(basePrefix);

    final extraBits = bitsForCount(subnetCount);
    final newPrefix = basePrefix + extraBits;
    if (newPrefix > 32) {
      throw FormatException(
        'Impossible de creer $subnetCount sous-reseaux depuis un /$basePrefix '
        ': prefixe resultant /$newPrefix > /32',
      );
    }

    final blockSize = 1 << (32 - newPrefix);
    return List.generate(subnetCount, (i) {
      final subnetIp = baseNetwork.add(i * blockSize);
      return SubnetCalculator.calculate(
        ipInput: subnetIp.toString(),
        maskInput: newPrefix.toString(),
      );
    });
  }

  /// VLSM classique : alloue un sous-reseau par besoin en hotes fourni dans
  /// [requiredHosts], du plus grand au plus petit, a partir de la base
  /// [baseIpInput]/[basePrefixInput]. Le resultat conserve l'ordre d'entree.
  static List<VlsmAllocation> allocate({
    required String baseIpInput,
    required String basePrefixInput,
    required List<int> requiredHosts,
    List<String>? labels,
  }) {
    if (requiredHosts.isEmpty) {
      throw const FormatException('Aucun besoin en hotes fourni');
    }
    final basePrefix = SubnetMask.parsePrefix(basePrefixInput);
    final baseIp = Ipv4Address.parse(baseIpInput);
    final baseNetwork = baseIp & SubnetMask.fromPrefix(basePrefix);
    final baseBlockSize = 1 << (32 - basePrefix);
    final baseEnd = baseNetwork.value + baseBlockSize;

    final order = List.generate(requiredHosts.length, (i) => i)
      ..sort((a, b) => requiredHosts[b].compareTo(requiredHosts[a]));

    final results = List<VlsmAllocation?>.filled(requiredHosts.length, null);
    var cursor = baseNetwork.value;

    for (final i in order) {
      final hosts = requiredHosts[i];
      if (hosts < 1) {
        throw FormatException(
          'Le besoin en hotes doit etre au moins 1 (position ${i + 1})',
        );
      }
      final hostBits = hosts <= 2 ? 2 : bitsForCount(hosts + 2);
      final prefix = 32 - hostBits;
      final blockSize = 1 << hostBits;

      final alignedCursor = (cursor + blockSize - 1) ~/ blockSize * blockSize;
      if (alignedCursor + blockSize > baseEnd) {
        throw FormatException(
          'Le reseau de base /$basePrefix est trop petit pour satisfaire '
          'tous les besoins en hotes',
        );
      }

      final subnetIp = Ipv4Address(alignedCursor);
      final info = SubnetCalculator.calculate(
        ipInput: subnetIp.toString(),
        maskInput: prefix.toString(),
      );
      results[i] = VlsmAllocation(
        label: labels != null && i < labels.length
            ? labels[i]
            : 'Sous-reseau ${i + 1}',
        requestedHosts: hosts,
        subnet: info,
      );
      cursor = alignedCursor + blockSize;
    }

    return results.cast<VlsmAllocation>();
  }
}
