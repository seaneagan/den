
library den_api.src.yaml_edit;

import 'package:yaml/yaml.dart';
import 'package:source_span/source_span.dart';

import 'util.dart';

String deleteMapKey(String yaml, YamlMap mapNode, String key) {

  if(!mapNode.containsKey(key)) return yaml;
  YamlNode previousValueNode, keyNode, nextKeyNode;
  var orderedKeys = mapNode.nodes.keys.toList()..sort((a, b) => a.span.compareTo(b.span));

  var keyNodeIterator = orderedKeys.iterator;
  while(keyNodeIterator.moveNext()) {
    var curr = keyNodeIterator.current;
    if(curr.value == key) {
      keyNode = curr;
      if(keyNodeIterator.moveNext()) {
        nextKeyNode = keyNodeIterator.current;
      }
      break;
    }
    previousValueNode = mapNode.nodes[curr];
  }

  var isFlow = mapNode.style == CollectionStyle.FLOW;
  // TODO: Support flow mappings.  (See also http://dartbug.com/21328 is fixed.)
  if(isFlow) throw new UnimplementedError('Editing flow mappings is not yet supported.');

  getEndIndex(YamlNode valueNode, YamlNode nextKeyNode) {
    var valueEndIndex = valueNode.span.end.offset;
    if(isFlow) {
      // Consume trailing comma if there is one.
      return nextKeyNode == null ?
          mapNode.span.end.offset :
          nextKeyNode.span.start.offset;
    }
    // Consume trailing newline and any trailing comment.
    var endIndex = yaml.indexOf('\n', valueEndIndex - 1) + 1;
    return endIndex == -1 ? yaml.length : endIndex;
  }

  var valueNode = mapNode.nodes[key];
  var removePreviousSeparator = nextKeyNode == null;
  var startIndex = removePreviousSeparator ?
      getEndIndex(previousValueNode, keyNode) :
      keyNode.span.start.offset;
  var endIndex = getEndIndex(valueNode, nextKeyNode);

//  var startIndex = keyNode.span.start.offset - keyNode.span.start.column;
//  var endIndex = yaml.indexOf('\n', valueNode.span.end.offset - 1) + 1;

  return yaml.substring(0, startIndex) + yaml.substring(endIndex);
}

String setMapKey(String yaml, YamlMap mapNode, String key, value, bool ownLine) {
  var startLocation, endLocation, insertion;
  // TODO: Support flow mappings.
  var isFlow = mapNode.style == CollectionStyle.FLOW;
  if(isFlow) throw new UnimplementedError('Editing flow mappings is not yet supported.');
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
  // TODO: Show a diff (with red/green ansicolor), and add an interactive mode which will prompt "Is this OK? (y/n): "
  return (new StringBuffer()
      ..write(wholeText.substring(0, start.offset))
      ..write(newText)
      ..write(wholeText.substring(end.offset)))
      .toString();
}
