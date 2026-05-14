import 'dart:io';

import 'package:dart_ari/dart_ari.dart';

HttpClient client = HttpClient();
Config config = Config();

/// Optional dedup hooks set by the active [ARI] instance so static factory
/// methods on `Bridge` / `Channel` (e.g. `Bridge.list()`) can route through
/// the live cache instead of creating duplicate instances for ids that the
/// client already tracks.
///
/// Typed as `dynamic Function(dynamic)` to avoid a circular import on the
/// `Bridge` / `Channel` types (which live in libraries that themselves
/// import this file). Callers cast the result back to the concrete type.
dynamic Function(dynamic json)? bridgeDeduper;
dynamic Function(dynamic json)? channelDeduper;
