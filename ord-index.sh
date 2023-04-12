#!/bin/bash
# Note:
# This index checking is only used for double database location
# where the one who is indexing will keep the data in a separate location.
# Once done with indexing, it should transfer to the original location

NETWORK="regtest" # Leave empty string for Mainnet
DEFAULT_DATA_DIR="/home/bitcoin/.local/share/ord/"
ALT_DATA_DIR="/home/bitcoin/ord-data/"

if ps -fu $UID | grep "ord" | grep "data-dir" | grep -q "index-sats index"
then 
   echo "Still running.."
else
   # Change the -r flag for NETWORK
   # -r : regtest
   # -t : regtest
   # <nothing> : mainnet

   echo "Begin indexing.."
   ord@afwcxx -r --data-dir=$ALT_ORD_DIR --index-sats index

   echo "Transferring to original location"
   \cp $ALT_DATA_DIR$NETWORK"/index.redb" $DEFAULT_DATA_DIR$NETWORK"/index.redb.new"
   mv -f $DEFAULT_DATA_DIR$NETWORK"/index.redb.new" $DEFAULT_DATA_DIR$NETWORK"/index.redb"

   echo "Done.."
fi

