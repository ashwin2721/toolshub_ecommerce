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
