class RecordEntry {
  const RecordEntry(this.title, {required this.minutes});
  final String title;
  final int minutes;
  String formatDuration({String unit = 'min'}) => '$minutes $unit';
  String get label => '$title · ${formatDuration()}';
}
