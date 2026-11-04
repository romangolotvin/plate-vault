/// An owner's review of a plate the app already stored.
///
/// [scannedNumber] is the text Plate Vault kept from the scan.
/// [correctedNumber] is what the collector typed under «Скорректировать номер».
enum AppealDelivery {
  /// Saved on the phone. The desktop program has not accepted it yet.
  queued,

  /// Desktop has the appeal and the owner has not decided.
  sent,

  approved,
  rejected,
}

class PlateAppeal {
  PlateAppeal({
    required this.id,
    required this.plateItemId,
    required this.countryCode,
    required this.scannedNumber,
    required this.correctedNumber,
    required this.photoPaths,
    required this.createdAt,
    required this.delivery,
    this.error,
  });

  final String id;
  final String plateItemId;
  final String countryCode;

  /// Number as the system stored it.
  final String scannedNumber;

  /// Number the collector wants instead.
  final String correctedNumber;

  /// Local photo files that belong to the plate.
  final List<String> photoPaths;
  final DateTime createdAt;
  final AppealDelivery delivery;
  final String? error;

  bool get isOpen =>
      delivery == AppealDelivery.queued || delivery == AppealDelivery.sent;

  PlateAppeal copyWith({
    AppealDelivery? delivery,
    String? error,
    bool clearError = false,
  }) {
    return PlateAppeal(
      id: id,
      plateItemId: plateItemId,
      countryCode: countryCode,
      scannedNumber: scannedNumber,
      correctedNumber: correctedNumber,
      photoPaths: photoPaths,
      createdAt: createdAt,
      delivery: delivery ?? this.delivery,
      error: clearError ? null : (error ?? this.error),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'plateItemId': plateItemId,
    'countryCode': countryCode,
    'scannedNumber': scannedNumber,
    'correctedNumber': correctedNumber,
    'photoPaths': photoPaths,
    'createdAt': createdAt.toIso8601String(),
    'delivery': delivery.name,
    'error': error,
  };

  /// Payload the desktop program stores and shows.
  Map<String, dynamic> toDesktopMeta() => {
    'id': id,
    'plateItemId': plateItemId,
    'countryCode': countryCode,
    'scannedNumber': scannedNumber,
    'correctedNumber': correctedNumber,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  factory PlateAppeal.fromJson(Map<String, dynamic> json) {
    final photos = json['photoPaths'];
    return PlateAppeal(
      id: json['id'] as String? ?? '',
      plateItemId: json['plateItemId'] as String? ?? '',
      countryCode: (json['countryCode'] as String? ?? '').toUpperCase(),
      scannedNumber: json['scannedNumber'] as String? ?? '',
      correctedNumber: json['correctedNumber'] as String? ?? '',
      photoPaths: photos is List
          ? photos.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
          : const [],
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      delivery: AppealDelivery.values.firstWhere(
        (e) => e.name == json['delivery'],
        orElse: () => AppealDelivery.queued,
      ),
      error: json['error'] as String?,
    );
  }
}

PlateAppeal? latestAppeal(List<PlateAppeal> all, String plateItemId) {
  PlateAppeal? latest;
  for (final appeal in all) {
    if (appeal.plateItemId != plateItemId) continue;
    if (latest == null || appeal.createdAt.isAfter(latest.createdAt)) {
      latest = appeal;
    }
  }
  return latest;
}

/// Why a new appeal cannot be filed, or null when it can.
String? appealBlockReason(List<PlateAppeal> all, String plateItemId) {
  final latest = latestAppeal(all, plateItemId);
  if (latest != null && latest.isOpen) {
    return 'Заявление уже отправлено и ждёт решения владельца.';
  }
  return null;
}

List<PlateAppeal> upsertAppeal(List<PlateAppeal> all, PlateAppeal appeal) {
  final next = [...all];
  final index = next.indexWhere((e) => e.id == appeal.id);
  if (index >= 0) {
    next[index] = appeal;
  } else {
    next.insert(0, appeal);
  }
  next.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return next;
}

String appealDeliveryLabel(AppealDelivery delivery) {
  return switch (delivery) {
    AppealDelivery.queued => 'Ждёт отправки',
    AppealDelivery.sent => 'На рассмотрении',
    AppealDelivery.approved => 'Принято',
    AppealDelivery.rejected => 'Отклонено',
  };
}

/// Maps the desktop program's status string onto the phone.
AppealDelivery deliveryFromServer(String status) {
  return switch (status) {
    'approved' => AppealDelivery.approved,
    'rejected' => AppealDelivery.rejected,
    _ => AppealDelivery.sent,
  };
}
