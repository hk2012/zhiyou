class AppRouteNames {
  AppRouteNames._();

  static const String root = '/';
  static const String login = '/login';

  static const String home = '/home';
  static const String explore = '/explore';
  static const String spotDetail = '/spot-detail';
  static const String community = '/community';
  static const String profile = '/profile';

  static const String creationModal = '/create';
  static const String mall = '/mall';
  static const String mallCart = '/mall/cart';
  static const String mallCheckout = '/mall/checkout';
  static const String mallProductDetail = '/mall/product-detail';
  static const String settings = '/settings';

  static const String devices = '/devices';
  static const String deviceDetail = '/devices/:deviceId';
  static const String deviceAdd = '/devices/add';
  static const String deviceScenes = '/device-scenes';
  static const String deviceAlerts = '/device-alerts';
  static const String deviceCommand = '/device-commands/:commandId';

  static String deviceDetailPath(String deviceId) => '/devices/$deviceId';

  static String deviceCommandPath(String commandId) =>
      '/device-commands/$commandId';
}
