{{flutter_js}}
{{flutter_build_config}}

const flutterConfig = {
  canvasKitBaseUrl: "canvaskit/",
  fontFallbackBaseUrl: "flutter-font-fallback/",
};

const ensureFlutterHost = () => {
  let host = document.getElementById('flutter-host');
  if (!host) {
    host = document.createElement('div');
    host.id = 'flutter-host';
    document.body.appendChild(host);
  }
  return host;
};

for (const build of _flutter.buildConfig.builds) {
  if (build.mainJsPath) {
    const separator = build.mainJsPath.includes('?') ? '&' : '?';
    build.mainJsPath = `${build.mainJsPath}${separator}v=${Date.now()}`;
  }
}
_flutter.loader.load({
  config: flutterConfig,
  onEntrypointLoaded: async (engineInitializer) => {
    const appRunner = await engineInitializer.initializeEngine({
      ...flutterConfig,
      hostElement: ensureFlutterHost(),
    });
    await appRunner.runApp();
  },
});
