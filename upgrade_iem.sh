#!/bin/bash

# matt.groves@demandscience.com
# Full linux-based upgrade of IEM

# Edit these settings to reflect your environment
IEM_ZIP='iem-8.1.0.zip'                 # Ensure this file is in your current working directory
IEM_URL='https://www.your.domain.com'   # The URL of your IEM installation
IEM_WEBROOT='/var/www/your.domain.com'  # Your installation directory and web root
BACKUP_DIR='/root/iem_backups'          # A new directory for working backups
IEM_USER='www-data'                     # User that the web server or web user runs as
IEM_GROUP='www-data'                    # Group that the web server or web user runs as

# Don't edit beyond this point
if [ -z ${IEM_ZIP} ] || [ -z ${IEM_URL} ] || [ -z ${IEM_WEBROOT} ] || [ -z ${BACKUP_DIR} ] || [ -z ${IEM_USER} ] || [ -z ${IEM_GROUP} ]; then
        echo "ERROR: Please ensure that all the variables have been set correctly in the script"
        exit
fi

# Script variables
DATE=`date +'%a-%b-%d-%Y-%H%M%S'`
IEM_DIR=`echo ${IEM_ZIP} | sed -e 's/\.zip//g'`
CHECK_IEM='https://www.interspire.com/downloads/check_iem.zip'  # Hosted by Interspire
ERROR=0

# Sanity checks
echo
echo "* IEM upgrade script - we recommend you take a full backup of your installation before proceeding *"
echo "Checking pre-requisites"
for BINARY in unzip wget tar ; do
        if ! BINARY_LOCATION="$(type -p "${BINARY}")" || [[ -z $BINARY_LOCATION ]]; then
                echo "ERROR: ${BINARY} not installed"
                ERROR=1
        fi
done
if [ ! -d "${IEM_WEBROOT}" ]; then
        echo "ERROR: Web root directory ${IEM_WEBROOT} does not exist"
        ERROR=1
fi
if [ ! -f "${IEM_ZIP}" ]; then
        echo "ERROR: IEM zip file ${IEM_ZIP} not found in current working directory"
        ERROR=1
fi
if [ ! USER="$(id ${IEM_USER})" ]; then
        echo "ERROR: Username ${IEM_USER} does not exist"
        ERROR=1
fi
if [ ! GROUP="$(id ${IEM_GROUP})" ]; then
        echo "ERROR: Username ${IEM_GROUP} does not exist"
        ERROR=1
fi

if [ "${ERROR}" -eq 1 ] ; then
        echo "Exiting due to issues outlined above"
        echo
        exit
fi

echo "Beginning upgrade process"
# Download check_iem.zip and ensure software requirements can be met
rm -f check_iem.php check_iem.zip ${IEM_WEBROOT}/check_iem.php
wget -q -4 ${CHECK_IEM}
if [ ! -f "check_iem.zip" ] ; then
        echo "ERROR: Download of ${CHECK_IEM} did not result in check_iem.zip - check and resolve"
        exit
fi

unzip -qq check_iem.zip
cp check_iem.php ${IEM_WEBROOT}/
chown ${IEM_USER}:${IEM_GROUP} ${IEM_WEBROOT}/check_iem.php
echo "Please browse to ${IEM_URL}/check_iem.php to ensure that all software requirements are met and press any key to continue or CTRL-C to exit"
read WAIT

echo "Continuing..."
echo "Creating backup of ${IEM_WEBROOT} to ${BACKUP_DIR}/backup.${DATE}.tar.gz"
mkdir -p ${BACKUP_DIR}
cd ${IEM_WEBROOT}
tar -zcfp ${BACKUP_DIR}/backup.${DATE}.tar.gz *
cd - > /dev/null 2>&1

echo "Backing up config.php to ${BACKUP_DIR}"
cp -f ${IEM_WEBROOT}/admin/includes/config.php ${BACKUP_DIR}/

echo "Creating temporary IEM working snapshot"
rm -rf /tmp/iem-temp/
mkdir -p /tmp/iem-temp
unzip -qq ${IEM_ZIP} -d /tmp/iem-temp/
mv /tmp/iem-temp/${IEM_DIR}/* /tmp/iem-temp/ && rmdir /tmp/iem-temp/${IEM_DIR}

echo "Copying existing configs"
cp -rf ${IEM_WEBROOT}/admin/com/storage/  /tmp/iem-temp/admin/com/
cp -f ${IEM_WEBROOT}/admin/includes/config.php  /tmp/iem-temp/admin/includes/
cp -rf ${IEM_WEBROOT}/admin/temp/  /tmp/iem-temp/admin/

echo "Setting ownership and permissions"
chown -R ${IEM_USER}:${IEM_GROUP} /tmp/iem-temp/*
chmod 644 /tmp/iem-temp/admin/includes/config.php
chmod 755 /tmp/iem-temp/admin/temp/ /tmp/iem-temp/admin/com/storage/

echo "Copying temporary IEM working snapshot to production webroot ${IEM_WEBROOT}"
cp -prf /tmp/iem-temp/admin/* ${IEM_WEBROOT}/
rm -rf /tmp/iem-temp/

echo
echo "Completed"
echo "Please clear your browser's cache and visit ${IEM_URL} to upgrade via the Upgrade Wizard"
echo
