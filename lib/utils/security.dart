import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Kata sandi disimpan ter-hash (kebutuhan non-fungsional "Keamanan").
/// Catatan: SHA-256 dengan garam tetap cukup untuk tugas kuliah; untuk
/// produksi gunakan bcrypt/argon2 di sisi server.
String hashPassword(String plain) =>
    sha256.convert(utf8.encode('send-shoes-care::$plain')).toString();
