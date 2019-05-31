#!/bin/bash

check() {
  [[ $? != 0 ]] && exit 1
  true
}

dialog --yesno "Run clang-tidy?" 10 30

dialog --menu "Choose Compiler" 15 40 6 default "default on the system" gcc "" clang ""

dialog --prgbox "cmc c --verbose --no-color --clang --lld" 60 80

dialog --prgbox "make -j12" 60 80

dialog --prgbox "make test" 60 80
