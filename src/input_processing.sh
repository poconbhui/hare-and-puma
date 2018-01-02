#!/bin/bash

#
# INPUT PROCESSING
#

#
# processes input file dropping lines starting with #
#
#  Usage:
#    file_contents=$( process_input_file filename )
#
process_input_file(){
  cat "$1" | grep -v '#'
}


