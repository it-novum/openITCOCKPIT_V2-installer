#!/bin/bash

pear_path=$1
declare -a pear_packages
pear_cmd="pear install --alldeps"
pear_packages=($(ls $pear_path/openitc_install/pear/*))
for((c=0;c<${#pear_packages[@]};c++)); do 
  if [ "`awk '/^.*(\.tar\.gz|\.tgz)$/{print}'<<<${pear_packages[$c]}`" != "" ]; then  # filter all unnecessary files
    pear_cmd=$pear_cmd" ${pear_packages[$c]}"
  fi
done
$pear_cmd


