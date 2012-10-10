#!/bin/bash

source $hare_puma_install_path/input_processing.sh
source $hare_puma_install_path/arrays.sh
source $hare_puma_install_path/diffusion.sh

#
# MAIN FUNCTION
#
# Useage:
#   main config_filename
#

main(){
  config_file="$1"

#
# set default algorithm variables
#
  set_default_algorithm_variables

#
# import data from config file
#
  source "$config_file"

  land=( $(process_input_file "$land_file") )
  hare_density=( $(process_input_file "$hare_file") )
  puma_density=( $(process_input_file "$puma_file") )


#pad arrays
  land=( $(pad_array land ) )
  hare_density=( $(pad_array hare_density ) )
  puma_density=( $(pad_array puma_density ) )


#
#run algorithm
#

#output initial array
  echo
  echo "TIME: 0"
  print_array hare_density

  for time in $(seq $var_dt $var_dt $var_run_time); do
#output current array
    update_densities land hare_density puma_density

    echo
    echo "TIME: "$time
    print_array hare_density

  done

}
