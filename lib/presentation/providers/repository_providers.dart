import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/network/proxy_client.dart';
import '../../features/ingredient_analyzer/data/local_ingredient_repository.dart';
import '../../features/ingredient_analyzer/data/remote_ingredient_repository.dart';
import '../../features/ingredient_analyzer/domain/repositories/ingredient_repository.dart';
import '../../features/visual_qa/data/local_qa_repository.dart';
import '../../features/visual_qa/data/remote_qa_repository.dart';
import '../../features/visual_qa/domain/repositories/qa_repository.dart';

/// The proxy client, or `null` when remote features are not configured
/// (`ENABLE_REMOTE_QA`, `API_PROXY_URL` and `PROXY_API_KEY` must all be set).
/// Tests override this provider with a client backed by a fake HTTP client.
final proxyClientProvider = Provider<ProxyClient?>((ref) {
  if (!AppConfig.remoteConfigured) return null;
  final client = ProxyClient(
    baseUrl: AppConfig.apiProxyUrl,
    apiKey: AppConfig.proxyApiKey,
    timeout: Duration(seconds: AppConfig.remoteTimeoutSeconds),
  );
  ref.onDispose(client.close);
  return client;
});

/// Q&A: backend with on-device fallback, or purely on-device.
final qaRepositoryProvider = Provider<QaRepository>((ref) {
  final local = LocalQaRepository();
  final client = ref.watch(proxyClientProvider);
  return client == null
      ? local
      : RemoteQaRepository(client: client, fallback: local);
});

/// Ingredients: on-device extraction, summary optionally rephrased by the
/// backend.
final ingredientRepositoryProvider = Provider<IngredientRepository>((ref) {
  final local = LocalIngredientRepository();
  final client = ref.watch(proxyClientProvider);
  return client == null
      ? local
      : RemoteIngredientRepository(client: client, local: local);
});
