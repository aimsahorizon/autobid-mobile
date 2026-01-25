import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FileEncryptionService {
  final SupabaseClient supabase;

  FileEncryptionService(this.supabase);

  // Generate user-specific encryption key from master key + user ID
  encrypt.Key _getUserKey(String userId) {
    final masterKey = dotenv.env['MASTER_ENCRYPTION_KEY'];
    
    if (masterKey == null) {
      throw Exception('MASTER_ENCRYPTION_KEY not found in .env');
    }

    // Use user ID as salt (UUID is > 16 chars, take first 16)
    final userSalt = userId.length >= 16 ? userId.substring(0, 16) : userId.padRight(16, '0');
    final combinedKey = '$masterKey$userSalt';
    
    // Ensure key is exactly 32 bytes for AES-256
    return encrypt.Key.fromUtf8(combinedKey.padRight(32).substring(0, 32));
  }

  Future<Uint8List> encryptFile({
    required Uint8List fileBytes,
    required String userId,
  }) async {
    final key = _getUserKey(userId);
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));

    final encrypted = encrypter.encryptBytes(fileBytes, iv: iv);

    // Prepend IV to encrypted data (first 16 bytes)
    final result = Uint8List.fromList([...iv.bytes, ...encrypted.bytes]);
    return result;
  }

  Future<Uint8List> decryptFile({
    required Uint8List encryptedBytes,
    required String userId,
  }) async {
    final key = _getUserKey(userId);

    // Extract IV (first 16 bytes)
    final iv = encrypt.IV(Uint8List.fromList(encryptedBytes.sublist(0, 16)));
    final encryptedData = encryptedBytes.sublist(16);

    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
    final decrypted = encrypter.decryptBytes(
      encrypt.Encrypted(encryptedData),
      iv: iv,
    );

    return Uint8List.fromList(decrypted);
  }

  Future<String> uploadEncryptedFile({
    required Uint8List fileBytes,
    required String userId,
    required String bucket,
    required String path,
  }) async {
    // Encrypt file
    final encrypted = await encryptFile(fileBytes: fileBytes, userId: userId);

    // Upload to Supabase Storage
    await supabase.storage
      .from(bucket)
      .uploadBinary(path, encrypted);

    // Return the path or public URL (Note: Public URL won't work for private buckets directly)
    // We return the Public URL format to maintain compatibility with existing DB schema fields,
    // but the content at this URL is encrypted and the bucket should be private.
    return supabase.storage.from(bucket).getPublicUrl(path);
  }

  Future<Uint8List> downloadAndDecryptFile({
    required String userId,
    required String bucket,
    required String path,
  }) async {
    // Download from Supabase Storage
    final encryptedBytes = await supabase.storage
      .from(bucket)
      .download(path);

    // Decrypt file
    final decrypted = await decryptFile(
      encryptedBytes: encryptedBytes,
      userId: userId,
    );

    return decrypted;
  }
}
