import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

const API_SERVER = 'https://api.openrouteservice.org';
const PROJECT_KEY = '5b3ce3597851110001cf6248536ac8c6ad974ca4819e3bf315dc61c6';

class OSMAPIService {
  static OSMAPIService _instance;
  final HttpClient _client = new HttpClient();
  Uri _apiUrl;
  String _projectKey;

  factory OSMAPIService() {
    if (_instance == null) {
      _instance = new OSMAPIService._internal();
    }

    return _instance;
  }
  static OSMAPIService getInstance() => new OSMAPIService();
  OSMAPIService._internal() {
     _apiUrl = Uri.parse(API_SERVER);
     _projectKey = PROJECT_KEY;
  }

  void _setRequestHeaders(HttpHeaders headers) {
    headers.contentType = new ContentType('application', 'json', charset: 'utf-8');
    headers.add(HttpHeaders.userAgentHeader, 'OSM mobile app');
  }

  Future request(String method, String path, {params, body}) async {
    Uri url = _apiUrl.replace(
      path: path,
      queryParameters: {
        'api_key': _projectKey
      }..addAll(params),
    );
    HttpClientRequest req = await _client.openUrl(method, url);

    print('Making request: ${req.uri.toString()}');
    _setRequestHeaders(req.headers);
    if (body != null) {
      JsonEncoder enc = new JsonEncoder();
      String json = enc.convert(body);

      print(json);
      req.write(json);
    }
    await req.flush();
    HttpClientResponse res = await req.close();
    String resBody = await res.transform(new Utf8Decoder()).join();
    dynamic jsonResponse = new JsonCodec().decode(resBody);
    
    _client.close();

    if (jsonResponse is Map && jsonResponse.containsKey('error')) {
      return new Future.error(new Exception(jsonResponse['error']));
    }

    return new Future.value(jsonResponse);
  }
}