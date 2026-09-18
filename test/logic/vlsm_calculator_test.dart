import 'package:flutter_test/flutter_test.dart';
import 'package:ipv4_subnet_calculator/logic/vlsm_calculator.dart';

void main() {
  group('VlsmCalculator.splitEqual', () {
    test('divise un /24 en 4 sous-reseaux egaux (/26)', () {
      final subnets = VlsmCalculator.splitEqual(
        baseIpInput: '192.168.1.0',
        basePrefixInput: '24',
        subnetCount: 4,
      );

      expect(subnets, hasLength(4));
      expect(subnets.map((s) => s.prefixLength), everyElement(26));
      expect(
        subnets.map((s) => s.networkAddress.toString()),
        [
          '192.168.1.0',
          '192.168.1.64',
          '192.168.1.128',
          '192.168.1.192',
        ],
      );
      expect(subnets.first.usableHostCount, 62);
    });

    test('un nombre non-puissance-de-deux arrondit vers le haut', () {
      final subnets = VlsmCalculator.splitEqual(
        baseIpInput: '10.0.0.0',
        basePrefixInput: '24',
        subnetCount: 3,
      );

      // 3 sous-reseaux demandes => 2 bits empruntes (4 blocs possibles), on
      // ne renvoie que les 3 demandes.
      expect(subnets, hasLength(3));
      expect(subnets.map((s) => s.prefixLength), everyElement(26));
    });

    test('leve une erreur si le prefixe resultant depasse /32', () {
      expect(
        () => VlsmCalculator.splitEqual(
          baseIpInput: '192.168.1.0',
          basePrefixInput: '31',
          subnetCount: 4,
        ),
        throwsFormatException,
      );
    });
  });

  group('VlsmCalculator.allocate', () {
    test('alloue du plus grand au plus petit sans chevauchement', () {
      final allocations = VlsmCalculator.allocate(
        baseIpInput: '192.168.1.0',
        basePrefixInput: '24',
        requiredHosts: [50, 20, 10, 2],
      );

      expect(allocations, hasLength(4));
      // L'ordre de sortie suit l'ordre d'entree, pas l'ordre d'allocation.
      expect(allocations.map((a) => a.requestedHosts), [50, 20, 10, 2]);

      final subnetFor50 = allocations[0].subnet;
      expect(subnetFor50.prefixLength, 26); // 62 hotes utilisables >= 50
      expect(subnetFor50.networkAddress.toString(), '192.168.1.0');

      final subnetFor20 = allocations[1].subnet;
      expect(subnetFor20.prefixLength, 27); // 30 hotes utilisables >= 20
      expect(subnetFor20.networkAddress.toString(), '192.168.1.64');

      final subnetFor10 = allocations[2].subnet;
      expect(subnetFor10.prefixLength, 28); // 14 hotes utilisables >= 10
      expect(subnetFor10.networkAddress.toString(), '192.168.1.96');

      final subnetFor2 = allocations[3].subnet;
      expect(subnetFor2.prefixLength, 30); // 2 hotes utilisables
      expect(subnetFor2.networkAddress.toString(), '192.168.1.112');

      // Aucun chevauchement : chaque bloc commence apres la fin du precedent.
      final networks = [
        subnetFor50,
        subnetFor20,
        subnetFor10,
        subnetFor2,
      ]..sort((a, b) => a.networkAddress.value.compareTo(b.networkAddress.value));
      for (var i = 1; i < networks.length; i++) {
        expect(
          networks[i].networkAddress.value,
          greaterThanOrEqualTo(networks[i - 1].broadcastAddress.value + 1),
        );
      }
    });

    test('leve une erreur si le reseau de base est trop petit', () {
      expect(
        () => VlsmCalculator.allocate(
          baseIpInput: '192.168.1.0',
          basePrefixInput: '28',
          requiredHosts: [50],
        ),
        throwsFormatException,
      );
    });

    test('leve une erreur sur une liste de besoins vide', () {
      expect(
        () => VlsmCalculator.allocate(
          baseIpInput: '192.168.1.0',
          basePrefixInput: '24',
          requiredHosts: [],
        ),
        throwsFormatException,
      );
    });
  });
}
