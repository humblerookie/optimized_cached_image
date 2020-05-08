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
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              SizedBox(
                height: 20,
              ),
              Text("This is via the widget: OptimizedCacheImage"),
              // the following Image will have width its dimensions on disk = width of device
              // You don't need to specify width/height explicitly the widget automatically
              // detects it based on its parent's constraints.
              OptimizedCacheImage(
                imageUrl: "https://i.picsum.photos/id/110/1000/300.jpg",
              ),
              SizedBox(
                height: 20,
              ),
              Text("This is via the provider: OptimizedCacheImageProvider"),
              //Unlike OptimizedCacheImage, OptimizedCacheImageProvider needs cacheWidth or/and cacheHeight to resize images
              Image(
                image: OptimizedCacheImageProvider(
                    "https://upload.wikimedia.org/wikipedia/commons/4/47/PNG_transparency_demonstration_1.png",
                    cacheHeight: 50,
                    cacheWidth: 20),
              ),
              //If you do not wish to use cache resizing then just unset `useScaleCacheManager`flag
              Image(
                image: OptimizedCacheImageProvider(
                    "https://cdn.pixabay.com/photo/2015/03/26/09/47/sky-690293__340.jpg",
                    useScaleCacheManager: false,
                    cacheHeight: 50,
                    cacheWidth: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
