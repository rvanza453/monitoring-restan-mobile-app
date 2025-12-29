import 'package:json_annotation/json_annotation.dart';
import 'pagination.dart';

part 'api_response.g.dart';

@JsonSerializable(genericArgumentFactories: true)
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final String timestamp;
  final String? details;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    required this.timestamp,
    this.details,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$ApiResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$ApiResponseToJson(this, toJsonT);

  @override
  String toString() {
    return 'ApiResponse{success: $success, message: $message, hasData: ${data != null}}';
  }
}

@JsonSerializable(genericArgumentFactories: true)
class ApiListResponse<T> {
  final bool success;
  final String message;
  final ApiListData<T>? data;
  final String timestamp;
  final String? details;

  const ApiListResponse({
    required this.success,
    required this.message,
    this.data,
    required this.timestamp,
    this.details,
  });

  factory ApiListResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$ApiListResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$ApiListResponseToJson(this, toJsonT);

  @override
  String toString() {
    return 'ApiListResponse{success: $success, message: $message, itemCount: ${data?.items.length ?? 0}}';
  }
}

@JsonSerializable(genericArgumentFactories: true)
class ApiListData<T> {
  final List<T> items;
  final Pagination pagination;

  const ApiListData({
    required this.items,
    required this.pagination,
  });

  factory ApiListData.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$ApiListDataFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$ApiListDataToJson(this, toJsonT);

  @override
  String toString() {
    return 'ApiListData{itemCount: ${items.length}, pagination: $pagination}';
  }
}