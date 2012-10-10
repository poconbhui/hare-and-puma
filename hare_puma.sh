#!/usr/bin/env bash
hare_puma_install_path=src


source $hare_puma_install_path/useage.sh

# if -h passed in, print useage message and die
if [[ "$1" == "-h" ]]; then
  useage_message
  exit 1;
fi


source $hare_puma_install_path/main.sh


#
# Run Main
#

main "$1"
