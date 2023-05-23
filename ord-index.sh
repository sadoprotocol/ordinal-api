#!/bin/bash
# Note:
# This index checking is only used for double database location
# where the one who is indexing will keep the data in a separate location.
# Once done with indexing, it should transfer to the original location

if [ ! -f "./.ord-index-config" ]
then
  echo "No config file found.."
  exit
fi

source "./.ord-index-config"

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

# ==

BITCOIN_CLI_OPTIONS=()
ORD_CLI_OPTIONS=()

if [ $NETWORK = "regtest" ]; then
  BITCOIN_CLI_OPTIONS=( --regtest )
  ORD_CLI_OPTIONS=( -r )
elif [ $NETWORK = "testnet3" ]; then
  BITCOIN_CLI_OPTIONS=( --testnet )
  ORD_CLI_OPTIONS=( -t )
elif [ $NETWORK = "" ]; then
  BITCOIN_CLI_OPTIONS=()
  ORD_CLI_OPTIONS=()
else
  echo "Invalid network"
  exit
fi


# SETUP END ==


HEIGHT=$(bitcoin-cli "${BITCOIN_CLI_OPTIONS[@]}" getblockcount)

echo "HEIGHT is $HEIGHT"

# HARDLINK SWITCHER - 2
rm $DEFAULT_DATA_DIR$NETWORK"/index.redb"
ln $ALT_DUP_DATA_DIR$NETWORK"/index.redb" $DEFAULT_DATA_DIR$NETWORK"/index.redb"

echo "Begin indexing.."

REORG=$(ord@afwcxx "${ORD_CLI_OPTIONS[@]}" --data-dir=$ALT_DATA_DIR --index-sats index 2>&1 | grep -P 'reorg')

echo "REORG is $REORG"

if [ -z "$REORG" ]
then
  # HARDLINK SWITCHER - 1
  rm $DEFAULT_DATA_DIR$NETWORK"/index.redb"
  ln $ALT_DATA_DIR$NETWORK"/index.redb" $DEFAULT_DATA_DIR$NETWORK"/index.redb"

  REORG=$(ord@afwcxx "${ORD_CLI_OPTIONS[@]}" --data-dir=$ALT_DUP_DATA_DIR --index-sats index 2>&1 | grep -P 'reorg')

  # HARDLINK SWITCHER - 2
  rm $DEFAULT_DATA_DIR$NETWORK"/index.redb"
  ln $ALT_DUP_DATA_DIR$NETWORK"/index.redb" $DEFAULT_DATA_DIR$NETWORK"/index.redb"

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
    rsync -a $ALT_DATA_DIR$NETWORK"/index.redb" $ALT_DATA_DIR$NETWORK"/index.redb.$HEIGHT"

    while [ $STALE -ge $STALEMAX ]
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
