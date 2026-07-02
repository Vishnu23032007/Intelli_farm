class EnvConfig {
  static const String flaskBackendUrl = String.fromEnvironment(
    'FLASK_BACKEND_URL',
    defaultValue: 'http://172.16.142.21:5000',
  );

  static const String weatherApiKey1 = String.fromEnvironment(
    'WEATHER_API_KEY_1',
    defaultValue: 'bd58ea1265cb41f1b5e95015251707',
  );

  static const String weatherApiKey2 = String.fromEnvironment(
    'WEATHER_API_KEY_2',
    defaultValue: 'c47ca008bbbc46bdb4c33918250905',
  );

  static const String freeImageApiKey = String.fromEnvironment(
    'FREEIMAGE_API_KEY',
    defaultValue: '6d207e02198a847aa98d0a2a901485a5',
  );

  static const String openWeatherApiKey = String.fromEnvironment(
    'OPENWEATHER_API_KEY',
    defaultValue: 'a5a2ef9a34b7c16b0460dc9173e1af32',
  );
}
