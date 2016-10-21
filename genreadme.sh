#!/bin/bash

CMDS=("help" "setup" "bump" "set" "show")

for CMD in ${CMDS[@]}
do
    echo "##$CMD"
    echo
    echo "\`\`\`"
    ./version.sh help "$CMD"
    echo "\`\`\`"
    echo
done
