import 'ip_address.dart';

/// Conversions between a CIDR prefix length (0-32) and a dotted subnet mask.
class SubnetMask {
  const SubnetMask._();

  static Ipv4Address fromPrefix(int prefixLength) {
    if (prefixLength < 0 || prefixLength > 32) {
      throw FormatException(
        'Le prefixe doit etre compris entre 0 et 32 (recu: $prefixLength)',
      );
    }
    if (prefixLength == 0) return const Ipv4Address(0);
    final mask = (0xFFFFFFFF << (32 - prefixLength)) & 0xFFFFFFFF;
    return Ipv4Address(mask);
  }

  static int toPrefix(Ipv4Address mask) {
    final bits = mask.value.toRadixString(2).padLeft(32, '0');
    final firstZero = bits.indexOf('0');
    final prefixLength = firstZero == -1 ? 32 : firstZero;
    if (bits.substring(prefixLength).contains('1')) {
      throw FormatException('Masque de sous-reseau invalide : "$mask"');
    }
    return prefixLength;
  }

  /// Accepte soit un prefixe CIDR ("24"), soit un masque pointe ("255.255.255.0").
  static int parsePrefix(String input) {
    final trimmed = input.trim();
    final asInt = int.tryParse(trimmed);
    if (asInt != null) {
      if (asInt < 0 || asInt > 32) {
        throw FormatException(
          'Le prefixe doit etre compris entre 0 et 32 (recu: $asInt)',
        );
      }
      return asInt;
    }
    return toPrefix(Ipv4Address.parse(trimmed));
  }
}
