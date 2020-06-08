import 'dart:io';

import 'package:flutter/material.dart';
import 'package:optimized_cached_image/image_cache_manager.dart';
import 'package:optimized_cached_image/widgets.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final urlPrefix = "https://i.picsum.photos/id/";
  final urlSuffix = "/1000/1000.jpg";

  @override
  void initState() {
    super.initState();

    /// Just a demo of the param(s) in ImageCacheManager,
    /// you don't need to do this unless you wish to customize stuff
    ImageCacheManager.init(ImageCacheConfig(storagePath: path()));
  }

  Future<Directory> path() async => (await getExternalCacheDirectories())[0];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Optimized Cached Image Example'),
        ),
        body: Container(
          child: ListView.builder(
              itemBuilder: (BuildContext context, int index) {
                return OptimizedCacheImage(
                  imageUrl: "https://i.picsum.photos/id/${(index + 1)}/200/300.jpg",
                );
              },
              itemCount: 60,
            ),
        ),
      ),
    );
  }
}
