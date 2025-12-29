import 'package:json_annotation/json_annotation.dart';
import 'user.dart';

part 'auth_response.g.dart';

@JsonSerializable()
class AuthResponse {
  final String token;
  final User user;
  @JsonKey(name: 'expires_at')
  final String expiresAt;

  const AuthResponse({
    required this.token,
    required this.user,
    required this.expiresAt,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => _$AuthResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);

  @override
  String toString() {
    return 'AuthResponse{token: ${token.substring(0, 10)}..., user: $user, expiresAt: $expiresAt}';
  }
}