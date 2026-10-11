import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:visionassist_ai/core/network/proxy_client.dart';
import 'package:visionassist_ai/features/ingredient_analyzer/data/local_ingredient_repository.dart';
import 'package:visionassist_ai/features/ingredient_analyzer/data/remote_ingredient_repository.dart';

const _label = 'Mengandung susu dan telur. Bebas gluten. '
    'EXP: 12/12/2027. Rp 15.000';

RemoteIngredientRepository _repo(
  MockClientHandler handler, {
  List<http.Request>? log,
}) {
  final client = ProxyClient(
    baseUrl: 'https://proxy.test',
    apiKey: 'k',
    client: MockClient((req) {
      log?.add(req);
      return handler(req);
    }),
    timeout: const Duration(milliseconds: 200),
  );
  return RemoteIngredientRepository(
    client: client,
    local: LocalIngredientRepository(),
  );
}

http.Response _summary(String s) =>
    http.Response.bytes(utf8.encode(jsonEncode({'summary': s})), 200);

void main() {
  final localAnalysis = LocalIngredientRepository().analyze(_label);

  group('RemoteIngredientRepository', () {
    test('uses the remote summary but keeps local structured fields', () async {
      final repo = _repo(
        (_) async => _summary('Mengandung susu dan telur, kedaluwarsa 2027.'),
      );
      final r = await repo.analyze(_label);
      final local = await localAnalysis;

      expect(r.summary, 'Mengandung susu dan telur, kedaluwarsa 2027.');
      expect(r.allergens, local.allergens);
      expect(r.negatedAllergens, local.negatedAllergens);
      expect(r.expiryDate, local.expiryDate);
      expect(r.prices, local.prices);
    });

    test('sends the locally extracted fields to the proxy', () async {
      final log = <http.Request>[];
      final repo = _repo((_) async => _summary('Mengandung susu.'), log: log);
      await repo.analyze(_label);

      final sent = jsonDecode(log.single.body) as Map<String, dynamic>;
      final local = await localAnalysis;
      expect(log.single.url.path, '/v1/ingredients/summarize');
      expect(sent['allergens'], local.allergens);
      expect(sent['negated_allergens'], local.negatedAllergens);
      expect(sent['expiry_date'], local.expiryDate);
      expect(sent['prices'], local.prices);
      expect(sent['ocr_text'], _label);
    });

    test('keeps the local summary when the remote one leaks an allergen',
        () async {
      // Label has no wijen, but the "LLM" invents one.
      final repo = _repo((_) async => _summary('Mengandung susu dan wijen.'));
      final r = await repo.analyze(_label);
      expect(r.summary, (await localAnalysis).summary);
    });

    test('keeps the local summary when the remote one exceeds 15 words',
        () async {
      final long = List.filled(16, 'kata').join(' ');
      final repo = _repo((_) async => _summary(long));
      final r = await repo.analyze(_label);
      expect(r.summary, (await localAnalysis).summary);
    });

    test('keeps the local summary when the remote one is blank', () async {
      final repo = _repo((_) async => _summary('   '));
      final r = await repo.analyze(_label);
      expect(r.summary, (await localAnalysis).summary);
    });

    test('falls back to local on HTTP 503', () async {
      final repo = _repo((_) async => http.Response('down', 503));
      final r = await repo.analyze(_label);
      expect(r.summary, (await localAnalysis).summary);
    });

    test('falls back to local on network error', () async {
      final repo = _repo((_) async => throw http.ClientException('down'));
      final r = await repo.analyze(_label);
      expect(r.summary, (await localAnalysis).summary);
    });

    test('empty OCR text never hits the network', () async {
      final log = <http.Request>[];
      final repo = _repo((_) async => _summary('x'), log: log);
      await repo.analyze('   ');
      expect(log, isEmpty);
    });
  });
}
