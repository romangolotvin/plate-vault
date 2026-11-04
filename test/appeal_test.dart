import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:plate_vault/data/appeals/appeal_client.dart';
import 'package:plate_vault/data/appeals/plate_appeal.dart';
import 'package:plate_vault/features/appeals/appeal_widgets.dart';

void main() {
  test('desktop meta keeps the scanned number and the correction', () {
    final appeal = PlateAppeal(
      id: 'a1',
      plateItemId: 'p1',
      countryCode: 'RU',
      scannedNumber: 'М777ЕР178',
      correctedNumber: 'М777ЕР177',
      photoPaths: const ['/tmp/wide.jpg', '/tmp/close.jpg'],
      createdAt: DateTime.utc(2026, 11, 4, 18),
      delivery: AppealDelivery.queued,
    );
    final meta = appeal.toDesktopMeta();
    expect(meta['scannedNumber'], 'М777ЕР178');
    expect(meta['correctedNumber'], 'М777ЕР177');
    expect(meta['plateItemId'], 'p1');
    expect(meta.containsKey('photoPaths'), isFalse);

    final restored = PlateAppeal.fromJson(appeal.toJson());
    expect(restored.scannedNumber, appeal.scannedNumber);
    expect(restored.correctedNumber, appeal.correctedNumber);
    expect(restored.photoPaths, appeal.photoPaths);
    expect(restored.delivery, AppealDelivery.queued);
  });

  test('a plate can have only one open appeal', () {
    final open = PlateAppeal(
      id: 'open',
      plateItemId: 'plate',
      countryCode: 'RU',
      scannedNumber: 'A1',
      correctedNumber: 'B1',
      photoPaths: const [],
      createdAt: DateTime.utc(2026, 11, 1),
      delivery: AppealDelivery.sent,
    );
    expect(appealBlockReason([open], 'plate'), isNotNull);
    expect(appealDeliveryLabel(open.delivery), 'На рассмотрении');

    final closed = open.copyWith(delivery: AppealDelivery.rejected);
    expect(appealBlockReason([closed], 'plate'), isNull);
    expect(latestAppeal([open, closed], 'plate')?.id, 'open');
  });

  test('server status maps onto the phone delivery', () {
    expect(deliveryFromServer('pending'), AppealDelivery.sent);
    expect(deliveryFromServer('approved'), AppealDelivery.approved);
    expect(deliveryFromServer('rejected'), AppealDelivery.rejected);
  });

  test('submit posts both numbers and the photo bytes', () async {
    late String authorization;
    late Map<String, dynamic> meta;
    late List<int> bodyBytes;
    final client = AppealClient(
      client: _CaptureClient(
        onSend: (request) async {
          authorization = request.headers['authorization'] ?? '';
          bodyBytes = await request.finalize().toBytes();
          final body = utf8.decode(bodyBytes);
          final metaStart = body.indexOf('{');
          final metaEnd = body.indexOf('}');
          meta = jsonDecode(
            body.substring(metaStart, metaEnd + 1),
          ) as Map<String, dynamic>;
          return http.StreamedResponse(
            Stream<List<int>>.value(
              utf8.encode(
                jsonEncode({
                  'id': meta['id'],
                  'status': 'pending',
                  'scannedNumber': meta['scannedNumber'],
                  'correctedNumber': meta['correctedNumber'],
                }),
              ),
            ),
            201,
          );
        },
      ),
    );
    final appeal = PlateAppeal(
      id: 'appeal-1',
      plateItemId: 'plate-1',
      countryCode: 'RU',
      scannedNumber: 'A123BC77',
      correctedNumber: 'А123ВС77',
      photoPaths: const [],
      createdAt: DateTime.utc(2026, 11, 4),
      delivery: AppealDelivery.queued,
    );
    final view = await client.submit(
      baseUrl: 'http://127.0.0.1:8787',
      token: 'CODE1234',
      appeal: appeal,
      photos: [
        AppealPhotoBytes(filename: 'wide.jpg', bytes: const [9, 8, 7]),
      ],
    );
    expect(authorization, 'Bearer CODE1234');
    expect(view.status, 'pending');
    expect(meta['scannedNumber'], 'A123BC77');
    expect(meta['correctedNumber'], 'А123ВС77');
    expect(bodyBytes, containsAll(<int>[9, 8, 7]));
  });

  testWidgets('profile appeal button is labeled Обжаловать', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppealBar(
            statusLabel: 'Ждёт отправки',
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );
    expect(find.text('Обжаловать'), findsOneWidget);
    expect(find.text('Ждёт отправки'), findsOneWidget);
    await tester.tap(find.text('Обжаловать'));
    expect(tapped, isTrue);
  });

  testWidgets('correction field is labeled Скорректировать номер', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppealCorrectedField(controller: TextEditingController()),
        ),
      ),
    );
    expect(find.text('Скорректировать номер'), findsOneWidget);
  });
}

class _CaptureClient extends http.BaseClient {
  _CaptureClient({required this.onSend});

  final Future<http.StreamedResponse> Function(http.BaseRequest request) onSend;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      onSend(request);
}
