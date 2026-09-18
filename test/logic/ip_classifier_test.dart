import 'package:flutter_test/flutter_test.dart';
import 'package:ipv4_subnet_calculator/logic/ip_classifier.dart';
import 'package:ipv4_subnet_calculator/models/ip_address.dart';
import 'package:ipv4_subnet_calculator/models/ip_classification.dart';

void main() {
  IpClassification classify(String ip) =>
      IpClassifier.classify(Ipv4Address.parse(ip));

  group('classe historique', () {
    test('classe A', () {
      expect(classify('10.0.0.1').ipClass, IpClass.a);
      expect(classify('126.0.0.1').ipClass, IpClass.a);
    });

    test('classe B', () {
      expect(classify('172.16.0.1').ipClass, IpClass.b);
    });

    test('classe C', () {
      expect(classify('192.168.1.1').ipClass, IpClass.c);
    });

    test('classe D (multicast)', () {
      expect(classify('224.0.0.1').ipClass, IpClass.d);
    });

    test('classe E (reservee)', () {
      expect(classify('240.0.0.1').ipClass, IpClass.e);
    });
  });

  group('portee', () {
    test('privee RFC 1918', () {
      expect(classify('10.1.2.3').scope, contains('Privee'));
      expect(classify('172.16.5.5').scope, contains('Privee'));
      expect(classify('192.168.1.1').scope, contains('Privee'));
    });

    test('bouclage', () {
      expect(classify('127.0.0.1').scope, contains('Bouclage'));
    });

    test('liaison locale APIPA', () {
      expect(classify('169.254.1.1').scope, contains('Liaison locale'));
    });

    test('multicast', () {
      expect(classify('239.1.2.3').scope, contains('Multicast'));
    });

    test('publique', () {
      expect(classify('8.8.8.8').scope, 'Publique');
    });
  });
}
