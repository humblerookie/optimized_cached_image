
import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart';

class CustomFetcherResponse extends  FileFetcherResponse {
  final StreamedResponse _response;

  CustomFetcherResponse(this._response);

  @override
  bool hasHeader(String name) {
    return _response.headers.containsKey(name);
  }

  @override
  String header(String name) {
    return _response.headers[name];
  }

  @override
  Uint8List get bodyBytes => Uint8List(1);

  @override
  get statusCode => _response.statusCode;

}