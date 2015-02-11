
library den.src.yaml_to_ansi;

import 'package:yaml/yaml.dart';

abstract class YamlHighlighterTheme {
  String formatKey(String key);
  String formatScalar(String scalar);
}

class YamlHighlighter {
  final String yaml;
  final YamlNode node;
  final YamlHighlighterTheme theme;
  final buffer = new StringBuffer();
  int offset = 0;


  YamlHighlighter(this.yaml, this.node, this.theme);

  String toString() {
    _consumeNode(node);
    return buffer.toString();
  }

  void _consumeNode(YamlNode node) {
    if (node is YamlMap) {
      _consumeMap(node);
    } else if (node is YamlList) {
      _consumeList(node);
    } else {
      _consumeScalar(node);
    }
  }

  void _consumeMap(YamlMap yamlMap) {
    _step(yamlMap.span.start);
    var orderedKeys = yamlMap.nodes.keys.toList()..sort((a, b) => a.span.compareTo(b.span));
    orderedKeys.forEach((YamlNode key) {
      var value = yamlMap.nodes[key];
      _step(key.span.start);
      _step(key.span.end, theme.formatKey);
      _step(value.span.start);
      _consumeNode(value);
    });
    _step(yamlMap.span.end);
  }

  void _consumeList(YamlList yamlList) {
    _step(yamlList.span.start);
    yamlList.nodes.forEach((YamlNode node) {
      _step(node.span.start);
      _consumeNode(node);
    });
    _step(yamlList.span.end);
  }

  void _consumeScalar(YamlNode node) {
    _step(node.span.end, theme.formatScalar);
  }

  void _step(location, [formatter]) {
    if (formatter == null) formatter = (x) => x;
    var formatted = formatter(yaml.substring(offset, offset = location.offset));
    buffer.write(formatted);
  }
}