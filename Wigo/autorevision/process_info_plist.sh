#!/bin/sh

echo ${SRCROOT}/Wigo/autorevision/autorevision.sh -s VCS_NUM
gitcount=`${SRCROOT}/Wigo/autorevision/autorevision.sh -s VCS_NUM`
githash=`${SRCROOT}/Wigo/autorevision/autorevision.sh -s VCS_SHORT_HASH`

plistBuddy="/usr/libexec/PlistBuddy"
infoPlist=${TEMP_DIR}"/Preprocessed-Info.plist"
$plistBuddy -c "Set GitHash $githash" $infoPlist
$plistBuddy -c "Set GitCount $gitcount" $infoPlist
