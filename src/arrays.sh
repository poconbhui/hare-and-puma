#!/bin/bash

#
# ARRAY FUNCTIONS
#

#
# wrapper function for array operations.
# arrays are stored in format: [width, height, value, value, value...]
#
# Usage:
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
#  Usage:
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
#  Usage:
#    array_offset width height x y
#
array_offset(){
  echo $(( $4*$2 + $3 + 2 )) #+2 to jump past height and width
}


#
# echos out element x,y of given array
#
#  Usage:
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
#  Usage:
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
#  Usage:
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
#  Usage:
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

