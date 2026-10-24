import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../settings/graph_view_settings.dart';

/// Persistence boundary for graph viewport settings.
abstract interface class GraphViewSettingsStore {
  /// Loads saved settings or returns defaults when none are valid.
  Future<GraphViewSettings> load();

  /// Persists all graph viewport settings as one versioned value.
  Future<void> save(GraphViewSettings settings);
}

/// Cross-platform local implementation backed by `shared_preferences`.
final class SharedPreferencesGraphViewSettingsStore
    implements GraphViewSettingsStore {
  SharedPreferencesGraphViewSettingsStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _storageKey = 'graph_view_settings';

  final SharedPreferencesAsync _preferences;

  @override
  Future<GraphViewSettings> load() async {
    try {
      final encodedSettings = await _preferences.getString(_storageKey);
      if (encodedSettings == null) {
        return GraphViewSettings.defaults;
      }

      final decodedSettings = jsonDecode(encodedSettings);
      if (decodedSettings is! Map<String, dynamic>) {
        return GraphViewSettings.defaults;
      }
      return GraphViewSettings.fromJson(decodedSettings);
    } on FormatException {
      return GraphViewSettings.defaults;
    } on TypeError {
      return GraphViewSettings.defaults;
    }
  }

  @override
  Future<void> save(GraphViewSettings settings) =>
      _preferences.setString(_storageKey, jsonEncode(settings.toJson()));
}
