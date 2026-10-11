import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:visionassist_ai/core/network/proxy_client.dart';
import 'package:visionassist_ai/features/visual_qa/data/local_qa_repository.dart';
import 'package:visionassist_ai/features/visual_qa/data/remote_qa_repository.dart';

const _ocr = 'Paracetamol 500mg. Diminum 3 kali sehari setelah makan.';

RemoteQaRepository _repo(
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
  return RemoteQaRepository(client: client, fallback: LocalQaRepository());
}

http.Response _ok(Map<String, Object?> body) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), 200);

void main() {
  group('RemoteQaRepository', () {
    test('maps the proxy response and sends snake_case fields', () async {
      final log = <http.Request>[];
      final repo = _repo(
        (_) async => _ok({
          'answer': 'Diminum 3 kali sehari setelah makan.',
          'is_grounded': true,
          'source_sentence': 'Diminum 3 kali sehari setelah makan.',
        }),
        log: log,
      );

      final a = await repo.answer(
        question: 'Berapa kali sehari?',
        ocrText: _ocr,
      );

      expect(a.answer, 'Diminum 3 kali sehari setelah makan.');
      expect(a.isGrounded, isTrue);
      expect(a.sourceSentence, isNotNull);
      expect(log.single.url.path, '/v1/qa/answer');
      expect(jsonDecode(log.single.body), {
        'question': 'Berapa kali sehari?',
        'ocr_text': _ocr,
      });
    });

    test('keeps an ungrounded proxy answer ungrounded', () async {
      final repo = _repo(
        (_) async => _ok({
          'answer': 'Saya tidak yakin, silakan tanyakan apoteker.',
          'is_grounded': false,
          'source_sentence': null,
        }),
      );
      final a = await repo.answer(question: 'Dosis?', ocrText: _ocr);
      expect(a.isGrounded, isFalse);
      expect(a.sourceSentence, isNull);
    });

    test('falls back to local on HTTP 500', () async {
      final repo = _repo((_) async => http.Response('oops', 500));
      final a = await repo.answer(question: 'kali sehari', ocrText: _ocr);
      expect(a.isGrounded, isTrue);
      expect(a.answer, contains('3 kali sehari'));
    });

    test('falls back to local on network error', () async {
      final repo = _repo((_) async => throw http.ClientException('down'));
      final a = await repo.answer(question: 'kali sehari', ocrText: _ocr);
      expect(a.answer, contains('3 kali sehari'));
    });

    test('falls back to local on a malformed body', () async {
      final repo = _repo((_) async => _ok({'unexpected': 1}));
      final a = await repo.answer(question: 'kali sehari', ocrText: _ocr);
      expect(a.answer, contains('3 kali sehari'));
    });

    test('empty OCR text never hits the network', () async {
      final log = <http.Request>[];
      final repo = _repo((_) async => _ok({}), log: log);
      final a = await repo.answer(question: 'Dosis?', ocrText: '   ');
      expect(log, isEmpty);
      expect(a.isGrounded, isFalse);
      expect(a.answer, 'Saya tidak yakin, silakan tanyakan apoteker.');
    });

    test('clips overlong text to the backend limit of 2000 chars', () async {
      final log = <http.Request>[];
      final repo = _repo(
        (_) async => _ok({'answer': 'x', 'is_grounded': true}),
        log: log,
      );
      await repo.answer(question: 'q' * 5000, ocrText: 'o' * 5000);
      final sent = jsonDecode(log.single.body) as Map<String, dynamic>;
      expect((sent['question'] as String).length, 2000);
      expect((sent['ocr_text'] as String).length, 2000);
    });
  });
}
