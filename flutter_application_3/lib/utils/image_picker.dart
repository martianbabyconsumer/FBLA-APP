// Cross-platform image picker facade. Uses conditional imports in the project to pick an image on web.
// This file simply re-exports the platform implementations.
export 'image_picker_stub.dart' if (dart.library.html) 'image_picker_web.dart';
