/**
 * Generates a random numeric string of the given length.
 * Mirrors lib/components/random_code.dart
 */
export function generateCode(length: number): string {
  let result = '';
  for (let i = 0; i < length; i++) {
    result += Math.floor(Math.random() * 10).toString();
  }
  return result;
}
