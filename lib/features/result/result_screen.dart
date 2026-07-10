import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/capture_session.dart';
import '../capture/capture_controller.dart';
import '../capture/screenshot_thumb.dart';
import 'reanalyze_sheet.dart';

class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({super.key});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _reanalyzing = false;

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

  Future<void> _onReanalyze() async {
    if (_reanalyzing) return;
    final confirmed = await showReanalyzeSheet(context, ref);
    if (!confirmed || !mounted) return;

    setState(() => _reanalyzing = true);
    final error =
        await ref.read(captureControllerProvider.notifier).reanalyze();
    if (!mounted) return;
    setState(() => _reanalyzing = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Анализ обновлён')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(captureControllerProvider);
    final analyzing = session.status == CaptureStatus.analyzing;
    final markdown = session.prompt ?? '';
    final structuredJson = session.structuredJson;
    final hasJson =
        structuredJson != null && structuredJson.trim().isNotEmpty;

    if (analyzing) {
      return PopScope(
        canPop: false,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Повторный анализ'),
            automaticallyImplyLeading: false,
          ),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  session.targetLabel ?? 'Сессия захвата',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${session.screenshotPaths.length} скриншотов · '
                  'те же кадры, новые настройки AI',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.slate,
                      ),
                ),
                const Spacer(),
                LinearProgressIndicator(
                  value: session.analysisProgress?.clamp(0.0, 1.0),
                ),
                const SizedBox(height: 16),
                Text(
                  _analysisDetail(session),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  _analysisPhaseLabel(session.analysisPhase),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.slate,
                      ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () {
                    ref
                        .read(captureControllerProvider.notifier)
                        .cancelAnalysis();
                  },
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Отменить анализ'),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
                        final canDelete =
                            !_reanalyzing &&
                            session.screenshotPaths.length > 1;
                        return ScreenshotThumb(
                          path: path,
                          aspectRatio: 9 / 16,
                          canDelete: canDelete,
                          onDelete: () => _confirmRemove(context, path),
                        );
                      },
                    ),
                  ),
                if (session.screenshotPaths.length > 1) ...[
                  const SizedBox(height: 8),
                  Text(
                    '× на кадре — убрать из сессии перед повторным анализом '
                    '(минимум 1).',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.slate,
                        ),
                  ),
                ],
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: session.screenshotPaths.isEmpty || _reanalyzing
                      ? null
                      : _onReanalyze,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Повторить анализ'),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: () {
                    ref.read(captureControllerProvider.notifier).reset();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('Новый обзор'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _analysisPhaseLabel(String? phase) {
    return switch (phase) {
      'preparing' => 'Подготовка изображений',
      'uploading' => 'Отправка в AI',
      'waiting' => 'Ждём ответ модели',
      _ => 'Анализ AI',
    };
  }

  String _analysisDetail(CaptureSession session) {
    final done = session.analysisImagesDone;
    final total = session.analysisImagesTotal;
    final images = total > 0 ? '$done/$total' : (done > 0 ? '$done' : '…');
    final eta = session.analysisEtaSec;
    final etaLabel = eta == null
        ? null
        : eta <= 0
            ? 'скоро'
            : '~$eta с';
    return switch (session.analysisPhase) {
      'preparing' =>
        etaLabel == null ? 'Сжатие $images' : 'Сжатие $images · $etaLabel',
      'uploading' =>
        etaLabel == null ? 'Загрузка $images' : 'Загрузка $images · $etaLabel',
      'waiting' => etaLabel == null
          ? 'Анализ $images фото'
          : 'Анализ $images фото · $etaLabel',
      _ => 'Собираем промпт…',
    };
  }

  Future<void> _confirmRemove(BuildContext context, String path) async {
    final count = ref.read(captureControllerProvider).screenshotPaths.length;
    if (count <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Должен остаться хотя бы один скриншот'),
        ),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить кадр?'),
        content: const Text(
          'Скриншот будет убран из сессии. Для нового промпта нажмите '
          '«Повторить анализ».',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final error =
        ref.read(captureControllerProvider.notifier).removeScreenshot(path);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
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
