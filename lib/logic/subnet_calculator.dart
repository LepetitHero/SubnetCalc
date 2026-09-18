import '../models/ip_address.dart';
import '../models/subnet_info.dart';
import '../models/subnet_mask.dart';
import 'ip_classifier.dart';

/// Pure IPv4 subnet math. No Flutter/UI dependency, easy to unit test.
class SubnetCalculator {
  const SubnetCalculator._();

  /// Accepte une IP et un masque/prefixe donnes separement en un seul appel
  /// au format CIDR, ex. "192.168.1.10/24".
  static SubnetInfo calculateFromCidr(String cidrInput) {
    final parts = cidrInput.trim().split('/');
    if (parts.length != 2) {
      throw FormatException(
        'Format CIDR invalide, attendu "ip/prefixe" : "$cidrInput"',
      );
    }
    return calculate(ipInput: parts[0], maskInput: parts[1]);
  }

  static SubnetInfo calculate({
    required String ipInput,
    required String maskInput,
  }) {
    final ip = Ipv4Address.parse(ipInput);
    final prefixLength = SubnetMask.parsePrefix(maskInput);
    final mask = SubnetMask.fromPrefix(prefixLength);
    final wildcard = mask.complement;

    final network = ip & mask;
    final broadcast = network | wildcard;

    final hostBits = 32 - prefixLength;
    final totalAddresses = 1 << hostBits;

    final Ipv4Address firstUsable;
    final Ipv4Address lastUsable;
    final int usableHostCount;

    if (prefixLength == 32) {
      // Route hote unique : pas de reseau/broadcast distincts.
      firstUsable = network;
      lastUsable = network;
      usableHostCount = 1;
    } else if (prefixLength == 31) {
      // RFC 3021 : lien point-a-point, les deux adresses sont utilisables.
      firstUsable = network;
      lastUsable = broadcast;
      usableHostCount = 2;
    } else {
      firstUsable = network.add(1);
      lastUsable = broadcast.add(-1);
      usableHostCount = totalAddresses - 2;
    }

    return SubnetInfo(
      ip: ip,
      prefixLength: prefixLength,
      subnetMask: mask,
      wildcardMask: wildcard,
      networkAddress: network,
      broadcastAddress: broadcast,
      firstUsable: firstUsable,
      lastUsable: lastUsable,
      totalAddresses: totalAddresses,
      usableHostCount: usableHostCount,
      classification: IpClassifier.classify(ip),
    );
  }
}
