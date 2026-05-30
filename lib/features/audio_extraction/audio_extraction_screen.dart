import 'package:apexload/core/routing/app_router.dart';
import 'package:apexload/shared/models/download_format_model.dart';
import 'package:apexload/shared/models/media_info_model.dart';
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
  final _urlController = TextEditingController();
  var _format = 'MP3';
  var _quality = 'Standard';
  var _loading = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _extract() async {
    final l = AppLocalizations.of(context);
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      AppNotification.info(context, message: l.t('pasteFirst'));
      return;
    }

    final format = DownloadFormatModel(
      id: _format == 'M4A' ? 'm4a' : 'mp3',
      label: _format == 'M4A' ? 'M4A Audio' : 'MP3 Audio',
      extension: _format.toLowerCase(),
      type: DownloadType.audio,
      isPremium: true,
      sizeLabel: 'Unknown',
    );
    setState(() => _loading = true);
    try {
      final job = await ref
          .read(apiDownloadServiceProvider)
          .startDownload(
            url: url,
            selectedFormats: [format],
            premium: false,
            noWatermark: false,
          );
      if (!mounted) return;
      setState(() => _loading = false);
      context.push(
        '/download-progress',
        extra: DownloadProgressArgs(
          media: MediaInfoModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: l.t('audioExtraction'),
            mediaType: MediaType.audio,
            platform: 'Unknown',
            duration: '',
            thumbnailUrl: '',
            sourceUrl: url,
            formats: [format],
          ),
          formats: [format],
          fileName: 'apexload_audio.${format.extension}',
          saveToGallery: true,
          apiJobId: job.jobId,
        ),
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppNotification.error(context, message: error.toString());
    }
  }

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
                  controller: _urlController,
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
                  isLoading: _loading,
                  onPressed: _loading ? null : _extract,
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
