String detectPlatformName(String url) {
  final value = url.trim().toLowerCase();
  final uri = Uri.tryParse(value.contains('://') ? value : 'https://$value');
  final host = uri?.host.toLowerCase() ?? '';
  if (_hostMatches(host, const ['tiktok.com'])) {
    return 'TikTok';
  }
  if (_hostMatches(host, const ['instagram.com', 'instagr.am'])) {
    return 'Instagram';
  }
  if (_hostMatches(host, const ['facebook.com', 'fb.watch'])) {
    return 'Facebook';
  }
  if (_hostMatches(host, const ['twitter.com', 'x.com'])) {
    return 'X/Twitter';
  }
  if (_hostMatches(host, const ['pinterest.com', 'pin.it'])) {
    return 'Pinterest';
  }
  if (_hostMatches(host, const ['reddit.com'])) {
    return 'Reddit';
  }
  if (_hostMatches(host, const ['snapchat.com', 'snap.com'])) {
    return 'Snapchat';
  }
  return 'Auto detect';
}

bool _hostMatches(String host, List<String> domains) {
  return domains.any((domain) => host == domain || host.endsWith('.$domain'));
}
