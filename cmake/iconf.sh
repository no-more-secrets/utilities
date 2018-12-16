#!/bin/bash

check() {
  [[ $? != 0 ]] && exit 1
  true
}

dialog --yesno "Run clang-tidy?" 10 30

dialog --menu "Choose Compiler" 15 40 6 default "default on the system" gcc "" clang ""

dialog --prgbox "cmc --verbose --no-color" 40 80
