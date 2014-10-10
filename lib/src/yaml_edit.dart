
library yaml_edit;

import 'package:yaml/yaml.dart';
import 'package:source_span/source_span.dart';

import 'util.dart';

String deleteMapKey(String yaml, YamlMap mapNode, String key) {

  if(!mapNode.containsKey(key)) return yaml;
  var keyNode = mapNode.nodes.keys.firstWhere((keyNode) => keyNode.value == key);
  var valueNode = mapNode.nodes[key];
  // - 1 to remove preceding newline as well.
  // TODO: Is there ever a case where there is no newline?
  var startIndex = (keyNode.span.start.offset - keyNode.span.start.column) - 1;
  var endIndex = valueNode.span.end.offset;
    
  return yaml.substring(0, startIndex) + yaml.substring(endIndex);
}


String setMapKey(String yaml, YamlMap mapNode, String key, value, bool ownLine) {
  var startLocation, endLocation, insertion;
  if(mapNode.isEmpty) throw new UnimplementedError("Editing empty flow mappings e.g. {} is not yet implemented.");
  if(mapNode.containsKey(key)) {
    var valueNode = mapNode.nodes[key];
    startLocation = valueNode.span.start;
    endLocation = valueNode.span.end;
    YamlNode keyNode = mapNode.nodes.keys.firstWhere((keyNode) => keyNode.value == key);
    var currentOwnLine = keyNode.span.end.line != startLocation.line;
    if(currentOwnLine == ownLine) {
      insertion = value;
    } else if (currentOwnLine) {
      var keyEnd = keyNode.span.end;
      var valueOffset = yaml.indexOf(':', keyEnd.offset) + 1;
      startLocation = new SourceLocation(
          valueOffset, 
          sourceUrl: keyNode.span.sourceUrl, 
          line: keyEnd.line,
          column: keyEnd.column + (valueOffset - keyEnd.offset));
    } else { // ownLine && !currentOwnLine
      var keyColumn = keyNode.span.start.column;
      insertion = '\n${indent(value, keyColumn + 2)}';
    }
  } else {
    startLocation = mapNode.span.end;
    endLocation = mapNode.span.end;
    var keyColumn = mapNode.nodes.keys.last.span.start.column;
    var val = ownLine ? '\n${indent(value, keyColumn + 2)}' : ' $value';
    insertion = '${indent(key, keyColumn)}:$val\n';
    // Ensure newline before new key.
    if(new String.fromCharCode(yaml.codeUnitAt(startLocation.offset - 1)) != '\n') {
      insertion = '\n$insertion';
    }
  }
  return replaceSpan(yaml, insertion, startLocation, endLocation);
}

String replaceSpan(String wholeText, String newText, SourceLocation start, SourceLocation end) {
  var toReplace = new SourceSpan(start, end, wholeText.substring(start.offset, end.offset));
  // TODO: Show a diff (with red/green ansicolor), and add an interactive mode which will prompt "Is this OK? (y/n): "
  // print('Replacing $toReplace with $newText');
  return (new StringBuffer()
      ..write(wholeText.substring(0, start.offset))
      ..write(newText)
      ..write(wholeText.substring(end.offset)))
      .toString();
}
