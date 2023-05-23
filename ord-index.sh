#!/bin/bash
# Note:
# This index checking is only used for double database location
# where the one who is indexing will keep the data in a separate location.
# Once done with indexing, it should transfer to the original location

# TODO
NETWORK="regtest" # OR "testnet3", "" for Mainnet
DEFAULT_DATA_DIR="/home/bitcoin-regtest/.local/share/ord/"
ALT_DATA_DIR="/home/bitcoin-regtest/ord-data/"
ALT_DUP_DATA_DIR="/home/bitcoin-regtest/ord-data-dup/"

if ps -fu $UID | grep "ord" | grep "data-dir" | grep -q "index-sats index"
then 
  echo "Still running.."
  exit
fi

if test -f "$ALT_DATA_DIR$NETWORK/lock"; then
  echo "Process not finished.."
  exit
fi

# LOCK
touch "$ALT_DATA_DIR$NETWORK/lock"


# == SETUP

mkdir -p $ALT_DATA_DIR$NETWORK

if [ ! -f $ALT_DATA_DIR$NETWORK"/index.redb" ]
then
  rsync -a $DEFAULT_DATA_DIR$NETWORK"/index.redb" $ALT_DATA_DIR$NETWORK"/index.redb"
fi

# ==

mkdir -p $ALT_DUP_DATA_DIR$NETWORK

if [ ! -f $ALT_DUP_DATA_DIR$NETWORK"/index.redb" ]
then
  rsync -a $DEFAULT_DATA_DIR$NETWORK"/index.redb" $ALT_DUP_DATA_DIR$NETWORK"/index.redb"
fi

# SETUP END ==


# TODO
HEIGHT=$(bitcoin-cli --regtest getblockcount)

echo "HEIGHT is $HEIGHT"

# HARDLINK SWITCHER - 2
rm $DEFAULT_DATA_DIR$NETWORK"/index.redb"
ln $ALT_DUP_DATA_DIR$NETWORK"/index.redb" $DEFAULT_DATA_DIR$NETWORK"/index.redb"

echo "Begin indexing.."
# TODO
# Change the -r flag for NETWORK
# -r : regtest
# -t : testnet3
# <nothing> : mainnet
REORG=$(ord@afwcxx -r --data-dir=$ALT_DATA_DIR --index-sats index 2>&1 | grep -P 'reorg')

echo "REORG is $REORG"

if [ -z "$REORG" ]
then
  # HARDLINK SWITCHER - 1
  rm $DEFAULT_DATA_DIR$NETWORK"/index.redb"
  ln $ALT_DATA_DIR$NETWORK"/index.redb" $DEFAULT_DATA_DIR$NETWORK"/index.redb"

  # TODO
  # Change the -r flag for NETWORK
  # -r : regtest
  # -t : testnet3
  # <nothing> : mainnet
  REORG=$(ord@afwcxx -r --data-dir=$ALT_DUP_DATA_DIR --index-sats index 2>&1 | grep -P 'reorg')

  # HARDLINK SWITCHER - 2
  rm $DEFAULT_DATA_DIR$NETWORK"/index.redb"
  ln $ALT_DUP_DATA_DIR$NETWORK"/index.redb" $DEFAULT_DATA_DIR$NETWORK"/index.redb"

  # SNAPSHOT PROCESS
  MOD=$(expr $HEIGHT % 30)

  echo "MOD is $MOD"

  if [ $MOD -eq 0 ];
  then
    STALE=$(expr $HEIGHT - 100)
    STALEMIN=$(expr $HEIGHT - 1000)
    echo "STALE is $STALE"
    echo "STALEMIN is $STALEMIN"
    echo "Creating snapshot"
    rsync -a $ALT_DATA_DIR$NETWORK"/index.redb" $ALT_DATA_DIR$NETWORK"/index.redb.$HEIGHT"

    while [ $STALE -ge $STALEMIN ]
    do
      echo "CURRENT STALE is $STALE"
      if test -f "$ALT_DATA_DIR$NETWORK/index.redb.$STALE"; then
        echo "Removing stale $STALE"
        rm $ALT_DATA_DIR$NETWORK"/index.redb.$STALE"
        echo "Removed stale"
      fi
      ((STALE=STALE-1))
    done
  fi

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
