import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('en'), Locale('ar')];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const delegate = _AppLocalizationsDelegate();

  static const _values = <String, Map<String, String>>{
    'en': {
      'home': 'Home',
      'downloads': 'Downloads',
      'settings': 'Settings',
      'appPreferences': 'App preferences',
      'storageAndDownloads': 'Storage and downloads',
      'support': 'Support',
      'skip': 'Skip',
      'continue': 'Continue',
      'next': 'Next',
      'back': 'Back',
      'close': 'Close',
      'getStarted': 'Get Started',
      'onboardingTitle1': 'Paste any supported media link',
      'onboardingDesc1':
          'Copy a public video link from your favorite platform and paste it here.',
      'onboardingTitle2': 'Choose your format',
      'onboardingDesc2':
          'Download video, extract audio, save thumbnails, and more.',
      'onboardingTitle3': 'Go Premium for more power',
      'onboardingDesc3':
          'Unlock FHD & 4K quality, Quick Editor, Audio Swap, faster queue, and no ads.',
      'pasteYourVideoLink': 'Paste your video link',
      'howToUse': 'How to use',
      'analyzeLink': 'Analyze link',
      'downloadCompleted': 'Download completed',
      'downloadSavedToLibrary': 'Download saved to your library.',
      'analyzeFailed': 'Could not analyze this link. Please try again.',
      'backendUnavailableDemo':
          'Service is temporarily unavailable. Please try again shortly.',
      'downloadJobFailed': 'Could not create download job. Please try again.',
      'downloadFailed': 'Download failed. Please try another format or link.',
      'downloadFailedNoFiles':
          'Download completed, but no files were returned.',
      'noMediaToShow': 'No media to show',
      'analyzeFirstForOptions':
          'Paste and analyze a link first to choose download options.',
      'noDownloadInProgress': 'No download in progress',
      'startDownloadFirst': 'Start a download from the options screen first.',
      'noVideoSelected': 'No video selected',
      'openQuickEditorFirst':
          'Open Quick Editor from a downloaded video first.',
      'instagramBlocked':
          'Instagram blocked this request. Please refresh Instagram cookies and try again.',
      'facebookPhotoUnavailable':
          'Facebook photo posts are not available for this link. Try a video link.',
      'youtubeRequiresAuth':
          'YouTube requires sign-in verification. Please refresh YouTube cookies from the admin panel.',
      'youtubeFormatUnavailable':
          'This YouTube format is not available. Try another quality or link.',
      'youtubeFormatsTemporarilyUnavailable':
          'YouTube video formats are temporarily unavailable. Please try another link.',
      'connectionProblem': 'Connection problem. Please try again.',
      'serverConnectionProblem':
          'Could not connect to the server. Please check your internet connection and try again.',
      'queued': 'Queued',
      'downloading': 'Downloading',
      'readyToOpen': 'Ready to open',
      'preparingYourFile': 'Starting device transfer',
      'preparingYourFileDescription':
          'The server finished preparing your file. Starting a secure transfer to this device.',
      'savingToDevice': 'Downloading to your device',
      'savingFileToDevice': 'Transferring to your device...',
      'preparingLargeVideo': 'Transferring a large video',
      'largeVideoSavingMessage':
          '1080p and 4K videos are larger, so transfer time depends on the file size and your connection speed.',
      'largeVideoSavingSubtitle':
          'Keep ApexLoad open until the transfer finishes.',
      'activeOperationWakelockNote':
          'Keep ApexLoad open while this finishes. The screen will stay awake during downloading, transferring, or processing.',
      'downloadSaveFailed':
          'The download completed, but the file could not be saved on your device. Please try again.',
      'addingToGallery': 'Adding to Gallery',
      'galleryPublishFailed':
          'File saved in ApexLoad, but it could not be added to Gallery.',
      'calculating': 'Calculating...',
      'selectDownloadOption': 'Please select at least one download option.',
      'upgradeToPremium': 'Upgrade to Premium',
      'premium': 'Premium',
      'premiumRequired': 'Premium required',
      'legalShort': 'Only download content you own or have permission to use.',
      'legalFull':
          'This app is intended only for downloading content you own, have permission to use, or content that is publicly allowed to be downloaded. Users are responsible for respecting copyright and platform terms.',
      'responsibleUseAgreementTitle': 'Responsible Use Agreement',
      'responsibleUseSummary':
          'ApexLoad is intended for downloading and editing publicly accessible media that you own or have permission to use.',
      'responsibleUseMustNotDownload': 'You must not use ApexLoad to download:',
      'responsibleUseNoPrivateProfiles': 'Private profiles or private posts',
      'responsibleUseNoLoginOnly': 'Login-only media',
      'responsibleUseNoPaidMedia': 'Paid or subscriber-only media',
      'responsibleUseNoDrm': 'DRM-protected media',
      'responsibleUseNoRestricted': 'Restricted media',
      'responsibleUseNoCopyright': 'Copyrighted content without authorization',
      'responsibleUseNoPrivacyViolations':
          'Content that violates privacy rights',
      'responsibleUseNoIllegalOrPlatformViolations':
          'Content whose downloading violates applicable law or platform rules',
      'responsibleUseCheckbox':
          'I have read and agree to the Terms of Use and Acceptable Use Policy.',
      'decline': 'Decline',
      'agreeAndContinue': 'Agree and Continue',
      'legalLinks': 'Legal links',
      'acceptableUsePolicy': 'Acceptable Use Policy',
      'copyrightPolicy': 'Copyright Policy',
      'takedownRequest': 'Takedown Request',
      'submitTakedownRequest': 'Submit Takedown Request',
      'legalAndResponsibleUse': 'Legal and Responsible Use',
      'reviewResponsibleUseAgreement': 'Review Responsible Use Agreement',
      'reviewResponsibleUseAgreementSubtitle':
          'Review the rules for lawful and permitted downloads',
      'couldNotOpenLink': 'Could not open this link. Please try again.',
      'backendProcessingDisclosure':
          'ApexLoad sends the link you submit to api.apexload.org to analyze the media and prepare your requested download.',
      'confirmDownloadRightsTitle': 'Confirm your right to download',
      'confirmDownloadRightsMessage':
          'Only download content you own, created yourself, or have permission to save and use. Do not download private, paid, protected, restricted, or copyrighted content without authorization.',
      'confirmDownloadRightsCheckbox':
          'I confirm that I own this content or have permission to download and use it.',
      'supportedPlatforms': 'Supported platforms',
      'sourceNotSupported':
          'This source is not supported. ApexLoad only works with the '
          'platforms listed below.',
      'contentOwnershipNotice':
          'ApexLoad is not affiliated with, endorsed by, or sponsored by any '
          'of these platforms. All content belongs to its respective owners. '
          'Only save content you created, own, or have permission to save.',
      'recentDownloads': 'Recent downloads',
      'viewAll': 'View all',
      'pasteFirst': 'Paste a public media link first.',
      'clipboardEmpty': 'Clipboard is empty right now.',
      'premiumActive': 'Premium active',
      'active': 'Active',
      'freePlan': 'Free plan',
      'noWatermarkDownloads': 'No watermark downloads',
      'noWatermarkWhenAvailable': 'No watermark when available',
      'homeUpgradeCopy':
          'Go Premium for FHD & 4K downloads, no ads, Quick Editor, Audio Swap, and',
      'fhd4kDownloads': 'FHD & 4K downloads when available',
      'fhd4kDownloadsWhenAvailable': 'Download in FHD & 4K when available.',
      'fhd4kExport': 'FHD & 4K export',
      'fhd4kShort': 'FHD & 4K',
      'unlockFhd4kQuality': 'Unlock FHD & 4K quality',
      'monthly': 'Monthly',
      'yearly': 'Yearly',
      'choosePlan': 'Choose your plan',
      'testerPremiumTitle': 'Tester Premium is active',
      'testerPremiumMessage':
          'All Premium features are unlocked in this tester build. No purchase is required.',
      'monthlyPrice': r'$0.99/month',
      'yearlyPrice': r'$9.99/year',
      'import': 'Import',
      'validate': 'Validate',
      'language': 'Language',
      'theme': 'Theme',
      'quickEditor': 'Quick Editor',
      'quickEditorSubtitle':
          'Trim, mute, extract audio, and compress your videos.',
      'quickEditorLandingSubtitle':
          'Choose a downloaded video or a local file, then pick a local editing tool.',
      'quickEditorPremiumTitle': 'Quick Editor is a Premium feature.',
      'quickEditorPremiumMessage':
          'Upgrade to trim, mute, extract audio, replace audio, and compress your videos.',
      'chooseVideoSource': 'Choose video source',
      'chooseVideoSourceDescription':
          'Use an ApexLoad download or pick a video stored on this device.',
      'chooseAudioSource': 'Choose audio source',
      'files': 'Files',
      'browseDeviceFiles': 'Browse files stored on this device.',
      'photoLibrary': 'Photo Library',
      'gallery': 'Gallery',
      'chooseVideoFromLibrary': 'Choose a video from your media library.',
      'chooseVideoForAudio': 'Choose a video and use its audio track.',
      'clearLink': 'Clear link',
      'pasteFromClipboard': 'Paste from clipboard',
      'chooseLocalVideo': 'Choose local video',
      'localVideoPremiumTitle': 'Premium feature',
      'localVideoPremiumMessage':
          'Choosing a local video is available with ApexLoad Premium. Upgrade to Premium to import videos from your device and use the Quick Editor tools.',
      'chooseFromDownloads': 'Choose from Downloads',
      'noEditableVideosYet':
          'No downloaded videos yet. Download a video first or choose a local file.',
      'localFile': 'Local file',
      'editVideo': 'Edit Video',
      'trimVideo': 'Trim video',
      'muteVideo': 'Mute video',
      'extractAudio': 'Extract audio',
      'compressVideo': 'Compress video',
      'videoOptimizer': 'Video Optimizer',
      'videoOptimizerSubtitle':
          'Reduce size, convert to MP4, and prepare a cleaner output locally.',
      'videoOptimizerPremiumTitle': 'Video Optimizer is a Premium feature.',
      'videoOptimizerPremiumMessage':
          'Upgrade to optimize videos locally before sharing.',
      'optimizerPreset': 'Optimizer preset',
      'optimizerLocalOnly': 'Optimization runs locally on this device.',
      'optimizeVideo': 'Optimize video',
      'optimizerSuccess': 'Video optimized successfully',
      'convertVideoToMp4': 'Convert Video to MP4',
      'exportEditedVideo': 'Export edited video',
      'format': 'Format',
      'startTime': 'Start time',
      'endTime': 'End time',
      'trimDuration': 'Trim duration',
      'seconds': 'seconds',
      'previewSelection': 'Preview selection',
      'validTrimRange': 'Please select a valid trim range.',
      'videoPreviewUnavailable':
          'Video preview is not available for this file.',
      'applyTrim': 'Apply Trim',
      'removeOriginalAudio': 'Remove original audio',
      'applyMute': 'Apply Mute',
      'standard': 'Standard',
      'high': 'High',
      'smallFile': 'Small file',
      'balanced': 'Balanced',
      'highQuality': 'High quality',
      'highestQuality': 'Highest quality',
      'estimatedReduction': 'Estimated size reduction: 35% smaller',
      'compress': 'Compress',
      'exportSettings': 'Export Settings',
      'saveToGallery': 'Save to gallery',
      'saveOptions': 'Save options',
      'noWatermarkNote': 'Applied only when the platform/source provides it.',
      'processingLocally': 'Processing locally on this device',
      'processingEditor': 'Processing locally on this device',
      'processingLargeVideo': 'Processing a large video',
      'largeVideoProcessingMessage':
          'ApexLoad is using faster mobile processing for this large video. Please keep the app open until the export is complete.',
      'trimSuccess': 'Trim applied successfully',
      'muteSuccess': 'Video muted successfully',
      'audioExtractedSuccess': 'Audio extracted successfully',
      'compressSuccess': 'Video compressed successfully',
      'exportSuccess': 'Edited video exported successfully',
      'editedFileReady': 'Your edited file is ready',
      'openEditedFile': 'Open edited file',
      'viewInDownloads': 'View in Downloads',
      'couldNotEditFile':
          'Could not edit this file. Please try another file or option.',
      'originalFileMissing':
          'The original file could not be found. Please download it again and try editing.',
      'fileMustBeSavedBeforeEdit':
          'This file must be saved on your device before editing. Please download it again.',
      'savedToApexLoad': 'Saved to ApexLoad',
      'editedFileSavedSuccess': 'Edited file saved successfully.',
      'couldNotGenerateThumbnail': 'Could not generate thumbnail.',
      'deleteThisFile': 'Delete this file?',
      'fileDeleted': 'File deleted.',
      'sharingFailed': 'Sharing failed. Please try again.',
      'today': 'Today',
      'yesterday': 'Yesterday',
      'older': 'Older',
      'edited': 'Edited',
      'editor': 'Editor',
      'editorToolSoon': 'This editor tool will be added soon.',
      'quickEditorBenefit': 'Trim, mute, extract audio, and compress videos.',
      'platformTikTok': 'TikTok',
      'platformInstagram': 'Instagram',
      'platformFacebook': 'Facebook',
      'platformXTwitter': 'X/Twitter',
      'platformYouTubeShorts': 'YouTube Shorts',
      'platformPinterest': 'Pinterest',
      'platformReddit': 'Reddit',
      'platformSnapchat': 'Snapchat',
      'unlockPremiumTitle': 'Unlock ApexLoad Premium',
      'premiumSubtitle': 'More speed. More quality. No limits.',
      'premiumDownloads': 'Premium Downloads',
      'premiumCreatorTools': 'Premium Creator Tools',
      'premiumEditorTools': 'Premium Editor Tools',
      'premiumUnlimitedDescription': 'Download without daily limits.',
      'premiumHdDownloads': 'HD / Full HD / 4K downloads',
      'premiumHdDownloadsDescription':
          'Higher quality downloads when the source provides them.',
      'premiumMp3Extraction': 'MP3 audio extraction',
      'premiumMp3Description': 'Save audio from supported videos.',
      'premiumNoWatermark': 'No watermark when possible',
      'premiumNoWatermarkDescription':
          'Applied automatically when the source supports it.',
      'premiumQuickEditorTools': 'Quick Editor tools',
      'premiumFasterQueue': 'Faster processing queue',
      'premiumFasterQueueDescription': 'Priority handling for supported jobs.',
      'premiumNoAdsDescription': 'Use ApexLoad without ad interruptions.',
      'videoToGifBenefit':
          'Turn your favorite video moments into shareable GIFs.',
      'reelsShortsBenefit': 'Create platform-ready vertical videos in seconds.',
      'whatsappStatusBenefit': 'Save viewed WhatsApp photos and videos easily.',
      'videoOptimizerBenefit':
          'Reduce file size while controlling output quality.',
      'advancedAudioSwapBenefit': 'Choose exactly where your new audio begins.',
      'professionalTrimPreview': 'Professional Trim Preview',
      'audioStartSelector': 'Audio Start Selector',
      'advancedAudioSwap': 'Advanced Audio Swap',
      'localVideoConversion': 'Local video conversion',
      'localOptimization': 'Local optimization',
      'noAds': 'No ads',
      'audioExtraction': 'Audio extraction',
      'fasterQueue': 'Faster queue',
      'unlimitedDownloads': 'Unlimited downloads',
      'cloudSave': 'Cloud save',
      'bestValue': 'Best Value',
      'premiumActivatedDemo': 'Premium is active.',
      'premiumActiveButton': 'Premium Active',
      'subscribeNow': 'Subscribe',
      'restorePurchases': 'Restore Purchases',
      'restorePurchasesSubtitle':
          'Already subscribed? Bring your Premium plan back to this device.',
      'premiumAlreadyActive': 'Premium is already active on this device.',
      'subscriptionTemporarilyUnavailable':
          'Subscription plans are not available right now. Please check your '
          'connection and try again shortly.',
      'restoringPurchases': 'Restoring purchases...',
      'restorePurchasesSuccess': 'Your Premium subscription was restored.',
      'nothingToRestore': 'No active Premium subscription was found.',
      'purchasePending':
          'Your purchase is pending approval. Premium will activate after Apple confirms it.',
      'purchaseCancelled': 'Purchase cancelled.',
      'purchaseFailed':
          'The purchase could not be completed. Please try again.',
      'storeUnavailable':
          'The App Store is unavailable right now. Check your connection and try again.',
      'subscriptionProductsUnavailable':
          'Apple did not return the ApexLoad subscription products. Retry once, then share the support code below if the problem continues.',
      'supportCode': 'Support code',
      'retryAppStore': 'Retry App Store',
      'premiumLegalNotice':
          'Payment is charged to your Apple ID at confirmation. Subscriptions renew automatically unless cancelled at least 24 hours before the current period ends. Manage or cancel in your App Store account settings. By subscribing, you agree to the Terms of Use and Privacy Policy.',
      'downloadOptions': 'Download options',
      'chooseFormat': 'Choose format',
      'customFilename': 'Custom filename',
      'download': 'Download',
      'openAudioTool': 'Open audio extraction tool',
      'viewPremium': 'View Premium',
      'notNow': 'Not now',
      'premiumOption': 'Premium option',
      'premiumFeatureSummary':
          'Unlock FHD & 4K quality, Quick Editor, and audio extraction.',
      'downloadProgress': 'Download progress',
      'selectedType': 'Selected type',
      'requestedFormat': 'Requested format',
      'returnedFileType': 'Returned file type',
      'returnedFilename': 'Returned filename',
      'openLibrary': 'Open Library',
      'downloadAnother': 'Download Another',
      'cancel': 'Cancel',
      'platform': 'Platform',
      'speed': 'Speed',
      'queuePosition': 'Queue position',
      'savedLocally': 'Saved locally',
      'done': 'Done',
      'searchDownloads': 'Search downloads',
      'playbackTip': 'Playback tip',
      'playbackTipMessage':
          'If a downloaded video does not open on your phone, it may be in a format your device does not support. You can convert it to MP4 using Quick Editor, or open it with a media player like VLC.',
      'openQuickEditor': 'Open Quick Editor',
      'convertToMp4': 'Convert to MP4',
      'noDownloadsYet': 'No downloads yet',
      'pasteLinkOnHome': 'Paste a link on the Home screen to start.',
      'renameFile': 'Rename file',
      'filename': 'Filename',
      'save': 'Save',
      'upgradeNow': 'Upgrade Now',
      'maybeLater': 'Maybe Later',
      'dailyLimitReachedTitle': 'Daily limit reached',
      'dailyLimitReachedMessage':
          'You reached your free daily limit. Upgrade to Premium for unlimited downloads.',
      'freeDownloadsLeft': 'Free downloads left today: {count}/5',
      'adPlaceholderTitle': 'ApexLoad Free',
      'adPlaceholderMessage': 'Your download is ready.',
      'premiumActivatedSuccess': 'Premium activated successfully.',
      'premiumMonthly': 'Premium Monthly',
      'premiumYearly': 'Premium Yearly',
      'fhd4kPremiumTitle': 'FHD & 4K downloads are Premium.',
      'fhd4kPremiumMessage':
          'Upgrade to download in higher quality when available.',
      'audioExtractionPremiumTitle': 'Audio extraction is Premium.',
      'audioExtractionPremiumMessage':
          'Upgrade to extract audio from your media links.',
      'noWatermarkPremiumTitle': 'No watermark downloads are Premium.',
      'noWatermarkPremiumMessage':
          'Available when the platform provides a no-watermark version.',
      'audioSwapPremiumTitle': 'Audio Swap is a Premium feature.',
      'audioSwapPremiumMessage':
          'Upgrade to replace the original video sound with your own audio.',
      'audioSwap': 'Audio Swap',
      'audioSwapReplaceAudio': 'Audio Swap / Replace Audio',
      'replaceAudio': 'Replace Audio',
      'audioSwapSubtitle': 'Replace original audio with your own sound.',
      'audioSwapDescription':
          'Replace the original video sound with an audio file from your phone.',
      'chooseAudioFile': 'Choose audio file',
      'pickAudioFile': 'Pick Audio File',
      'selectedAudio': 'Selected audio',
      'audioFormatSupport': 'MP3 / M4A / WAV supported later',
      'audioStartPosition': 'Audio start position in video',
      'audioStartPoint': 'Audio start point',
      'audioStartPointHelp':
          'Choose where the selected audio begins. It will start at the beginning of the video.',
      'audioStartsAtVideoPoint':
          'The new audio starts at video second 0. If it is shorter than the video, choose whether to loop it or leave the rest silent.',
      'audioSectionUsed': 'Audio section used',
      'removeOriginalSound': 'Remove original sound',
      'keepOriginalSoundSoftly': 'Keep original sound softly',
      'audioVolume': 'Audio volume',
      'preview': 'Preview',
      'applyAudioSwap': 'Apply Audio Swap',
      'audioReplacedSuccess': 'Audio replaced successfully.',
      'couldNotReplaceAudio':
          'Could not replace the audio. Please try another audio file.',
      'noAudioSelected': 'Pick an audio file first.',
      'originalAudio': 'Original audio',
      'replaceOriginalAudio': 'Replace original audio',
      'removeOriginalAudioOnly': 'Remove original audio only',
      'chooseNewAudio': 'Choose new audio',
      'noNewAudioNeeded': 'No new audio needed for remove-only export.',
      'previewAndApply': 'Preview and apply',
      'previewWithNewAudio': 'Preview with new audio',
      'audioTrimmedToVideoLength':
          'The new audio will be trimmed to match the video length.',
      'audioShorterThanVideo':
          'If the audio is shorter, the export ends when the new audio ends.',
      'advancedOptions': 'Advanced options',
      'videoToGif': 'Video to GIF',
      'createGif': 'Create GIF',
      'previewGifRange': 'Preview GIF range',
      'gifCreatedSuccess': 'GIF created successfully.',
      'couldNotCreateGif': 'Could not create this GIF. Try a shorter range.',
      'videoToGifPremiumTitle': 'Video to GIF is a Premium feature.',
      'reelsShortsCreator': 'Reels/Shorts Creator',
      'chooseOutputFormat': 'Choose output format',
      'resizeMode': 'Resize mode',
      'smartCrop': 'Smart crop',
      'fitWithBlurredBackground': 'Fit with background',
      'fitWithSolidBackground': 'Fit with solid background',
      'centerCrop': 'Center crop',
      'reelShortCreatedSuccess': 'Reel/Short created successfully.',
      'couldNotCreateReelShort':
          'Could not create this Reel/Short. Please try another option.',
      'reelsShortsPremiumTitle': 'Reels/Shorts Creator is a Premium feature.',
      'chooseVideo': 'Choose video',
      'selectedVideo': 'Selected video',
      'gifSettings': 'GIF settings',
      'quality': 'Quality',
      'size': 'Size',
      'small': 'Small',
      'medium': 'Medium',
      'original': 'Original',
      'fps': 'FPS',
      'loop': 'Loop',
      'reelsShortsOutputNote': 'Exports locally in a social-friendly MP4 size.',
      'demoPreviewReady': 'Preview is ready.',
      'somethingWentWrong': 'Something went wrong. Please try again.',
      'demoActionForNow': '{action} is not available yet.',
      'sharingSoon': 'Sharing will be added soon.',
      'couldNotOpenFile': 'Could not open this file. Please try again.',
      'fileNoLongerAvailable':
          'This file is no longer available on your device.',
      'demoExtractionPrepared': '{format} extraction is ready.',
      'notAvailableOnClip': 'Not available on this clip',
      'notAvailableForImage': 'Not available for this image',
      'Instagram photo posts are not available for this link. Try a Reel/video link.':
          'Instagram photo posts are not available for this link. Try a Reel/video link.',
      'Facebook photo posts are not available for this link. Try a video link.':
          'Facebook photo posts are not available for this link. Try a video link.',
      'noWatermarkApplied': 'No watermark applied when available',
      'downloadSelected': 'Download selected',
      'downloadSelectedItems': 'Download selected items',
      'downloadSelectedItemsCount': 'Download {count} selected items',
      'selectedItemsDownloaded': 'Selected items downloaded successfully',
      'chooseImageFormat': 'Choose image format',
      'originalImage': 'Original Image',
      'highQualityImage': 'High Quality Image',
      'compressedImage': 'Compressed Image',
      'jpgImage': 'JPG Image',
      'pngImage': 'PNG Image',
      'bestAvailableQuality': 'Best available quality',
      'premiumQualityWhenAvailable': 'Premium quality when available',
      'smallerFileSize': 'Smaller file size',
      'standardFormat': 'Standard format',
      'whenAvailable': 'When available',
      'imagePremiumTitle': 'High quality images are Premium.',
      'imagePremiumMessage':
          'Upgrade to download premium image formats when available.',
      'yourApexLoad': 'Your ApexLoad',
      'appStatus': 'App Status',
      'plan': 'Plan',
      'downloadsToday': 'Downloads today',
      'storageUsed': 'Storage used',
      'locked': 'Locked',
      'unlocked': 'Unlocked',
      'free': 'Free',
      'all': 'All',
      'video': 'Video',
      'audio': 'Audio',
      'images': 'Images',
      'open': 'Open',
      'share': 'Share',
      'edit': 'Edit',
      'rename': 'Rename',
      'delete': 'Delete',
      'goHome': 'Go Home',
      'pasteOneLinkPerLine': 'Paste one public link per line',
      'queuePreview': 'Queue preview',
      'ready': 'Ready',
      'invalidLink': 'Invalid link',
      'pasteMediaLink': 'Paste media link',
      'audioFormat': 'Audio format',
      'audioQuality': 'Audio quality',
      'systemDefault': 'System Default',
      'english': 'English',
      'arabic': 'Arabic',
      'system': 'System',
      'dark': 'Dark',
      'light': 'Light',
      'autoSaveToGallery': 'Auto-save to gallery',
      'autoSaveAndroidDescription':
          'Publish supported downloads to your device gallery automatically.',
      'keepScreenAwakeDuringDownloads': 'Keep screen awake during downloads',
      'keepScreenAwakeDuringDownloadsSubtitle':
          'Prevents the screen from sleeping while downloading, saving, or exporting media.',
      'autoSaveIosDescription':
          'Automatically add downloaded photos and videos to Photos. Files also remain in On My iPhone > ApexLoad.',
      'downloadLocation': 'Download location',
      'deviceDownloadsFolder': 'Device downloads folder',
      'downloadLocationAndroidSubtitle': 'View your ApexLoad media folders',
      'downloadLocationIosSubtitle': 'Files > On My iPhone > ApexLoad',
      'downloadLocationAndroidDescription':
          'ApexLoad keeps its files in dedicated folders in app storage. Supported media can also be published to your gallery when Auto-save is enabled.',
      'downloadLocationIosDescription':
          'Find your downloads in the Files app under On My iPhone > ApexLoad. ApexLoad does not display or expose the private iOS sandbox path.',
      'videosFolder': 'Videos',
      'audioFolder': 'Audio',
      'imagesFolder': 'Images',
      'editedFolder': 'Edited files',
      'gifsFolder': 'GIFs',
      'thumbnailsFolder': 'Thumbnails',
      'openFolder': 'Open folder',
      'folderOpenUnavailable':
          'Your file manager could not open this folder. You can still access saved media from Downloads.',
      'clearCache': 'Clear cache',
      'clearCacheSubtitle': 'Remove thumbnails and temporary editor previews',
      'clearCacheConfirmTitle': 'Clear temporary files?',
      'clearCacheConfirmMessage':
          'This removes generated thumbnails and temporary editor previews only. Your downloads, edited files, history, settings, and Premium status will stay safe.',
      'cacheClearedSuccess': 'Cleared {size} of temporary data.',
      'cacheClearFailed': 'Could not clear temporary files. Please try again.',
      'privacyPolicy': 'Privacy Policy',
      'privacyPolicySubtitle': 'How ApexLoad handles data and permissions',
      'termsOfUse': 'Terms of Use',
      'termsOfUseSubtitle': 'Rules for responsible use of ApexLoad',
      'contactSupport': 'Contact Support',
      'rateApp': 'Rate App',
      'rateAppSubtitle': 'Share feedback on the app store',
      'ratingAvailableAfterRelease':
          'App rating will be available after ApexLoad is released on the store.',
      'couldNotOpenStore': 'Could not open the app store. Please try again.',
      'supportEmailBody':
          'Please describe the issue below:\n\n\nApp version: {version}\nPlatform: {platform}\nOS version: {osVersion}',
      'emailAppUnavailableTitle': 'Email app unavailable',
      'emailAppUnavailableMessage':
          'No email app could be opened. You can copy our support address instead.',
      'copyEmail': 'Copy email',
      'emailCopied': 'Support email copied.',
      'legalLastUpdated': 'Last updated: July 2026',
      'privacyIntro':
          'This policy explains how the current ApexLoad app handles information when you analyze links, download media, use local editing tools, or contact support.',
      'privacyDataTitle': 'Information you provide',
      'privacyDataBody':
          'Links you submit, selected download formats, and related download options are sent to the ApexLoad backend so the request can be analyzed and processed. If you contact support, your email app prepares a message containing the app version, platform, OS version, and whatever details you choose to add.',
      'privacyProcessingTitle': 'Download and server processing',
      'privacyProcessingBody':
          'The ApexLoad backend may contact the public media platform or its delivery network to analyze and prepare requested media. Downloaded output is then transferred to your device. Do not submit private, restricted, or sensitive links that you are not authorized to access.',
      'privacyLocalTitle': 'Data stored on your device',
      'privacyLocalBody':
          'ApexLoad stores preferences, language and theme choices, local Premium state, daily usage counters, download history, saved file paths, and generated thumbnails on your device. Quick Editor processing is performed locally on the device. Clearing cache removes only temporary previews and generated thumbnails; deleting app data through the operating system may remove local records and app-managed files.',
      'privacyPermissionsTitle': 'Permissions',
      'privacyPermissionsBody':
          'Network access is used for analysis and downloads. Android may use media and folder access to publish downloads or read a WhatsApp .Statuses folder you explicitly choose. iOS uses the system file picker for files you select and exposes app documents through the Files app. ApexLoad does not request broad all-files access.',
      'privacyThirdPartiesTitle': 'Third-party services',
      'privacyThirdPartiesBody':
          'ApexLoad interacts with the social or media platform named in the submitted link, its content delivery providers, the ApexLoad API, and operating-system sharing, storage, and email services. Apple processes App Store subscription purchases and related payment information under Apple’s policies. ApexLoad does not receive your full payment-card details.',
      'privacyAccountsTitle': 'Accounts and subscriptions',
      'privacyAccountsBody':
          'ApexLoad does not require an ApexLoad account. Premium subscriptions are purchased and managed through the Apple App Store. The app reads verified StoreKit entitlement information and stores the current Premium state and expiration date locally so Premium features can be enabled. Use Restore Purchases to recover an active subscription on another eligible device.',
      'privacyChoicesTitle': 'Your choices',
      'privacyChoicesBody':
          'You can disable automatic gallery publishing on supported Android devices, remove individual downloads, clear temporary cache, revoke folder access in system settings, or clear the app data. Disabling a setting does not delete files already saved.',
      'legalContactTitle': 'Contact',
      'legalContactBody':
          'Questions about privacy, these terms, or ApexLoad can be sent to support@apexload.org.',
      'termsIntro':
          'By using ApexLoad, you agree to use it lawfully, responsibly, and only for content you own, are permitted to use, or are otherwise allowed to download.',
      'termsUseTitle': 'Responsible use',
      'termsUseBody':
          'You are responsible for every link and file you process. Follow applicable laws, platform rules, privacy rights, and any license or permission attached to the content.',
      'termsCopyrightTitle': 'Copyright and ownership',
      'termsCopyrightBody':
          'ApexLoad does not grant ownership of third-party content. Keep attribution and copyright notices where required, and obtain permission before copying, editing, publishing, or distributing content owned by someone else.',
      'termsProhibitedTitle': 'Prohibited misuse',
      'termsProhibitedBody':
          'Do not use ApexLoad to access private, login-only, paywalled, restricted, or DRM-protected content; bypass security controls; infringe copyright; harass others; distribute unlawful material; or overload the service through automated abuse.',
      'termsPlatformsTitle': 'Third-party platforms and availability',
      'termsPlatformsBody':
          'Supported platforms can change or block access without notice. A format, quality, thumbnail, audio track, or link may be unavailable. ApexLoad is not affiliated with or endorsed by the listed social platforms unless explicitly stated.',
      'termsSubscriptionsTitle': 'Premium features',
      'termsSubscriptionsBody':
          'ApexLoad offers monthly and yearly auto-renewing Premium subscriptions. The localized price and billing period are shown before purchase. Payment is charged to your Apple ID at confirmation. A subscription renews automatically unless cancelled at least 24 hours before the end of the current period. You can manage or cancel it in your App Store account settings. Premium features and availability may change, subject to applicable law and App Store terms.',
      'termsLimitationsTitle': 'Service limitations and liability',
      'termsLimitationsBody':
          'ApexLoad is provided on an as-available basis. Downloads and edits may fail because of network conditions, device storage, unsupported media, platform changes, or third-party restrictions. To the extent permitted by law, ApexLoad is not responsible for unauthorized use, lost data, unavailable third-party content, or indirect damages. Keep your own backups of important files.',
      'editingCompatibilityTitle': 'For the best editing compatibility',
      'editingCompatibilityMessage':
          'This video is not in MP4 format. For smoother editing on iPhone, we recommend converting it to MP4 first. You can also continue editing the original file.',
      'continueEditing': 'Continue editing',
      'editingComplete': 'Your file is ready',
      'editingCompleteMessage': 'Your edited file has been saved successfully. What would you like to do next?',
      'goToConvertMp4': 'Convert to MP4',
      'choosePlatform': 'Choose Platform',
      'instagramReel': 'Instagram Reel',
      'youtubeShort': 'YouTube Short',
      'tiktokVideo': 'TikTok Video',
      'snapchatSpotlight': 'Snapchat Spotlight',
      'readyForPlatform': 'Ready for {platform}',
      'safeZone': 'Safe Zone',
      'safeZoneHelp':
          'Keep faces, text, and important content inside this area.',
      'smartCropHelp':
          'Fills the full vertical screen by cropping the outer edges.',
      'blurredBackgroundHelp':
          'Shows the complete video with a background filling the empty space.',
      'platformPresetHelp':
          'Choose a platform preset and ApexLoad will prepare a vertical MP4.',
      'createInstagramReel': 'Create Instagram Reel',
      'createYouTubeShort': 'Create YouTube Short',
      'createTikTokVideo': 'Create TikTok Video',
      'createSnapchatSpotlight': 'Create Snapchat Spotlight',
      'videoStep': 'Video',
      'videoAudioSwapHelp':
          'This is the video whose audio will be replaced or mixed.',
      'selectAudioRange': 'Select audio range',
      'audioStart': 'Audio start',
      'audioEnd': 'Audio end',
      'selectedAudioDuration': 'Selected audio duration',
      'automaticMatch': 'Automatic Match',
      'customAudioRange': 'Custom Audio Range',
      'audioRangeHelp':
          'Choose the part of the audio you want to use. The selected audio will begin when the video starts.',
      'loopAudioUntilVideoEnds': 'Loop audio until video ends',
      'leaveRemainingVideoSilent': 'Leave remaining video silent',
      'keepOriginalAfterAudioEnds':
          'Keep original audio after selected audio ends',
      'playSelectedSegment': 'Play selected audio segment',
      'resetSelection': 'Reset selection',
      'outputSummary': 'Output summary',
      'statusSaver': 'Status Saver',
      'whatsappStatusSaver': 'WhatsApp Status Saver',
      'whatsappStatusHomeCopy':
          'Save viewed WhatsApp status photos and videos locally.',
      'androidOnly': 'Android only',
      'whatsappStatusAndroidOnlyTitle':
          'WhatsApp Status Saver is available on Android only.',
      'whatsappStatusAndroidOnlyMessage':
          'iOS does not allow apps to access WhatsApp status folders.',
      'whatsappStatusPremiumTitle':
          'WhatsApp Status Saver is a Premium feature.',
      'whatsappStatusPremiumMessage':
          'Preview local statuses, then upgrade to save them into ApexLoad.',
      'whatsappStatusLocalOnly':
          'WhatsApp only stores statuses on your device after you view them.',
      'whatsappStatusStep1':
          'Open WhatsApp and view the statuses you want to save.',
      'whatsappStatusStep2': 'Return to ApexLoad.',
      'whatsappStatusStep3': 'Tap Connect WhatsApp Status Folder.',
      'whatsappStatusStep4': 'Choose the WhatsApp .Statuses folder.',
      'connectWhatsappFolder': 'Connect WhatsApp Folder',
      'connectWhatsappBusinessFolder': 'Connect WhatsApp Business Folder',
      'howToFindFolder': 'How to find the folder',
      'howToFindWhatsappFolder': 'How to find the WhatsApp status folder',
      'whatsappFolderGuide':
          'In the Android folder picker, open WhatsApp or WhatsApp Business, then Media, then choose .Statuses. ApexLoad only reads files already on your phone.',
      'whatsappHowToUseCta': 'Please click here: How to use',
      'whatsappHowToUseSubtitle': 'Learn how to connect the .Statuses folder',
      'whatsappTutorialTitle': 'How to use WhatsApp Status Saver',
      'whatsappTutorialHiddenFilesNote':
          'If .Statuses does not appear, enable Show hidden files from the three-dot menu.',
      'tapImageToEnlarge': 'Tap image to enlarge',
      'whatsappTutorialStep1Title': 'Step 1 — Tap Change folder',
      'whatsappTutorialStep1Description':
          'Tap Change folder to choose the WhatsApp Status folder.',
      'whatsappTutorialStep2Title': 'Step 2 — Show hidden files',
      'whatsappTutorialStep2Description':
          'Tap the three-dot menu, then enable Show hidden files.',
      'whatsappTutorialStep3Title': 'Step 3 — Open .Statuses',
      'whatsappTutorialStep3Description':
          'Tap the .Statuses folder after hidden files are visible.',
      'whatsappTutorialStep4Title': 'Step 4 — Use this folder',
      'whatsappTutorialStep4Description':
          'Tap Use this folder after entering .Statuses.',
      'whatsappTutorialStep5Title': 'Step 5 — Allow access',
      'whatsappTutorialStep5Description':
          'Tap Allow to give ApexLoad access to the .Statuses folder.',
      'whatsappTutorialStep6Title': 'Step 6 — View your statuses',
      'whatsappTutorialStep6Description':
          'Return to ApexLoad and scroll down to view and save your WhatsApp statuses.',
      'pasteLinkTutorialTitle': 'How to copy and paste a video link',
      'pasteLinkInstagramShareTitle': 'Instagram — Tap Share',
      'pasteLinkInstagramCopyTitle': 'Instagram — Copy link',
      'pasteLinkTikTokShareTitle': 'TikTok — Tap Share',
      'pasteLinkTikTokCopyTitle': 'TikTok — Copy link',
      'pasteLinkInstagramShareDescription':
          'Open the Instagram Reel and tap the Share icon.',
      'pasteLinkCopyDescription':
          'Tap Copy link, then return to ApexLoad and paste it.',
      'pasteLinkTikTokShareDescription':
          'Open the TikTok video and tap the Share icon.',
      'pasteLinkTutorialNote':
          'After copying the link, return to ApexLoad and tap Analyze link.',
      'showHiddenFiles': 'Show hidden files',
      'whatsappInstructionsStandardTitle': 'Normal WhatsApp',
      'whatsappInstructionStandardStep1':
          'Open WhatsApp and view the statuses you want to save.',
      'whatsappInstructionStandardStep2': 'Return to ApexLoad.',
      'whatsappInstructionStandardStep3': 'Tap Connect WhatsApp Statuses.',
      'whatsappInstructionStandardStep4':
          'In the Android folder picker, open Android > media > com.whatsapp > WhatsApp > Media.',
      'whatsappInstructionStandardStep5':
          'Tap the 3-dot menu in the top corner.',
      'whatsappInstructionStandardStep6': 'Enable Show hidden files.',
      'whatsappInstructionStandardStep7': 'Open the hidden folder: .Statuses.',
      'whatsappInstructionStandardStep8': 'Tap Use this folder or Allow.',
      'whatsappInstructionsBusinessTitle': 'WhatsApp Business',
      'whatsappInstructionBusinessStep1':
          'Open WhatsApp Business and view the statuses you want to save.',
      'whatsappInstructionBusinessStep2': 'Return to ApexLoad.',
      'whatsappInstructionBusinessStep3':
          'Tap Connect WhatsApp Business Folder.',
      'whatsappInstructionBusinessStep4':
          'In the Android folder picker, open Android > media > com.whatsapp.w4b > WhatsApp Business > Media.',
      'whatsappInstructionBusinessStep5':
          'Tap the 3-dot menu in the top corner.',
      'whatsappInstructionBusinessStep6': 'Enable Show hidden files.',
      'whatsappInstructionBusinessStep7': 'Open the hidden folder: .Statuses.',
      'whatsappInstructionBusinessStep8': 'Tap Use this folder or Allow.',
      'whatsappHiddenFolderNote':
          '.Statuses is hidden by Android. If you cannot see it, tap the 3-dot menu and enable Show hidden files.',
      'whatsappStatusReadNote':
          'ApexLoad only reads statuses already saved on your device after you view them in WhatsApp.',
      'whatsappPickerHint':
          'Choose Android > media > com.whatsapp > WhatsApp > Media > .Statuses',
      'whatsappBusinessPickerHint':
          'Choose Android > media > com.whatsapp.w4b > WhatsApp Business > Media > .Statuses',
      'folderConnectionCancelled': 'Folder connection was cancelled.',
      'tryAgain': 'Try again',
      'disconnectFolder': 'Disconnect folder',
      'connected': 'Connected',
      'notConnected': 'Not connected',
      'whatsappConnected': 'WhatsApp status folder connected',
      'whatsappBusinessConnected': 'WhatsApp Business status folder connected',
      'folderSettings': 'Folder settings',
      'refresh': 'Refresh',
      'saved': 'Saved',
      'videos': 'Videos',
      'saveSelected': 'Save selected',
      'selectAll': 'Select all',
      'statusGallery': 'Status Gallery',
      'connectWhatsappFolderFirst':
          'Connect your WhatsApp .Statuses folder to show local statuses.',
      'noWhatsappStatusesFound':
          'No statuses were found. Open WhatsApp, view some statuses, then refresh.',
      'whatsappFolderAccessError':
          'Could not access the selected WhatsApp folder. Please connect it again.',
      'statusAlreadySaved': 'This status is already saved.',
      'statusSavedSuccess': 'Status saved to ApexLoad.',
      'whatsappAutoDetected': 'WhatsApp statuses detected automatically.',
      'guidedPermissionText':
          'Use the How to use guide above, then connect the .Statuses folder. You only need to do this once.',
      'connectWhatsappStatuses': 'Connect WhatsApp Statuses',
      'connectWhatsappSetupExplanation':
          'Android requires one-time permission to access viewed WhatsApp statuses. Complete these steps once, and ApexLoad will load statuses automatically afterward.',
      'whatsappSetupStep1':
          'Tap Change Folder to open the Android folder picker.',
      'whatsappSetupStep2':
          'In the folder picker, tap the three-dot menu and choose Show hidden files.',
      'whatsappSetupStep3': 'Open the .Statuses folder.',
      'whatsappSetupStep4': 'Tap Use this folder, then tap Allow.',
      'whatsappSetupStep5':
          'After that, ApexLoad will load statuses automatically.',
      'watchInstructions': 'View Instructions',
      'changeFolder': 'Change folder',
      'wrongWhatsappFolder':
          'This does not appear to be the WhatsApp .Statuses folder. Please enable hidden files and choose .Statuses.',
      'wrongWhatsappFolderSelected':
          'This is not the .Statuses folder. Please tap Change Folder, show hidden files, then choose .Statuses.',
      'setupRequired': 'Setup required',
      'validatingFolder': 'Folder selected, validating',
      'wrongFolderSelected': 'Wrong folder selected',
      'connectedNoStatuses': 'Connected, but no statuses viewed yet',
      'checkingSavedAccess': 'Checking saved access',
      'connecting': 'Connecting',
      'scanningStatuses': 'Scanning statuses',
      'foundStatuses': 'Found {count} statuses',
      'chooseFolderManually': 'Choose folder manually',
      'detectingWhatsapp': 'Detecting WhatsApp…',
      'connectedAutomatically': 'Connected automatically',
      'permissionRequired': 'Permission required',
      'permissionRevoked': 'Permission revoked',
      'folderNotFound': 'Folder not found',
      'noStatusesFound': 'No statuses found',
      'iosWhatsappTitle': 'WhatsApp Status',
      'iosWhatsappRefresh': 'Refresh WhatsApp Web',
      'iosWhatsappResync': 'Resync WhatsApp Web',
      'iosWhatsappResyncHint':
          'Reconnects and reloads every status your linked account has.',
      'iosWhatsappResyncStarted':
          'WhatsApp Web is reconnecting. Status updates appear as they sync.',
      'iosWhatsappSyncing': 'Syncing your WhatsApp updates…',
      'iosWhatsappRenderFailedTitle': 'WhatsApp Web stopped responding',
      'iosWhatsappRenderFailedMessage':
          'iOS closed the web page to free memory. Your linked WhatsApp '
          'account is still connected.',
      'iosWhatsappRenderFailedRetry': 'Reload WhatsApp Web',
      'iosWhatsappRecovered':
          'WhatsApp Web ran out of memory and was reloaded. Your account is '
          'still linked.',
      'iosWhatsappHelp': 'Show status-saving guide',
      'iosWhatsappDisconnect': 'Disconnect WhatsApp',
      'iosWhatsappDisconnectQuestion': 'Disconnect WhatsApp?',
      'iosWhatsappDisconnectMessage':
          'This removes the WhatsApp Web session stored inside ApexLoad. Saved status files will not be deleted.',
      'iosWhatsappDisconnected':
          'The WhatsApp Web session was removed from ApexLoad.',
      'iosWhatsappIntroTitle': 'Connect securely with WhatsApp Web',
      'iosWhatsappIntroDescription':
          'Open the official WhatsApp Web page inside ApexLoad, link your account, choose a status, then save it in its original quality.',
      'iosWhatsappPrivacyTitle': 'Session stays on this device',
      'iosWhatsappPrivacyDescription':
          'ApexLoad does not send your WhatsApp session to its server.',
      'iosWhatsappManualTitle': 'Only saves when you ask',
      'iosWhatsappManualDescription':
          'There is no automatic scanning or bulk status collection.',
      'iosWhatsappResponsibleTitle': 'Save responsibly',
      'iosWhatsappResponsibleDescription':
          'Only save content you own or have permission to keep.',
      'iosWhatsappPhaseNote':
          'Your account remains inside the secure WhatsApp Web session on this iPhone.',
      'iosWhatsappStart': 'Connect WhatsApp Web',
      'iosWhatsappTutorialTitle': 'Connect WhatsApp Web',
      'iosWhatsappTutorialSubtitle':
          'Use phone-number linking to connect on the same iPhone.',
      'iosWhatsappTutorialStep1Title': 'Continue in the browser',
      'iosWhatsappTutorialStep1Description':
          'Tap Continue to WhatsApp Web. You do not need to download WhatsApp again.',
      'iosWhatsappTutorialStep2Title': 'Choose phone-number login',
      'iosWhatsappTutorialStep2Description':
          'Tap Log in with phone number below the QR code.',
      'iosWhatsappTutorialStep3Title': 'Enter your WhatsApp number',
      'iosWhatsappTutorialStep3Description':
          'Select your country, enter your number, then tap Next. Enter the linking code in WhatsApp under Settings › Linked Devices › Link a Device › Link with phone number instead.',
      'iosWhatsappOpenWeb': 'Open WhatsApp Web',
      'iosWhatsappStatusDetected': 'Status detected',
      'iosWhatsappConnected': 'WhatsApp connected',
      'iosWhatsappLinkAccount': 'Link your WhatsApp account',
      'iosWhatsappOpening': 'Opening WhatsApp Web…',
      'iosWhatsappWaiting': 'Waiting for WhatsApp',
      'iosWhatsappSaving': 'Saving status locally…',
      'iosWhatsappSaveStatus': 'Save current status',
      'iosWhatsappSavePhoto': 'Save current photo',
      'iosWhatsappSaveVideo': 'Save current video',
      'iosWhatsappOpenStatus': 'Open a status to save',
      'iosWhatsappLoadFailed': 'WhatsApp Web did not load',
      'iosWhatsappSaveFailed': 'Could not save this status',
      'iosWhatsappTryOpenStatus': 'Please open a status and try again.',
      'iosWhatsappSaved': 'Status saved',
      'iosWhatsappSavedFile': '{file} is ready in Downloads.',
      'iosWhatsappSavedSuccess': 'Status saved successfully',
      'iosWhatsappSavedDescription':
          'You can keep viewing statuses or open ApexLoad Downloads.',
      'iosWhatsappKeepBrowsing': 'Keep browsing',
      'iosWhatsappGuideTitle': 'Open a status before saving',
      'iosWhatsappGuideSubtitle':
          'ApexLoad saves the photo or video currently open in WhatsApp Web.',
      'iosWhatsappGuideStep1Title': 'Open Status updates',
      'iosWhatsappGuideStep1Description':
          'Tap the circular Status icon in the WhatsApp Web side menu.',
      'iosWhatsappGuideStep2Title': 'Choose a status',
      'iosWhatsappGuideStep2Description':
          'Select a contact, then open the photo or video you want.',
      'iosWhatsappGuideStep3Title': 'Keep it visible and save',
      'iosWhatsappGuideStep3Description':
          'While the status is displayed, tap Save current status in ApexLoad.',
      'iosWhatsappGuideTip':
          'The save button becomes ready when ApexLoad detects an open status.',
      'iosWhatsappSaveGuideTitle': 'How to save a WhatsApp status',
      'iosWhatsappSaveGuideSubtitle':
          'Follow these four steps once, then save directly from ApexLoad.',
      'iosWhatsappSaveGuideStep1Title': 'Open Status updates',
      'iosWhatsappSaveGuideStep1Description':
          'Tap the circular Status icon in the WhatsApp Web side menu.',
      'iosWhatsappSaveGuideStep2Title': 'Choose the status you want',
      'iosWhatsappSaveGuideStep2Description':
          'Select a contact from the recent status list.',
      'iosWhatsappSaveGuideStep3Title': 'Save the open photo or video',
      'iosWhatsappSaveGuideStep3Description':
          'Keep the status visible, then tap the ApexLoad save button.',
      'iosWhatsappSaveGuideStep4Title': 'Find it in Downloads',
      'iosWhatsappSaveGuideStep4Description':
          'After the confirmation appears, tap Downloads to view the saved file.',
      'iosWhatsappGotIt': 'Got it',
      'madeBy': 'Made by',
    },
    'ar': {
      'home': 'الرئيسية',
      'downloads': 'التحميلات',
      'settings': 'الإعدادات',
      'appPreferences': 'تفضيلات التطبيق',
      'storageAndDownloads': 'التخزين والتنزيلات',
      'support': 'الدعم',
      'skip': 'تخطي',
      'continue': 'متابعة',
      'next': 'التالي',
      'back': 'رجوع',
      'close': 'إغلاق',
      'getStarted': 'ابدأ الآن',
      'onboardingTitle1': 'الصق أي رابط وسائط مدعوم',
      'onboardingDesc1': 'انسخ رابط فيديو عام من منصتك المفضلة والصقه هنا.',
      'onboardingTitle2': 'اختر الصيغة المناسبة',
      'onboardingDesc2':
          'نزّل الفيديو، استخرج الصوت، احفظ الصورة المصغّرة، والمزيد.',
      'onboardingTitle3': 'فعّل بريميوم لقوة أكبر',
      'onboardingDesc3':
          'افتح جودة FHD و 4K عند توفرها، والمحرر السريع، وتبديل الصوت، والطابور الأسرع، وتجربة بدون إعلانات.',
      'pasteYourVideoLink': 'الصق رابط الفيديو',
      'analyzeLink': 'تحليل الرابط',
      'downloadCompleted': 'اكتمل التحميل',
      'downloadSavedToLibrary': 'تم حفظ التحميل في مكتبتك.',
      'analyzeFailed': 'تعذر تحليل الرابط، حاول مرة أخرى',
      'backendUnavailableDemo':
          'الخدمة غير متاحة مؤقتًا. يرجى المحاولة بعد قليل.',
      'downloadJobFailed': 'تعذر إنشاء مهمة التحميل، حاول مرة أخرى',
      'downloadFailed': 'فشل التحميل. جرّب صيغة أو رابطًا آخر.',
      'downloadFailedNoFiles': 'اكتمل التحميل، لكن لم يتم إرجاع أي ملفات.',
      'noMediaToShow': 'لا توجد وسائط للعرض',
      'analyzeFirstForOptions':
          'الصق رابطًا وحلّله أولًا لاختيار خيارات التحميل.',
      'noDownloadInProgress': 'لا يوجد تحميل قيد التقدم',
      'startDownloadFirst': 'ابدأ التحميل من شاشة الخيارات أولًا.',
      'noVideoSelected': 'لم يتم اختيار فيديو',
      'openQuickEditorFirst': 'افتح المحرر السريع من فيديو تم تحميله أولًا.',
      'instagramBlocked':
          'حظر Instagram هذا الطلب. حدّث ملفات تعريف الارتباط وجرب مرة أخرى.',
      'facebookPhotoUnavailable':
          'منشورات صور فيسبوك غير متاحة لهذا الرابط. جرّب رابط فيديو.',
      'youtubeRequiresAuth':
          'يتطلب يوتيوب التحقق من تسجيل الدخول. يرجى تحديث ملفات تعريف ارتباط يوتيوب من لوحة الإدارة.',
      'youtubeFormatUnavailable':
          'صيغة يوتيوب هذه غير متاحة. جرّب جودة أو رابطًا آخر.',
      'youtubeFormatsTemporarilyUnavailable':
          'صيغ فيديو يوتيوب غير متاحة مؤقتًا. يرجى تجربة رابط آخر.',
      'connectionProblem': 'مشكلة في الاتصال. حاول مرة أخرى.',
      'serverConnectionProblem':
          'تعذّر الاتصال بالخادم. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.',
      'queued': 'في الانتظار',
      'downloading': 'جاري التنزيل',
      'readyToOpen': 'جاهز للفتح',
      'preparingYourFile': 'جارٍ بدء النقل إلى جهازك',
      'preparingYourFileDescription':
          'انتهى الخادم من تجهيز ملفك. جارٍ بدء نقله بأمان إلى هذا الجهاز.',
      'savingToDevice': 'جارٍ التنزيل إلى جهازك',
      'savingFileToDevice': 'جارٍ النقل إلى جهازك...',
      'preparingLargeVideo': 'جارٍ نقل فيديو كبير',
      'largeVideoSavingMessage':
          'ملفات الفيديو بدقة 1080p و4K أكبر حجمًا، لذلك يعتمد وقت النقل على حجم الملف وسرعة اتصالك.',
      'largeVideoSavingSubtitle': 'أبقِ ApexLoad مفتوحًا حتى يكتمل النقل.',
      'downloadSaveFailed':
          'اكتمل التحميل، ولكن تعذّر حفظ الملف على جهازك. يرجى المحاولة مرة أخرى.',
      'addingToGallery': 'جارٍ الإضافة إلى المعرض',
      'galleryPublishFailed':
          'تم حفظ الملف داخل ApexLoad، ولكن تعذّرت إضافته إلى المعرض.',
      'calculating': 'جارٍ الحساب...',
      'selectDownloadOption': 'اختر خيار تنزيل واحداً على الأقل',
      'upgradeToPremium': 'الترقية إلى بريميوم',
      'premium': 'بريميوم',
      'premiumRequired': 'بريميوم مطلوب',
      'legalShort': 'حمّل فقط المحتوى الذي تملكه أو لديك إذن باستخدامه.',
      'legalFull':
          'هذا التطبيق مخصص فقط لتحميل المحتوى الذي تملكه، أو لديك إذن لاستخدامه، أو المحتوى المسموح بتحميله بشكل عام. أنت مسؤول عن احترام حقوق النشر وشروط المنصات.',
      'responsibleUseAgreementTitle': 'اتفاقية الاستخدام المسؤول',
      'responsibleUseSummary':
          'ApexLoad مخصص لتحميل وتعديل الوسائط العامة التي تملكها أو لديك إذن باستخدامها.',
      'responsibleUseMustNotDownload': 'يجب ألا تستخدم ApexLoad لتحميل:',
      'responsibleUseNoPrivateProfiles': 'الحسابات أو المنشورات الخاصة',
      'responsibleUseNoLoginOnly': 'الوسائط التي تتطلب تسجيل الدخول',
      'responsibleUseNoPaidMedia': 'الوسائط المدفوعة أو الخاصة بالمشتركين فقط',
      'responsibleUseNoDrm': 'الوسائط المحمية بإدارة الحقوق الرقمية',
      'responsibleUseNoRestricted': 'الوسائط المقيّدة',
      'responsibleUseNoCopyright': 'محتوى محمي بحقوق النشر دون تصريح',
      'responsibleUseNoPrivacyViolations': 'محتوى ينتهك حقوق الخصوصية',
      'responsibleUseNoIllegalOrPlatformViolations':
          'محتوى يخالف تحميله القانون أو قواعد المنصة',
      'responsibleUseCheckbox':
          'لقد قرأت وأوافق على شروط الاستخدام وسياسة الاستخدام المقبول.',
      'decline': 'رفض',
      'agreeAndContinue': 'الموافقة والمتابعة',
      'legalLinks': 'روابط قانونية',
      'acceptableUsePolicy': 'سياسة الاستخدام المقبول',
      'copyrightPolicy': 'سياسة حقوق النشر',
      'takedownRequest': 'طلب إزالة المحتوى',
      'submitTakedownRequest': 'إرسال طلب إزالة',
      'legalAndResponsibleUse': 'القانون والاستخدام المسؤول',
      'reviewResponsibleUseAgreement': 'مراجعة اتفاقية الاستخدام المسؤول',
      'reviewResponsibleUseAgreementSubtitle':
          'راجع قواعد التحميل القانوني والمسموح',
      'couldNotOpenLink': 'تعذّر فتح هذا الرابط. يرجى المحاولة مرة أخرى.',
      'backendProcessingDisclosure':
          'يرسل ApexLoad الرابط الذي تدخله إلى api.apexload.org لتحليل الوسائط وتجهيز التحميل الذي طلبته.',
      'confirmDownloadRightsTitle': 'تأكيد حقك في التحميل',
      'confirmDownloadRightsMessage':
          'قم بتحميل المحتوى الذي تملكه أو أنشأته بنفسك أو لديك إذن بحفظه واستخدامه فقط. لا تقم بتحميل محتوى خاص أو مدفوع أو محمي أو مقيّد أو محمي بحقوق النشر دون تصريح.',
      'confirmDownloadRightsCheckbox':
          'أؤكد أنني أملك هذا المحتوى أو لدي إذن لتحميله واستخدامه.',
      'supportedPlatforms': 'المنصات المدعومة',
      'sourceNotSupported':
          'هذا المصدر غير مدعوم. يعمل ApexLoad مع المنصات المذكورة أدناه فقط.',
      'contentOwnershipNotice':
          'ApexLoad ليس تابعًا لأي من هذه المنصات ولا معتمدًا أو مدعومًا منها. '
          'جميع المحتويات ملك لأصحابها. احفظ فقط المحتوى الذي أنشأته أو تملكه '
          'أو لديك إذن بحفظه.',
      'recentDownloads': 'آخر التحميلات',
      'viewAll': 'عرض الكل',
      'pasteFirst': 'الصق رابط وسائط عام أولاً.',
      'clipboardEmpty': 'الحافظة فارغة الآن.',
      'premiumActive': 'الاشتراك المميز نشط',
      'active': 'مفعّل',
      'freePlan': 'الخطة المجانية',
      'noWatermarkDownloads': 'تحميلات بدون علامة مائية',
      'noWatermarkWhenAvailable': 'بدون علامة مائية عند توفرها',
      'homeUpgradeCopy':
          'احصل على بريميوم لتحميل بجودة FHD و 4K عند توفرها، وبدون إعلانات، والمحرر السريع، وتبديل الصوت، و',
      'fhd4kDownloads': 'تحميل بجودة FHD و 4K عند توفرها',
      'fhd4kDownloadsWhenAvailable': 'حمّل بجودة FHD و 4K عند توفرها.',
      'fhd4kExport': 'تصدير بجودة FHD و 4K',
      'fhd4kShort': 'FHD و 4K',
      'unlockFhd4kQuality': 'افتح جودة FHD و 4K عند توفرها',
      'monthly': 'شهري',
      'yearly': 'سنوي',
      'choosePlan': 'اختر خطتك',
      'testerPremiumTitle': 'اشتراك المختبر المميز مفعّل',
      'testerPremiumMessage':
          'جميع الميزات المميزة مفتوحة في نسخة الاختبار هذه، ولا يلزم إجراء أي عملية شراء.',
      'monthlyPrice': '0.99 دولار / شهرياً',
      'yearlyPrice': '9.99 دولار / سنوياً',
      'import': 'استيراد',
      'validate': 'تحقق',
      'language': 'اللغة',
      'theme': 'المظهر',
      'quickEditor': 'المحرر السريع',
      'quickEditorSubtitle':
          'قص الفيديو، كتم الصوت، استخراج الصوت، وضغط الفيديو.',
      'quickEditorLandingSubtitle':
          'اختر فيديو تم تنزيله أو ملفًا من جهازك، ثم اختر أداة التعديل المناسبة.',
      'quickEditorPremiumTitle': 'المحرر السريع ميزة بريميوم',
      'quickEditorPremiumMessage':
          'قم بالترقية لقص الفيديو، كتم الصوت، استخراج الصوت، استبدال الصوت، وضغط الفيديو',
      'chooseVideoSource': 'اختر مصدر الفيديو',
      'chooseVideoSourceDescription':
          'استخدم فيديو من تنزيلات ApexLoad أو اختر فيديو محفوظًا على هذا الجهاز.',
      'chooseAudioSource': 'اختر مصدر الصوت',
      'files': 'الملفات',
      'browseDeviceFiles': 'تصفح الملفات المحفوظة على هذا الجهاز.',
      'photoLibrary': 'مكتبة الصور',
      'gallery': 'المعرض',
      'chooseVideoFromLibrary': 'اختر فيديو من مكتبة الوسائط.',
      'chooseVideoForAudio': 'اختر فيديو لاستخدام مساره الصوتي.',
      'clearLink': 'مسح الرابط',
      'pasteFromClipboard': 'لصق من الحافظة',
      'chooseLocalVideo': 'اختيار فيديو من الجهاز',
      'localVideoPremiumTitle': 'ميزة بريميوم',
      'localVideoPremiumMessage':
          'اختيار فيديو من الجهاز متاح لمشتركي ApexLoad Premium. قم بالترقية إلى بريميوم لاستيراد الفيديوهات من جهازك واستخدام أدوات المحرر السريع.',
      'chooseFromDownloads': 'اختيار من التنزيلات',
      'noEditableVideosYet':
          'لا توجد فيديوهات قابلة للتعديل بعد. نزّل فيديو أولًا أو اختر ملفًا من جهازك.',
      'localFile': 'ملف من الجهاز',
      'editVideo': 'تعديل الفيديو',
      'trimVideo': 'قص الفيديو',
      'muteVideo': 'كتم الصوت',
      'extractAudio': 'استخراج الصوت',
      'compressVideo': 'ضغط الفيديو',
      'videoOptimizer': 'تحسين الفيديو',
      'videoOptimizerSubtitle':
          'قلّل الحجم، وحوّل إلى MP4، وجهّز إخراجًا أنظف محليًا.',
      'videoOptimizerPremiumTitle': 'تحسين الفيديو ميزة بريميوم.',
      'videoOptimizerPremiumMessage':
          'قم بالترقية لتحسين الفيديوهات محليًا قبل مشاركتها.',
      'optimizerPreset': 'إعداد التحسين',
      'optimizerLocalOnly': 'يتم التحسين محليًا على هذا الجهاز.',
      'optimizeVideo': 'تحسين الفيديو',
      'optimizerSuccess': 'تم تحسين الفيديو بنجاح',
      'convertVideoToMp4': 'تحويل الفيديو إلى MP4',
      'exportEditedVideo': 'تصدير الفيديو المعدل',
      'format': 'الصيغة',
      'startTime': 'وقت البداية',
      'endTime': 'وقت النهاية',
      'trimDuration': 'مدة القص',
      'seconds': 'ثواني',
      'previewSelection': 'معاينة المقطع',
      'validTrimRange': 'يرجى اختيار نطاق قص صحيح.',
      'videoPreviewUnavailable': 'معاينة الفيديو غير متاحة لهذا الملف.',
      'applyTrim': 'تطبيق القص',
      'removeOriginalAudio': 'إزالة الصوت الأصلي',
      'applyMute': 'تطبيق الكتم',
      'standard': 'عادي',
      'high': 'عالي',
      'smallFile': 'ملف صغير',
      'balanced': 'متوازن',
      'highQuality': 'جودة عالية',
      'highestQuality': 'أعلى جودة',
      'estimatedReduction': 'تقليل الحجم المتوقع: أصغر بنسبة 35%',
      'compress': 'ضغط',
      'exportSettings': 'إعدادات التصدير',
      'saveToGallery': 'حفظ في المعرض',
      'saveOptions': 'خيارات الحفظ',
      'noWatermarkNote': 'تطبق فقط عندما توفرها المنصة أو المصدر.',
      'processingLocally': 'تتم المعالجة محلياً على هذا الجهاز',
      'processingEditor': 'تتم المعالجة محليًا على هذا الجهاز',
      'processingLargeVideo': 'جارٍ معالجة فيديو كبير',
      'largeVideoProcessingMessage':
          'يستخدم ApexLoad معالجة أسرع للهواتف لهذا الفيديو الكبير. يرجى إبقاء التطبيق مفتوحًا حتى يكتمل التصدير.',
      'trimSuccess': 'تم تطبيق القص بنجاح',
      'muteSuccess': 'تم كتم الفيديو بنجاح',
      'audioExtractedSuccess': 'تم استخراج الصوت بنجاح',
      'compressSuccess': 'تم ضغط الفيديو بنجاح',
      'exportSuccess': 'تم تصدير الفيديو المعدل بنجاح',
      'editedFileReady': 'ملفك المعدّل جاهز',
      'openEditedFile': 'فتح الملف المعدّل',
      'viewInDownloads': 'عرض في التنزيلات',
      'couldNotEditFile': 'تعذّر تعديل هذا الملف. يرجى تجربة ملف أو خيار آخر.',
      'originalFileMissing':
          'تعذّر العثور على الملف الأصلي. يرجى تنزيله مرة أخرى ثم محاولة تعديله.',
      'fileMustBeSavedBeforeEdit':
          'يجب حفظ هذا الملف على جهازك قبل تعديله. يرجى تنزيله مرة أخرى.',
      'savedToApexLoad': 'تم الحفظ في ApexLoad',
      'editedFileSavedSuccess': 'تم حفظ الملف المعدّل بنجاح.',
      'couldNotGenerateThumbnail': 'تعذّر إنشاء الصورة المصغّرة.',
      'deleteThisFile': 'هل تريد حذف هذا الملف؟',
      'fileDeleted': 'تم حذف الملف.',
      'sharingFailed': 'تعذّرت المشاركة. يرجى المحاولة مرة أخرى.',
      'today': 'اليوم',
      'yesterday': 'أمس',
      'older': 'أقدم',
      'edited': 'معدّل',
      'editor': 'المحرر',
      'editorToolSoon': 'سيتم إضافة هذه الأداة قريبًا.',
      'quickEditorBenefit':
          'قص الفيديو، كتم الصوت، استخراج الصوت، وضغط الفيديو.',
      'platformTikTok': 'تيك توك',
      'platformInstagram': 'إنستغرام',
      'platformFacebook': 'فيسبوك',
      'platformXTwitter': 'إكس/تويتر',
      'platformYouTubeShorts': 'يوتيوب شورتس',
      'platformPinterest': 'بنترست',
      'platformReddit': 'ريديت',
      'platformSnapchat': 'سناب شات',
      'unlockPremiumTitle': 'افتح ApexLoad بريميوم',
      'premiumSubtitle': 'سرعة أكثر. جودة أعلى. بدون حدود.',
      'premiumDownloads': 'تحميلات بريميوم',
      'premiumCreatorTools': 'أدوات صناع المحتوى',
      'premiumEditorTools': 'أدوات التعديل المميزة',
      'premiumUnlimitedDescription': 'حمّل بدون حدود يومية.',
      'premiumHdDownloads': 'تحميل بجودة عالية حتى 4K',
      'premiumHdDownloadsDescription': 'جودة أعلى عند توفرها من المصدر.',
      'premiumMp3Extraction': 'استخراج الصوت MP3',
      'premiumMp3Description': 'احفظ الصوت من الفيديوهات المدعومة.',
      'premiumNoWatermark': 'بدون علامة مائية عند الإمكان',
      'premiumNoWatermarkDescription': 'تُطبق تلقائياً عندما يدعم المصدر ذلك.',
      'premiumQuickEditorTools': 'أدوات التعديل السريع',
      'premiumFasterQueue': 'أولوية في المعالجة',
      'premiumFasterQueueDescription': 'أولوية للمهام المدعومة.',
      'premiumNoAdsDescription': 'استخدم ApexLoad بدون مقاطعة إعلانية.',
      'videoToGifBenefit':
          'حوّل لحظات الفيديو المفضلة لديك إلى صور GIF قابلة للمشاركة.',
      'reelsShortsBenefit': 'أنشئ فيديوهات عمودية جاهزة للمنصات خلال ثوانٍ.',
      'whatsappStatusBenefit':
          'احفظ صور وفيديوهات حالات واتساب التي شاهدتها بسهولة.',
      'videoOptimizerBenefit': 'قلّل حجم الملف مع التحكم في جودة الإخراج.',
      'advancedAudioSwapBenefit': 'اختر بدقة من أين يبدأ الصوت الجديد.',
      'professionalTrimPreview': 'معاينة القص الاحترافية',
      'audioStartSelector': 'تحديد بداية الصوت',
      'advancedAudioSwap': 'تبديل الصوت المتقدم',
      'localVideoConversion': 'تحويل الفيديو محليًا',
      'localOptimization': 'تحسين الفيديو محليًا',
      'noAds': 'بدون إعلانات',
      'audioExtraction': 'استخراج الصوت',
      'fasterQueue': 'طابور أسرع',
      'unlimitedDownloads': 'تحميلات غير محدودة',
      'cloudSave': 'حفظ سحابي',
      'bestValue': 'أفضل قيمة',
      'premiumActivatedDemo': 'اشتراك بريميوم نشط.',
      'premiumActiveButton': 'الاشتراك المميز نشط',
      'subscribeNow': 'اشترك الآن',
      'restorePurchases': 'استعادة المشتريات',
      'restorePurchasesSubtitle':
          'هل سبق أن اشتركت؟ استعد خطة بريميوم على هذا الجهاز.',
      'premiumAlreadyActive': 'بريميوم مفعّل بالفعل على هذا الجهاز.',
      'subscriptionTemporarilyUnavailable':
          'خطط الاشتراك غير متاحة حاليًا. يرجى التحقق من الاتصال والمحاولة '
          'مرة أخرى بعد قليل.',
      'restoringPurchases': 'جارٍ استعادة المشتريات...',
      'restorePurchasesSuccess': 'تمت استعادة اشتراك بريميوم.',
      'nothingToRestore': 'لم يتم العثور على اشتراك بريميوم نشط.',
      'purchasePending':
          'عملية الشراء بانتظار الموافقة. سيتم تفعيل بريميوم بعد تأكيد Apple.',
      'purchaseCancelled': 'تم إلغاء عملية الشراء.',
      'purchaseFailed': 'تعذّر إكمال عملية الشراء. يرجى المحاولة مرة أخرى.',
      'storeUnavailable':
          'متجر App Store غير متاح الآن. تحقق من اتصالك وحاول مرة أخرى.',
      'subscriptionProductsUnavailable':
          'لم تُرجع Apple منتجات اشتراك ApexLoad. أعد المحاولة مرة واحدة، ثم شارك رمز الدعم أدناه إذا استمرت المشكلة.',
      'supportCode': 'رمز الدعم',
      'retryAppStore': 'إعادة المحاولة مع App Store',
      'premiumLegalNotice':
          'يتم خصم المبلغ من Apple ID عند التأكيد. تتجدد الاشتراكات تلقائيًا ما لم يتم إلغاؤها قبل 24 ساعة على الأقل من نهاية الفترة الحالية. يمكنك الإدارة أو الإلغاء من إعدادات حساب App Store. بالاشتراك، فإنك توافق على شروط الاستخدام وسياسة الخصوصية.',
      'downloadOptions': 'خيارات التحميل',
      'chooseFormat': 'اختر الصيغة',
      'customFilename': 'اسم الملف المخصص',
      'download': 'تحميل',
      'howToUse': 'طريقة الاستخدام',
      'openAudioTool': 'فتح أداة استخراج الصوت',
      'viewPremium': 'عرض بريميوم',
      'notNow': 'ليس الآن',
      'premiumOption': 'خيار بريميوم',
      'premiumFeatureSummary':
          'افتح جودة FHD و 4K عند توفرها، والمحرر السريع، واستخراج الصوت.',
      'downloadProgress': 'تقدم التحميل',
      'selectedType': 'النوع المحدد',
      'requestedFormat': 'الصيغة المطلوبة',
      'returnedFileType': 'نوع الملف المستلم',
      'returnedFilename': 'اسم الملف المستلم',
      'openLibrary': 'فتح المكتبة',
      'downloadAnother': 'تحميل رابط آخر',
      'cancel': 'إلغاء',
      'platform': 'المنصة',
      'speed': 'السرعة',
      'queuePosition': 'ترتيب الطابور',
      'savedLocally': 'تم الحفظ محلياً',
      'done': 'تم',
      'searchDownloads': 'البحث في التحميلات',
      'playbackTip': 'ملاحظة للتشغيل',
      'playbackTipMessage':
          'إذا لم يعمل الفيديو على هاتفك، فقد يكون بصيغة لا يدعمها الجهاز. يمكنك تحويله إلى MP4 من خلال المحرر السريع، أو فتحه باستخدام مشغل وسائط مثل VLC.',
      'openQuickEditor': 'فتح المحرر السريع',
      'convertToMp4': 'تحويل إلى MP4',
      'noDownloadsYet': 'لا توجد تحميلات بعد',
      'pasteLinkOnHome': 'الصق رابطاً في الشاشة الرئيسية للبدء.',
      'renameFile': 'إعادة تسمية الملف',
      'filename': 'اسم الملف',
      'save': 'حفظ',
      'upgradeNow': 'الترقية الآن',
      'maybeLater': 'ربما لاحقاً',
      'dailyLimitReachedTitle': 'تم الوصول إلى الحد اليومي',
      'dailyLimitReachedMessage':
          'لقد وصلت إلى الحد اليومي المجاني. قم بالترقية إلى بريميوم لتحميلات غير محدودة.',
      'freeDownloadsLeft': 'التحميلات المجانية المتبقية اليوم: {count}/5',
      'adPlaceholderTitle': 'ApexLoad المجاني',
      'adPlaceholderMessage': 'التحميل جاهز.',
      'premiumActivatedSuccess': 'تم تفعيل بريميوم بنجاح.',
      'premiumMonthly': 'بريميوم شهري',
      'premiumYearly': 'بريميوم سنوي',
      'fhd4kPremiumTitle': 'تحميلات FHD و 4K ميزة بريميوم.',
      'fhd4kPremiumMessage': 'قم بالترقية للتحميل بجودة أعلى عند توفرها.',
      'audioExtractionPremiumTitle': 'استخراج الصوت ميزة بريميوم.',
      'audioExtractionPremiumMessage':
          'قم بالترقية لاستخراج الصوت من روابط الوسائط.',
      'noWatermarkPremiumTitle': 'التحميل بدون علامة مائية ميزة بريميوم.',
      'noWatermarkPremiumMessage':
          'متاح عندما توفر المنصة نسخة بدون علامة مائية.',
      'audioSwapPremiumTitle': 'تبديل الصوت ميزة بريميوم.',
      'audioSwapPremiumMessage':
          'قم بالترقية لاستبدال صوت الفيديو الأصلي بصوت من جهازك.',
      'audioSwap': 'تبديل الصوت',
      'audioSwapReplaceAudio': 'تبديل الصوت / استبدال الصوت',
      'replaceAudio': 'استبدال الصوت',
      'audioSwapSubtitle': 'استبدل صوت الفيديو الأصلي بصوت من جهازك',
      'audioSwapDescription': 'استبدل صوت الفيديو الأصلي بملف صوتي من هاتفك.',
      'chooseAudioFile': 'اختر ملفًا صوتيًا',
      'pickAudioFile': 'اختيار ملف صوتي',
      'selectedAudio': 'الصوت المختار',
      'audioFormatSupport': 'سيتم دعم MP3 / M4A / WAV لاحقاً',
      'audioStartPosition': 'بداية الصوت داخل الفيديو',
      'audioStartPoint': 'نقطة بداية الصوت',
      'audioStartPointHelp':
          'اختر من أين يبدأ الصوت المحدد. سيتم تشغيله من بداية الفيديو.',
      'audioStartsAtVideoPoint':
          'سيبدأ الصوت الجديد من الثانية 0 في الفيديو. إذا كان أقصر من مدة الفيديو، اختر تكراره أو ترك الجزء المتبقي صامتًا.',
      'audioSectionUsed': 'الجزء المستخدم من الصوت',
      'removeOriginalSound': 'إزالة الصوت الأصلي',
      'keepOriginalSoundSoftly': 'إبقاء الصوت الأصلي منخفض',
      'audioVolume': 'مستوى الصوت',
      'preview': 'معاينة',
      'applyAudioSwap': 'تطبيق تبديل الصوت',
      'audioReplacedSuccess': 'تم استبدال الصوت بنجاح.',
      'couldNotReplaceAudio': 'تعذّر استبدال الصوت. يرجى تجربة ملف صوتي آخر.',
      'noAudioSelected': 'اختر ملفاً صوتياً أولاً.',
      'originalAudio': 'الصوت الأصلي',
      'replaceOriginalAudio': 'استبدال الصوت الأصلي',
      'removeOriginalAudioOnly': 'إزالة الصوت الأصلي فقط',
      'chooseNewAudio': 'اختيار صوت جديد',
      'noNewAudioNeeded': 'لا تحتاج إلى ملف صوتي جديد عند إزالة الصوت فقط.',
      'previewAndApply': 'المعاينة والتطبيق',
      'previewWithNewAudio': 'معاينة بالصوت الجديد',
      'audioTrimmedToVideoLength':
          'سيتم ضبط الصوت الجديد ليتناسب مع مدة الفيديو.',
      'audioShorterThanVideo':
          'إذا كان الصوت أقصر، سينتهي التصدير عند نهاية الصوت الجديد.',
      'advancedOptions': 'خيارات متقدمة',
      'videoToGif': 'تحويل الفيديو إلى GIF',
      'createGif': 'إنشاء GIF',
      'previewGifRange': 'معاينة جزء GIF',
      'gifCreatedSuccess': 'تم إنشاء GIF بنجاح.',
      'couldNotCreateGif': 'تعذّر إنشاء GIF. جرّب مدة أقصر.',
      'videoToGifPremiumTitle': 'تحويل الفيديو إلى GIF ميزة بريميوم.',
      'reelsShortsCreator': 'صانع Reels/Shorts',
      'chooseOutputFormat': 'اختر تنسيق الإخراج',
      'resizeMode': 'طريقة تغيير المقاس',
      'smartCrop': 'قص ذكي',
      'fitWithBlurredBackground': 'ملاءمة مع خلفية',
      'fitWithSolidBackground': 'ملاءمة مع خلفية ثابتة',
      'centerCrop': 'قص من الوسط',
      'reelShortCreatedSuccess': 'تم إنشاء Reel/Short بنجاح.',
      'couldNotCreateReelShort': 'تعذّر إنشاء Reel/Short. يرجى تجربة خيار آخر.',
      'reelsShortsPremiumTitle': 'صانع Reels/Shorts ميزة بريميوم.',
      'chooseVideo': 'اختيار فيديو',
      'selectedVideo': 'الفيديو المختار',
      'gifSettings': 'إعدادات GIF',
      'quality': 'الجودة',
      'size': 'الحجم',
      'small': 'صغير',
      'medium': 'متوسط',
      'original': 'الأصلي',
      'fps': 'إطار/ثانية',
      'loop': 'تكرار',
      'reelsShortsOutputNote':
          'يتم التصدير محليًا بصيغة MP4 مناسبة للمنصات الاجتماعية.',
      'demoPreviewReady': 'المعاينة جاهزة.',
      'somethingWentWrong': 'حدث خطأ، حاول مرة أخرى',
      'demoActionForNow': '{action} غير متاح حالياً.',
      'sharingSoon': 'ستتم إضافة المشاركة قريبًا.',
      'couldNotOpenFile': 'تعذّر فتح هذا الملف. يرجى المحاولة مرة أخرى.',
      'fileNoLongerAvailable': 'هذا الملف لم يعد متاحًا على جهازك.',
      'demoExtractionPrepared': 'استخراج {format} جاهز.',
      'notAvailableOnClip': 'غير متوفر لهذا المقطع',
      'notAvailableForImage': 'غير متوفر لهذه الصورة',
      'Instagram photo posts are not available for this link. Try a Reel/video link.':
          'منشورات الصور في إنستغرام غير متاحة لهذا الرابط. جرّب رابط Reel أو فيديو.',
      'Facebook photo posts are not available for this link. Try a video link.':
          'منشورات صور فيسبوك غير متاحة لهذا الرابط. جرّب رابط فيديو.',
      'noWatermarkApplied': 'سيتم التحميل بدون علامة مائية عند توفر ذلك',
      'downloadSelected': 'تحميل المحدد',
      'downloadSelectedItems': 'تحميل العناصر المحددة',
      'downloadSelectedItemsCount': 'تحميل {count} عناصر محددة',
      'selectedItemsDownloaded': 'تم تحميل العناصر المحددة بنجاح',
      'chooseImageFormat': 'اختر صيغة الصورة',
      'originalImage': 'الصورة الأصلية',
      'highQualityImage': 'صورة عالية الجودة',
      'compressedImage': 'صورة مضغوطة',
      'jpgImage': 'صورة JPG',
      'pngImage': 'صورة PNG',
      'bestAvailableQuality': 'أفضل جودة متاحة',
      'premiumQualityWhenAvailable': 'جودة بريميوم عند توفرها',
      'smallerFileSize': 'حجم ملف أصغر',
      'standardFormat': 'صيغة قياسية',
      'whenAvailable': 'عند توفرها',
      'imagePremiumTitle': 'الصور عالية الجودة ميزة بريميوم.',
      'imagePremiumMessage': 'قم بالترقية لتحميل صيغ الصور المميزة عند توفرها.',
      'yourApexLoad': 'حساب ApexLoad الخاص بك',
      'appStatus': 'حالة التطبيق',
      'plan': 'الخطة',
      'downloadsToday': 'تحميلات اليوم',
      'storageUsed': 'المساحة المستخدمة',
      'locked': 'مقفل',
      'unlocked': 'مفتوح',
      'free': 'مجاني',
      'all': 'الكل',
      'video': 'فيديو',
      'audio': 'صوت',
      'images': 'صور',
      'open': 'فتح',
      'share': 'مشاركة',
      'edit': 'تعديل',
      'rename': 'إعادة تسمية',
      'delete': 'حذف',
      'goHome': 'العودة للرئيسية',
      'pasteOneLinkPerLine': 'الصق رابطاً عاماً في كل سطر',
      'queuePreview': 'معاينة القائمة',
      'ready': 'جاهز',
      'invalidLink': 'رابط غير صالح',
      'pasteMediaLink': 'الصق رابط الوسائط',
      'audioFormat': 'صيغة الصوت',
      'audioQuality': 'جودة الصوت',
      'systemDefault': 'افتراضي النظام',
      'english': 'English',
      'arabic': 'العربية',
      'system': 'النظام',
      'dark': 'داكن',
      'light': 'فاتح',
      'autoSaveToGallery': 'الحفظ التلقائي في المعرض',
      'autoSaveAndroidDescription':
          'نشر التحميلات المدعومة تلقائيًا في معرض الجهاز.',
      'autoSaveIosDescription':
          'إضافة الصور والفيديوهات المحمّلة تلقائيًا إلى تطبيق الصور، مع بقائها أيضًا في الملفات > على iPhone الخاص بي > ApexLoad.',
      'downloadLocation': 'مكان التحميل',
      'deviceDownloadsFolder': 'مجلد التحميلات على الجهاز',
      'downloadLocationAndroidSubtitle': 'عرض مجلدات وسائط ApexLoad',
      'downloadLocationIosSubtitle': 'الملفات > على iPhone الخاص بي > ApexLoad',
      'downloadLocationAndroidDescription':
          'يحفظ ApexLoad ملفاته في مجلدات مخصصة داخل مساحة التطبيق. ويمكن أيضًا نشر الوسائط المدعومة في المعرض عند تفعيل الحفظ التلقائي.',
      'downloadLocationIosDescription':
          'ستجد تحميلاتك في تطبيق الملفات ضمن على iPhone الخاص بي > ApexLoad. لا يعرض ApexLoad مسار نظام iOS الداخلي الخاص.',
      'videosFolder': 'الفيديوهات',
      'audioFolder': 'الصوتيات',
      'imagesFolder': 'الصور',
      'editedFolder': 'الملفات المعدّلة',
      'gifsFolder': 'صور GIF',
      'thumbnailsFolder': 'الصور المصغّرة',
      'openFolder': 'فتح المجلد',
      'folderOpenUnavailable':
          'تعذّر على مدير الملفات فتح هذا المجلد. لا يزال بإمكانك الوصول إلى الوسائط من صفحة التحميلات.',
      'clearCache': 'مسح الذاكرة المؤقتة',
      'clearCacheSubtitle': 'حذف الصور المصغّرة ومعاينات المحرر المؤقتة',
      'clearCacheConfirmTitle': 'هل تريد مسح الملفات المؤقتة؟',
      'clearCacheConfirmMessage':
          'سيتم حذف الصور المصغّرة التي أنشأها التطبيق ومعاينات المحرر المؤقتة فقط. ستبقى تحميلاتك وملفاتك المعدّلة وسجل التحميل والإعدادات وحالة بريميوم محفوظة.',
      'cacheClearedSuccess': 'تم مسح {size} من البيانات المؤقتة.',
      'cacheClearFailed': 'تعذّر مسح الملفات المؤقتة. يرجى المحاولة مرة أخرى.',
      'privacyPolicy': 'سياسة الخصوصية',
      'privacyPolicySubtitle': 'كيفية تعامل ApexLoad مع البيانات والأذونات',
      'termsOfUse': 'شروط الاستخدام',
      'termsOfUseSubtitle': 'قواعد الاستخدام المسؤول لتطبيق ApexLoad',
      'contactSupport': 'التواصل مع الدعم',
      'rateApp': 'تقييم التطبيق',
      'rateAppSubtitle': 'شارك رأيك عبر متجر التطبيقات',
      'ratingAvailableAfterRelease':
          'سيصبح تقييم ApexLoad متاحًا بعد نشر التطبيق في المتجر.',
      'couldNotOpenStore': 'تعذّر فتح متجر التطبيقات. يرجى المحاولة مرة أخرى.',
      'supportEmailBody':
          'يرجى وصف المشكلة أدناه:\n\n\nإصدار التطبيق: {version}\nالمنصة: {platform}\nإصدار النظام: {osVersion}',
      'emailAppUnavailableTitle': 'تعذّر فتح تطبيق البريد',
      'emailAppUnavailableMessage':
          'لم نتمكن من فتح تطبيق بريد. يمكنك نسخ عنوان الدعم بدلًا من ذلك.',
      'copyEmail': 'نسخ البريد',
      'emailCopied': 'تم نسخ بريد الدعم.',
      'legalLastUpdated': 'آخر تحديث: يوليو 2026',
      'privacyIntro':
          'توضح هذه السياسة كيفية تعامل الإصدار الحالي من ApexLoad مع المعلومات عند تحليل الروابط أو تحميل الوسائط أو استخدام أدوات التعديل المحلية أو التواصل مع الدعم.',
      'privacyDataTitle': 'المعلومات التي تقدمها',
      'privacyDataBody':
          'تُرسل الروابط التي تدخلها وصيغ التحميل المحددة وخيارات التحميل المرتبطة بها إلى خادم ApexLoad لتحليل الطلب ومعالجته. وعند التواصل مع الدعم، يجهّز تطبيق البريد رسالة تتضمن إصدار التطبيق والمنصة وإصدار النظام وأي تفاصيل تختار إضافتها.',
      'privacyProcessingTitle': 'معالجة التحميل على الخادم',
      'privacyProcessingBody':
          'قد يتصل خادم ApexLoad بمنصة الوسائط العامة أو شبكة توزيع المحتوى التابعة لها لتحليل الوسائط المطلوبة وتجهيزها، ثم يُنقل الملف الناتج إلى جهازك. لا ترسل روابط خاصة أو مقيّدة أو حساسة لا تملك صلاحية الوصول إليها.',
      'privacyLocalTitle': 'البيانات المحفوظة على جهازك',
      'privacyLocalBody':
          'يحفظ ApexLoad على جهازك التفضيلات واللغة والمظهر وحالة بريميوم المحلية وعداد الاستخدام اليومي وسجل التحميل ومسارات الملفات والصور المصغّرة. تتم عمليات المحرر السريع محليًا على الجهاز. مسح الذاكرة المؤقتة يحذف المعاينات المؤقتة والصور المصغّرة فقط، بينما قد يؤدي مسح بيانات التطبيق من النظام إلى حذف السجلات المحلية والملفات التي يديرها التطبيق.',
      'privacyPermissionsTitle': 'الأذونات',
      'privacyPermissionsBody':
          'يُستخدم اتصال الشبكة للتحليل والتحميل. وقد يستخدم أندرويد الوصول إلى الوسائط والمجلدات لنشر التحميلات أو قراءة مجلد .Statuses الذي تختاره بنفسك. ويستخدم iOS منتقي الملفات لاختيار الملفات ويعرض مستندات التطبيق في تطبيق الملفات. لا يطلب ApexLoad صلاحية الوصول الشامل إلى جميع الملفات.',
      'privacyThirdPartiesTitle': 'الخدمات الخارجية',
      'privacyThirdPartiesBody':
          'يتعامل ApexLoad مع منصة التواصل أو الوسائط الموجودة في الرابط، ومزودي توزيع المحتوى، وواجهة ApexLoad البرمجية، وخدمات المشاركة والتخزين والبريد في نظام التشغيل. تعالج Apple مشتريات اشتراكات App Store ومعلومات الدفع المرتبطة بها وفق سياساتها. لا يستلم ApexLoad بيانات بطاقة الدفع الكاملة.',
      'privacyAccountsTitle': 'الحسابات والاشتراكات',
      'privacyAccountsBody':
          'لا يتطلب ApexLoad إنشاء حساب. يتم شراء اشتراكات بريميوم وإدارتها من خلال Apple App Store. يقرأ التطبيق معلومات الاستحقاق الموثقة من StoreKit ويحفظ حالة بريميوم الحالية وتاريخ انتهائها محليًا لتفعيل الميزات. استخدم استعادة المشتريات لاستعادة اشتراك نشط على جهاز مؤهل آخر.',
      'privacyChoicesTitle': 'خياراتك',
      'privacyChoicesBody':
          'يمكنك تعطيل النشر التلقائي في المعرض على أجهزة أندرويد المدعومة، وحذف تحميلات فردية، ومسح الملفات المؤقتة، وإلغاء إذن المجلد من إعدادات النظام، أو مسح بيانات التطبيق. تغيير الإعداد لا يحذف الملفات المحفوظة مسبقًا.',
      'legalContactTitle': 'التواصل',
      'legalContactBody':
          'يمكن إرسال الأسئلة المتعلقة بالخصوصية أو هذه الشروط أو ApexLoad إلى support@apexload.org.',
      'termsIntro':
          'باستخدام ApexLoad، فإنك توافق على استعماله بصورة قانونية ومسؤولة وللمحتوى الذي تملكه أو لديك إذن باستخدامه أو يُسمح لك بتحميله.',
      'termsUseTitle': 'الاستخدام المسؤول',
      'termsUseBody':
          'أنت مسؤول عن كل رابط وملف تعالجه. التزم بالقوانين المعمول بها وشروط المنصات وحقوق الخصوصية وأي ترخيص أو إذن مرتبط بالمحتوى.',
      'termsCopyrightTitle': 'حقوق النشر والملكية',
      'termsCopyrightBody':
          'لا يمنحك ApexLoad ملكية محتوى الآخرين. حافظ على نسب المحتوى وإشعارات حقوق النشر عند الحاجة، واحصل على الإذن قبل نسخ محتوى يملكه شخص آخر أو تعديله أو نشره أو توزيعه.',
      'termsProhibitedTitle': 'الاستخدام المحظور',
      'termsProhibitedBody':
          'لا تستخدم ApexLoad للوصول إلى محتوى خاص أو يتطلب تسجيل الدخول أو مدفوع أو مقيّد أو محمي بإدارة الحقوق الرقمية، أو لتجاوز وسائل الحماية، أو انتهاك حقوق النشر، أو مضايقة الآخرين، أو نشر مواد غير قانونية، أو إساءة استخدام الخدمة آليًا.',
      'termsPlatformsTitle': 'المنصات الخارجية وتوفر الخدمة',
      'termsPlatformsBody':
          'قد تغيّر المنصات المدعومة طريقة عملها أو تمنع الوصول دون إشعار. وقد لا تتوفر صيغة أو جودة أو صورة مصغّرة أو مسار صوتي أو رابط. ApexLoad غير تابع للمنصات الاجتماعية المذكورة ولا يحظى بتأييدها ما لم يُذكر ذلك صراحة.',
      'termsSubscriptionsTitle': 'ميزات بريميوم',
      'termsSubscriptionsBody':
          'يوفر ApexLoad اشتراكات بريميوم شهرية وسنوية تتجدد تلقائيًا. يظهر السعر المحلي وفترة الفوترة قبل الشراء. يتم خصم المبلغ من Apple ID عند التأكيد. يتجدد الاشتراك تلقائيًا ما لم يتم إلغاؤه قبل 24 ساعة على الأقل من نهاية الفترة الحالية. يمكنك إدارته أو إلغاؤه من إعدادات حساب App Store. قد تتغير ميزات بريميوم وتوفرها وفق القانون المعمول به وشروط App Store.',
      'termsLimitationsTitle': 'حدود الخدمة والمسؤولية',
      'termsLimitationsBody':
          'تُقدّم خدمة ApexLoad حسب توفرها. قد تفشل التحميلات أو التعديلات بسبب الشبكة أو مساحة الجهاز أو وسائط غير مدعومة أو تغييرات المنصات أو قيود الجهات الخارجية. وفي الحدود التي يسمح بها القانون، لا يتحمل ApexLoad مسؤولية الاستخدام غير المصرح به أو فقدان البيانات أو عدم توفر محتوى خارجي أو الأضرار غير المباشرة. احتفظ بنسخة احتياطية من ملفاتك المهمة.',
      'editingCompatibilityTitle': 'لأفضل توافق أثناء التعديل',
      'editingCompatibilityMessage':
          'هذا الفيديو ليس بصيغة MP4. لتعديل أكثر سلاسة على iPhone، نوصي بتحويله إلى MP4 أولًا. ويمكنك أيضًا متابعة تعديل الملف الأصلي.',
      'continueEditing': 'متابعة التعديل',
      'editingComplete': 'ملفك جاهز',
      'editingCompleteMessage': 'تم حفظ الملف المعدل بنجاح. ماذا تود أن تفعل بعد ذلك؟',
      'goToConvertMp4': 'تحويل إلى MP4',
      'choosePlatform': 'اختر المنصة',
      'instagramReel': 'Instagram Reel',
      'youtubeShort': 'YouTube Short',
      'tiktokVideo': 'TikTok Video',
      'snapchatSpotlight': 'Snapchat Spotlight',
      'readyForPlatform': 'جاهز لـ {platform}',
      'safeZone': 'منطقة آمنة',
      'safeZoneHelp': 'أبقِ الوجوه والنصوص والمحتوى المهم داخل هذه المنطقة.',
      'smartCropHelp': 'يملأ الشاشة العمودية بالكامل مع قص الحواف الخارجية.',
      'blurredBackgroundHelp':
          'يعرض الفيديو بالكامل مع خلفية تملأ المساحة الفارغة.',
      'platformPresetHelp':
          'اختر منصة وسيجهز ApexLoad فيديو MP4 عموديًا مناسبًا.',
      'createInstagramReel': 'إنشاء Instagram Reel',
      'createYouTubeShort': 'إنشاء YouTube Short',
      'createTikTokVideo': 'إنشاء TikTok Video',
      'createSnapchatSpotlight': 'إنشاء Snapchat Spotlight',
      'videoStep': 'الفيديو',
      'videoAudioSwapHelp': 'هذا هو الفيديو الذي سيتم استبدال صوته أو دمجه.',
      'selectAudioRange': 'حدد نطاق الصوت',
      'audioStart': 'بداية الصوت',
      'audioEnd': 'نهاية الصوت',
      'selectedAudioDuration': 'مدة الصوت المحددة',
      'automaticMatch': 'مطابقة تلقائية',
      'customAudioRange': 'نطاق صوت مخصص',
      'audioRangeHelp':
          'اختر الجزء الذي تريد استخدامه من الملف الصوتي. سيبدأ الصوت المحدد عند بداية الفيديو.',
      'loopAudioUntilVideoEnds': 'تكرار الصوت حتى نهاية الفيديو',
      'leaveRemainingVideoSilent': 'ترك الجزء المتبقي من الفيديو صامتًا',
      'keepOriginalAfterAudioEnds':
          'الإبقاء على الصوت الأصلي بعد انتهاء الصوت المحدد',
      'playSelectedSegment': 'تشغيل الجزء المحدد',
      'resetSelection': 'إعادة التحديد',
      'outputSummary': 'ملخص الإخراج',
      'statusSaver': 'حافظ الحالات',
      'whatsappStatusSaver': 'حفظ حالات واتساب',
      'whatsappStatusHomeCopy': 'احفظ صور وفيديوهات حالات واتساب التي شاهدتها.',
      'androidOnly': 'أندرويد فقط',
      'whatsappStatusAndroidOnlyTitle':
          'حفظ حالات واتساب متاح على أندرويد فقط.',
      'whatsappStatusAndroidOnlyMessage':
          'نظام iOS لا يسمح للتطبيقات بالوصول إلى مجلد حالات واتساب.',
      'whatsappStatusPremiumTitle': 'حافظ حالات واتساب ميزة بريميوم.',
      'whatsappStatusPremiumMessage':
          'يمكنك معاينة الحالات المحلية، والترقية لحفظها داخل ApexLoad.',
      'whatsappStatusLocalOnly':
          'يحفظ واتساب الحالات على جهازك بعد مشاهدتها فقط.',
      'whatsappStatusStep1': 'افتح واتساب وشاهد الحالات التي تريد حفظها.',
      'whatsappStatusStep2': 'ارجع إلى ApexLoad.',
      'whatsappStatusStep3': 'اضغط ربط مجلد حالات واتساب.',
      'whatsappStatusStep4': 'اختر مجلد WhatsApp .Statuses.',
      'connectWhatsappFolder': 'ربط مجلد واتساب',
      'connectWhatsappBusinessFolder': 'ربط مجلد واتساب بزنس',
      'howToFindFolder': 'طريقة العثور على المجلد',
      'howToFindWhatsappFolder': 'طريقة العثور على مجلد حالات واتساب',
      'whatsappFolderGuide':
          'في منتقي المجلدات على أندرويد، افتح WhatsApp أو WhatsApp Business ثم Media ثم اختر .Statuses. يقرأ ApexLoad الملفات الموجودة على هاتفك فقط.',
      'whatsappHowToUseCta': 'اضغط هنا لمعرفة طريقة الاستخدام',
      'whatsappHowToUseSubtitle': 'تعرّف على طريقة ربط مجلد .Statuses',
      'whatsappTutorialTitle': 'طريقة استخدام حفظ حالات واتساب',
      'whatsappTutorialHiddenFilesNote':
          'إذا لم يظهر مجلد .Statuses، فعّل خيار إظهار الملفات المخفية من قائمة الثلاث نقاط.',
      'tapImageToEnlarge': 'اضغط على الصورة للتكبير',
      'whatsappTutorialStep1Title': 'الخطوة 1 — اضغط تغيير المجلد',
      'whatsappTutorialStep1Description':
          'اضغط تغيير المجلد لاختيار مجلد حالات واتساب.',
      'whatsappTutorialStep2Title': 'الخطوة 2 — إظهار الملفات المخفية',
      'whatsappTutorialStep2Description':
          'اضغط قائمة الثلاث نقاط، ثم فعّل إظهار الملفات المخفية.',
      'whatsappTutorialStep3Title': 'الخطوة 3 — افتح مجلد .Statuses',
      'whatsappTutorialStep3Description':
          'اضغط مجلد .Statuses بعد ظهور الملفات المخفية.',
      'whatsappTutorialStep4Title': 'الخطوة 4 — استخدم هذا المجلد',
      'whatsappTutorialStep4Description':
          'اضغط استخدام هذا المجلد بعد الدخول إلى .Statuses.',
      'whatsappTutorialStep5Title': 'الخطوة 5 — السماح بالوصول',
      'whatsappTutorialStep5Description':
          'اضغط سماح لمنح ApexLoad الوصول إلى مجلد .Statuses.',
      'whatsappTutorialStep6Title': 'الخطوة 6 — اعرض حالات واتساب',
      'whatsappTutorialStep6Description':
          'ارجع إلى ApexLoad ومرّر للأسفل لعرض حالات واتساب وحفظها.',
      'pasteLinkTutorialTitle': 'طريقة نسخ ولصق رابط الفيديو',
      'pasteLinkInstagramShareTitle': 'إنستغرام — اضغط مشاركة',
      'pasteLinkInstagramCopyTitle': 'إنستغرام — نسخ الرابط',
      'pasteLinkTikTokShareTitle': 'تيك توك — اضغط مشاركة',
      'pasteLinkTikTokCopyTitle': 'تيك توك — نسخ الرابط',
      'pasteLinkInstagramShareDescription':
          'افتح ريل إنستغرام واضغط على أيقونة المشاركة.',
      'pasteLinkCopyDescription':
          'اضغط نسخ الرابط، ثم ارجع إلى ApexLoad والصقه.',
      'pasteLinkTikTokShareDescription':
          'افتح فيديو تيك توك واضغط على أيقونة المشاركة.',
      'pasteLinkTutorialNote':
          'بعد نسخ الرابط، ارجع إلى ApexLoad واضغط تحليل الرابط.',
      'showHiddenFiles': 'إظهار الملفات المخفية',
      'whatsappInstructionsStandardTitle': 'واتساب العادي',
      'whatsappInstructionStandardStep1':
          'افتح واتساب وشاهد الحالات التي تريد حفظها.',
      'whatsappInstructionStandardStep2': 'ارجع إلى ApexLoad.',
      'whatsappInstructionStandardStep3': 'اضغط ربط حالات واتساب.',
      'whatsappInstructionStandardStep4':
          'في منتقي المجلدات على أندرويد، افتح Android > media > com.whatsapp > WhatsApp > Media.',
      'whatsappInstructionStandardStep5':
          'اضغط قائمة الثلاث نقاط في الزاوية العلوية.',
      'whatsappInstructionStandardStep6': 'فعّل إظهار الملفات المخفية.',
      'whatsappInstructionStandardStep7': 'افتح المجلد المخفي: .Statuses.',
      'whatsappInstructionStandardStep8': 'اضغط استخدام هذا المجلد أو سماح.',
      'whatsappInstructionsBusinessTitle': 'واتساب بزنس',
      'whatsappInstructionBusinessStep1':
          'افتح واتساب بزنس وشاهد الحالات التي تريد حفظها.',
      'whatsappInstructionBusinessStep2': 'ارجع إلى ApexLoad.',
      'whatsappInstructionBusinessStep3': 'اضغط ربط مجلد واتساب بزنس.',
      'whatsappInstructionBusinessStep4':
          'في منتقي المجلدات على أندرويد، افتح Android > media > com.whatsapp.w4b > WhatsApp Business > Media.',
      'whatsappInstructionBusinessStep5':
          'اضغط قائمة الثلاث نقاط في الزاوية العلوية.',
      'whatsappInstructionBusinessStep6': 'فعّل إظهار الملفات المخفية.',
      'whatsappInstructionBusinessStep7': 'افتح المجلد المخفي: .Statuses.',
      'whatsappInstructionBusinessStep8': 'اضغط استخدام هذا المجلد أو سماح.',
      'whatsappHiddenFolderNote':
          'مجلد .Statuses مخفي بواسطة أندرويد. إذا لم يظهر لك، اضغط على قائمة الثلاث نقاط وفعّل إظهار الملفات المخفية.',
      'whatsappStatusReadNote':
          'يقرأ ApexLoad الحالات المحفوظة على جهازك فقط بعد مشاهدتها في واتساب.',
      'whatsappPickerHint':
          'اختر Android > media > com.whatsapp > WhatsApp > Media > .Statuses',
      'whatsappBusinessPickerHint':
          'اختر Android > media > com.whatsapp.w4b > WhatsApp Business > Media > .Statuses',
      'folderConnectionCancelled': 'تم إلغاء ربط المجلد.',
      'tryAgain': 'حاول مرة أخرى',
      'disconnectFolder': 'فصل المجلد',
      'connected': 'متصل',
      'notConnected': 'غير متصل',
      'whatsappConnected': 'تم ربط مجلد حالات واتساب',
      'whatsappBusinessConnected': 'تم ربط مجلد حالات واتساب بزنس',
      'folderSettings': 'إعدادات المجلد',
      'refresh': 'تحديث',
      'saved': 'محفوظ',
      'videos': 'فيديوهات',
      'saveSelected': 'حفظ المحدد',
      'selectAll': 'تحديد الكل',
      'statusGallery': 'معرض الحالات',
      'connectWhatsappFolderFirst':
          'اربط مجلد .Statuses في واتساب لعرض الحالات المحلية.',
      'noWhatsappStatusesFound':
          'لم يتم العثور على حالات. افتح واتساب وشاهد بعض الحالات ثم حدّث الصفحة.',
      'whatsappFolderAccessError':
          'تعذّر الوصول إلى مجلد واتساب المحدد. يرجى ربطه مرة أخرى.',
      'statusAlreadySaved': 'تم حفظ هذه الحالة مسبقًا.',
      'statusSavedSuccess': 'تم حفظ الحالة في ApexLoad.',
      'whatsappAutoDetected': 'تم اكتشاف حالات واتساب تلقائيًا.',
      'guidedPermissionText':
          'استخدم دليل طريقة الاستخدام أعلاه، ثم اربط مجلد .Statuses. ستحتاج إلى تنفيذ هذه الخطوة مرة واحدة فقط.',
      'connectWhatsappStatuses': 'ربط حالات واتساب',
      'connectWhatsappSetupExplanation':
          'يتطلب أندرويد إذنًا لمرة واحدة للوصول إلى حالات واتساب التي شاهدتها. أكمل هذه الخطوات مرة واحدة، وسيحمّل ApexLoad الحالات تلقائيًا بعد ذلك.',
      'whatsappSetupStep1': 'اضغط تغيير المجلد لفتح منتقي المجلدات في أندرويد.',
      'whatsappSetupStep2':
          'في منتقي المجلدات، اضغط قائمة الثلاث نقاط واختر إظهار الملفات المخفية.',
      'whatsappSetupStep3': 'افتح مجلد .Statuses.',
      'whatsappSetupStep4': 'اضغط استخدام هذا المجلد، ثم اضغط سماح.',
      'whatsappSetupStep5': 'بعد ذلك، سيحمّل ApexLoad الحالات تلقائيًا.',
      'watchInstructions': 'عرض التعليمات',
      'changeFolder': 'تغيير المجلد',
      'wrongWhatsappFolder':
          'لا يبدو أن هذا هو مجلد .Statuses في واتساب. يرجى تفعيل الملفات المخفية واختيار .Statuses.',
      'wrongWhatsappFolderSelected':
          'هذا ليس مجلد .Statuses. يرجى الضغط على تغيير المجلد، ثم إظهار الملفات المخفية، ثم اختيار .Statuses.',
      'setupRequired': 'الإعداد مطلوب',
      'validatingFolder': 'تم اختيار المجلد، جارٍ التحقق',
      'wrongFolderSelected': 'تم اختيار مجلد غير صحيح',
      'connectedNoStatuses': 'تم الربط، لكن لا توجد حالات مشاهدة بعد',
      'checkingSavedAccess': 'جارٍ التحقق من صلاحية الحفظ',
      'connecting': 'جارٍ الربط',
      'scanningStatuses': 'جارٍ فحص الحالات',
      'foundStatuses': 'تم العثور على {count} حالات',
      'chooseFolderManually': 'اختيار المجلد يدويًا',
      'detectingWhatsapp': 'جارٍ اكتشاف واتساب…',
      'connectedAutomatically': 'تم الاتصال تلقائيًا',
      'permissionRequired': 'يلزم منح الإذن',
      'permissionRevoked': 'تم إلغاء الإذن',
      'folderNotFound': 'لم يتم العثور على المجلد',
      'noStatusesFound': 'لا توجد حالات',
      'iosWhatsappTitle': 'حالات واتساب',
      'iosWhatsappRefresh': 'تحديث واتساب ويب',
      'iosWhatsappResync': 'إعادة مزامنة واتساب ويب',
      'iosWhatsappResyncHint': 'يعيد الاتصال ويحمّل كل حالات حسابك المرتبط.',
      'iosWhatsappResyncStarted':
          'جارٍ إعادة اتصال واتساب ويب. ستظهر الحالات تباعًا أثناء المزامنة.',
      'iosWhatsappSyncing': 'جارٍ مزامنة تحديثات واتساب…',
      'iosWhatsappRenderFailedTitle': 'توقّف واتساب ويب عن الاستجابة',
      'iosWhatsappRenderFailedMessage':
          'أغلق نظام iOS صفحة الويب لتحرير الذاكرة. ما زال حساب واتساب '
          'المرتبط متصلًا.',
      'iosWhatsappRenderFailedRetry': 'إعادة تحميل واتساب ويب',
      'iosWhatsappRecovered':
          'نفدت ذاكرة واتساب ويب فأُعيد تحميله. حسابك ما زال مرتبطًا.',
      'iosWhatsappHelp': 'عرض تعليمات حفظ الحالة',
      'iosWhatsappDisconnect': 'فصل واتساب',
      'iosWhatsappDisconnectQuestion': 'هل تريد فصل واتساب؟',
      'iosWhatsappDisconnectMessage':
          'سيؤدي ذلك إلى إزالة جلسة واتساب ويب المحفوظة داخل ApexLoad، ولن تُحذف ملفات الحالات المحفوظة.',
      'iosWhatsappDisconnected': 'تمت إزالة جلسة واتساب ويب من ApexLoad.',
      'iosWhatsappIntroTitle': 'اتصل بأمان مع واتساب ويب',
      'iosWhatsappIntroDescription':
          'افتح صفحة واتساب ويب الرسمية داخل ApexLoad، واربط حسابك، واختر حالة، ثم احفظها بجودتها الأصلية.',
      'iosWhatsappPrivacyTitle': 'تبقى الجلسة على هذا الجهاز',
      'iosWhatsappPrivacyDescription':
          'لا يرسل ApexLoad جلسة واتساب الخاصة بك إلى خوادمه.',
      'iosWhatsappManualTitle': 'يحفظ فقط عندما تطلب',
      'iosWhatsappManualDescription':
          'لا يوجد فحص تلقائي أو جمع جماعي للحالات.',
      'iosWhatsappResponsibleTitle': 'احفظ بمسؤولية',
      'iosWhatsappResponsibleDescription':
          'احفظ فقط المحتوى الذي تملكه أو لديك إذن للاحتفاظ به.',
      'iosWhatsappPhaseNote':
          'يبقى حسابك داخل جلسة واتساب ويب الآمنة على هذا الآيفون.',
      'iosWhatsappStart': 'ربط واتساب ويب',
      'iosWhatsappTutorialTitle': 'ربط واتساب ويب',
      'iosWhatsappTutorialSubtitle':
          'استخدم الربط برقم الهاتف للاتصال على نفس الآيفون.',
      'iosWhatsappTutorialStep1Title': 'تابع داخل المتصفح',
      'iosWhatsappTutorialStep1Description':
          'اضغط متابعة إلى واتساب ويب. لا تحتاج إلى تنزيل واتساب مرة أخرى.',
      'iosWhatsappTutorialStep2Title': 'اختر تسجيل الدخول برقم الهاتف',
      'iosWhatsappTutorialStep2Description':
          'اضغط تسجيل الدخول برقم الهاتف أسفل رمز QR.',
      'iosWhatsappTutorialStep3Title': 'أدخل رقم واتساب',
      'iosWhatsappTutorialStep3Description':
          'اختر بلدك، وأدخل رقمك، ثم اضغط التالي. أدخل رمز الربط في واتساب من الإعدادات ‹ الأجهزة المرتبطة ‹ ربط جهاز ‹ الربط باستخدام رقم الهاتف.',
      'iosWhatsappOpenWeb': 'فتح واتساب ويب',
      'iosWhatsappStatusDetected': 'تم اكتشاف الحالة',
      'iosWhatsappConnected': 'تم ربط واتساب',
      'iosWhatsappLinkAccount': 'اربط حساب واتساب',
      'iosWhatsappOpening': 'جارٍ فتح واتساب ويب…',
      'iosWhatsappWaiting': 'في انتظار واتساب',
      'iosWhatsappSaving': 'جارٍ حفظ الحالة محليًا…',
      'iosWhatsappSaveStatus': 'حفظ الحالة الحالية',
      'iosWhatsappSavePhoto': 'حفظ الصورة الحالية',
      'iosWhatsappSaveVideo': 'حفظ الفيديو الحالي',
      'iosWhatsappOpenStatus': 'افتح حالة لحفظها',
      'iosWhatsappLoadFailed': 'تعذّر تحميل واتساب ويب',
      'iosWhatsappSaveFailed': 'تعذّر حفظ هذه الحالة',
      'iosWhatsappTryOpenStatus': 'افتح حالة ثم حاول مرة أخرى.',
      'iosWhatsappSaved': 'تم حفظ الحالة',
      'iosWhatsappSavedFile': 'أصبح {file} جاهزًا في التنزيلات.',
      'iosWhatsappSavedSuccess': 'تم حفظ الحالة بنجاح',
      'iosWhatsappSavedDescription':
          'يمكنك متابعة مشاهدة الحالات أو فتح تنزيلات ApexLoad.',
      'iosWhatsappKeepBrowsing': 'متابعة التصفح',
      'iosWhatsappGuideTitle': 'افتح حالة قبل الحفظ',
      'iosWhatsappGuideSubtitle':
          'يحفظ ApexLoad الصورة أو الفيديو المعروض حاليًا في واتساب ويب.',
      'iosWhatsappGuideStep1Title': 'افتح تحديثات الحالة',
      'iosWhatsappGuideStep1Description':
          'اضغط أيقونة الحالة الدائرية في القائمة الجانبية لواتساب ويب.',
      'iosWhatsappGuideStep2Title': 'اختر حالة',
      'iosWhatsappGuideStep2Description':
          'اختر جهة اتصال، ثم افتح الصورة أو الفيديو الذي تريد حفظه.',
      'iosWhatsappGuideStep3Title': 'أبقِ الحالة معروضة ثم احفظها',
      'iosWhatsappGuideStep3Description':
          'أثناء عرض الحالة، اضغط حفظ الحالة الحالية في ApexLoad.',
      'iosWhatsappGuideTip':
          'يصبح زر الحفظ جاهزًا عندما يكتشف ApexLoad حالة مفتوحة.',
      'iosWhatsappSaveGuideTitle': 'طريقة حفظ حالة واتساب',
      'iosWhatsappSaveGuideSubtitle':
          'اتبع هذه الخطوات الأربع مرة واحدة، ثم احفظ مباشرة من ApexLoad.',
      'iosWhatsappSaveGuideStep1Title': 'افتح تحديثات الحالة',
      'iosWhatsappSaveGuideStep1Description':
          'اضغط أيقونة الحالة الدائرية في القائمة الجانبية لواتساب ويب.',
      'iosWhatsappSaveGuideStep2Title': 'اختر الحالة التي تريدها',
      'iosWhatsappSaveGuideStep2Description':
          'اختر جهة اتصال من قائمة الحالات الحديثة.',
      'iosWhatsappSaveGuideStep3Title': 'احفظ الصورة أو الفيديو المفتوح',
      'iosWhatsappSaveGuideStep3Description':
          'أبقِ الحالة معروضة، ثم اضغط زر الحفظ في ApexLoad.',
      'iosWhatsappSaveGuideStep4Title': 'اعثر عليها في التنزيلات',
      'iosWhatsappSaveGuideStep4Description':
          'بعد ظهور تأكيد الحفظ، اضغط التنزيلات لعرض الملف المحفوظ.',
      'iosWhatsappGotIt': 'فهمت',
      'activeOperationWakelockNote':
          'يرجى إبقاء ApexLoad مفتوحًا حتى تكتمل العملية. ستبقى الشاشة نشطة أثناء التنزيل أو النقل أو المعالجة.',
      'keepScreenAwakeDuringDownloads': 'إبقاء الشاشة نشطة أثناء التنزيل',
      'keepScreenAwakeDuringDownloadsSubtitle':
          'يمنع إطفاء الشاشة أثناء تنزيل أو حفظ أو تصدير الوسائط.',
      'madeBy': 'صنع بواسطة',
    },
  };

  String t(String key) =>
      _values[locale.languageCode]?[key] ?? _values['en']![key] ?? key;

  bool has(String key) =>
      _values[locale.languageCode]?.containsKey(key) == true ||
      _values['en']?.containsKey(key) == true;

  String platformName(String name) {
    return switch (name) {
      'TikTok' => t('platformTikTok'),
      'Instagram' => t('platformInstagram'),
      'Facebook' => t('platformFacebook'),
      'X/Twitter' => t('platformXTwitter'),
      'YouTube Shorts' => t('platformYouTubeShorts'),
      'Pinterest' => t('platformPinterest'),
      'Reddit' => t('platformReddit'),
      'Snapchat' => t('platformSnapchat'),
      _ => name,
    };
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
