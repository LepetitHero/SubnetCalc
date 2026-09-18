import 'package:flutter_test/flutter_test.dart';
import 'package:ipv4_subnet_calculator/logic/supernet_calculator.dart';

void main() {
  group('SupernetCalculator.summarize', () {
    test('4 /24 contigus se regroupent en un /22', () {
      final summary = SupernetCalculator.summarize([
        '192.168.0.0/24',
        '192.168.1.0/24',
        '192.168.2.0/24',
        '192.168.3.0/24',
      ]);

      expect(summary.networkAddress.toString(), '192.168.0.0');
      expect(summary.prefixLength, 22);
      expect(summary.broadcastAddress.toString(), '192.168.3.255');
    });

    test('deux /24 non alignes retombent sur un bloc plus large', () {
      // 192.168.1.0/24 et 192.168.2.0/24 ne partagent pas le meme /23,
      // le plus petit bloc commun est donc un /22 (192.168.0.0/22).
      final summary = SupernetCalculator.summarize([
        '192.168.1.0/24',
        '192.168.2.0/24',
      ]);

      expect(summary.networkAddress.toString(), '192.168.0.0');
      expect(summary.prefixLength, 22);
    });

    test('un seul reseau ne peut pas etre regroupe', () {
      expect(
        () => SupernetCalculator.summarize(['192.168.1.0/24']),
        throwsFormatException,
      );
    });

    test('reseaux deja identiques', () {
      final summary = SupernetCalculator.summarize([
        '10.0.0.0/8',
        '10.0.0.0/8',
      ]);

      expect(summary.networkAddress.toString(), '10.0.0.0');
      expect(summary.prefixLength, 8);
    });
  });
}
