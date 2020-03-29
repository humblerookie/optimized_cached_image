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
and that's it, you don't need to specify any explicit sizes images will be loaded based on available space in the container. However In case you feel auto size doesn't work for you feel free to specify `width` and `height` params.


If you're using the provider you'd have to specify `cacheWidth` or `cacheHeight` in order for resize to work. You can wrap it inside [LayoutBuilder](https://api.flutter.dev/flutter/widgets/LayoutBuilder-class.html) or specify an explicity size
````dart
LayoutBuilder(builder: (_, constraints) {
  Image(image: OptimizedCacheImageProvider(url, cacheWidth:constraints.maxWidth))
})
````
or
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

## Advanced Usage
This library modifies/appends url query params to demarcate different sizes. In case your 
image urls have a preexisting query parameters that clash with the ones this library 
internally uses to identify image sizes namely `oci_width` and `oci_height`, all you need 
to do is instantiate the `ImageCacheManager` with a `ImageCacheConfig` which accepts custom 
query keys which the library can use along with a few other params.
- `useHttpStream` : Uses chunked/streamed downloading that reduces memory footprint.
- `maxAgeCacheObject` : Max age of the cache objects default is 30 days
- `maxNrOfCacheObjects`:  Max number of the cache objects default is 200
     
**Note:** Ensure `ImageCacheManager` is instantiated with this config before any load happens.

To instantiate:
```
ImageCacheManager.init(ImageCacheConfig(widthKey:"custom-width", heightKey:"custom-height", useHttpStream: true))
```


## How it works
This library appends query params to the url keys for which are in `ImageCacheConfig` and interprets them while resizing.
The optimized cached images stores and retrieves files using the [flutter_cache_manager](https://pub.dartlang.org/packages/flutter_cache_manager).
The optimized cached images resizes files using the [flutter_image_compress](https://pub.dartlang.org/packages/flutter_image_compress). 


For detailed usage about all the params check out the [parent project](https://github.com/Baseflow/flutter_cached_network_image/blob/develop/example/lib/main.dart) from which this was ported.

## TODO
This library is a WIP. A few things that are going to be worked on are.
- Prevent same url from being downloaded multiple times for different image sizes
- Cleanup code.

  
 
