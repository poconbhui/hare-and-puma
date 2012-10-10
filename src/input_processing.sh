#!/bin/bash

#
# INPUT PROCESSING
#

#
# processes input file dropping lines starting with #
#
#  Useage:
#    file_contents=$( process_input_file filename )
#
process_input_file(){
  cat "$1" | grep -v '#'
}


