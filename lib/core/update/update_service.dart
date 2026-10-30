import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';

class UpdateCheckResult {
  const UpdateCheckResult({
    required this.upToDate,
    required this.currentVersion,
    this.latestVersion,
    this.releaseNotes,
    this.releaseUrl,
    this.apkUrl,
    this.message,
  });

  final bool upToDate;
  final String currentVersion;
  final String? latestVersion;
  final String? releaseNotes;
  final String? releaseUrl;
  final String? apkUrl;
  final String? message;
}

/// Abstraction so Settings UI stays store-ready.
/// Swap [GithubReleaseUpdateService] for [StoreUpdateService] later.
abstract class UpdateService {
  Future<UpdateCheckResult> check();
  Future<void> openUpdate(UpdateCheckResult result);
}

class GithubReleaseUpdateService implements UpdateService {
  GithubReleaseUpdateService({
    this.owner = AppConstants.githubOwner,
    this.repo = AppConstants.githubRepo,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String owner;
  final String repo;
  final http.Client _client;

  @override
  Future<UpdateCheckResult> check() async {
    final info = await PackageInfo.fromPlatform();
    final current = info.version;

    if (owner.contains('YOUR_') || repo.isEmpty) {
      return UpdateCheckResult(
        upToDate: true,
        currentVersion: current,
        message:
            'Укажите githubOwner/githubRepo в constants.dart для проверки релизов.',
      );
    }

    final uri = Uri.https(
      'api.github.com',
      '/repos/$owner/$repo/releases/latest',
    );

    try {
      final response = await _client.get(
        uri,
        headers: {
          'Accept': 'application/vnd.github+json',
          'User-Agent': 'PlateVault-UpdateCheck',
        },
      );

      if (response.statusCode == 404) {
        return UpdateCheckResult(
          upToDate: true,
          currentVersion: current,
          message: 'Релизов на GitHub пока нет.',
        );
      }
      if (response.statusCode != 200) {
        return UpdateCheckResult(
          upToDate: true,
          currentVersion: current,
          message: 'Не удалось проверить обновления (${response.statusCode}).',
        );
      }

      final body = response.body;
      final tag = _extractJsonString(body, 'tag_name')?.replaceFirst('v', '');
      final htmlUrl = _extractJsonString(body, 'html_url');
      final notes = _extractJsonString(body, 'body');
      final apkUrl = _findApkAsset(body);

      if (tag == null) {
        return UpdateCheckResult(
          upToDate: true,
          currentVersion: current,
          message: 'Некорректный ответ GitHub.',
        );
      }

      final newer = _isNewer(tag, current);
      return UpdateCheckResult(
        upToDate: !newer,
        currentVersion: current,
        latestVersion: tag,
        releaseNotes: notes,
        releaseUrl: htmlUrl,
        apkUrl: apkUrl,
        message: newer
            ? 'Доступна версия $tag'
            : 'У вас актуальная версия $current',
      );
    } catch (e) {
      return UpdateCheckResult(
        upToDate: true,
        currentVersion: current,
        message: 'Ошибка сети при проверке обновлений.',
      );
    }
  }

  @override
  Future<void> openUpdate(UpdateCheckResult result) async {
    if (!kIsWeb && Platform.isIOS) {
      final store = Uri.parse(AppConstants.appStoreUrl);
      if (await canLaunchUrl(store)) {
        await launchUrl(store, mode: LaunchMode.externalApplication);
        return;
      }
    }

    final target = result.apkUrl ?? result.releaseUrl;
    if (target == null) return;
    final uri = Uri.parse(target);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  bool _isNewer(String latest, String current) {
    List<int> parts(String v) => v
        .split(RegExp(r'[^0-9]+'))
        .where((e) => e.isNotEmpty)
        .map(int.parse)
        .toList();
    final a = parts(latest);
    final b = parts(current);
    final len = a.length > b.length ? a.length : b.length;
    for (var i = 0; i < len; i++) {
      final x = i < a.length ? a[i] : 0;
      final y = i < b.length ? b[i] : 0;
      if (x != y) return x > y;
    }
    return false;
  }

  String? _extractJsonString(String json, String key) {
    final match = RegExp('"$key"\\s*:\\s*"((?:\\\\.|[^"\\\\])*)"')
        .firstMatch(json);
    return match?.group(1)?.replaceAll(r'\n', '\n').replaceAll(r'\"', '"');
  }

  String? _findApkAsset(String json) {
    final match = RegExp(
      r'"browser_download_url"\s*:\s*"(https://[^"]+\.apk)"',
      caseSensitive: false,
    ).firstMatch(json);
    return match?.group(1);
  }
}

/// Future Play / App Store implementation — wire this in after listing goes live.
class StoreUpdateService implements UpdateService {
  @override
  Future<UpdateCheckResult> check() async {
    final info = await PackageInfo.fromPlatform();
    return UpdateCheckResult(
      upToDate: true,
      currentVersion: info.version,
      message:
          'Обновления будут приходить через Google Play и App Store.',
      releaseUrl: Platform.isIOS
          ? AppConstants.appStoreUrl
          : AppConstants.playStoreUrl,
    );
  }

  @override
  Future<void> openUpdate(UpdateCheckResult result) async {
    final url = result.releaseUrl ??
        (Platform.isIOS
            ? AppConstants.appStoreUrl
            : AppConstants.playStoreUrl);
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
