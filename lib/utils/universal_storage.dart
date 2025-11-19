/// Universal storage interface for cross-platform logging
abstract class UniversalStorage {
  Future<void> writeLog(String message);

  Future<void> init();

  Future<void> close();
}
