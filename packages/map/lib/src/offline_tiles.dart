import 'package:hive_flutter/hive_flutter.dart';

/// Simple in-memory and Hive-backed cache for resolved tile URLs.
class OfflineTileCache {
  OfflineTileCache._();

  static final OfflineTileCache instance = OfflineTileCache._();

  static const _boxName = 'tq_tile_cache';
  static const _maxEntries = 500;

  Box<dynamic>? _box;
  final Map<String, String> _memory = {};
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    _box = await Hive.openBox<dynamic>(_boxName);
    _initialized = true;
  }

  Future<String?> get(String key) async {
    await _ensureReady();
    if (_memory.containsKey(key)) return _memory[key];
    return _box!.get(key) as String?;
  }

  Future<void> put(String key, String url) async {
    await _ensureReady();
    _memory[key] = url;
    await _box!.put(key, url);
    await _trimIfNeeded();
  }

  Future<void> clear() async {
    await _ensureReady();
    _memory.clear();
    await _box!.clear();
  }

  Future<void> _trimIfNeeded() async {
    if (_box!.length <= _maxEntries) return;
    final keys = _box!.keys.cast<String>().toList();
    final excess = keys.length - _maxEntries;
    for (var i = 0; i < excess; i++) {
      await _box!.delete(keys[i]);
      _memory.remove(keys[i]);
    }
  }

  Future<void> _ensureReady() async {
    if (!_initialized) await init();
  }
}

/// Resolves a tile URL and optionally stores it in the offline cache.
Future<String> resolveTileUrl({
  required String template,
  required int z,
  required int x,
  required int y,
  OfflineTileCache? cache,
}) async {
  final resolved = template
      .replaceAll('{z}', '$z')
      .replaceAll('{x}', '$x')
      .replaceAll('{y}', '$y');
  final key = '$template:$z/$x/$y';
  await (cache ?? OfflineTileCache.instance).put(key, resolved);
  return resolved;
}
