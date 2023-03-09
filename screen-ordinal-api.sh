#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
screen -X -S ordinal-api quit
screen -S ordinal-api -dm SCRIPT_DIR/start-ordinal-api.sh

