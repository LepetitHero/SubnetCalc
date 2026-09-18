/// An immutable IPv4 address backed by its 32-bit unsigned representation.
class Ipv4Address {
  final int value;

  const Ipv4Address(this.value);

  factory Ipv4Address.parse(String input) {
    final octets = input.trim().split('.');
    if (octets.length != 4) {
      throw FormatException('Adresse IPv4 invalide : "$input"');
    }
    var result = 0;
    for (final part in octets) {
      if (part.isEmpty || !RegExp(r'^\d+$').hasMatch(part)) {
        throw FormatException('Adresse IPv4 invalide : "$input"');
      }
      final octet = int.parse(part);
      if (octet < 0 || octet > 255) {
        throw FormatException('Octet hors limites (0-255) dans "$input"');
      }
      result = (result << 8) | octet;
    }
    return Ipv4Address(result & 0xFFFFFFFF);
  }

  Ipv4Address operator &(Ipv4Address other) =>
      Ipv4Address(value & other.value);

  Ipv4Address operator |(Ipv4Address other) =>
      Ipv4Address(value | other.value);

  Ipv4Address get complement => Ipv4Address(~value & 0xFFFFFFFF);

  Ipv4Address add(int delta) => Ipv4Address((value + delta) & 0xFFFFFFFF);

  /// Representation en 4 octets binaires separes par des points,
  /// ex. "11000000.10101000.00000001.00001010".
  String toBinaryDotted() {
    final a = (value >> 24) & 0xFF;
    final b = (value >> 16) & 0xFF;
    final c = (value >> 8) & 0xFF;
    final d = value & 0xFF;
    String bin(int octet) => octet.toRadixString(2).padLeft(8, '0');
    return '${bin(a)}.${bin(b)}.${bin(c)}.${bin(d)}';
  }

  @override
  String toString() {
    final a = (value >> 24) & 0xFF;
    final b = (value >> 16) & 0xFF;
    final c = (value >> 8) & 0xFF;
    final d = value & 0xFF;
    return '$a.$b.$c.$d';
  }

  @override
  bool operator ==(Object other) =>
      other is Ipv4Address && other.value == value;

  @override
  int get hashCode => value.hashCode;
}
