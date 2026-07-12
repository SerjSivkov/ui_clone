import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Information about the latest GitHub release.
class UpdateInfo {
  const UpdateInfo({
    required this.version,
    required this.body,
    required this.url,
  });

  final String version;
  final String body;
  final String url;
}

/// Result of a version check.
class UpdateCheckResult {
  const UpdateCheckResult({
    this.info,
    required this.checkedAt,
    required this.fromCache,
    this.hasError = false,
  });

  final UpdateInfo? info;
  final DateTime checkedAt;
  final bool fromCache;
  final bool hasError;
}

const _cacheTtl = Duration(hours: 4);
const _checkedAtKey = 'update_check_checked_at';
const _versionKey = 'update_check_version';
const _bodyKey = 'update_check_body';
const _urlKey = 'update_check_url';

/// Checks GitHub releases for a newer version, using a local cache.
Future<UpdateCheckResult> checkForUpdateWithCache(
  SharedPreferences prefs, {
  bool ignoreCache = false,
}) async {
  final now = DateTime.now();

  if (!ignoreCache) {
    final checkedAtMillis = prefs.getInt(_checkedAtKey);
    if (checkedAtMillis != null) {
      final checkedAt = DateTime.fromMillisecondsSinceEpoch(checkedAtMillis);
      if (now.difference(checkedAt) < _cacheTtl) {
        final version = prefs.getString(_versionKey);
        final body = prefs.getString(_bodyKey);
        final url = prefs.getString(_urlKey);

        if (version != null && body != null && url != null) {
          final packageInfo = await PackageInfo.fromPlatform();
          if (!_isNewerVersion(packageInfo.version, version)) {
            return UpdateCheckResult(
              info: null,
              checkedAt: checkedAt,
              fromCache: true,
            );
          }
          return UpdateCheckResult(
            info: UpdateInfo(version: version, body: body, url: url),
            checkedAt: checkedAt,
            fromCache: true,
          );
        }
      }
    }
  }

  try {
    final info = await _fetchLatestRelease();
    await _saveCache(prefs, info);
    return UpdateCheckResult(
      info: info,
      checkedAt: now,
      fromCache: false,
    );
  } catch (_) {
    return UpdateCheckResult(
      info: null,
      checkedAt: now,
      fromCache: false,
      hasError: true,
    );
  }
}

Future<UpdateInfo?> _fetchLatestRelease() async {
  final packageInfo = await PackageInfo.fromPlatform();
  final currentVersion = packageInfo.version;

  final response = await http.get(
    Uri.parse(
      'https://api.github.com/repos/SerjSivkov/ui_clone/releases/latest',
    ),
    headers: {'Accept': 'application/vnd.github+json'},
  );

  if (response.statusCode != 200) return null;

  final data = jsonDecode(response.body) as Map<String, dynamic>;
  final tag = data['tag_name'] as String?;
  final body = data['body'] as String?;
  final htmlUrl = data['html_url'] as String?;

  if (tag == null || body == null || htmlUrl == null) return null;

  final latestVersion = _stripVersionPrefix(tag);
  if (!_isNewerVersion(currentVersion, latestVersion)) return null;

  return UpdateInfo(
    version: latestVersion,
    body: body,
    url: htmlUrl,
  );
}

Future<void> _saveCache(SharedPreferences prefs, UpdateInfo? info) async {
  final now = DateTime.now();
  await prefs.setInt(_checkedAtKey, now.millisecondsSinceEpoch);
  if (info != null) {
    await prefs.setString(_versionKey, info.version);
    await prefs.setString(_bodyKey, info.body);
    await prefs.setString(_urlKey, info.url);
  } else {
    await prefs.remove(_versionKey);
    await prefs.remove(_bodyKey);
    await prefs.remove(_urlKey);
  }
}

String _stripVersionPrefix(String tag) {
  return tag.replaceFirst(RegExp(r'^v'), '');
}

bool _isNewerVersion(String current, String latest) {
  final currentParts = _parseVersion(current);
  final latestParts = _parseVersion(latest);

  if (currentParts == null || latestParts == null) return false;

  for (var i = 0; i < 3; i++) {
    final diff = latestParts[i] - currentParts[i];
    if (diff != 0) return diff > 0;
  }
  return false;
}

List<int>? _parseVersion(String version) {
  final parts = version.split('.');
  if (parts.length < 3) return null;

  final numbers = <int>[];
  for (var i = 0; i < 3; i++) {
    final n = int.tryParse(parts[i]);
    if (n == null) return null;
    numbers.add(n);
  }
  return numbers;
}
