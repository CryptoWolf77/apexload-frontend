import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/shared/services/app_state.dart';
import 'package:apexload/shared/widgets/app_notification.dart';
import 'package:apexload/shared/widgets/gradient_scaffold.dart';
import 'package:apexload/shared/widgets/premium_badge.dart';
import 'package:apexload/shared/widgets/premium_locked_card.dart';
import 'package:apexload/shared/widgets/primary_gradient_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AudioExtractionScreen extends ConsumerStatefulWidget {
  const AudioExtractionScreen({super.key});

  @override
  ConsumerState<AudioExtractionScreen> createState() =>
      _AudioExtractionScreenState();
}

class _AudioExtractionScreenState extends ConsumerState<AudioExtractionScreen> {
  var _format = 'MP3';
  var _quality = 'Standard';

  @override
  Widget build(BuildContext context) {
    final premium = ref.watch(subscriptionControllerProvider).isPremium;
    final l = AppLocalizations.of(context);
    return GradientScaffold(
      appBar: AppBar(
        title: Text(l.t('audioExtraction')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      child: premium
          ? ListView(
              padding: const EdgeInsets.all(18),
              children: [
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.link_rounded),
                    hintText: l.t('pasteMediaLink'),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  l.t('audioFormat'),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'MP3', label: Text('MP3')),
                    ButtonSegment(value: 'M4A', label: Text('M4A')),
                  ],
                  selected: {_format},
                  onSelectionChanged: (value) =>
                      setState(() => _format = value.first),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Text(
                      l.t('audioQuality'),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(width: 8),
                    if (!premium) const PremiumBadge(label: 'High'),
                  ],
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'Standard',
                      label: Text(l.t('standard')),
                    ),
                    ButtonSegment(value: 'High', label: Text(l.t('high'))),
                  ],
                  selected: {_quality},
                  onSelectionChanged: (value) {
                    if (value.first == 'High' && !premium) {
                      context.push('/premium');
                    } else {
                      setState(() => _quality = value.first);
                    }
                  },
                ),
                const SizedBox(height: 24),
                PrimaryGradientButton(
                  label: l.t('extractAudio'),
                  icon: Icons.graphic_eq_rounded,
                  onPressed: () => AppNotification.success(
                    context,
                    message: l
                        .t('demoExtractionPrepared')
                        .replaceFirst('{format}', _format),
                  ),
                ),
              ],
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: PremiumLockedCard(
                  title: l.t('audioExtractionPremiumTitle'),
                  description: l.t('audioExtractionPremiumMessage'),
                  onUpgrade: () => context.push('/premium'),
                ),
              ),
            ),
    );
  }
}
