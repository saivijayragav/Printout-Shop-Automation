import 'dart:math';

String generateCode(int length) {
  const chars = '1234567890';
  final rand = Random();
  return List.generate(length, (index) => chars[rand.nextInt(chars.length)]).join();
}
