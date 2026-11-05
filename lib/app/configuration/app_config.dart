enum AppEnvironment {
  development,
  staging,
  production,
}

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.appName,
  });

  final AppEnvironment environment;
  final String appName;

  static const development = AppConfig(
    environment: AppEnvironment.development,
    appName: 'Sahaay Dev',
  );

  static const staging = AppConfig(
    environment: AppEnvironment.staging,
    appName: 'Sahaay Staging',
  );

  static const production = AppConfig(
    environment: AppEnvironment.production,
    appName: 'Sahaay',
  );
}
