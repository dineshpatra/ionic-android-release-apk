#!/bin/sh
# =======================================================
# File to generate android release apk with verification 
#
# @Author:
#	Dinesh Patra <dineshpatra@invincix.com>
#   Ram Krishna  <ramk0713@gmail.com>
# ========================================================
# 1. change the version in config.xml & package.json
# 2. config.xml:
# 		<widget id="com.afdbam2019.www" version="1.0.2" xmlns="http://www.w3.org/ns/widgets" xmlns:cdv="http://cordova.apache.org/ns/1.0">
#    package.json:
#	    "version": "1.0.2",
# 3. If no android platform found
#    ionic cordova platform add android
# 4. If no resource generated
#    ionic cordova resources android
#

APK_FILE_NAME=RELEASE_APK_FILE_NAME
APK_VERSION=1.0.0
APK_RELEASE_DIR=apk

# keytool description
ORGANIZATION_UNIT="organization unit"
ORGANIZATION_NAME="organization name" 
FIRST_AND_LAST_NAME="first and last name" 
LOCALITY="locality"
PROVINCE="province/state"
COUNTRY_CODE="2 digit country code"

APK_JKS_FILE_NAME=JKS_FILE_NAME
APK_JKS_ALIAS=JKS ALIAS
ANDROID_JKS=${APK_RELEASE_DIR}/${APK_JKS_FILE_NAME}.jks
JKS_PASSWORD=AfDBDigitalPlatform@2019!

# ionic set up 
IONIC_ANDROID_UNSIGNED_APK=platforms/android/app/build/outputs/apk/release/app-release-unsigned.apk
IONIC_ANDROID_SIGNED_APK=${APK_RELEASE_DIR}/${APK_FILE_NAME}-v${APK_VERSION}.apk


log_message()
{
	current_date=$(date '+%A %W %Y %X')
	echo "[IONIC CORDOVA ANDROID RELEASE][${current_date}] $1"
} 

# If directory does not exist,
# create a new directory
if [ ! -d "${APK_RELEASE_DIR}" ]
then 
	log_message "${APK_RELEASE_DIR} directory does not exist. creating it."
	mkdir ${APK_RELEASE_DIR}
fi

# Give a production release
#echo "Generating android cordova production release"
#ionic cordova build android --prod --release

log_message "Checking JKS file ${ANDROID_JKS}."
keytool_check="$(keytool -list\
                         -keystore ${APK_RELEASE_DIR}/${APK_JKS_FILE_NAME}.jks\
                         -alias ${APK_JKS_ALIAS}\
                         -keypass ${JKS_PASSWORD}\
                         -storepass ${JKS_PASSWORD}
)"

if [[ ${keytool_check} == ${APK_JKS_ALIAS}* ]]
then
	log_message "Already keytool alias ${APK_JKS_ALIAS} exists."
else
	log_message "keytool alias ${APK_JKS_ALIAS} does not exists. trying to create one."
	keytool -genkey -v -keystore ${APK_RELEASE_DIR}/${APK_JKS_FILE_NAME}.jks\
            -keyalg RSA -keysize 2048 -validity 10000 -alias ${APK_JKS_ALIAS}\
            -keypass ${JKS_PASSWORD} -storepass ${JKS_PASSWORD}
            -dname "CN=${FIRST_AND_LAST_NAME}, OU=${ORGANIZATION_UNIT}, O=${ORGANIZATION_NAME}, L=${LOCALITY}, S=${PROVINCE}, C=${COUNTRY_CODE}"

fi

# Doing jar signer
log_message "Jar signing."
jarsigner -verbose \
          -sigalg SHA1withRSA \
          -digestalg SHA1 \
          -keystore ${ANDROID_JKS} ${IONIC_ANDROID_UNSIGNED_APK} ${APK_JKS_ALIAS} \
          -keypass ${JKS_PASSWORD} \
          -storepass ${JKS_PASSWORD}
log_message "Jar signing completed."

# Optimizing the jar
log_message "Optimizing jar via zipalign."
apk_file_name=${APK_RELEASE_DIR}/${APK_FILE_NAME}.apk
rm -f ${apk_file_name}
zipalign -v 4 ${IONIC_ANDROID_UNSIGNED_APK} ${apk_file_name
log_message "Completed Optimizing jar via zipalign."

# verifying the app
log_message "Verifying the apk."
apksigner verify ${apk_file_name}
log_message "Verification completed."

# generate zip file
log_message "Generating new zip file."
echo ${JKS_PASSWORD} >> ${APK_RELEASE_DIR}/jks_password.txt
rm -f ${APK_RELEASE_DIR}-v${APK_VERSION}.zip
zip -r ${APK_RELEASE_DIR}-v${APK_VERSION}.zip ${APK_RELEASE_DIR}
log_message "Completed======."

 
