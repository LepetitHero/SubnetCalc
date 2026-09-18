import 'ip_address.dart';
import 'ip_classification.dart';

/// Result of a single subnet calculation.
class SubnetInfo {
  final Ipv4Address ip;
  final int prefixLength;
  final Ipv4Address subnetMask;
  final Ipv4Address wildcardMask;
  final Ipv4Address networkAddress;
  final Ipv4Address broadcastAddress;
  final Ipv4Address? firstUsable;
  final Ipv4Address? lastUsable;
  final int totalAddresses;
  final int usableHostCount;
  final IpClassification classification;

  const SubnetInfo({
    required this.ip,
    required this.prefixLength,
    required this.subnetMask,
    required this.wildcardMask,
    required this.networkAddress,
    required this.broadcastAddress,
    required this.firstUsable,
    required this.lastUsable,
    required this.totalAddresses,
    required this.usableHostCount,
    required this.classification,
  });
}
