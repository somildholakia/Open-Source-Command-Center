import 'package:opensource_command_center/domain/domain.dart';
import 'package:opensource_command_center/services/connection/connection_store.dart';

/// In-memory [ConnectionStore] for tests (no platform channels).
class InMemoryConnectionStore implements ConnectionStore {
  ProviderConnectionRecord? record;

  int saveCalls = 0;
  int clearCalls = 0;

  InMemoryConnectionStore([this.record]);

  @override
  ProviderConnectionRecord? load() => record;

  @override
  Future<void> save(ProviderConnectionRecord record) async {
    saveCalls++;
    this.record = record;
  }

  @override
  Future<void> clear() async {
    clearCalls++;
    record = null;
  }
}
