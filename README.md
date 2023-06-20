# Optimized Cached Image

[![pub package](https://img.shields.io/pub/v/optimized_cached_image.svg)](https://pub.dartlang.org/packages/optimized_cached_image)

### Important Update ###
This library is no longer being maintained. When I started this library, it was meant to add memory performant extensions which could not be directly added into the parent library. Since then a lot has changed, [the parent library](https://github.com/Baseflow/flutter_cached_network_image) has incorporated similar changes, perhaps with the exception of a trivial `LayoutBuilder` that auto detects image sizes. I feel like this is a good time to deprecate this library in favour of the [parent](https://github.com/Baseflow/flutter_cached_network_image)). 

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

## Handling Gifs
OCI uses [Flutter Image Compress](https://pub.dev/packages/flutter_image_compress) as the compression library, while being memory efficient this library doesn't provide out of box support for gifs, however it does allow compressing to webp. Hence all gifs are compressed to webp format beginning `2.0.2-alpha`.

## How it works
The optimized cached network images stores and retrieves files using the [flutter_cache_manager](https://pub.dev/packages/flutter_cache_manager).

## FAQ
### My app crashes when the image loading failed. (I know, this is not really a question.)
Does it really crash though? The debugger might pause, as the Dart VM doesn't recognize it as a caught exception; the console might print errors; even your crash reporting tool might report it (I know, that really sucks). However, does it really crash? Probably everything is just running fine. If you really get an app crashes you are fine to report an issue, but do that with a small example so we can reproduce that crash.
