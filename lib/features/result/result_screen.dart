import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import '../capture/capture_controller.dart';

class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({super.key});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  String _activeText({
    required String markdown,
    required String? structuredJson,
  }) {
    if (_tabs.index == 1 &&
        structuredJson != null &&
        structuredJson.isNotEmpty) {
      return structuredJson;
    }
    return markdown;
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(captureControllerProvider);
    final markdown = session.prompt ?? '';
    final structuredJson = session.structuredJson;
    final hasJson =
        structuredJson != null && structuredJson.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Промпт для клона'),
        actions: [
          IconButton(
            tooltip: 'Копировать',
            onPressed: markdown.isEmpty && !hasJson
                ? null
                : () async {
                    final text = _activeText(
                      markdown: markdown,
                      structuredJson: structuredJson,
                    );
                    await Clipboard.setData(ClipboardData(text: text));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _tabs.index == 1
                                ? 'JSON скопирован'
                                : 'Промпт скопирован',
                          ),
                        ),
                      );
                    }
                  },
            icon: const Icon(Icons.copy_rounded),
          ),
          IconButton(
            tooltip: 'Поделиться',
            onPressed: markdown.isEmpty && !hasJson
                ? null
                : () {
                    final text = _activeText(
                      markdown: markdown,
                      structuredJson: structuredJson,
                    );
                    Share.share(
                      text,
                      subject: _tabs.index == 1
                          ? 'UI Clone JSON'
                          : 'UI Clone prompt',
                    );
                  },
            icon: const Icon(Icons.ios_share_rounded),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          onTap: (_) => setState(() {}),
          tabs: const [
            Tab(text: 'Markdown'),
            Tab(text: 'JSON'),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.targetLabel ?? 'Сессия захвата',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  '${session.screenshotPaths.length} скриншотов · '
                  'палитра / экраны / компоненты в JSON',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.slate,
                      ),
                ),
                const SizedBox(height: 12),
                if (session.screenshotPaths.isNotEmpty)
                  SizedBox(
                    height: 96,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: session.screenshotPaths.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final path = session.screenshotPaths[index];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: AspectRatio(
                            aspectRatio: 9 / 16,
                            child: Image.file(
                              File(path),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                color: AppColors.mist,
                                child: const Icon(Icons.broken_image_outlined),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _ResultPane(
                  text: markdown.isEmpty ? 'Промпт пуст' : markdown,
                  empty: markdown.isEmpty,
                ),
                _ResultPane(
                  text: hasJson
                      ? structuredJson
                      : 'Структурированный JSON недоступен.\n'
                          'Модель вернула только текст — см. вкладку Markdown.',
                  empty: !hasJson,
                  mono: true,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: FilledButton(
              onPressed: () {
                ref.read(captureControllerProvider.notifier).reset();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Новый обзор'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultPane extends StatelessWidget {
  const _ResultPane({
    required this.text,
    this.empty = false,
    this.mono = false,
  });

  final String text;
  final bool empty;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE1E7EF)),
          ),
          child: SelectableText(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: empty ? AppColors.slate : AppColors.ink,
                  fontFamily: mono ? 'monospace' : null,
                  fontSize: mono ? 12.5 : null,
                ),
          ),
        ),
      ],
    );
  }
}
