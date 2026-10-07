import 'package:url_launcher/url_launcher.dart';

/// Opens [rawUrl] in the customer's browser, or in the partner's app when one is
/// installed. Returns false when the URL is unusable or the platform refused to
/// open it, so the caller can show a message rather than appear to do nothing.
///
/// Deliberately does NOT call `canLaunchUrl` first. Under Android 11+ package
/// visibility that returns false for an https URL unless the app declares a
/// matching `<queries>` intent, so gating on it makes the button permanently
/// dead on modern Android even though `launchUrl` itself works. On Flutter web,
/// any `await` between the tap and `launchUrl` also breaks the user-gesture
/// chain and the popup blocker eats the new tab. Skipping the check avoids both.
Future<bool> openExternalLink(String? rawUrl) async {
  final trimmed = (rawUrl ?? '').trim();
  if (trimmed.isEmpty) return false;

  // Re-check the scheme client-side: the server normalises on write, but a
  // record created before that validation existed could still reach here, and
  // `javascript:`/`data:` URLs are an injection vector on the web build.
  final uri = Uri.tryParse(trimmed);
  if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
    return false;
  }

  try {
    return await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
  } catch (_) {
    return false;
  }
}
