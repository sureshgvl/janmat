enum CachePriority {
  low,
  medium,
  high,
  normal,
}

class MultiLevelCache {
  Future<void> set(String key, dynamic value, {Duration? ttl, CachePriority? priority}) async {
    // Stub implementation
  }

  Future<T?> get<T>(String key) async {
    // Stub implementation
    return null;
  }

  Future<void> remove(String key) async {
    // Stub implementation
  }

  Map<String, dynamic> getStats() {
    // Stub implementation
    return {'memory': {'size': 0}};
  }

  Future<void> warmup(List<String> keys) async {
    // Stub implementation
  }

  Future<void> clear() async {
    // Stub implementation
  }
}