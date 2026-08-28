/// Non-web fallback — CSV report download is a web/admin feature.
void downloadCsv(String filename, String csv) {
  throw UnsupportedError('CSV download is only available on the web.');
}
