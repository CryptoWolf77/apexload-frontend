String detectPlatformName(String url) {
  final value = url.toLowerCase();
  if (value.contains('tiktok')) {
    return 'TikTok';
  }
  if (value.contains('instagram') || value.contains('instagr.am')) {
    return 'Instagram';
  }
  if (value.contains('facebook') || value.contains('fb.watch')) {
    return 'Facebook';
  }
  if (value.contains('twitter') || value.contains('x.com')) {
    return 'X/Twitter';
  }
  if (value.contains('youtube') || value.contains('youtu.be')) {
    return 'YouTube Shorts';
  }
  if (value.contains('pinterest')) {
    return 'Pinterest';
  }
  if (value.contains('reddit')) {
    return 'Reddit';
  }
  if (value.contains('snapchat.com') || value.contains('snap.com')) {
    return 'Snapchat';
  }
  return 'Auto detect';
}
