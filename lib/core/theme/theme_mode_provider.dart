import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage_provider.dart';
import '../storage/storage_keys.dart';

/// Manages the application's active ThemeMode and persists user preference.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadFromStorage();
    return ThemeMode.system;
  }

  Future<void> _loadFromStorage() async {
    try {
      final storage = ref.read(secureStorageProvider);
      final saved = await storage.read(StorageKeys.themeMode);
      if (saved != null) {
        switch (saved) {
          case 'light':
            state = ThemeMode.light;
            break;
          case 'dark':
            state = ThemeMode.dark;
            break;
          case 'system':
          default:
            state = ThemeMode.system;
            break;
        }
      }
    } catch (_) {
      // Fallback to default system mode on read error
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final storage = ref.read(secureStorageProvider);
      await storage.write(StorageKeys.themeMode, mode.name);
    } catch (_) {
      // Non-blocking write error
    }
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
