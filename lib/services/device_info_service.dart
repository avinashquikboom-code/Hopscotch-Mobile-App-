import 'dart:math';
import 'package:hopscotch/services/secure_storage_service.dart';

class DeviceInfoService {
  static final DeviceInfoService _instance = DeviceInfoService._internal();
  factory DeviceInfoService() => _instance;
  DeviceInfoService._internal();

  final SecureStorageService _secureStorage = SecureStorageService();

  Future<String> getDeviceId() async {
    String? deviceId = await _secureStorage.getDeviceId();
    
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = _generateDeviceId();
      await _secureStorage.saveDeviceId(deviceId);
    }
    
    return deviceId;
  }

  Future<String> getOrCreateSessionId() async {
    String? sessionId = await _secureStorage.getSessionId();
    
    if (sessionId == null || sessionId.isEmpty) {
      sessionId = _generateSessionId();
      await _secureStorage.saveSessionId(sessionId);
    }
    
    return sessionId;
  }

  Future<void> clearSession() async {
    await _secureStorage.clearSession();
  }

  String _generateDeviceId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random.secure();
    final randomPart = random.nextInt(100000).toString().padLeft(5, '0');
    return '$timestamp-$randomPart';
  }
}
