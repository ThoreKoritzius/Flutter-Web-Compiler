class RecordEntry {
  const RecordEntry(this.title, {required this.minutes});
  final String title;
  final int minutes;
  String get label => '$title · $minutes min';
}
