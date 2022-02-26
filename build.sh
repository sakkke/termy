#!/bin/bash

makearchiso/bin/makearchiso \
  -K ly \
  -L perl-linux-desktopfiles \
  -K obmenu-generator \
  "$@"
