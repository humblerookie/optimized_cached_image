# Optimized Cached Image

[![pub package](https://img.shields.io/pub/v/optimized_cached_image.svg)](https://pub.dartlang.org/packages/optimized_cached_image)

A flutter library for loading images from network, resizing and caching them for memory sensitivity. 
This resizes and stores the images in cache based on parent container constraints and hence
loads images of lower size into memory. This is heavily inspired by [cached_network_image](https://pub.dev/packages/cached_network_image) library.

This library exposes two classes for loading images
- `OptimizedCacheImage` which is a 1:1 mapping of `CachedNetworkImage`.
- `OptimizedCacheImageProvider` which is a mapping of `CachedNetworkImageProvider`.

A flutter library to show images from the internet and keep them in the cache directory.

## How to use
The CachedNetworkImage can be used directly or through the ImageProvider.

```dart
OptimizedCacheImage(
        imageUrl: "http://via.placeholder.com/350x150",
        placeholder: (context, url) => CircularProgressIndicator(),
        errorWidget: (context, url, error) => Icon(Icons.error),
     ),
 ```
and that's it, you don't need to specify any explicit sizes images will be loaded based on available space.

````dart
Image(image: OptimizedCacheImageProvider(url, cacheWidth:100))
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
This library appends query params to the url keys for which are in `ImageCacheConfig` and interprets them while resizing.
The optimized cached images stores and retrieves files using the [flutter_cache_manager](https://pub.dartlang.org/packages/flutter_cache_manager).
The optimized cached images resizes files using the [flutter_image_compress](https://pub.dartlang.org/packages/flutter_image_compress). 


## Misc Usage
This library modifies/appends url query params to demarcate different sizes. In case your 
image urls have a preexisting query parameters that clash with the ones this library 
internally uses to identify image sizes namely `oci_width` and `oci_height`, all you need 
to do is instantiate the `ImageCacheManager` with a `ImageCacheConfig` which accepts custom 
query keys which the library can use.

**Note:** Ensure `ImageCacheManager` is instantiated with this config before any load happens.

To instantiate:
```
ImageCacheManager(ImageCacheConfig(cacheConfig:ImageCacheConfig(widthKey:"custom-width", heightKey:"custom-height"))
```
For detailed usage about all the params check out the [parent project] (https://github.com/Baseflow/flutter_cached_network_image/blob/develop/example/lib/main.dart) from which this was ported.

## TODO
This library is a WIP. A few things that are going to be worked on are.
- Prevent same url from being downloaded multiple times for different image sizes
- Cleanup code.

  
 
