#!/bin/bash


BASE_SIMULATORS_PATH="$HOME/Library/Developer/CoreSimulator/Devices" # for now anyway
BASE_BUILD_PATH=$1
# will be supplied as something like "/Users/doughty/Library/Developer/Xcode/DerivedData/Wigo-gummklvhuhwfipgjqtbknjblupar/Build/Products"


# Allow us to use spaces in quoted file names in Bash Shell,
# per http://stackoverflow.com/a/1724065/535054 (See Dennis Williamson's comment):
_save_and_clear_internal_field_separator() {
    saveIFS="$IFS"; IFS='';
}


# Revert to the pre-existing IFS shell variable value so as not to leave shell with unintended side effects.
_restore_prior_interal_field_separator() {
    IFS="$saveIFS"
}

_find_specific_simulator() {
    # Reanimate command line parameters into nicely named variables:
    local base_simulators_path=$1  # The path that is the root of the various simulators that could be installed.
    local simulator_name=$2  # The custom simulator a user can give different simulator configurations, since the Xcode 6.0.1 iOS Simulator app

    # Construct the line we'll look for an exact match to in the plist file:
    local simulator_plist_line_to_match="<string>$simulator_name</string>"

    # Loop through all devices to figure out which is a match
    for SIMULATOR_DEVICE_DIRECTORY in ${base_simulators_path}/*; do
        # Retrieve the number of matches to our search string in the 'device.plist' file in the iterated simulator directory:
        local num_matches=$(grep "$simulator_plist_line_to_match" "$SIMULATOR_DEVICE_DIRECTORY"/device.plist | wc -l)

        # Did this directory return one match?
        if [ ${num_matches} -eq 1 ]; then
            # MATCHING_UDID=$(basename ${SIMULATOR_DEVICE_DIRECTORY})
            # Our return value is the full path of the matching simulator:
            local specific_simulator_path_found=${SIMULATOR_DEVICE_DIRECTORY}
            echo "$specific_simulator_path_found"
            return # We got what we came for; this confirms that we're going to use the simulator
        fi
    done

    echo "Simulator Not Found" # Signifies that no matching simulator could be found.
}

for SIMULATOR_NAME in Katniss Peeta
do
SIMULATOR=`_find_specific_simulator ${BASE_SIMULATORS_PATH} ${SIMULATOR_NAME}`
UDID=${SIMULATOR##*Devices/}

open -a "iOS Simulator" --args -CurrentDeviceUDID ${UDID}

sleep 10

# open /Applications/Xcode.app/Contents/Developer/Applications/iOS\ Simulator.app
# xcrun simctl boot ${UDID}

# we need to figure out where the app got built.  Presumably that's passed into this script, just like "iPhone 5s" should be above
xcrun simctl install ${UDID} ${BASE_BUILD_PATH}/Debug-iphonesimulator/wigo.app

osascript -e 'tell app "iOS Simulator" to quit'
done
