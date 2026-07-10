// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

/// Интерактивный релиз: версия в pubspec.yaml, commit, git-тег.
/// В отличие от books_vault_reader, тег создаётся на текущей ветке (без merge develop → master).
void main() async {
  print('📦 UI Clone Release Tool 📦');

  if (!await _isGitRepo()) {
    print('Error: Not a git repository.');
    exit(1);
  }

  final currentBranch = await _getCurrentBranch();
  print('Current branch: $currentBranch');

  print('\nSelect release type:');
  print('1. Stable');
  print('2. Beta');
  print('3. Alpha');

  final selection = stdin.readLineSync()?.trim();
  final String releaseType;

  switch (selection) {
    case '1':
      releaseType = 'stable';
      break;
    case '2':
      releaseType = 'beta';
      break;
    case '3':
      releaseType = 'alpha';
      break;
    default:
      print('Invalid selection.');
      exit(1);
  }

  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print('Error: pubspec.yaml not found.');
    exit(1);
  }

  final pubspecContent = pubspecFile.readAsStringSync();
  final versionRegExp = RegExp(r'version:\s*(\d+\.\d+\.\d+)(\+(\d+))?');
  final match = versionRegExp.firstMatch(pubspecContent);

  if (match == null) {
    print('Error: Could not find version in pubspec.yaml.');
    exit(1);
  }

  final currentVersion = match.group(1)!;
  final currentBuild = match.group(3) != null ? int.parse(match.group(3)!) : 0;

  print('\nCurrent version in pubspec.yaml: $currentVersion+$currentBuild');

  final allTags = await _getAllTags();
  final tags = await _getTagsByPattern(releaseType);

  var suggestedVersion = currentVersion;
  var suggestedPubspecBuild = currentBuild + 1;
  var suggestedTagBuild = 1;

  final stableTags = await _getTagsByPattern('stable');
  final lastStableVersion = _extractLatestVersionFromTags(stableTags);

  if (lastStableVersion == currentVersion) {
    final parts = currentVersion.split('.');
    if (parts.length == 3) {
      final major = int.parse(parts[0]);
      final minor = int.parse(parts[1]);
      final patch = int.parse(parts[2]);
      suggestedVersion = '$major.$minor.${patch + 1}';
      print('\nCurrent version matches the latest stable release.');
      print('Suggesting a new version: $suggestedVersion');
    }
  }

  if (releaseType != 'stable') {
    final versionTags = tags
        .where((tag) => tag.startsWith('v$suggestedVersion-$releaseType.'))
        .toList();
    if (versionTags.isNotEmpty) {
      suggestedTagBuild =
          _findHighestBuildNumber(versionTags, suggestedVersion, releaseType) +
              1;
    }
  }

  if (allTags.isNotEmpty) {
    print('\nRecent tags:');
    for (var i = 0; i < allTags.length && i < 5; i++) {
      print('  ${allTags[i]}');
    }
  }

  final suggestedTag = releaseType == 'stable'
      ? 'v$suggestedVersion'
      : 'v$suggestedVersion-$releaseType.$suggestedTagBuild';

  print('\nSuggested tag: $suggestedTag');
  print('Suggested pubspec version: $suggestedVersion+$suggestedPubspecBuild');

  print('\nEnter new version (or press Enter to use $suggestedVersion):');
  final newVersion = stdin.readLineSync()?.trim();
  final version =
      newVersion?.isNotEmpty == true ? newVersion! : suggestedVersion;

  print(
      'Enter new pubspec build number (or press Enter to use $suggestedPubspecBuild):');
  final newPubspecBuildStr = stdin.readLineSync()?.trim();
  final pubspecBuild = newPubspecBuildStr?.isNotEmpty == true
      ? int.parse(newPubspecBuildStr!)
      : suggestedPubspecBuild;

  if (releaseType != 'stable') {
    print(
        'Enter new tag build number (or press Enter to use $suggestedTagBuild):');
    final newTagBuildStr = stdin.readLineSync()?.trim();
    suggestedTagBuild = newTagBuildStr?.isNotEmpty == true
        ? int.parse(newTagBuildStr!)
        : suggestedTagBuild;
  }

  print('\nUpdate pubspec version to $version+$pubspecBuild? (y/n)');
  if (stdin.readLineSync()?.trim().toLowerCase() != 'y') {
    print('Release cancelled.');
    exit(0);
  }

  final updatedPubspec = pubspecContent.replaceFirst(
    versionRegExp,
    'version: $version+$pubspecBuild',
  );
  pubspecFile.writeAsStringSync(updatedPubspec);
  print('Updated pubspec.yaml version to $version+$pubspecBuild');

  final tag = releaseType == 'stable'
      ? 'v$version'
      : 'v$version-$releaseType.$suggestedTagBuild';

  print('\nTag to create: $tag');
  print('Confirm? (y/n)');
  if (stdin.readLineSync()?.trim().toLowerCase() != 'y') {
    print('Tag creation cancelled. Version update is still applied.');
    exit(0);
  }

  print('\nExecuting git commands...');

  try {
    await _runCommand('git', ['add', 'pubspec.yaml', 'CHANGELOG.md']);
    print('✅ git add pubspec.yaml CHANGELOG.md');

    await _runCommand('git', ['commit', '-m', 'release: $tag']);
    print('✅ git commit -m "release: $tag"');

    await _pushCurrentBranch(currentBranch);
    print('✅ git push');

    await _runCommand('git', ['tag', tag]);
    print('✅ git tag $tag');

    final remote = await _defaultRemote();
    await _runCommand('git', ['push', remote, tag]);
    print('✅ git push $remote $tag');

    print('\n🎉 Release $tag completed successfully!');
    print('Next: see docs/release-build.md for local build and publish.');
  } catch (e) {
    print('\n❌ Error during git operations: $e');
    exit(1);
  }
}

Future<bool> _isGitRepo() async {
  try {
    final result =
        await Process.run('git', ['rev-parse', '--is-inside-work-tree']);
    return result.exitCode == 0 && result.stdout.toString().trim() == 'true';
  } catch (_) {
    return false;
  }
}

Future<String> _getCurrentBranch() async {
  final result =
      await Process.run('git', ['rev-parse', '--abbrev-ref', 'HEAD']);
  return result.stdout.toString().trim();
}

Future<List<String>> _getAllTags() async {
  final result = await Process.run('git', ['tag', '--sort=-v:refname']);
  if (result.exitCode != 0) {
    return [];
  }
  final output = result.stdout.toString().trim();
  if (output.isEmpty) {
    return [];
  }
  return LineSplitter.split(output).toList();
}

Future<List<String>> _getTagsByPattern(String releaseType) async {
  final allTags = await _getAllTags();

  if (releaseType == 'stable') {
    final stablePattern = RegExp(r'^v\d+\.\d+\.\d+$');
    return allTags.where((tag) => stablePattern.hasMatch(tag)).toList();
  }

  final preReleasePattern =
      RegExp(r'^v\d+\.\d+\.\d+-' + releaseType + r'\.\d+$');
  return allTags.where((tag) => preReleasePattern.hasMatch(tag)).toList();
}

String? _extractLatestVersionFromTags(List<String> tags) {
  if (tags.isEmpty) {
    return null;
  }
  final versionRegExp = RegExp(r'v(\d+\.\d+\.\d+)');
  return versionRegExp.firstMatch(tags.first)?.group(1);
}

int _findHighestBuildNumber(
  List<String> tags,
  String version,
  String releaseType,
) {
  var highestBuild = 0;
  final escapedVersion = RegExp.escape(version);
  final pattern = '^v$escapedVersion-$releaseType\\.(\\d+)\$';
  final buildRegExp = RegExp(pattern);

  for (final tag in tags) {
    final match = buildRegExp.firstMatch(tag);
    if (match != null) {
      final buildNum = int.parse(match.group(1)!);
      if (buildNum > highestBuild) {
        highestBuild = buildNum;
      }
    }
  }

  return highestBuild;
}

Future<bool> _hasUpstream() async {
  final result = await Process.run(
    'git',
    ['rev-parse', '--abbrev-ref', '--symbolic-full-name', '@{u}'],
  );
  return result.exitCode == 0;
}

Future<String> _defaultRemote() async {
  final result = await Process.run('git', ['remote']);
  if (result.exitCode != 0) {
    return 'origin';
  }
  final remotes = LineSplitter.split(result.stdout.toString().trim())
      .where((remote) => remote.isNotEmpty)
      .toList();
  return remotes.isNotEmpty ? remotes.first : 'origin';
}

Future<void> _pushCurrentBranch(String branch) async {
  if (await _hasUpstream()) {
    await _runCommand('git', ['push']);
    return;
  }

  final remote = await _defaultRemote();
  await _runCommand('git', ['push', '-u', remote, branch]);
  print('ℹ️  Set upstream: $remote/$branch');
}

Future<ProcessResult> _runCommand(
  String command,
  List<String> arguments,
) async {
  final result = await Process.run(command, arguments);
  if (result.exitCode != 0) {
    throw Exception(
      'Command failed: $command ${arguments.join(' ')}\n${result.stderr}',
    );
  }
  return result;
}
