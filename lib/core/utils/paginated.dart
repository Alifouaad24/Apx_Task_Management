import 'package:equatable/equatable.dart';

/// Layer-neutral pagination envelope used by repositories, use cases and
/// controllers alike. It carries no transport details, so the domain layer can
/// depend on it safely.
class Paginated<T> extends Equatable {
  const Paginated({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  /// Convenience constructor for a single, complete page.
  factory Paginated.single(List<T> items) => Paginated<T>(
        items: items,
        page: 1,
        limit: items.length,
        total: items.length,
        totalPages: 1,
      );

  factory Paginated.empty() => Paginated<T>(
        items: const [],
        page: 1,
        limit: 0,
        total: 0,
        totalPages: 0,
      );

  final List<T> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  /// `true` when another page can be requested.
  bool get hasMore => page < totalPages;

  int get nextPage => page + 1;

  bool get isEmpty => items.isEmpty;

  /// Maps the payload while keeping the pagination metadata intact.
  Paginated<R> map<R>(R Function(T item) transform) => Paginated<R>(
        items: items.map(transform).toList(growable: false),
        page: page,
        limit: limit,
        total: total,
        totalPages: totalPages,
      );

  @override
  List<Object?> get props => [items, page, limit, total, totalPages];
}
