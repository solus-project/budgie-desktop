#!/bin/bash
CI_EXCLUDES="! -path */gvc/* ! -path */imports/natray/*"

# Ensure we're formatted everywhere.
clang-format -i $(find . $CI_EXCLUDES -name '*.[ch]')

# Check we have no typos.
which misspell 2>/dev/null >/dev/null
if [[ $? -eq 0 ]]; then
    misspell -error `find . $CI_EXCLUDES -name '*.[ch]'`
    misspell -error `find . $CI_EXCLUDES -name '*.vala'`
fi
