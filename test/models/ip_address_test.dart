import 'package:flutter_test/flutter_test.dart';
import 'package:ipv4_subnet_calculator/models/ip_address.dart';

void main() {
  group('Ipv4Address.toBinaryDotted', () {
    test('192.168.1.10', () {
      final ip = Ipv4Address.parse('192.168.1.10');
      expect(
        ip.toBinaryDotted(),
        '11000000.10101000.00000001.00001010',
      );
    });

    test('0.0.0.0', () {
      expect(Ipv4Address.parse('0.0.0.0').toBinaryDotted(), '00000000.00000000.00000000.00000000');
    });

    test('255.255.255.255', () {
      expect(
        Ipv4Address.parse('255.255.255.255').toBinaryDotted(),
        '11111111.11111111.11111111.11111111',
      );
    });
  });
}
