import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../api/interfaces/acceleration_api.dart';
import '../../../api/models/acceleration_models.dart';
import '../../../core/http/http_service.dart';

class XBoardAccelerationApi implements AccelerationApi {
  final HttpService _http;
  XBoardAccelerationApi(this._http);
  static const _prefix = '/api/v1/user/acceleration';

  Future<dynamic> _call(String method, String path,
      {Map<String, dynamic>? data, String? key}) async {
    try {
      final response = await _http.dio.request('$_prefix/$path',
          data: data,
          options: Options(
              method: method,
              headers: key == null ? null : {'Idempotency-Key': key}));
      final body = response.data as Map<String, dynamic>;
      if (body['success'] == false || body['status'] == 'fail')
        throw AccelerationApiException(
            body['error_code'] as String? ?? 'REQUEST_FAILED');
      return body['data'];
    } on DioException catch (error) {
      dynamic body = error.response?.data;
      if (body is String) {
        try {
          body = jsonDecode(body);
        } catch (_) {
          body = null;
        }
      }
      final code = body is Map ? body['error_code'] as String? : null;
      throw AccelerationApiException(
          code ?? (error.response == null ? 'NETWORK_ERROR' : 'REQUEST_FAILED'),
          error.response?.statusCode);
    }
  }

  @override
  Future<AccelerationCatalog> catalog() async => AccelerationCatalog.fromJson(
      Map<String, dynamic>.from(await _call('GET', 'catalog') as Map));
  @override
  Future<Map<String, dynamic>> state() async =>
      Map<String, dynamic>.from(await _call('GET', 'state') as Map);
  @override
  Future<int> savePreferences(
          Set<String> applicationIds, int expectedVersion) async =>
      (await _call('PUT', 'preferences', data: {
        'application_ids': applicationIds.toList()..sort(),
        'expected_version': expectedVersion
      }))['version'] as int;
  @override
  Future<AccelerationRelease> prepare(Set<String> applicationIds,
          int expectedVersion, String idempotencyKey) async =>
      AccelerationRelease.fromJson(Map<String, dynamic>.from(
          await _call('POST', 'prepare', key: idempotencyKey, data: {
        'application_ids': applicationIds.toList()..sort(),
        'expected_version': expectedVersion
      }) as Map));
  @override
  Future<AccelerationConfig> config() async => AccelerationConfig.fromJson(
      Map<String, dynamic>.from(await _call('GET', 'config') as Map));
  @override
  Future<void> ack(AccelerationRelease release, String result,
      {String? errorCode}) async {
    await _call('POST', 'ack', data: {
      'release_id': release.id,
      'version': release.version,
      'result': result,
      if (errorCode != null) 'error_code': errorCode
    });
  }

  @override
  Future<void> reportMeasurements(String entranceId, List<int> samples) async {
    await _call('POST', 'measurements',
        data: {'entrance_id': int.parse(entranceId), 'samples': samples});
  }
}
