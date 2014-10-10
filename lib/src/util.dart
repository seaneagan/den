
String indent(String str, int indent) {
  return str.splitMapJoin('\n', onNonMatch: (String line) => ' ' * indent + line);
}
