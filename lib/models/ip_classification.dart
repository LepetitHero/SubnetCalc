/// Classe historique d'une adresse IPv4 (A/B/C/D/E).
enum IpClass { a, b, c, d, e }

extension IpClassLabel on IpClass {
  String get label => switch (this) {
        IpClass.a => 'A',
        IpClass.b => 'B',
        IpClass.c => 'C',
        IpClass.d => 'D (multicast)',
        IpClass.e => 'E (reservee)',
      };
}

/// Resultat de la classification d'une adresse IPv4 : classe historique et
/// portee (privee, publique, loopback, ...).
class IpClassification {
  final IpClass ipClass;
  final String scope;

  const IpClassification({required this.ipClass, required this.scope});
}
