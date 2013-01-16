#!/bin/bash

source /apps/leuven/etc/bash.bashrc

module load matlab/R2011b

rm -f trial
mcc -mv -o trial \
    -a ./lib -a ./lib/events -a ./lib/interventions \
    FeiRun.m

