#!/bin/bash

usage(){
  echo "usage: $0 [-h] [-d address] [-c] [-l] [-u] [-C] [-t] [-s leaf1,leaf2,...]"
  echo "-h    display help"
  echo "-d source    Take input file from source. It can be a directory or http address"
  echo "-c    Print number of unique leaves from input"
  echo "-l    Print number of all leaves from input"
  echo "-u    Print trees containing different leaves (no leaves repetition in those trees)"
  echo "-C    For each tree print its leaves (no repetition). Order preserved"
  echo "-t    Print leaves from input (no repetition)"
  echo "-S leaf1,leaf2,...    Print trees containing all of given leaves"
  echo "-s leaf1,leaf2,...    Print trees containing at least one of given leaves"
}

leaves(){
  # Print every leaf from input file. Leaves may repeat
  grep -o "\<[[:alnum:]]\+\>" $1
}

# When script is called with no arguments, print usage and exit
if [ -z "$*" ]; then
  usage
  exit 1
fi

while getopts "hd:cluCtS:s:" opt; do
  case $opt in 
    \?) echo "Invalid option -$OPTARG. For help type trees.sh -h"
        exit 1;;
    :) echo "Option -$OPTARG requires an argument. For help type trees.sh -h"
       exit 1;;
    h) hflg=1;;
    d) dflg=1
       src=$OPTARG;;
    c) cflg=1;;
    l) lflg=1;;
    u) uflg=1;;
    C) Cflg=1;;
    t) tflg=1;;
    S) Sflg=1
       leaves=$OPTARG;;
    s) sflg=1
       leaves=$OPTARG;;
  esac
done


if [ "$hflg" = 1 ]; then
  usage
fi


if [ "$dflg" = 1 ]; then
  if [[ $src = 'http://'* ]] || [[ $src = 'https://'* ]]; then
    # download file. -N caused wget not to download when file already
    # exists and is no older than online file.
    # -q runs wget in quiet mode
    if wget -Nq $src; then
      filename=$(basename "$src")
    else
      >&2 echo "Failed to download file"
      exit 1
    fi
  elif [[ -r $src ]]; then
    filename=$src
  else
    # something went wrong. Print to stderr and exit
    >&2 echo "ERROR: $src is not http address nor a local file" 
    exit 1
  fi
else
  # if no input specified, then read from stdin
  filename="/dev/stdin"
fi


# Print number of unique leaves
if [ "$cflg" = 1 ]; then
  leaves "$filename" | sort | uniq | wc -w 
fi


# Print number of leaves
if [ "$lflg" = 1 ]; then
  leaves "$filename" | wc -w
fi


# Print unique leaves
if [ "$tflg" = 1 ]; then
  leaves "$filename" | sort -u 
fi


# Print trees containing only different leaves. (No two leaves are the same)
if [ "$uflg" = 1 ]; then
  while read line; do
    [ -z "$line" ] && continue # skip blank lines
    # calculate number of unique leaves and all leaves
    # if they are equal, then tree contains only unique leaves
    uniq_leaves=$( echo "$line" | leaves | sort -u | wc -w)
    all_leaves=$( echo "$line" | leaves | wc -w)
    if [ $uniq_leaves -eq $all_leaves ]; then
      echo $line
    fi
  done < "$filename"
fi


# For each tree print its leaves (no repetition)
if [ "$Cflg" = 1 ]; then
  while read line; do
    [ -z "$line" ] && continue # skip blank lines
    echo $( echo "$line" | leaves | sort | uniq | tr '\n' ' ')
  done < "$filename"
fi


# Print trees containing given leaves
if [ "$Sflg" = 1 ]; then
  leaves=$( echo $leaves | tr ',' ' ')
  while read line; do
    [ -z "$line" ] && continue # skip blank lines
    leaves_in_line="$( echo "$line" | leaves | sort -u | tr '\n' ' ')" 
    break_flg=0
    for leaf in $leaves; do
      leaf_in=$( echo $leaves_in_line | grep -o "\b$leaf\b" ) # empty str if leaf is not in
      # \b stands for boundaries of the word
      if [ "$leaf_in" = "" ]; then 
        break_flg=1
        break
      fi
    done
    if [ "$break_flg" = 0 ]; then
      echo $line
    fi
  done < "$filename"
fi


# Print trees containing at least one of given leaves.
if [ "$sflg" = 1 ]; then
  leaves=$( echo $leaves | tr ',' ' ')
  while read line; do
    [ -z "$line" ] && continue # skip blank lines
    leaves_in_line="$( echo "$line" | leaves | sort -u | tr '\n' ' ')" # Ten sort nie jest czasem problemem??? TODO
    for leaf in $leaves; do
      leaf_in=$( echo $leaves_in_line | grep -o "\b$leaf\b" ) # empty str if leaf is not in
      # \b stands for boundaries of the word
      if [ "$leaf_in" != "" ]; then 
        echo "$line"
        break
      fi
    done
  done < "$filename"
fi

