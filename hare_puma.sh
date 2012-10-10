#!/usr/bin/env bash

#
# Useage:
#   hare_puma land_file hare_file puma_file
#


#
# INPUT PROCESSING
#

preprocess_file(){
  cat "$1" | grep -v '#'
}

process_input_files(){

# process input to nicer variables
  local land_file=$1
  local hare_file=$2
  local puma_file=$3


#generate arrays
  land=( `preprocess_file $land_file` );
  hare_density=( `preprocess_file $hare_file` );
  puma_density=( `preprocess_file $puma_file` );

  board_dimensions=( `head $land_file` );
}



#
# ARRAY FUNCTIONS
#

#arrays stored in format height width value value value etc.
array(){
#input options:
  case "$#" in
# set entire array:
#   $( array $name )=( value value value )
    1 )
      echo "$1"
      ;;
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


array_new_name(){
  local array_name_length=8
  local array_name=$( tr -dc "[:alpha:]" < /dev/urandom | head -c $array_name_length )

  echo "$array_name"
}


#array_offset width height x y => y*width + x
array_offset(){
#  echo >&2
#  echo OFFSET >&2
#  echo HEIGHT $1 >&2
#  echo WIDTH $2 >&2
#  echo X $3 >&2
#  echo Y $4 >&2
#  echo >&2

  echo $(( $4*$2 + $3 + 2 )) #+2 to jump past height and width
}

#array_access $name $x $y => name[x][y]
array_access(){
#  echo >&2
#  echo ACCESS >&2
#  echo NAME $1 >&2
#  echo X $2 >&2
#  echo Y $3 >&2
#  echo >&2

  array_name=$1

  width=$(eval 'echo "${'$array_name'[0]}"')
  height=$(eval 'echo "${'$array_name'[1]}"')

  offset=$( array_offset $width $height  $2 $3 );

  eval 'echo "${'$array_name'['$offset']}"'
}

#array_set $name x y $value => name[x][y] = value
array_set(){
#  echo >&2
#  echo SET >&2
#  echo NAME $1 >&2
#  echo X $2 >&2
#  echo Y $3 >&2
#  echo VALUE $4 >&2
#  echo >&2
  array_name=$1

  width=$(eval 'echo "${'$array_name'[0]}"')
  height=$(eval 'echo "${'$array_name'[1]}"')

  offset=$( array_offset $height $width  $2 $3 );

  value=$4

  eval $array_name'['$offset']='$value
}


pad_array(){
  local width=$1;
  local height=$2;
  shift;
  shift;

  local array=( $@ );

  echo $height $width >&2
  echo $(( $height+2 )) $(( $width+2 ))" "


#pad top
  for i in $(seq 1 $(( $width+2 )) ); do
    echo -n 0" ";
  done
  echo

#pad edges
  for i in $(seq 0 $(( $height-1 ))); do
    echo 0 ${array[@]:$(( $i*$width )):$width} 0;
  done

#pad bottom
  for i in $(seq 1 $(( $width+2 )) ); do
    echo -n 0" ";
  done
}


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

set_algorithm_variables(){
  var_dt=0.4;
  var_r=0.08;
  var_a=0.04;
  var_k=0.02;
  var_b=0.02;
  var_m=0.06;
  var_l=0.02;
}


#allows for some nice array syntax while defining equations
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

hare_update_string(){
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

puma_update_string(){
if [[ x"$hare_update_string"x == "xx" ]];then
local eqn=$(cat <<"EOF"
  P[i][j] + var_dt*(var_b*H[i][j] - var_m*H[i][j]*P[i][j]
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

update_densities(){
# make copy of old densities so updates don't write over them

  new_hare_density=( ${board_dimensions[0]} ${board_dimensions[0]} )
  new_puma_density=( ${board_dimensions[0]} ${board_dimensions[0]} )

  for i in $(seq 0 $(( ${board_dimensions[0]}-1 ))); do
  for j in $(seq 0 $(( ${board_dimensions[1]}-1 ))); do

    if [[ "$( array land $i $j )" != "0" ]]; then
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


  hare_density=( $( echo ${new_hare_density[@]} ) )
  puma_density=( $( echo ${new_puma_density[@]} ) )
}


#
# MAIN FUNCTION
#

main(){
  process_input_files "$1" "$2" "$3"

  echo ${board_dimensions[0]}
  echo ${board_dimensions[1]}

#pad arrays
  land=( $(pad_array "${land[@]}") )
  hare_density=( $(pad_array "${hare_density[@]}") )
  puma_density=( $(pad_array "${puma_density[@]}") )

#modify dimensions from padding
  board_dimensions[0]=$(( ${board_dimensions[0]} + 2 ))
  board_dimensions[1]=$(( ${board_dimensions[1]} + 2 ))

#run algorithm
  set_algorithm_variables

  echo
  print_array hare_density

  update_densities

  echo
  print_array hare_density
}


main "$1" "$2" "$3"
