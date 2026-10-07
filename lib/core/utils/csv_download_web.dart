// dart:html is deprecated in favour of package:web + dart:js_interop, but
// migrating means adding package:web as a direct dependency in an already
// constraint-tight tree (it is transitive at 0.5.1 today, and the Blob /
// BlobPropertyBag typing differs between 0.5.x and 1.x). dart:html still
// works on Flutter 3.44, so this is a deadline to plan for, not a bug.
// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;

/// Triggers a browser download of [csv] as [filename] (web only).
void downloadCsv(String filename, String csv) {
  final bytes = utf8.encode(csv);
  final blob = html.Blob([bytes], 'text/csv');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none'
    ..click();
  html.Url.revokeObjectUrl(url);
}
