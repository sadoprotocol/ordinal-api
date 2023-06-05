#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if [ ! -f "$SCRIPT_DIR/.ord-index-config" ]
then
  echo "No config file found.."
  exit
fi

source "$SCRIPT_DIR/.ord-index-config"

RUNNING=$(ps -fu $UID | grep "ord" | grep "data-dir" | grep "$SNAPSHOT_DATA_DIR" | grep "index-sats index")

if [ ! -z "${RUNNING}" ]; then 
  echo "Still running.."
  exit
fi

if test -f "$SNAPSHOT_DATA_DIR$NETWORK/lock"; then
  echo "Process not finished.."
  exit
fi

mkdir -p $SNAPSHOT_DATA_DIR$NETWORK

# LOCK
touch "$SNAPSHOT_DATA_DIR$NETWORK/lock"


# == SETUP

if [ ! -f $SNAPSHOT_DATA_DIR$NETWORK"/index.redb" ]
then
  rsync -a $DEFAULT_DATA_DIR$NETWORK"/index.redb" $SNAPSHOT_DATA_DIR$NETWORK"/index.redb"
fi

# ==

BITCOIN_CLI_OPTIONS=()
ORD_CLI_OPTIONS=()

if [ ! -z "${NETWORK}" ]; then
  if [ $NETWORK = "regtest" ]; then
    BITCOIN_CLI_OPTIONS=( --regtest )
    ORD_CLI_OPTIONS=( -r )
  elif [ $NETWORK = "testnet3" ]; then
    BITCOIN_CLI_OPTIONS=( --testnet )
    ORD_CLI_OPTIONS=( -t )
  else
    echo "Invalid network"
    exit
  fi
fi

# SETUP END ==


HEIGHT=$(bitcoin-cli "${BITCOIN_CLI_OPTIONS[@]}" getblockcount)

echo "HEIGHT is $HEIGHT"
echo "Begin indexing.."

echo "indexing" > $SNAPSHOT_DATA_DIR$NETWORK"/height"

REORG=$(ord@cake "${ORD_CLI_OPTIONS[@]}" --data-dir=$SNAPSHOT_DATA_DIR --index-sats index 2>&1 | grep -P 'reorg')

echo "$HEIGHT" > $SNAPSHOT_DATA_DIR$NETWORK"/height"

echo "REORG is $REORG"

if [ -z "$REORG" ]
then
  # SNAPSHOT PROCESS
  MOD=$(expr $HEIGHT % 30)

  echo "MOD is $MOD"

  if [ $MOD -eq 0 ];
  then
    STALE=$(expr $HEIGHT - 200)
    STALEMAX=$(expr $HEIGHT - 1000)
    echo "STALE is $STALE"
    echo "STALEMAX is $STALEMAX"
    echo "Creating snapshot"
    rsync -a $SNAPSHOT_DATA_DIR$NETWORK"/index.redb" $SNAPSHOT_DATA_DIR$NETWORK"/index.redb.$HEIGHT"

    while [ $STALE -ge $STALEMAX ]
    do
      echo "CURRENT STALE is $STALE"
      if test -f "$SNAPSHOT_DATA_DIR$NETWORK/index.redb.$STALE"; then
        echo "Removing stale $STALE"
        rm $SNAPSHOT_DATA_DIR$NETWORK"/index.redb.$STALE"
        echo "Removed stale"
      fi
      ((STALE=STALE-1))
    done
  fi

  # UNLOCK
  rm "$SNAPSHOT_DATA_DIR$NETWORK/lock"

  if test -f "$SNAPSHOT_DATA_DIR$NETWORK/reorg"; then
    rm "$SNAPSHOT_DATA_DIR$NETWORK/reorg"
  fi

  echo "Done.."
else
  echo "PENDING: Perform self reorg recovery"

  touch "$SNAPSHOT_DATA_DIR$NETWORK/reorg"
  echo "Has reorg.."
fi
