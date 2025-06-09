#!/bin/bash

TMUX_SESSION_LIST=`tmux ls | awk -F':' '$4!~/(attached)/ {print $1}'`
# echo $TMUX_SESSION_LIST

for SESSION in $TMUX_SESSION_LIST
do
  # echo $SESSION
  tmux kill-session -t $SESSION
done
