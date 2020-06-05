import 'dart:io';

import 'package:flutter/material.dart';
import 'package:optimized_cached_image/cache_manager/resize_cache_manager.dart';
import 'package:optimized_cached_image/image_cache_manager.dart';
import 'package:optimized_cached_image/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tuple/tuple.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CachedNetworkImage Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyHomePage> {
  final urlPrefix = "https://i.picsum.photos/id/";
  final urlSuffix = "/1000/1000.jpg";
  String currentPage = 'Optimized Cached Image Example';

  void _select(Tuple2 choice) {
    setState(() {
      currentPage = choice.item1;
    });
  }

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
          appBar: AppBar(title: Text(currentPage), actions: <Widget>[
            IconButton(
              icon: Icon(_menuEntries[0].item2),
              onPressed: () {
                _select(_menuEntries[0]);
              },
            ),
          ]),
          body: _page(currentPage)),
    );
  }

  Widget _page(String page) {
    switch (page) {
      case 'Grid':
        {
          return _gridPage();
        }
    }

    return _homePage();
  }

  Widget _homePage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Center(
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
              OptimizedCacheImage(
                imageUrl: "https://i.picsum.photos/id/155/2000/1000.jpg",
                cacheManager: ResizeImageCacheManager(),
                fit: BoxFit.cover,
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
                    cacheManager: ImageCacheManager(),
                    cacheHeight: 50,
                    cacheWidth: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gridPage() {
    final _resizeCacheManager = ResizeImageCacheManager();
    final Orientation orientation = MediaQuery.of(context).orientation;
    final axisCount = (orientation == Orientation.portrait) ? 2 : 3;
    return GridView.builder(
      itemCount: 1000,
      padding: const EdgeInsets.all(4.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: axisCount,
        mainAxisSpacing: 4.0,
        crossAxisSpacing: 4.0,
      ),
      itemBuilder: (BuildContext context, int index) => OptimizedCacheImage(
        cacheManager: _resizeCacheManager,
        imageUrl: 'https://loremflickr.com/1024/640/music?lock=$index',
        placeholder: _loader,
        errorWidget: _error,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _loader(BuildContext context, String url) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _error(BuildContext context, String url, dynamic error) {
    print(error);
    return const Center(child: Icon(Icons.error));
  }
}

const List<Tuple2> _menuEntries = const <Tuple2>[
  const Tuple2('Grid', Icons.grid_on),
  //const Tuple2('List', Icons.list),
];
