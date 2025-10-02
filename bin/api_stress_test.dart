import 'dart:async';
import 'dart:convert';
import 'dart:io';

// --- NEW HELPER FUNCTION ---
// This function maps common HTTP status codes to their text descriptions.
String _getStatusText(int code) {
  switch (code) {
    case 200:
      return 'OK';
    case 400:
      return 'Bad Request';
    case 401:
      return 'Unauthorized';
    case 403:
      return 'Forbidden';
    case 404:
      return 'Not Found';
    case 429:
      return 'Too Many Requests';
    case 500:
      return 'Internal Server Error';
    case 503:
      return 'Service Unavailable';
    default:
      return 'Unknown Status';
  }
}

// --- Your API Function (slightly modified to accept a shared HttpClient) ---
// By passing the client in, we ensure we reuse the same one for all requests.
Future<int> listChannels(HttpClient client) async {
  // --- Configuration for your API endpoint ---
  const String scheme = 'http';
  const String host = '10.44.0.70'; // Assuming this is the Asterisk server
  const int port = 8088;
  const String apiKey =
      'asterisk:asterisk'; // Replace with your actual ARI user/pass

  var uri = Uri(
      scheme: scheme,
      host: host,
      port: port,
      path: "ari/channels",
      queryParameters: {'api_key': apiKey});

  try {
    HttpClientRequest request = await client.getUrl(uri);
    HttpClientResponse response = await request.close();

    // We must drain the response body to free up the connection
    await response.drain();

    return response.statusCode;
  } catch (e) {
    // Return a custom code for network-level failures
    // print('Network Error: $e');
    return -1; // Indicates a client-side error (e.g., connection failed)
  }
}

Future<void> main() async {
  // --- Test Configuration ---
  const int totalRequests = 10000; // Total number of requests to send
  const int concurrencyLimit =
      100; // How many requests to run in parallel at once

  print('--- API Stress Test ---');
  print('Total Requests: $totalRequests');
  print('Concurrency:    $concurrencyLimit');
  print('-----------------------');

  // Create a single, reusable HttpClient
  final client = HttpClient();
  final stopwatch = Stopwatch()..start();

  // A map to store the count of each status code we receive
  final statusCodeCounts = <int, int>{};
  int completedRequests = 0;

  // This function will be our "worker" that executes one request
  // and updates the counters.
  Future<void> runRequest() async {
    final statusCode = await listChannels(client);
    statusCodeCounts.update(statusCode, (value) => value + 1,
        ifAbsent: () => 1);
    completedRequests++;
    if (completedRequests % 500 == 0) {
      print(
          'Progress: $completedRequests / $totalRequests requests completed...');
    }
  }

  // A list to keep track of the currently "in-flight" requests
  final List<Future<void>> activeRequests = [];

  // Loop to start all the requests, respecting the concurrency limit
  for (int i = 0; i < totalRequests; i++) {
    // Add a new request to our list of active requests
    activeRequests.add(runRequest());

    // If we've hit our concurrency limit, wait for at least one request to finish
    // before starting the next one.
    if (activeRequests.length >= concurrencyLimit) {
      await Future.any(activeRequests);
      activeRequests.removeWhere((f) => f.isComplete);
    }
  }

  // Wait for all remaining requests to complete
  await Future.wait(activeRequests);

  stopwatch.stop();

  // --- Final Report ---
  final durationInSeconds = stopwatch.elapsed.inMilliseconds / 1000;
  final requestsPerSecond = totalRequests / durationInSeconds;

  print('\n--- Test Complete ---');
  print('Total Time: ${durationInSeconds.toStringAsFixed(2)} seconds');
  print('Requests Per Second (RPS): ${requestsPerSecond.toStringAsFixed(2)}');
  print('\nStatus Code Distribution:');

  statusCodeCounts.forEach((code, count) {
    var codeMeaning =
        code == -1 ? 'Network/Client Error' : _getStatusText(code);
    print('  - Code $code ($codeMeaning): $count requests');
  });
  print('-----------------------');

  // Close the HttpClient to release all resources
  client.close(force: true);
}

// Helper extension to check if a Future is complete
extension FutureIsComplete on Future {
  bool get isComplete {
    final completer = Completer();
    then((_) => completer.complete(), onError: (_) => completer.complete());
    return completer.isCompleted;
  }
}
