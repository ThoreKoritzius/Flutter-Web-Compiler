/// Outside browsers, platform services are unavailable.
Future<bool> browserClipboardWrite(String text) async => false;
Future<String?> browserClipboardRead() async => null;
bool browserVibrate(int milliseconds) => false;
void browserSetTitle(String title) {}
void browserHistoryBack() {}
Future<List<int>?> browserFetchBytes(String url) async => null;
