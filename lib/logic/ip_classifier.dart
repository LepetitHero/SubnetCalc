import '../models/ip_address.dart';
import '../models/ip_classification.dart';
import '../models/subnet_mask.dart';

/// Classification d'une adresse IPv4 : classe historique (A-E) et portee
/// (privee, publique, loopback, multicast, documentation, ...).
class IpClassifier {
  const IpClassifier._();

  static IpClassification classify(Ipv4Address ip) {
    return IpClassification(ipClass: _classOf(ip), scope: _scopeOf(ip));
  }

  static IpClass _classOf(Ipv4Address ip) {
    final firstOctet = (ip.value >> 24) & 0xFF;
    if (firstOctet < 128) return IpClass.a;
    if (firstOctet < 192) return IpClass.b;
    if (firstOctet < 224) return IpClass.c;
    if (firstOctet < 240) return IpClass.d;
    return IpClass.e;
  }

  static String _scopeOf(Ipv4Address ip) {
    if (ip.value == 0xFFFFFFFF) return 'Broadcast limite';
    if (_within(ip, '0.0.0.0', 8)) return 'Reseau courant (RFC 1122)';
    if (_within(ip, '10.0.0.0', 8)) return 'Privee (RFC 1918)';
    if (_within(ip, '100.64.0.0', 10)) return 'Partagee / CGNAT (RFC 6598)';
    if (_within(ip, '127.0.0.0', 8)) return 'Bouclage (loopback)';
    if (_within(ip, '169.254.0.0', 16)) {
      return 'Liaison locale / APIPA (RFC 3927)';
    }
    if (_within(ip, '172.16.0.0', 12)) return 'Privee (RFC 1918)';
    if (_within(ip, '192.0.2.0', 24)) return 'Documentation (TEST-NET-1)';
    if (_within(ip, '192.88.99.0', 24)) return 'Relais 6to4 (RFC 3068)';
    if (_within(ip, '192.168.0.0', 16)) return 'Privee (RFC 1918)';
    if (_within(ip, '198.18.0.0', 15)) return 'Test de performance (RFC 2544)';
    if (_within(ip, '198.51.100.0', 24)) return 'Documentation (TEST-NET-2)';
    if (_within(ip, '203.0.113.0', 24)) return 'Documentation (TEST-NET-3)';
    if (_within(ip, '224.0.0.0', 4)) return 'Multicast (RFC 5771)';
    if (_within(ip, '240.0.0.0', 4)) return 'Reservee (RFC 1112)';
    return 'Publique';
  }

  static bool _within(Ipv4Address ip, String networkIp, int prefix) {
    final mask = SubnetMask.fromPrefix(prefix);
    final network = Ipv4Address.parse(networkIp) & mask;
    return (ip & mask) == network;
  }
}
