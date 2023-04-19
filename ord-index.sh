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

echo "Begin indexing.."
# TODO
# Change the -r flag for NETWORK
# -r : regtest
# -t : testnet3
# <nothing> : mainnet
REORG=$(ord@afwcxx -r --data-dir=$ALT_DATA_DIR --index-sats index | grep -P 'reorg')

echo "REORG is $REORG"

if [ -z "$REORG" ]
then
  # TODO
  HEIGHT=$(bitcoin-cli --regtest getblockcount)

  echo "HEIGHT is $HEIGHT"

  MOD=$(expr $HEIGHT % 5)

  echo "MOD is $MOD"

  if [ $MOD -eq 0 ];
  then
    STALE=$(expr $HEIGHT - 50)
    echo "STALE is $STALE"
    echo "Creating snapshot"
    \cp $ALT_DATA_DIR$NETWORK"/index.redb" $ALT_DATA_DIR$NETWORK"/index.redb.$HEIGHT"

    if test -f "$ALT_DATA_DIR$NETWORK/index.redb.$STALE"; then
      echo "Removing stale"
      rm $ALT_DATA_DIR$NETWORK"/index.redb.$STALE"
      echo "Removed stale"
    fi

  fi

  echo "Transferring to original location"
  \cp $ALT_DATA_DIR$NETWORK"/index.redb" $DEFAULT_DATA_DIR$NETWORK"/index.redb.new"
  mv -f $DEFAULT_DATA_DIR$NETWORK"/index.redb.new" $DEFAULT_DATA_DIR$NETWORK"/index.redb"

  echo "Done.."
else
  echo "Has reorg.."
fi

rm "$ALT_DATA_DIR$NETWORK/lock"
