
library den_api.src.release_type;

class ReleaseType {
  final String _name;

  const ReleaseType._(this._name);

  static const ReleaseType major = const ReleaseType._('major');
  static const ReleaseType minor = const ReleaseType._('minor');
  static const ReleaseType patch = const ReleaseType._('patch');
  static const ReleaseType breaking = const ReleaseType._('breaking');
  static const ReleaseType release = const ReleaseType._('release');
  static const ReleaseType build = const ReleaseType._('build');

  static List<ReleaseType> values = [major, minor, patch, breaking, release, build];

  String toString() => 'ReleaseType.$_name';
}
