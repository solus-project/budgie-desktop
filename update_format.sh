#!/bin/bash

# Ensure we're formatted everywhere.
clang-format -i $(find src -name '*.[ch]' -not -path '*/gvc/*')

# Check we have no typos.
which misspell 2>/dev/null >/dev/null
if [[ $? -eq 0 ]]; then
    misspell -error `find src -name '*.[ch]' -not -path '*/gvc/*'`
    misspell -error `find src -name '*.vala' -not -path '*/gvc/*'`
fi
