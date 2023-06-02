#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if [ ! -f "$SCRIPT_DIR/.ord-index-config" ]
then
  echo "No config file found.."
  exit
fi

source "$SCRIPT_DIR/.ord-index-config"

RUNNING=$(ps -fu $UID | grep "ord" | grep "data-dir" | grep -v "$SNAPSHOT_DATA_DIR" | grep "index-sats index")

if [ ! -z "${RUNNING}" ]; then 
  echo "Still running.."
  exit
fi

if test -f "$ALT_DATA_DIR$NETWORK/lock"; then
  echo "Process not finished.."
  exit
fi

mkdir -p $ALT_DATA_DIR$NETWORK
mkdir -p $SNAPSHOT_DATA_DIR$NETWORK

# LOCK
touch "$ALT_DATA_DIR$NETWORK/lock"


# == SETUP

if [ ! -f $ALT_DATA_DIR$NETWORK"/index.redb" ]
then
  rsync -a $DEFAULT_DATA_DIR$NETWORK"/index.redb" $ALT_DATA_DIR$NETWORK"/index.redb"
fi

if [ ! -f $SNAPSHOT_DATA_DIR$NETWORK"/index.redb" ]
then
  rsync -a $DEFAULT_DATA_DIR$NETWORK"/index.redb" $SNAPSHOT_DATA_DIR$NETWORK"/index.redb"
fi

# ==

mkdir -p $ALT_DUP_DATA_DIR$NETWORK

if [ ! -f $ALT_DUP_DATA_DIR$NETWORK"/index.redb" ]
then
  rsync -a $DEFAULT_DATA_DIR$NETWORK"/index.redb" $ALT_DUP_DATA_DIR$NETWORK"/index.redb"
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

# HARDLINK SWITCHER - 2
rm $DEFAULT_DATA_DIR$NETWORK"/index.redb"
ln $ALT_DUP_DATA_DIR$NETWORK"/index.redb" $DEFAULT_DATA_DIR$NETWORK"/index.redb"

echo "Begin indexing.."

echo "indexing" > $ALT_DATA_DIR$NETWORK"/height"

REORG=$(ord@afwcxx "${ORD_CLI_OPTIONS[@]}" --data-dir=$ALT_DATA_DIR --index-sats index 2>&1 | grep -P 'reorg')

echo "$HEIGHT" > $ALT_DATA_DIR$NETWORK"/height"

echo "REORG is $REORG"

if [ -z "$REORG" ]
then
  # HARDLINK SWITCHER - 1
  rm $DEFAULT_DATA_DIR$NETWORK"/index.redb"
  ln $ALT_DATA_DIR$NETWORK"/index.redb" $DEFAULT_DATA_DIR$NETWORK"/index.redb"

  RUNNING=$(ps -fu $UID | grep "ord" | grep "data-dir" | grep -v "$SNAPSHOT_DATA_DIR" | grep "index-sats index")

  if [ ! -z "${RUNNING}" ]; then 
    echo "Still running.."
    # UNLOCK
    rm "$ALT_DATA_DIR$NETWORK/lock"
    exit
  fi

  echo "indexing" > $ALT_DUP_DATA_DIR$NETWORK"/height"

  REORG=$(ord@afwcxx "${ORD_CLI_OPTIONS[@]}" --data-dir=$ALT_DUP_DATA_DIR --index-sats index 2>&1 | grep -P 'reorg')

  echo "$HEIGHT" > $ALT_DUP_DATA_DIR$NETWORK"/height"

  # HARDLINK SWITCHER - 2
  rm $DEFAULT_DATA_DIR$NETWORK"/index.redb"
  ln $ALT_DUP_DATA_DIR$NETWORK"/index.redb" $DEFAULT_DATA_DIR$NETWORK"/index.redb"

  # UNLOCK
  rm "$ALT_DATA_DIR$NETWORK/lock"

  if test -f "$ALT_DATA_DIR$NETWORK/reorg"; then
    rm "$ALT_DATA_DIR$NETWORK/reorg"
  fi

  echo "Done.."
else
  echo "PENDING: Perform self reorg recovery"

  # UNLOCK
  rm "$ALT_DATA_DIR$NETWORK/lock"

  touch "$ALT_DATA_DIR$NETWORK/reorg"
  echo "Has reorg.."
fi
