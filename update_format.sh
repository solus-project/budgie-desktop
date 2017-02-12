#!/bin/bash
# Ensure we're formatted everywhere.
clang-format -i $(find . -name '*.[ch]' -not -path '*/gvc/*' -not -path '*/natray/*')

# Check we have no typos.
which misspell 2>/dev/null >/dev/null
if [[ $? -eq 0 ]]; then
    misspell -error `find . -name '*.[ch]' -not -path '*/gvc/*' -not -path '*/natray/*'`
    misspell -error `find . -name '*.vala' -not -path '*/gvc/*' -not -path '*/natray/*'`
fi
