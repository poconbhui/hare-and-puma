#!/usr/bin/env bash


#
# echo help message for hare_puma.sh
#
#  Useage:
#    useage_message
#
useage_message(){
cat <<"EOF"
 
 hare_puma calculates the following PDEs for the distribution of hares and
 pumas on an island.
 
 dH/dt = rH - aHP + k(d2H/dx2 + d2H/dy2)
 dP/dt = bHP - mP + l(d2P/dx2 + d2P/dy2)
 
 Useage:
   hare_puma.sh config_file
 
 Config file:
  land_file=path/to/land.dat
  hare_file=path/to/hare.dat
  puma_file=path/to/puma.dat
 
  var_dt=0.1
  var_l=0.4
  var_m=0.4
  ...
 
 Variables not defined in the config file will be set to some sane default.
 Note that the land_file, hare_file and puma_file are currently required.
 
 Example files:
 
 land_file.dat:
 5 5
 0 1 0 0 1
 0 1 1 0 1
 1 1 1 1 1
 1 0 1 1 0
 1 1 1 0 0
 
 hare_file.dat:
 5 5
 0     0.34 0    0    3.5
 0     2.66 3.2  0    4.1
 1.23  1.12 2.3  2.67 3.5
 2.099 0    1.9  2.43 0
 2.53  2.2  1.89 0    0
 
 Note that the land files are 0 for water and 1 for land, and the hare and
 puma files define the density of hares or pumas in each tile location.
 The hare and puma tiles must be 0 where the land tiles are 0, and must
 be a positive number.
 
 There is no need to pad the hare or puma files so the columns line up, it
 just looks nice.

EOF
}

# if -h passed in, print useage message and die
if [[ "$1" == "-h" ]]; then
  useage_message
  exit 1;
fi


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


#
# ARRAY FUNCTIONS
#

#
# wrapper function for array operations.
# arrays are stored in format: [width, height, value, value, value...]
#
# Useage:
#   array set array_name width height value value value...
#   array array_name x y new_value
#   array_name_x_y=$( array array_name x y )
#
array(){
#input options:

# set entire array:
  if [[ "$1" == "set" ]]; then
    shift
    name="$1"
    shift
    eval $name"=( ""$@"" )"

    return
  fi

  case "$#" in
# set array element:
#   array $name height width value
    4 )
      array_set "$1" "$2" "$3" "$4"
      ;;
# get array element:
#   array $name height width
    3 )
      array_access "$1" "$2" "$3"
      ;;
  esac
}


#
# echos the extent of a given dimension of a given array
#
#  Useage:
#    dim_extent=$( array_dim array_name dim )
#
array_dim(){
  array_name=$1
  dim=$2
  dim_size=$(eval 'echo "${'$array_name'['$dim']}"')

  echo $dim_size
}


#
# echos out distance of element x,y from the start of an array of
#   dimension width,height
#
#  Useage:
#    array_offset width height x y
#
array_offset(){
  echo $(( $4*$2 + $3 + 2 )) #+2 to jump past height and width
}


#
# echos out element x,y of given array
#
#  Useage:
#    array_access array_name x y
#
array_access(){
  array_name=$1

  width=$( array_dim $array_name 0 )
  height=$( array_dim $array_name 1 )

  offset=$( array_offset $width $height  $2 $3 );

  eval 'echo "${'$array_name'['$offset']}"'
}

#
# Sets given x y element of given array to given value
#  Useage:
#    array_set array_name x y value
#
array_set(){
  array_name=$1

  width=$( array_dim $array_name 0 )
  height=$( array_dim $array_name 1 )

  offset=$( array_offset $height $width  $2 $3 );

  value=$4

  eval $array_name'['$offset']='$value
}


#
# echos the input array padded on the edges with 0s
#  Useage:
#    padded_array=( $(pad_array array_name) )
#
pad_array(){
  local array_name=$1
  local width=$( array_dim $array_name 0 );
  local height=$( array_dim $array_name 1 );

  echo -n $(( $height+2 )) $(( $width+2 ))" "

#pad top
  for i in $(seq 1 $(( $width+2 )) ); do
    echo -n 0" ";
  done

#pad edges
  for y in $(seq 0 $(( $height-1 ))); do
  echo -n 0" "
  for x in $(seq 0 $(( $width-1 ))); do
    echo -n $(array $array_name $x $y)" ";
  done
  echo -n 0" "
  done

#pad bottom
  for i in $(seq 1 $(( $width+2 )) ); do
    echo -n 0" ";
  done
}


#
# echos the input array. Useful for outputting to stdout
#  Useage:
#    print_array array_name
#
print_array(){
  array_name=$1

  width=$(eval 'echo "${'$array_name'[0]}"')
  height=$(eval 'echo "${'$array_name'[1]}"')

  for y in $(seq 0 $(( $height-1 )) ); do
    for x in $(seq 0 $(( $width-1 )) ); do
      echo -n $( array $array_name $x $y )" "
    done
    echo
  done
}




#
# THE DIFFUSION ALGORITHM
#

#
# Set default algorithm variables as global variables
#  Useage:
#    set_default_algorithm_variables
#

set_default_algorithm_variables(){
  var_run_time=500;
  var_dt=0.4;
  var_r=0.08;
  var_a=0.04;
  var_k=0.02;
  var_b=0.02;
  var_m=0.06;
  var_l=0.02;
}


#
#equation parser changes equations written with some nice array
#  based syntax into some horrible bc compatible syntax that must
#  be parsed with bash first to change our horrible array
#  function based statements into actual numbers.
#
#  This allows for some nicer array syntax while defining equations
#  but requires the string to be evaled before being passed into bc.
#  Worth it!
#
#  Useage:
#    parsed_eqn=$( parse_eqn "$eqn_string" )
#
parse_eqn(){
  echo $1 |
#make alphanumerics variables
  sed 's#[a-z_]\{1,\}#$\0#g' |
#wrap arrays
  sed 's#\([A-Z]\)\(\[[^]]*\]\[[^]]*\]\)#$( array \1 \2 )#g' |
#process brackets
  sed 's#\]\[# ))" "$(( #g' | sed 's#\[#"$(( #g' | sed 's#\]# ))"#g' |
#replace array names
  sed 's#H#hare_density#g' | sed 's#P#puma_density#g' | sed 's#L#land#g'
}

#
# echo hare equation string
#  Useage:
#   some_var=$( hare_update_string )
#
hare_update_string(){
#if hare update string hasn't already been generated,
#  generate it
if [[ x"$hare_update_string"x == "xx" ]];then
local eqn=$(cat <<"EOF"
  H[i][j] + var_dt*( var_r*H[i][j] - var_a*H[i][j]*P[i][j]
    + var_k*(
      H[i-1][j] + H[i+1][j] + H[i][j-1] + H[i][j+1]
      - H[i][j]*(
          L[i-1][j] + L[i+1][j] + L[i][j-1] + L[i][j+1]
        )
      )
  )
EOF
)

  hare_update_string=$( parse_eqn "$eqn" )
fi

echo $hare_update_string

}

#
# echo puma update string
#  Useage:
#   some_var=$( puma_update_string )
#
puma_update_string(){
#if puma update string hasn't already been generated,
#  generate it
if [[ x"$hare_update_string"x == "xx" ]];then
local eqn=$(cat <<"EOF"
  P[i][j] + var_dt*(var_b*H[i][j]*P[i][j] - var_m*P[i][j]
    +var_l*(
      P[i-1][j] + P[i+1][j] + P[i][j-1] + P[i][j+1]

      - P[i][j]*(
          L[i-1][j] + L[i+1][j] + L[i][j-1] + L[i][j+1]
        )
      )
    )
EOF
)

  puma_update_string=$( parse_eqn "$eqn" )
fi

echo $puma_update_string

}


#
# Update Function
#   WARNING: SLOW!
#
#  Useage:
#    update_densities land_array_name hare_array_name puma_array_name
#
update_densities(){
  local land_in=$1
  local hare_density_in=$2
  local puma_density_in=$3

# make copy of old densities so updates don't write over them

  local new_hare_density=( $(array_dim $hare_density_in 0) $(array_dim $hare_density_in 1) )
  local new_puma_density=( $(array_dim $puma_density_in 0) $(array_dim $puma_density_in 1))

  for i in $(seq 0 $(( ${new_hare_density[0]}-1 ))); do
  for j in $(seq 0 $(( ${new_hare_density[1]}-1 ))); do

    if [[ "$( array $land_in $i $j )" != "0" ]]; then
      local population=$( eval "echo \"$( hare_update_string )\"" | bc -l );
      array new_hare_density $i $j $population

      local population=$( eval "echo \"$( puma_update_string )\"" | bc -l );
      array new_puma_density $i $j $population
    else
      array new_hare_density $i $j 0
      array new_puma_density $i $j 0
    fi

  done
  done


  array set $hare_density_in $( echo ${new_hare_density[@]} )
  array set $puma_density_in $( echo ${new_puma_density[@]} )
}


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


#
# Run Main
#

main "$1"
