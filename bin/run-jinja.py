#!/usr/bin/env python

import sys
import shutil

print(sys.argv[1])
print(sys.argv[2])

# no-op
shutil.copyfile(sys.argv[1], sys.argv[2])
