#!/bin/bash

# Log Message Function
info () {
  printf "\r  [\033[00;34m..\033[0m] $1\n"
}

success () {
  printf "\r\033[2K [\033[00;32mOK\033[0m] $1\n"
  echo $line
}

fail () {
  printf "\r\033[2K [\033[0;31mFAIL\033[0m] $1\n"
  echo ''
  exit
}

install_android_sdk() {
  read -r -p "Do you want to install android sdk? [y|N] " response
  if [[ $response =~ (y|yes|Y) ]];then
    brew tap caskroom/cask
    brew cask install android-sdk
    success "Installed Android SDK"
  fi
}

install_gralde() {
  read -r -p "Do you want to install gradle? [y|N] " response
  if [[ $response =~ (y|yes|Y) ]];then
    brew install gradle
    success "Installed gralde"
  fi
}

install_pod() {
  read -r -p "Do you want to install pod? [y|N] " response
  if [[ $response =~ (y|yes|Y) ]];then
    brew install pod
    success "Installed pod"
  fi
}

# Prepare input env and name build, app
info "Please input environment of the android build (dev | prod | uat)"
read ENV_BUILD
echo $line
info "Please input name of the build"
read NAME_BUILD
echo $line
info "Please input name of the app ios"
read NAME_APP_IOS
echo $line

# Current Project DIR
PROJECT_DIR=$PWD


# Check Build Folder Exits or Not
[ ! -d "$PROJECT_DIR/build" ] && mkdir $PROJECT_DIR/build
[ ! -d "$PROJECT_DIR/build/ios" ] && mkdir $PROJECT_DIR/build/ios
[ ! -d "$PROJECT_DIR/build/android" ] && mkdir $PROJECT_DIR/build/android

# Build IOS App
echo "***********************************************************"
info "IOS App is Building Now ...."
echo "***********************************************************"
echo $line

# Set Schema To Build
info "Please input name of the schema you want to build for ios app"
read NAME_SCHEMA
echo $line

# Install Pod Directory
read -r -p "Do you want to run pod install in ios dir? [y|N] " response
if [[ $response =~ (y|yes|Y) ]];then
  cd $PROJECT_DIR/ios
  pod install
  success "Pod Install Successful"
fi

# Set IOS Project DIR
cd $PROJECT_DIR
BUILD_IOS_DIR=$PROJECT_DIR/build/ios/
rm -rf $BUILD_IOS_DIR/$NAME_BUILD
mkdir $BUILD_IOS_DIR/$NAME_BUILD
success "Set Build Ios Directory App Successful"

#Archiving App
xcodebuild -workspace ios/thmtlphoenix.xcworkspace -scheme $NAME_SCHEMA -destination generic/platform=iOS -configuration EnterpriseDistribution archive -archivePath $BUILD_IOS_DIR/$NAME_BUILD/archive/CLI.xcarchive

xcodebuild -exportArchive -archivePath $BUILD_IOS_DIR/$NAME_BUILD/archive/CLI.xcarchive -exportOptionsPlist $PROJECT_DIR/scripts/key.plist -exportPath $BUILD_IOS_DIR/$NAME_BUILD

success "Archiving App Successfully"

#Remove Reduant Files
rm -rf $BUILD_IOS_DIR/$NAME_BUILD/archive
cd $BUILD_IOS_DIR/$NAME_BUILD
rm *.plist
rm *.log
mv *.ipa $NAME_APP_IOS.ipa
success "Successful Remove Reduant File"

success "Build IOS App Successful"

# Build Android App
echo "***********************************************************"
info "Android App is Building Now ...."
echo "***********************************************************"
echo $line

# Make Sure ANDROID_HOME PATH has available
install_android_sdk
export ANDROID_HOME=$HOME/Library/Android/sdk
success "Set ANDROID_HOME Successful"

# Set Android Project DIR
ANDROID_RELEASE_DIR=$PROJECT_DIR/android/app/build/outputs/apk
BUILD_ANDROID_DIR=$PROJECT_DIR/build/android/
rm -rf $BUILD_ANDROID_DIR/$NAME_BUILD
mkdir $BUILD_ANDROID_DIR/$NAME_BUILD
success "Set Build Android Directory App Successful"

# Clean App
cd $PROJECT_DIR/android
install_gralde
gradle clean
cd $PROJECT_DIR
success "Clean App Successful"

# Remove Release Folder
cd $ANDROID_RELEASE_DIR
rm -rf release
success "Remove Old Release Folder Successful"

# Build Project
cd $PROJECT_DIR
npx jetify
ENVFILE=.env.$ENV_BUILD npx react-native run-android --variant=release
success "Build Android App Successful"

# Copy To build Folder
cd $ANDROID_RELEASE_DIR/release
cp *.apk $BUILD_ANDROID_DIR/$NAME_BUILD
success "Copy To Build Android Folder Successful"

exit

