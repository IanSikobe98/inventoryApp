import 'json_helpers.dart';

/// Spring Data's `Page<T>` JSON, reduced to what the UI needs.
class PageResult<T> {
  const PageResult({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.number,
    required this.last,
  });

  final List<T> content;
  final int totalElements;
  final int totalPages;
  final int number;
  final bool last;

  factory PageResult.fromJson(
    Map<String, dynamic> j,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return PageResult(
      content: ((j['content'] as List?) ?? const [])
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList(),
      totalElements: asInt(j['totalElements']),
      totalPages: asInt(j['totalPages']),
      number: asInt(j['number']),
      last: j['last'] as bool? ?? true,
    );
  }
}
