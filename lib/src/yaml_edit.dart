
library yaml_edit;

import 'package:yaml/yaml.dart';

String setMapKey(String yaml, YamlMap mapNode, String key, value) {
  var startLocation, endLocation, insertion;
  if(mapNode.containsKey(key)) {
    var replaceNode = mapNode.nodes[key];
    startLocation = replaceNode.span.start;
    endLocation = replaceNode.span.end;
    insertion = value;
  } else {
    startLocation = mapNode.span.end;
    endLocation = mapNode.span.end;
    var indent = mapNode.isEmpty ? mapNode.span.start.column + 2 : mapNode.nodes.keys.last.span.start.column;
    if(value is Map) {
      value = value.keys.fold('', (str, key) {
        
      });
    }
    insertion = '${' ' * indent}$key:${value.startsWith('\n') ? '' : ' '}$value\n';
  }
  return (new StringBuffer()
      ..write(yaml.substring(0, startLocation.offset))
      ..write(insertion)
      ..write(yaml.substring(endLocation.offset)))
      .toString();
}
