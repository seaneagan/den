den [![pub package](http://img.shields.io/pub/v/den.svg)](https://pub.dartlang.org/packages/den) [![Build Status](https://drone.io/github.com/seaneagan/den/status.png)](https://drone.io/github.com/seaneagan/den/latest)
===

Pubspec editing and analysis.

##Install

```shell
pub global activate den
```

##Usage

```shell

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

# Install comprehensive tab-completion for den of
# package names, commands, options, flags, etc.
den completion install
```

##Inspiration

`den install` was inspired by [`npm install --save`][npm install] and [`bower install --save`][bower install]
`den fetch` and `den pull` were inspired by [`david` and `david update`][david].

[npm install]: https://www.npmjs.org/doc/cli/npm-install.html
[bower install]: http://bower.io/docs/api/#install
[david]: https://github.com/alanshaw/david#cli
