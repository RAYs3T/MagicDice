#!/bin/bash

# This script is intended to update the plugin version of MagicDice
# that is installed on a gameserver.
# It just downloads the newest version and tries to merge it on the
# one that is existing on the gameserver

BASE_UPDATE_URL="https://gitlab.com/PushTheLimits/Sourcemod/MagicDice"
PACKAGE_CORE="${BASE_UPDATE_URL}/-/jobs/artifacts/master/download?job=build%3Acore"
PACKAGE_MODULES="${BASE_UPDATE_URL}/-/jobs/artifacts/master/download?job=build%3Amodules"
DOWNLOAD_CACHE="./magicdice_download_cache"
DOWNLOAD_CACHE_PATCH="${DOWNLOAD_CACHE}/patch"
GAMESERVER_DIRECTORY="$1"

function print_usage ()
{
    echo "You can use this script to update/install MagicDice on your gameserver."
    echo ""
    echo "Usage: "
    echo "$0 <server directory>"
}

function wipe_download_cache()
{
    echo "Wipe download cache ..."
    rm -rf "${DOWNLOAD_CACHE}"
}

################
# Start Script #
################


if [ -z "${GAMESERVER_DIRECTORY}" ]
then
    echo >&2 "You have to specify a server directory which you want to update"
    print_usage
    exit 1
fi

if [ ! -d "${GAMESERVER_DIRECTORY}" ]
then
    echo >&2 "The server directory '${GAMESERVER_DIRECTORY}' does not exists or is not accessible"
    exit 1
fi

# Check if this relly is a gameserver installation
if [ ! -d "${GAMESERVER_DIRECTORY}/cstrike" ]
then
    echo >&2 "The gameserver directory does not include a cstrike folder. Is this really a gameserver directory?!"
    exit 1
fi

OLD_VERSION_PRESENT=0
if [ ! -f "${GAMESERVER_DIRECTORY}/cstrike/addons/sourcemod/plugins/magicdice.smx" ]
then
    echo "No previous installation of MagicDice found. Performing a fresh install ..."
    OLD_VERSION_PRESENT=0
else
    echo "Found a installed version of MagicDice! keeping configs ..."
    OLD_VERSION_PRESENT=1
fi

# Check if wget is present
command -v wget >/dev/null 2>&1 || { echo >&2 "I require wget but it's not installed.  Aborting."; exit 1; }

# Check if unzip is present
command -v unzip >/dev/null 2>&1 || { echo >&2 "I require unzip but it's not installed.  Aborting."; exit 1; }


wipe_download_cache

ZIP_CORE="${DOWNLOAD_CACHE}/core.zip"
ZIP_MODULES="${DOWNLOAD_CACHE}/modules.zip"

# Try to download new packages
mkdir -p "${DOWNLOAD_CACHE}" || { echo >&2 "Unable to create download cache ${DOWNLOAD_CACHE} Aborting."; exit 1; }

echo "Downloading core ..."
wget  -O"${ZIP_CORE}" "${PACKAGE_CORE}" || { echo >&2 "Unable to download core!"; exit 1; }

echo "Downloading modules ..."
wget  -O"${ZIP_MODULES}" "${PACKAGE_MODULES}" || { echo >&2 "Unable to download modules!"; exit 1; }

# Decompress
echo "Decompressing core ..."
unzip -o "${ZIP_CORE}" "package/*" -d "${DOWNLOAD_CACHE_PATCH}" || { echo >&2 "Unable to unzip core!"; exit 1; }
echo "Decompressing modules ..."
unzip -o "${ZIP_MODULES}"  "package/*" -d "${DOWNLOAD_CACHE_PATCH}" || { echo >&2 "Unable to unzip modules!"; exit 1; }

DOWNLOAD_CACHE_DEPLOY_PACKAGE="${DOWNLOAD_CACHE_PATCH}/package"
echo "Files to deploy located in: ${DOWNLOAD_CACHE_DEPLOY_PACKAGE}"

# Remove config when already present
if [ "${OLD_VERSION_PRESENT}" -gt 0 ]
then
    echo "Old version is present, removing configs in new installation ..."
    find "${DOWNLOAD_CACHE_DEPLOY_PACKAGE}" -name '*.cfg' -exec rm -rf {} \;
else
    echo "No old installation present, performing a full install ..."
fi

echo "Copy files over gameserver ..."
cp -r ${DOWNLOAD_CACHE_DEPLOY_PACKAGE}/* ${GAMESERVER_DIRECTORY}/cstrike

wipe_download_cache
echo "Done."