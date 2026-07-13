import 'package:apexload/core/constants/app_constants.dart';
import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/shared/widgets/gradient_scaffold.dart';
import 'package:apexload/shared/widgets/legal_notice_card.dart';
import 'package:apexload/shared/widgets/primary_gradient_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  var _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final pages = [
      _OnboardingPageData(
        icon: Icons.link_rounded,
        title: l.t('onboardingTitle1'),
        description: l.t('onboardingDesc1'),
      ),
      _OnboardingPageData(
        icon: Icons.tune_rounded,
        title: l.t('onboardingTitle2'),
        description: l.t('onboardingDesc2'),
      ),
      _OnboardingPageData(
        icon: Icons.workspace_premium_rounded,
        title: l.t('onboardingTitle3'),
        description: l.t('onboardingDesc3'),
      ),
    ];
    final last = _page == pages.length - 1;
    return GradientScaffold(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: _finishOnboarding,
                child: Text(l.t('skip')),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (value) => setState(() => _page = value),
                itemCount: pages.length,
                itemBuilder: (context, index) =>
                    _OnboardingPage(data: pages[index]),
              ),
            ),
            const LegalNoticeCard(),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: i == _page ? 26 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: i == _page
                          ? AppColors.primaryEnd
                          : Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            PrimaryGradientButton(
              label: last ? l.t('getStarted') : l.t('continue'),
              icon: last
                  ? Icons.arrow_forward_rounded
                  : Icons.chevron_right_rounded,
              onPressed: () {
                if (last) {
                  _finishOnboarding();
                } else {
                  _controller.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});

  final _OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 330;
        final iconSize = compact ? 96.0 : 132.0;
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryStart, AppColors.primaryEnd],
                    ),
                    borderRadius: BorderRadius.circular(compact ? 28 : 38),
                  ),
                  child: Icon(
                    data.icon,
                    size: compact ? 48 : 64,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: compact ? 18 : 32),
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: compact
                      ? Theme.of(context).textTheme.titleLarge
                      : Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  data.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTone.textSecondary(context),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}
