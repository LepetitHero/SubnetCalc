import 'package:flutter_test/flutter_test.dart';
import 'package:ipv4_subnet_calculator/logic/subnet_calculator.dart';

void main() {
  group('SubnetCalculator.calculate', () {
    test('/24 classique', () {
      final info = SubnetCalculator.calculate(
        ipInput: '192.168.1.10',
        maskInput: '24',
      );

      expect(info.networkAddress.toString(), '192.168.1.0');
      expect(info.broadcastAddress.toString(), '192.168.1.255');
      expect(info.subnetMask.toString(), '255.255.255.0');
      expect(info.wildcardMask.toString(), '0.0.0.255');
      expect(info.firstUsable.toString(), '192.168.1.1');
      expect(info.lastUsable.toString(), '192.168.1.254');
      expect(info.usableHostCount, 254);
      expect(info.totalAddresses, 256);
      expect(info.classification.scope, contains('Privee'));
    });

    test('calculateFromCidr equivaut a ip + masque separes', () {
      final fromCidr = SubnetCalculator.calculateFromCidr('192.168.1.10/24');
      final separate = SubnetCalculator.calculate(
        ipInput: '192.168.1.10',
        maskInput: '24',
      );

      expect(fromCidr.networkAddress, separate.networkAddress);
      expect(fromCidr.prefixLength, separate.prefixLength);
    });

    test('calculateFromCidr rejette un format sans "/"', () {
      expect(
        () => SubnetCalculator.calculateFromCidr('192.168.1.10'),
        throwsFormatException,
      );
    });

    test('accepte un masque pointe en plus du prefixe CIDR', () {
      final byPrefix = SubnetCalculator.calculate(
        ipInput: '10.0.0.5',
        maskInput: '20',
      );
      final byMask = SubnetCalculator.calculate(
        ipInput: '10.0.0.5',
        maskInput: '255.255.240.0',
      );

      expect(byMask.networkAddress, byPrefix.networkAddress);
      expect(byMask.prefixLength, byPrefix.prefixLength);
    });

    test('/30 (4 adresses, 2 hotes utilisables)', () {
      final info = SubnetCalculator.calculate(
        ipInput: '172.16.0.5',
        maskInput: '30',
      );

      expect(info.networkAddress.toString(), '172.16.0.4');
      expect(info.broadcastAddress.toString(), '172.16.0.7');
      expect(info.firstUsable.toString(), '172.16.0.5');
      expect(info.lastUsable.toString(), '172.16.0.6');
      expect(info.usableHostCount, 2);
      expect(info.totalAddresses, 4);
    });

    test('/31 : lien point-a-point RFC 3021, 2 adresses utilisables', () {
      final info = SubnetCalculator.calculate(
        ipInput: '192.168.0.0',
        maskInput: '31',
      );

      expect(info.networkAddress.toString(), '192.168.0.0');
      expect(info.broadcastAddress.toString(), '192.168.0.1');
      expect(info.firstUsable.toString(), '192.168.0.0');
      expect(info.lastUsable.toString(), '192.168.0.1');
      expect(info.usableHostCount, 2);
    });

    test('/32 : hote unique', () {
      final info = SubnetCalculator.calculate(
        ipInput: '203.0.113.7',
        maskInput: '32',
      );

      expect(info.networkAddress.toString(), '203.0.113.7');
      expect(info.broadcastAddress.toString(), '203.0.113.7');
      expect(info.firstUsable.toString(), '203.0.113.7');
      expect(info.lastUsable.toString(), '203.0.113.7');
      expect(info.usableHostCount, 1);
      expect(info.totalAddresses, 1);
    });

    test('/0 : masque nul', () {
      final info = SubnetCalculator.calculate(
        ipInput: '8.8.8.8',
        maskInput: '0',
      );

      expect(info.networkAddress.toString(), '0.0.0.0');
      expect(info.broadcastAddress.toString(), '255.255.255.255');
      expect(info.usableHostCount, (1 << 32) - 2);
    });

    test('rejette une IP mal formee', () {
      expect(
        () => SubnetCalculator.calculate(
          ipInput: '192.168.1.999',
          maskInput: '24',
        ),
        throwsFormatException,
      );
      expect(
        () => SubnetCalculator.calculate(
          ipInput: '192.168.1',
          maskInput: '24',
        ),
        throwsFormatException,
      );
    });

    test('rejette un prefixe hors limites', () {
      expect(
        () => SubnetCalculator.calculate(
          ipInput: '192.168.1.1',
          maskInput: '33',
        ),
        throwsFormatException,
      );
    });

    test('rejette un masque non contigu', () {
      expect(
        () => SubnetCalculator.calculate(
          ipInput: '192.168.1.1',
          maskInput: '255.0.255.0',
        ),
        throwsFormatException,
      );
    });
  });
}
