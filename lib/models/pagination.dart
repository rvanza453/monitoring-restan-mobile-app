import 'package:json_annotation/json_annotation.dart';

part 'pagination.g.dart';

@JsonSerializable()
class Pagination {
  @JsonKey(name: 'current_page')
  final int currentPage;
  @JsonKey(name: 'total_pages')
  final int totalPages;
  @JsonKey(name: 'total_items')
  final int totalItems;
  @JsonKey(name: 'items_per_page')
  final int itemsPerPage;
  @JsonKey(name: 'has_next')
  final bool hasNext;
  @JsonKey(name: 'has_prev')
  final bool hasPrev;

  const Pagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.hasNext,
    required this.hasPrev,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) => _$PaginationFromJson(json);

  Map<String, dynamic> toJson() => _$PaginationToJson(this);

  @override
  String toString() {
    return 'Pagination{currentPage: $currentPage, totalPages: $totalPages, totalItems: $totalItems}';
  }
}