#!/bin/bash
set -evx

mkdir ~/.phasecore

# safety check
if [ ! -f ~/.phasecore/.phase.conf ]; then
  cp share/phase.conf.example ~/.phasecore/phase.conf
fi
