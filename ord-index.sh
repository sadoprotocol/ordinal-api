#!/bin/bash
# Note:
# This index checking is only used for double database location
# where the one who is indexing will keep the data in a separate location.
# Once done with indexing, it should transfer to the original location

# TODO
NETWORK="regtest" # OR "testnet3", "" for Mainnet
DEFAULT_DATA_DIR="/home/bitcoin-regtest/.local/share/ord/"
ALT_DATA_DIR="/home/bitcoin-regtest/ord-data/"

if ps -fu $UID | grep "ord" | grep "data-dir" | grep -q "index-sats index"
then 
  echo "Still running.."
  exit
fi

if test -f "$ALT_DATA_DIR$NETWORK/lock"; then
  echo "Process not finished.."
  exit
fi

touch "$ALT_DATA_DIR$NETWORK/lock"

# TODO
HEIGHT=$(bitcoin-cli --regtest getblockcount)

echo "HEIGHT is $HEIGHT"

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
  MOD=$(expr $HEIGHT % 5)

  echo "MOD is $MOD"

  if [ $MOD -eq 0 ];
  then
    STALE=$(expr $HEIGHT - 50)
    STALEMIN=$(expr $HEIGHT - 1000)
    echo "STALE is $STALE"
    echo "STALEMIN is $STALEMIN"
    echo "Creating snapshot"
    \cp $ALT_DATA_DIR$NETWORK"/index.redb" $ALT_DATA_DIR$NETWORK"/index.redb.$HEIGHT"

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

  echo "Transferring to original location"
  \cp $ALT_DATA_DIR$NETWORK"/index.redb" $DEFAULT_DATA_DIR$NETWORK"/index.redb.new"
  mv -f $DEFAULT_DATA_DIR$NETWORK"/index.redb.new" $DEFAULT_DATA_DIR$NETWORK"/index.redb"

  if test -f "$ALT_DATA_DIR$NETWORK/reorg"; then
    rm "$ALT_DATA_DIR$NETWORK/reorg"
  fi

  echo "Done.."
else
  touch "$ALT_DATA_DIR$NETWORK/reorg"
  echo "Has reorg.."
fi

rm "$ALT_DATA_DIR$NETWORK/lock"
