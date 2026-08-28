// Cross-platform CSV download. On web this triggers a real browser download;
// on other platforms the stub throws (reports are a web/admin feature).
export 'csv_download_stub.dart'
    if (dart.library.html) 'csv_download_web.dart';
