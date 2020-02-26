#!/bin/bash
set -x

key_id=`gpg2 --list-keys --keyid-format LONG "MariaDB Platform QA" | sed -n 2p | sed "s/ //g"`
key_grip=`gpg2 --with-keygrip -K ${key_id} | grep "Keygrip" | sed -n 1p | sed "s/Keygrip =//" | sed "s/ //g"`

/usr/lib/gnupg2/gpg-preset-passphrase --preset --passphrase $PASSPHRASE ${key_grip}


