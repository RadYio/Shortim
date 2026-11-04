import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/series.dart';
import '../models/timer_interval.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../widgets/shortim_mark.dart';
import '../widgets/transitions.dart';
import 'run_screen.dart';

/// First-run flow (see the `app-onboarding-design` skill): one activation
/// moment — starting a timer — reached in three screens. Welcome, a single
/// tap-to-choose question that visibly shapes the next screen, then the
/// personalised result itself, one tap from running.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.sounds,
    required this.storage,
    required this.onDone,
  });

  final SoundService sounds;
  final StorageService storage;

  /// Called once onboarding is complete; the shell takes over from there.
  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

enum _Category { hiit, stretch, breathing, custom }

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  _Category? _chosen;

  String _nextId(int seed) => '${DateTime.now().microsecondsSinceEpoch}-$seed';

  Series _seriesFor(_Category category) {
    TimerInterval iv(int seed, int seconds) =>
        TimerInterval(id: _nextId(seed), seconds: seconds);
    return switch (category) {
      _Category.hiit => Series(
        intervals: [iv(0, 20), iv(1, 10)],
        loopMode: LoopMode.repeatN,
        loopCount: 8,
      ),
      _Category.stretch => Series(
        intervals: [iv(0, 30)],
        loopMode: LoopMode.repeatN,
        loopCount: 6,
      ),
      _Category.breathing => Series(
        intervals: [iv(0, 4), iv(1, 4), iv(2, 4)],
        loopMode: LoopMode.repeatN,
        loopCount: 5,
      ),
      _Category.custom => Series(intervals: [iv(0, 30)]),
    };
  }

  void _choose(_Category category) {
    setState(() => _chosen = category);
    _pages.nextPage(duration: AppMotion.slow, curve: AppMotion.brand);
  }

  Future<void> _finish({required bool launch}) async {
    final series = _seriesFor(_chosen ?? _Category.custom);
    await widget.storage.saveDraft(series);
    await widget.storage.setOnboarded();
    if (!mounted) return;
    widget.onDone();
    if (launch) {
      Navigator.of(context).pushReplacement(
        fadeSlideRoute<void>(
          (_) => RunScreen(series: series, sounds: widget.sounds, storage: widget.storage),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _pages,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _WelcomePage(onStart: () => _pages.nextPage(
              duration: AppMotion.slow,
              curve: AppMotion.brand,
            )),
            _CategoryPage(onChoose: _choose),
            _ResultPage(
              category: _chosen ?? _Category.custom,
              series: _seriesFor(_chosen ?? _Category.custom),
              onStartNow: () => _finish(launch: true),
              onEditFirst: () => _finish(launch: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: AppMotion.slow,
            curve: AppMotion.emphasis,
            builder: (context, t, child) => Transform.scale(
              scale: 0.8 + 0.2 * t,
              child: Opacity(opacity: t.clamp(0, 1), child: child),
            ),
            child: CustomPaint(
              size: const Size.square(72),
              painter: const ShortimMarkPainter(),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            context.l10n.onboardWelcomeTitle,
            textAlign: TextAlign.center,
            style: AppText.wordmark(fontSize: 34),
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.onboardWelcomeSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: AppColors.brand300),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onStart,
              child: Text(context.l10n.onboardStart),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _CategoryPage extends StatelessWidget {
  const _CategoryPage({required this.onChoose});

  final ValueChanged<_Category> onChoose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final options = [
      (_Category.hiit, Icons.bolt_rounded, l10n.onboardHiit, l10n.onboardHiitHint),
      (
        _Category.stretch,
        Icons.self_improvement_rounded,
        l10n.onboardStretch,
        l10n.onboardStretchHint,
      ),
      (
        _Category.breathing,
        Icons.air_rounded,
        l10n.onboardBreathing,
        l10n.onboardBreathingHint,
      ),
      (
        _Category.custom,
        Icons.tune_rounded,
        l10n.onboardCustom,
        l10n.onboardCustomHint,
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.onboardCategoryTitle, style: AppText.wordmark(fontSize: 28)),
          const SizedBox(height: 8),
          Text(
            l10n.onboardCategorySubtitle,
            style: TextStyle(fontSize: 15, color: AppColors.brand400),
          ),
          const SizedBox(height: 28),
          for (final (i, option) in options.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _CategoryTile(
                icon: option.$2,
                title: option.$3,
                hint: option.$4,
                delay: i,
                onTap: () => onChoose(option.$1),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.icon,
    required this.title,
    required this.hint,
    required this.delay,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String hint;
  final int delay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.slow,
      curve: Interval(0.08 * delay, 1, curve: AppMotion.brand),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 16 * (1 - t)), child: child),
      ),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.brand700),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Icon(icon, color: AppColors.text, size: 26),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hint,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.brand400,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.brand500),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultPage extends StatelessWidget {
  const _ResultPage({
    required this.category,
    required this.series,
    required this.onStartNow,
    required this.onEditFirst,
  });

  final _Category category;
  final Series series;
  final VoidCallback onStartNow;
  final VoidCallback onEditFirst;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = switch (category) {
      _Category.hiit => l10n.onboardHiit,
      _Category.stretch => l10n.onboardStretch,
      _Category.breathing => l10n.onboardBreathing,
      _Category.custom => l10n.onboardCustom,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.onboardResultTitle, style: AppText.wordmark(fontSize: 28)),
          const SizedBox(height: 24),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: AppMotion.slow,
            curve: AppMotion.emphasis,
            builder: (context, t, child) => Transform.scale(
              scale: 0.92 + 0.08 * t,
              child: Opacity(opacity: t.clamp(0, 1), child: child),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.accent2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    series.rounds > 1
                        ? l10n.totalDurationRounds(
                            formatDuration(series.totalDuration),
                            series.rounds,
                            formatDuration(series.roundDuration),
                          )
                        : l10n.totalDuration(formatDuration(series.totalDuration)),
                    style: AppText.mono(fontSize: 15, color: AppColors.brand300),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onStartNow,
              child: Text(l10n.onboardStartNow),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onEditFirst, child: Text(l10n.onboardEditFirst)),
        ],
      ),
    );
  }
}
