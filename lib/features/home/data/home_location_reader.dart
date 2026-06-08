export 'home_location_reader_stub.dart'
    if (dart.library.html) 'home_location_reader_web.dart'
    if (dart.library.io) 'home_location_reader_native.dart';
