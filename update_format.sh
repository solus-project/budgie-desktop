#!/bin/bash
clang-format -i $(find . -name '*.[ch]' -not -path "./gvc/*" -not -path "./imports/*")
