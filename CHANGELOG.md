## 3.0.1

* Avoid unnecessary null checks

## 3.0.0

* Null safety and interim gif support.

## 2.0.2-alpha

* Limited gif support. Gifs are compressed into webp and rendered as of now.

## 2.0.1

* Update to null safety package dependencies. OCI still needs to migrate code to respect null
  safety. Additionally fix issue with hero widgets

## 2.0.0

* Update flutter cache manager dependency and other pub dependencies

## 2.0.0-dev.2

* Fix issues with file package conflicting with dart io.

## 2.0.0-dev.1

* Update with flutter cache manager dependency and `CachedNetworkImage`. Introduces breaking api
  changes.

## 1.0.0

* Release to Pub

## 1.0.0-rc1

* Removed included octo_image library.

## 1.0.0-beta

* Prevent unnecessary downloads from happening by caching the image from the original url and
  resizing it for different sizes.

## 0.1.15

* Syncing changes with Cached Network Image

## 0.1.14

* Fix open socket issue in compression library and allow debug mode.

## 0.1.13

* Fixed an issue around compression error handling

## 0.1.12

* Fix issue with stream closure, causing some stream to remain open.

## 0.1.11

* Revert to original file when compression fails.

## 0.1.10

* Migrate to latest apis in cache manager dependency. Now the stream fetching is done by default
  instead of via flag.

## 0.1.9

* Fix transparency/image format issues.

## 0.1.8

* Fix dependency version breaking change in flutter cache library.

## 0.1.7

* Add style fixes

## 0.1.6

* Add experimental support for streamed downloading via `useHttpStream` flag which further reduces
  the memory footprint.

## 0.1.5

* Minor lint issues and formatting patched.

## 0.1.4

* Fixed issue faced while specifying custom width and height.

## 0.1.3

* Readme updated.

## 0.1.2

* Minor lint issues and formatting patched.

## 0.1.1

* Updated examples.

## 0.1.0

* Minimalist/Core functionality of the library and health fixes.

## 0.0.1

* Minimalist/Core functionality of the library.
