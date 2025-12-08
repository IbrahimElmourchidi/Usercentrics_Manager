class UserscentericsNotInitializedException implements Exception {
  final String methodName;

  UserscentericsNotInitializedException({required this.methodName});

  @override
  String toString() =>
      'UsercentricsManager: "$methodName" was called before initialize(). '
      'Call UsercentricsManager.instance.initialize() first.';
}
