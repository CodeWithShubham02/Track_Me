import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;


String decryptFMS(String encryptedBase64, String hashKey) {
  try {
    // 1️⃣ SHA256 hash raw bytes
    final hashBytes = sha256.convert(utf8.encode(hashKey)).bytes;

    // 2️⃣ Key & IV = first 16 bytes
    final keyBytes = Uint8List.fromList(hashBytes.sublist(0, 16));
    final ivBytes = Uint8List.fromList(hashBytes.sublist(0, 16));

    final key = encrypt.Key(keyBytes);
    final iv = encrypt.IV(ivBytes);

    // 3️⃣ AES-128-CBC with PKCS7
    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'),
    );

    final decrypted = encrypter.decrypt64(encryptedBase64, iv: iv);

    // 4️⃣ Optional: remove unwanted special chars
    final cleaned = decrypted.replaceAll(RegExp(r'[^\w\s.,@-]'), '').trim();

    return cleaned;
  } catch (e) {
    print("Error: $e");
    return '';
  }
}

String encryptFMS(String plainText, String hashKey) {
  // Hash the key using SHA256
  var keyHash = sha256.convert(utf8.encode(hashKey)).bytes;

  // Get 16-byte key and IV (same as decrypt)
  final keyBytes = Uint8List.fromList(keyHash.sublist(0, 16));
  final ivBytes = Uint8List.fromList(keyHash.sublist(0, 16));

  final key = encrypt.Key(keyBytes);
  final iv = encrypt.IV(ivBytes);

  final encrypter = encrypt.Encrypter(
    encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'),
  );

  final encrypted = encrypter.encrypt(plainText, iv: iv);
  return encrypted.base64; // return Base64 string
}
