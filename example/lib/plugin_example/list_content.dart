import 'package:flutter/material.dart';
import 'package:optimized_cached_image/optimized_cached_image.dart';

/// Demonstrates a [ListView] containing [OptimizedCacheImage]
class ListContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (BuildContext context, int index) => Card(
        child: Column(
          children: <Widget>[
            OptimizedCacheImage(
              imageUrl: 'https://loremflickr.com/320/240/music?lock=$index',
              placeholder: (BuildContext context, String url) => Container(
                width: 320,
                height: 240,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ),
      itemCount: 10,
    );
  }
}
