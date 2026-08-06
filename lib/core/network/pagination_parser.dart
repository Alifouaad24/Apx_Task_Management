import 'dart:math';

import '../utils/paginated.dart';
import 'api_client.dart';

/// Builds a [Paginated] from a `{data: [...], meta: {...}}` response.
///
/// Shared by every paginated data source so the (surprisingly fiddly) metadata
/// normalisation exists once: key aliases differ between APIs, and `totalPages`
/// is frequently missing and must be derived.
class PaginationParser {
  const PaginationParser._();

  static Paginated<T> parse<T>(
    dynamic body, {
    required T Function(Map<String, dynamic> json) itemBuilder,
    required int requestedPage,
    required int requestedLimit,
  }) {
    final rawItems = ApiResponseParser.list(body);
    final meta = ApiResponseParser.meta(body);

    final items = <T>[];
    for (final entry in rawItems) {
      if (entry is Map<String, dynamic>) {
        try {
          items.add(itemBuilder(entry));
        } catch (_) {
          // Skip malformed records rather than failing the whole page.
          continue;
        }
      }
    }

    int? readInt(List<String> keys) {
      for (final key in keys) {
        final value = meta[key];
        if (value is num) return value.toInt();
        if (value is String) {
          final parsed = int.tryParse(value);
          if (parsed != null) return parsed;
        }
      }
      return null;
    }

    final page = readInt(['page', 'currentPage', 'current_page']) ?? requestedPage;
    final limit =
        readInt(['limit', 'perPage', 'per_page', 'pageSize']) ?? requestedLimit;
    final total = readInt(['total', 'totalItems', 'total_count', 'count']) ??
        items.length;

    var totalPages = readInt(['totalPages', 'total_pages', 'lastPage', 'last_page']);
    totalPages ??= limit > 0 ? (total / limit).ceil() : 1;

    return Paginated<T>(
      items: items,
      page: page,
      limit: limit,
      total: total,
      // Guard against a server reporting fewer pages than we are already on.
      totalPages: max(totalPages, items.isEmpty ? 0 : page),
    );
  }
}
