import 'dart:convert';

class EncryptionUtils {
  static String toBase64(String plainText) {
    final bytes = utf8.encode(plainText);
    final base64String = base64.encode(bytes);

    return base64String;
  }
}
