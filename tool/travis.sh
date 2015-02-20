#!/usr/bin/env bash
set -o xtrace

# Run tests.
pub global activate test_runner
test_runner -v

# Analyze all libraries.
pub global activate tuneup
tuneup check

# Code coverage.
if [ "$REPO_TOKEN" ]; then
  pub global activate dart_coveralls
  dart_coveralls report --token $REPO_TOKEN --retry 3 test/test.dart
fi
