class RedisConnectionConfig {
  final String host;
  final int port;
  final String? password;

  const RedisConnectionConfig({
    required this.host,
    required this.port,
    this.password,
  });
}
