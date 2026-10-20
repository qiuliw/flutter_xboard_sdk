import '../models/user_model.dart';

class RealNameStatus {
  final bool required;
  final bool verified;
  final String? realName;
  final String? idNumberMask;
  final int? verifiedAt;

  const RealNameStatus({
    required this.required,
    required this.verified,
    this.realName,
    this.idNumberMask,
    this.verifiedAt,
  });

  factory RealNameStatus.fromJson(Map<String, dynamic> json) {
    return RealNameStatus(
      required: json['required'] == true || json['required'] == 1,
      verified: json['verified'] == true || json['verified'] == 1,
      realName: json['real_name'] as String?,
      idNumberMask: json['id_number_mask'] as String?,
      verifiedAt: json['verified_at'] is int
          ? json['verified_at'] as int
          : int.tryParse('${json['verified_at']}'),
    );
  }
}

class RealNamePreconsultResult {
  final bool verified;
  final String? verifyId;
  final String? authUrl;
  final String? message;

  const RealNamePreconsultResult({
    this.verified = false,
    this.verifyId,
    this.authUrl,
    this.message,
  });

  factory RealNamePreconsultResult.fromJson(Map<String, dynamic> json) {
    return RealNamePreconsultResult(
      verified: json['verified'] == true || json['verified'] == 1,
      verifyId: json['verify_id'] as String?,
      authUrl: json['auth_url'] as String?,
      message: json['message'] as String?,
    );
  }
}

abstract class UserApi {
  Future<UserModel> getUserInfo();
  Future<bool> updateUserInfo(Map<String, dynamic> data);
  Future<bool> changePassword(String oldPassword, String newPassword);
  Future<bool> resetSecurity();
  Future<RealNameStatus> getRealNameStatus();
  Future<RealNamePreconsultResult> startRealNameVerify({
    required String realName,
    required String certNo,
  });
}
