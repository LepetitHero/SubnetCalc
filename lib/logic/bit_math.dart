/// Smallest number of bits `n` such that `2^n >= count`.
///
/// Uses integer arithmetic only (no `log`/`ceil`) to avoid floating-point
/// rounding errors right at power-of-two boundaries.
int bitsForCount(int count) {
  var bits = 0;
  while ((1 << bits) < count) {
    bits++;
  }
  return bits;
}
