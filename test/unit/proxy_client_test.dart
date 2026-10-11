import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:visionassist_ai/core/network/proxy_client.dart';

ProxyClient _client(
  MockClientHandler handler, {
  Duration timeout = const Duration(seconds: 1),
  String baseUrl = 'https://proxy.test',
}) =>
    ProxyClient(
      baseUrl: baseUrl,
      apiKey: 'secret-key',
      client: MockClient(handler),
      timeout: timeout,
    );

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  group('ProxyClient', () {
    test('POSTs JSON to /v1<path> with the X-API-Key header', () async {
      late http.Request seen;
      final client = _client((req) async {
        seen = req;
        return _json({'ok': true});
      });

      final result = await client.postJson('/qa/answer', {'question': 'q'});

      expect(result, {'ok': true});
      expect(seen.method, 'POST');
      expect(seen.url.toString(), 'https://proxy.test/v1/qa/answer');
      expect(seen.headers['X-API-Key'], 'secret-key');
      expect(seen.headers['Content-Type'], contains('application/json'));
      expect(jsonDecode(seen.body), {'question': 'q'});
    });

    test('strips a trailing slash from the base URL', () async {
      late Uri seen;
      final client = _client(
        (req) async {
          seen = req.url;
          return _json({});
        },
        baseUrl: 'https://proxy.test/',
      );
      await client.postJson('/x', {});
      expect(seen.toString(), 'https://proxy.test/v1/x');
    });

    test('decodes UTF-8 bodies correctly', () async {
      final client = _client(
        (_) async => _json({'answer': 'Rp 15.000 – €'}),
      );
      final result = await client.postJson('/x', {});
      expect(result['answer'], 'Rp 15.000 – €');
    });

    test('non-200 status becomes ProxyException with the code', () async {
      final client = _client((_) async => _json({'detail': 'no'}, 401));
      expect(
        client.postJson('/x', {}),
        throwsA(
          isA<ProxyException>().having((e) => e.statusCode, 'status', 401),
        ),
      );
    });

    test('invalid JSON becomes ProxyException', () async {
      final client = _client((_) async => http.Response('not json', 200));
      expect(client.postJson('/x', {}), throwsA(isA<ProxyException>()));
    });

    test('JSON that is not an object becomes ProxyException', () async {
      final client = _client((_) async => _json(<String>['a']));
      expect(client.postJson('/x', {}), throwsA(isA<ProxyException>()));
    });

    test('timeout becomes ProxyException', () async {
      final never = Completer<http.Response>();
      final client = _client(
        (_) => never.future,
        timeout: const Duration(milliseconds: 30),
      );
      expect(client.postJson('/x', {}), throwsA(isA<ProxyException>()));
    });

    test('transport errors become ProxyException', () async {
      final client = _client((_) async => throw http.ClientException('boom'));
      expect(client.postJson('/x', {}), throwsA(isA<ProxyException>()));
    });
  });
}
