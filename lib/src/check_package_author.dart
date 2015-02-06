
library den.src.check_package_author;

List<String> checkAuthor(String author) {
  var hasName = new RegExp(r"^ *[^<]");
  var hasEmail = new RegExp(r"<[^>]+> *$");

  var messages = [];

  if (!hasName.hasMatch(author)) {
    messages.add('Author "$author" should have a name.');
  }
  if (!hasEmail.hasMatch(author)) {
    messages.add('Author "$author" should have an email address\n(e.g. "name <email>").');
  }

  return messages;
}
