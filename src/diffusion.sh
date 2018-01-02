#!/bin/bash

#
# THE DIFFUSION ALGORITHM
#

#
# Set default algorithm variables as global variables
#  Usage:
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
#  Usage:
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
#  Usage:
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
#  Usage:
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
#  Usage:
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
