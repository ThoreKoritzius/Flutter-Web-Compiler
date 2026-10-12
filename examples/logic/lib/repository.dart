import 'dart:convert';

abstract interface class SummaryTransport {
  Future<String> read();
}

class Summary {
  const Summary(this.activities);
  final List<Activity> activities;
  double get totalMinutes =>
      activities.fold(0, (sum, item) => sum + item.minutes);

  factory Summary.fromJson(Map<String, dynamic> json) => Summary(
    (json['activities'] as List<dynamic>)
        .map((item) => Activity.fromJson(item as Map<String, dynamic>))
        .toList(growable: false),
  );
}

class Activity {
  const Activity(this.name, this.minutes);
  final String name;
  final double minutes;

  factory Activity.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String;
    final minutes = (json['minutes'] as num).toDouble();
    if (!minutes.isFinite || minutes < 0)
      throw FormatException('Invalid duration');
    return Activity(name, minutes);
  }
}

/// Used unchanged by VM tests and the official JavaScript compilation.
class SummaryRepository {
  const SummaryRepository(this.transport);
  final SummaryTransport transport;

  Future<Summary> fetch() async {
    final body = await transport.read();
    final response = jsonDecode(body) as Map<String, dynamic>;
    if (response['errors'] != null) throw FormatException('Request failed');
    return Summary.fromJson(response['data'] as Map<String, dynamic>);
  }
}
