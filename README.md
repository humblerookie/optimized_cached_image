# Optimized Cached Image

[![pub package](https://img.shields.io/pub/v/optimized_cached_image.svg)](https://pub.dartlang.org/packages/optimized_cached_image)

A flutter library for loading images from network, resizing and caching them for memory sensitivity.
This resizes and stores the images in cache based on parent container constraints and hence
loads images of lower size into memory. This is heavily inspired by [cached_network_image](https://pub.dev/packages/cached_network_image) library.

This library exposes two classes for loading images
- `OptimizedCacheImage` which is a 1:1 mapping of `CachedNetworkImage`.
- `OptimizedCacheImageProvider` which is a mapping of `CachedNetworkImageProvider`.

## How to use
The OptimizedCacheImage can be used directly or through the ImageProvider.
Both the OptimizedCacheImage as OptimizedCacheImageProvider have minimal support for web. It currently doesn't include caching.

With a placeholder:
```dart
OptimizedCacheImage(
        imageUrl: "http://via.placeholder.com/350x150",
        placeholder: (context, url) => CircularProgressIndicator(),
        errorWidget: (context, url, error) => Icon(Icons.error),
     ),
 ```
 
 Or with a progress indicator:
 ```dart
OptimizedCacheImage(
        imageUrl: "http://via.placeholder.com/350x150",
        progressIndicatorBuilder: (context, url, downloadProgress) =>
                CircularProgressIndicator(value: downloadProgress.progress),
        errorWidget: (context, url, error) => Icon(Icons.error),
     ),
 ```


````dart
Image(image: OptimizedCacheImageProvider(url))
````

When you want to have both the placeholder functionality and want to get the imageprovider to use in another widget you can provide an imageBuilder:
```dart
OptimizedCacheImage(
  imageUrl: "http://via.placeholder.com/200x150",
  imageBuilder: (context, imageProvider) => Container(
    decoration: BoxDecoration(
      image: DecorationImage(
          image: imageProvider,
          fit: BoxFit.cover,
          colorFilter:
              ColorFilter.mode(Colors.red, BlendMode.colorBurn)),
    ),
  ),
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
),
```

## How it works
The optimized cached network images stores and retrieves files using the [optimized_cached_image](https://pub.dev/packages/optimized_cached_image).

## FAQ
### My app crashes when the image loading failed. (I know, this is not really a question.)
Does it really crash though? The debugger might pause, as the Dart VM doesn't recognize it as a caught exception; the console might print errors; even your crash reporting tool might report it (I know, that really sucks). However, does it really crash? Probably everything is just running fine. If you really get an app crashes you are fine to report an issue, but do that with a small example so we can reproduce that crash.
