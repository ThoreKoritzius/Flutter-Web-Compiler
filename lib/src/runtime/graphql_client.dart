import 'dart:convert';

/// An HTTP boundary that can be implemented by browsers or test transports.
abstract interface class GraphqlTransport {
  Future<GraphqlHttpResponse> post(String body);
}

class GraphqlHttpResponse {
  const GraphqlHttpResponse(this.status, this.body);
  final int status;
  final String body;
}

/// Deliberately excludes server messages, payloads and credentials.
class GraphqlRequestException implements Exception {
  const GraphqlRequestException(this.kind);
  final String kind;
  @override
  String toString() => 'GraphqlRequestException: $kind';
}

/// Strict JSON GraphQL queries. Partial data plus errors is rejected.
/// Authentication and session refresh belong to the supplied transport.
class GraphqlClient {
  const GraphqlClient(this.transport);
  final GraphqlTransport transport;

  Future<Map<String, dynamic>> query(
    String document, {
    Map<String, dynamic> variables = const {},
    String? operationName,
  }) async {
    if (document.trim().isEmpty) throw ArgumentError('Empty GraphQL document.');
    final response = await transport.post(
      jsonEncode({
        'query': document,
        'variables': variables,
        if (operationName != null) 'operationName': operationName,
      }),
    );
    if (response.status < 200 || response.status >= 300) {
      throw const GraphqlRequestException('http');
    }
    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const GraphqlRequestException('invalid-json');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const GraphqlRequestException('invalid-envelope');
    }
    final errors = decoded['errors'];
    if (errors != null) {
      if (errors is! List) {
        throw const GraphqlRequestException('invalid-envelope');
      }
      if (errors.isNotEmpty) {
        throw const GraphqlRequestException('graphql');
      }
    }
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw const GraphqlRequestException('missing-data');
    }
    return data;
  }
}
