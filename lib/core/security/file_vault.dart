import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage.dart';
import '../storage/secure_storage_provider.dart';

/// Encrypts downloaded files and decrypts them into memory only.
/// AES-256-GCM: tampering with the stored file makes decryption fail.
/// Whole-file in memory, fine for PDFs. Large videos will need chunking.
class FileVault {
  FileVault(this._storage);

  final SecureStorage _storage;

  static const _keyName = 'vault_key';
  static final _algo = AesGcm.with256bits();

  Future<SecretKey> _key() async {
    final saved = await _storage.read(_keyName);
    if (saved != null) return SecretKey(base64Decode(saved));

    final key = await _algo.newSecretKey();
    await _storage.write(_keyName, base64Encode(await key.extractBytes()));
    return key;
  }

  Future<void> encryptFile({
    required String plainPath,
    required String encryptedPath,
  }) async {
    final plain = await File(plainPath).readAsBytes();
    final box = await _algo.encrypt(plain, secretKey: await _key());
    await File(encryptedPath).writeAsBytes(box.concatenation());
  }

  Future<Uint8List> decryptFile(String encryptedPath) async {
    final data = await File(encryptedPath).readAsBytes();
    final box =
        SecretBox.fromConcatenation(data, nonceLength: 12, macLength: 16);
    final plain = await _algo.decrypt(box, secretKey: await _key());
    return Uint8List.fromList(plain);
  }
}

final fileVaultProvider = Provider<FileVault>((ref) {
  return FileVault(ref.watch(secureStorageProvider));
});