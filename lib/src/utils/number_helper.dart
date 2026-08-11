/// Formats a number count into a compact string representation (e.g., 1.2K, 1.5M, etc.).
String formatCount(int count) {
  if (count >= 1000000) {
    double value = count / 1000000;
    return value.toStringAsFixed(value == value.toInt() ? 0 : 1) + 'M';
  } else if (count >= 1000) {
    double value = count / 1000;
    return value.toStringAsFixed(value == value.toInt() ? 0 : 1) + 'K';
  }
  return count.toString();
}
