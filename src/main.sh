#!/bin/bash

source $hare_puma_install_path/input_processing.sh
source $hare_puma_install_path/arrays.sh
source $hare_puma_install_path/diffusion.sh

#
# MAIN FUNCTION
#
# Usage:
#   main config_filename
#

main(){
  config_file="$1"

#
# set default variables
#
  set_default_algorithm_variables
  output_dir="$PWD"

#
# import data from config file
#

# require config file specified
  if ! test -f "$config_file" ; then
    echo "Config file must be specified!" >&2
    exit 1;
  fi

  source "$config_file"

# require land, hare and puma files specified
  if ! test -f "$land_file" ; then
    echo "Land file must be specified!" >&2
    exit 1;
  fi
  if ! test -f "$hare_file" ; then
    echo "Hare file must be specified!" >&2
    exit 1;
  fi
  if ! test -f "$puma_file" ; then
    echo "Puma file must be specified!" >&2
    exit 1;
  fi

  land=( $(process_input_file "$land_file") )
  hare_density=( $(process_input_file "$hare_file") )
  puma_density=( $(process_input_file "$puma_file") )


#pad arrays
  land=( $(pad_array land ) )
  hare_density=( $(pad_array hare_density ) )
  puma_density=( $(pad_array puma_density ) )


#
# run algorithm
#


#
#output initial array
#
  echo
  echo "TIME: 0"

#output hares
  echo $( array_dim hare_density 0 ) $( array_dim hare_density 1 ) \
    > $output_dir/hare_0.pgm
  print_array hare_density \
    >> $output_dir/hare_0.pgm

#output pumas
  echo $( array_dim puma_density 0 ) $( array_dim puma_density 1 ) \
    > $output_dir/puma_0.pgm
  print_array puma_density \
    >> $output_dir/puma_0.pgm

#
# run update loop
#
  for time in $(seq $var_dt $var_dt $var_run_time); do
#output current array
    update_densities land hare_density puma_density

    echo
    echo "TIME: "$time

#output hares
    echo $( array_dim hare_density 0 ) $( array_dim hare_density 1 ) \
      > $output_dir/hare_$( echo $time | sed 's/\./_/g' ).pgm
    print_array hare_density \
      >> $output_dir/hare_$( echo $time | sed 's/\./_/g' ).pgm

#output pumas
    echo $( array_dim puma_density 0 ) $( array_dim puma_density 1 ) \
      > $output_dir/puma_$( echo $time | sed 's/\./_/g' ).pgm
    print_array puma_density \
      >> $output_dir/puma_$( echo $time | sed 's/\./_/g' ).pgm

  done

}
