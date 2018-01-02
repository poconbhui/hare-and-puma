#!/usr/bin/env bash
hare_puma_install_path=src


source $hare_puma_install_path/usage.sh

# if -h passed in, print usage message and die
if [[ "$1" == "-h" ]]; then
  usage_message
  exit 1;
fi


source $hare_puma_install_path/main.sh


#
# Run Main
#

main "$1"
