import 'package:flutter/material.dart';
import 'package:optimized_cached_image/widgets.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
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
                height: 50,
              ),
              Text("This is via the widget: OptimizedCacheImage"),
              // the following Image will have width its dimensions on disk = width of device
              // You don't need to specify width/height explicitly the widget automatically
              // detects it based on its parent's constraints.
              OptimizedCacheImage(
                imageUrl:
                    "https://grist.files.wordpress.com/2019/07/ocean1.jpg",
              ),
              SizedBox(
                height: 50,
              ),
              Text("This is via the provider: OptimizedCacheImageProvider"),
              //Unlike OptimizedCacheImage, OptimizedCacheImageProvider needs cacheWidth or/and cacheHeight to resize images
              Image(
                image: OptimizedCacheImageProvider(
                    "https://p.bigstockphoto.com/rwyznvNQ76U2liDFDH6g_bigstock-Yachts-In-City-Bay-At-Hot-Summ-283784740.jpg",
                    cacheHeight: 150,
                    cacheWidth: 200),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
