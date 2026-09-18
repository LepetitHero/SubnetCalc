import 'subnet_info.dart';

/// One subnet allocated by [VlsmCalculator.allocate], tied back to the
/// host requirement that produced it.
class VlsmAllocation {
  final String label;
  final int requestedHosts;
  final SubnetInfo subnet;

  const VlsmAllocation({
    required this.label,
    required this.requestedHosts,
    required this.subnet,
  });
}
