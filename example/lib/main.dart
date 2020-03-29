import 'package:flutter/material.dart';
import 'package:optimized_cached_image/image_cache_manager.dart';
import 'package:optimized_cached_image/widgets.dart';

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

    ///This initialization is not really needed, just for the purpose of showcase.
    /// `useHttpStream` reduces memory footprint but is experimental as of now
    /// other params are `widthKey` and `heightKey`
    ImageCacheManager.init(ImageCacheConfig(useHttpStream: true));
  }

  @override
  Widget build(BuildContext context) {
    final items = 20;

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
                    "https://p.bigstockphoto.com/rwyznvNQ76U2liDFDH6g_bigstock-Yachts-In-City-Bay-At-Hot-Summ-283784740.jpg",
                    cacheHeight: 50,
                    cacheWidth: 20),
              ),
              Container(
                  height: 300,
                  child: GridView.count(
                      crossAxisCount: 2,
                      children: List.generate(items, (index) {
                        final url = "$urlPrefix${(index + 60)}$urlSuffix";
                        return OptimizedCacheImage(
                          imageUrl: url,
                        );
                      }))),
            ],
          ),
        ),
      ),
    );
  }
}
