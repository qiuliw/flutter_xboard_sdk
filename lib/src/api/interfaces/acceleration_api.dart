import '../models/acceleration_models.dart';

abstract class AccelerationApi {
  Future<AccelerationCatalog> catalog();
  Future<Map<String, dynamic>> state();
  Future<int> savePreferences(Set<String> applicationIds, int expectedVersion);
  Future<AccelerationRelease> prepare(
      Set<String> applicationIds, int expectedVersion, String idempotencyKey);
  Future<AccelerationConfig> config();
  Future<void> ack(AccelerationRelease release, String result,
      {String? errorCode});
  Future<void> reportMeasurements(String entranceId, List<int> samples);
}
