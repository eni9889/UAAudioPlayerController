#!/bin/sh
set -e

RESOURCES_TO_COPY=${PODS_ROOT}/resources-to-copy-${TARGETNAME}.txt
> "$RESOURCES_TO_COPY"

install_resource()
{
  case $1 in
    *.storyboard)
      echo "ibtool --reference-external-strings-file --errors --warnings --notices --output-format human-readable-text --compile ${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$1\" .storyboard`.storyboardc ${PODS_ROOT}/$1 --sdk ${SDKROOT}"
      ibtool --reference-external-strings-file --errors --warnings --notices --output-format human-readable-text --compile "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$1\" .storyboard`.storyboardc" "${PODS_ROOT}/$1" --sdk "${SDKROOT}"
      ;;
    *.xib)
        echo "ibtool --reference-external-strings-file --errors --warnings --notices --output-format human-readable-text --compile ${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$1\" .xib`.nib ${PODS_ROOT}/$1 --sdk ${SDKROOT}"
      ibtool --reference-external-strings-file --errors --warnings --notices --output-format human-readable-text --compile "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$1\" .xib`.nib" "${PODS_ROOT}/$1" --sdk "${SDKROOT}"
      ;;
    *.framework)
      echo "mkdir -p ${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      mkdir -p "${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      echo "rsync -av ${PODS_ROOT}/$1 ${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      rsync -av "${PODS_ROOT}/$1" "${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      ;;
    *.xcdatamodel)
      echo "xcrun momc \"${PODS_ROOT}/$1\" \"${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$1"`.mom\""
      xcrun momc "${PODS_ROOT}/$1" "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$1" .xcdatamodel`.mom"
      ;;
    *.xcdatamodeld)
      echo "xcrun momc \"${PODS_ROOT}/$1\" \"${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$1" .xcdatamodeld`.momd\""
      xcrun momc "${PODS_ROOT}/$1" "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$1" .xcdatamodeld`.momd"
      ;;
    *.xcassets)
      ;;
    /*)
      echo "$1"
      echo "$1" >> "$RESOURCES_TO_COPY"
      ;;
    *)
      echo "${PODS_ROOT}/$1"
      echo "${PODS_ROOT}/$1" >> "$RESOURCES_TO_COPY"
      ;;
  esac
}
install_resource "../../Pod/Assets/Images/AudioPlayerNoArtwork.png"
install_resource "../../Pod/Assets/Images/player-airplay.png"
install_resource "../../Pod/Assets/Images/player-airplay@2x.png"
install_resource "../../Pod/Assets/Images/player-backward.png"
install_resource "../../Pod/Assets/Images/player-backward@2x.png"
install_resource "../../Pod/Assets/Images/player-bar-shadow.png"
install_resource "../../Pod/Assets/Images/player-bar-shadow@2x.png"
install_resource "../../Pod/Assets/Images/player-equalizer-off.png"
install_resource "../../Pod/Assets/Images/player-equalizer-off@2x.png"
install_resource "../../Pod/Assets/Images/player-equalizer-on.png"
install_resource "../../Pod/Assets/Images/player-equalizer-on@2x.png"
install_resource "../../Pod/Assets/Images/player-forward.png"
install_resource "../../Pod/Assets/Images/player-forward@2x.png"
install_resource "../../Pod/Assets/Images/player-pause.png"
install_resource "../../Pod/Assets/Images/player-pause@2x.png"
install_resource "../../Pod/Assets/Images/player-play.png"
install_resource "../../Pod/Assets/Images/player-play@2x.png"
install_resource "../../Pod/Assets/Images/player-playlist.png"
install_resource "../../Pod/Assets/Images/player-playlist@2x.png"
install_resource "../../Pod/Assets/Images/player-repeat-all.png"
install_resource "../../Pod/Assets/Images/player-repeat-all@2x.png"
install_resource "../../Pod/Assets/Images/player-repeat-none.png"
install_resource "../../Pod/Assets/Images/player-repeat-none@2x.png"
install_resource "../../Pod/Assets/Images/player-repeat-one.png"
install_resource "../../Pod/Assets/Images/player-repeat-one@2x.png"
install_resource "../../Pod/Assets/Images/player-shuffle-off.png"
install_resource "../../Pod/Assets/Images/player-shuffle-off@2x.png"
install_resource "../../Pod/Assets/Images/player-shuffle-on.png"
install_resource "../../Pod/Assets/Images/player-shuffle-on@2x.png"
install_resource "../../Pod/Assets/Images/player-volume-ios6.png"
install_resource "../../Pod/Assets/Images/player-volume-ios6@2x.png"
install_resource "../../Pod/Assets/Images/player-volume.png"
install_resource "../../Pod/Assets/Images/player-volume@2x.png"
install_resource "../../Pod/Assets/Images/player_progress_max.png"
install_resource "../../Pod/Assets/Images/player_progress_max@2x.png"
install_resource "../../Pod/Assets/Images/player_progress_middle.png"
install_resource "../../Pod/Assets/Images/player_progress_middle@2x.png"
install_resource "../../Pod/Assets/Images/player_progress_min.png"
install_resource "../../Pod/Assets/Images/player_progress_min@2x.png"
install_resource "../../Pod/Assets/Images/player_progress_thumb.png"
install_resource "../../Pod/Assets/Images/player_progress_thumb@2x.png"
install_resource "../../Pod/Assets/Images/player_volumeimage_max.png"
install_resource "../../Pod/Assets/Images/player_volumeimage_max@2x.png"
install_resource "../../Pod/Assets/Images/player_volumeimage_min.png"
install_resource "../../Pod/Assets/Images/player_volumeimage_min@2x.png"
install_resource "../../Pod/Assets/Images/player_volumeslider_max.png"
install_resource "../../Pod/Assets/Images/player_volumeslider_max@2x.png"
install_resource "../../Pod/Assets/Images/player_volumeslider_min.png"
install_resource "../../Pod/Assets/Images/player_volumeslider_min@2x.png"
install_resource "../../Pod/Assets/Nibs/UAAudioPlayerController.xib"

rsync -avr --copy-links --no-relative --exclude '*/.svn/*' --files-from="$RESOURCES_TO_COPY" / "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
if [[ "${ACTION}" == "install" ]]; then
  rsync -avr --copy-links --no-relative --exclude '*/.svn/*' --files-from="$RESOURCES_TO_COPY" / "${INSTALL_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
fi
rm -f "$RESOURCES_TO_COPY"

if [[ -n "${WRAPPER_EXTENSION}" ]] && [ `xcrun --find actool` ] && [ `find . -name '*.xcassets' | wc -l` -ne 0 ]
then
  case "${TARGETED_DEVICE_FAMILY}" in 
    1,2)
      TARGET_DEVICE_ARGS="--target-device ipad --target-device iphone"
      ;;
    1)
      TARGET_DEVICE_ARGS="--target-device iphone"
      ;;
    2)
      TARGET_DEVICE_ARGS="--target-device ipad"
      ;;
    *)
      TARGET_DEVICE_ARGS="--target-device mac"
      ;;  
  esac 
  find "${PWD}" -name "*.xcassets" -print0 | xargs -0 actool --output-format human-readable-text --notices --warnings --platform "${PLATFORM_NAME}" --minimum-deployment-target "${IPHONEOS_DEPLOYMENT_TARGET}" ${TARGET_DEVICE_ARGS} --compress-pngs --compile "${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
fi
