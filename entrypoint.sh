#!/usr/bin/env bash

getFirstSecretKey() {
    gpg -K --with-colons | awk -F: '/^sec:/ { print $5 ; exit }'
}

createNewKey() {
    cat <<EOF | gpg --batch --gen-key
    Key-Type: RSA
    Key-Length: 4096
    Subkey-Type: RSA
    Subkey-Length: 4096
    Name-Real: Duply
    Name-Email: backup@duply
    Expire-Date: 0
    Passphrase: $GPG_PASSPHRASE
    %commit
EOF
}

fixPermissions() {
    chown -R $(whoami) $GNUPGHOME
    chmod 600 $GNUPGHOME/*
    chmod 700 $GNUPGHOME
}

# we don't want the public/private key to stay in this container, if he is removed all backups are lost too
[ ! -d $GNUPGHOME ] && echo "$GNUPGHOME must be mounted as volume into this container!" && exit 1

# we don't check for the existence of $BACKUP_SOURCE, maybe a pre-script is used (for DB dumps etc) which creates it

echo "Initializing backup container..."
echo "Setting permissions for GPG homedir..."
fixPermissions

GPG_KEY_ID=$(getFirstSecretKey)

if [ -z $GPG_KEY_ID ]; then
    if [ -z $GPG_PASSPHRASE ]; then
	echo "No GPG_PASSPHRASE given, generating a random string..."
        export GPG_PASSPHRASE=$(pwgen 15)

	# no need to store the pw, it will be set in the duply profile
    fi

    echo "No GPG key found, creating a new one..."
    createNewKey

    GPG_KEY_ID=$(getFirstSecretKey)
else
    echo "Re-using existing key with ID $GPG_KEY_ID"
fi

# only if this folder exists duply will create the profile(s) there
mkdir -p /etc/duply

if [ -f /etc/duply/data/conf ]; then
    echo "Re-using existing Duply profile 'data'..."
else
    echo "Creating a new Duply profile 'data'..."
    duply data create

    # when the container is recreated the hostname changes, which will cause:
    # "Aborting because you may have accidentally tried to backup two different data sets to the same remote location"
    echo 'DUPL_PARAMS="$DUPL_PARAMS --allow-source-mismatch "' >> /etc/duply/data/conf
fi

echo "Setting key, passphrase, source & target in profile if not yet set..."
sed -i \
    -e "s#_KEY_ID_#$GPG_KEY_ID#g" \
    -e "s#_GPG_PASSWORD_#$GPG_PASSPHRASE#g" \
    -e "s#/path/of/source#$BACKUP_SOURCE#g" \
    -e "s#TARGET=.*#TARGET='$BACKUP_TARGET'#g" \
    -e "s/#GPG_OPTS=.*/GPG_OPTS='--pinentry-mode loopback'/g" \
    /etc/duply/data/conf

echo "Starting container command..."
exec "$@"
