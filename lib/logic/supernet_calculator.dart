import '../models/ip_address.dart';
import '../models/subnet_info.dart';
import '../models/subnet_mask.dart';
import 'subnet_calculator.dart';

/// Regroupement de reseaux (supernetting / route summarization) : trouve le
/// plus petit bloc CIDR qui contient integralement tous les reseaux donnes.
class SupernetCalculator {
  const SupernetCalculator._();

  /// [cidrInputs] : au moins deux reseaux au format "ip/prefixe".
  static SubnetInfo summarize(List<String> cidrInputs) {
    if (cidrInputs.length < 2) {
      throw const FormatException(
        'Il faut au moins deux reseaux a regrouper',
      );
    }

    final networks = cidrInputs.map(SubnetCalculator.calculateFromCidr).toList();

    var lowest = networks.first.networkAddress.value;
    var highest = networks.first.broadcastAddress.value;
    for (final n in networks.skip(1)) {
      if (n.networkAddress.value < lowest) lowest = n.networkAddress.value;
      if (n.broadcastAddress.value > highest) highest = n.broadcastAddress.value;
    }

    final prefixLength = _commonPrefixLength(lowest, highest);
    final mask = SubnetMask.fromPrefix(prefixLength);
    final summaryNetwork = Ipv4Address(lowest) & mask;

    return SubnetCalculator.calculate(
      ipInput: summaryNetwork.toString(),
      maskInput: prefixLength.toString(),
    );
  }

  /// Nombre de bits de poids fort identiques entre [a] et [b]. Comme [a] et
  /// [b] sont les bornes basse/haute d'une plage continue, tout ce qui se
  /// trouve entre les deux partage ce meme prefixe.
  static int _commonPrefixLength(int a, int b) {
    var xor = a ^ b;
    var length = 32;
    while (xor != 0) {
      xor >>= 1;
      length--;
    }
    return length;
  }
}
