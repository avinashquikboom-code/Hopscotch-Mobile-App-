import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Test Dart HttpClient fetching image from https://api.fciseller.com', () async {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('https://api.fciseller.com/api/uploads/images/1785665039550-85851986-22328.jpg'));
    final response = await request.close();
    
    print('HTTP Response Status Code: ${response.statusCode}');
    print('Content Type: ${response.headers.contentType}');
    print('Content Length: ${response.contentLength}');

    expect(response.statusCode, 200);
    client.close();
  });
}
