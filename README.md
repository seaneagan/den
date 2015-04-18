den [![pub package](https://img.shields.io/pub/v/den.svg)](https://pub.dartlang.org/packages/den) [![Build Status](https://travis-ci.org/seaneagan/den.svg?branch=master)](https://travis-ci.org/seaneagan/den)
===

A pubspec authoring tool.

##Install

```shell
pub global activate den
```

##Usage

```shell
# `den ...` requires Dart >=1.7, on 1.6 use `pub global run den ...`

# Create a pubspec.  Field value prompts default to your local git info.
den spec
# Bypass prompts, accept defaults.
den spec --force

# Bump your pubspec version (and do a tagged version commit if in a git repo)
den bump 1.2.3
den bump patch
den bump major --pre-id beta
den bump release --pre
den bump build  (1.0.2+1 --> 1.0.2+2)

# Install dependencies (defaults to '>={latest stable} <{next breaking}')
den install polymer browser
den install unittest --dev
den install polymer#any
den install git://github.com/owner/repo.git -sgit
den install git://github.com/owner/repo#ref -sgit
den install path/to/foo -spath

# Uninstall dependencies
den uninstall junk kludge

# Keep dependencies up-to-date

# Show outdated (all by deafult)
den fetch
den fetch polymer

# Update outdated to '>={latest stable} <{next breaking}' (all by default)
den pull
den pull polymer

# Install comprehensive TAB-completion for den
den completion install

# Complete commands, options, package names, etc.
den i[TAB] -> install
den install unit[TAB] -> unittest
den uninstall j[TAB] -> junk
den fetch p[TAB] -> polymer
den pull p[TAB] -> polymer
```

###Package Authors

Add the following package installation instructions to your README:

```shell
pub global activate den
den install <your package name>
```

##^ Constraints

`den install` and `den pull` will take advantage of [^ constraints][caret_info] 
e.g. `^1.2.3` if either of:

* Your [sdk constraint][sdk_constraint] disallows pre-1.8.0 SDKs when ^ was introduced.
* You pass the `--caret` flag, which updates your sdk constraint for you.

Otherwise, they will use range syntax e.g. `>=1.2.3 <2.0.0` 

[caret_info]: https://groups.google.com/a/dartlang.org/forum/#!topic/misc/0t9qQF-rZg4
[sdk_constraint]: https://www.dartlang.org/tools/pub/pubspec.html#sdk-constraints

##Inspiration

`den install` was inspired by [`npm install --save`][npm install] and [`bower install --save`][bower install]
`den fetch` and `den pull` were inspired by [`david` and `david update`][david].

[npm install]: https://www.npmjs.org/doc/cli/npm-install.html
[bower install]: http://bower.io/docs/api/#install
[david]: https://github.com/alanshaw/david#cli
