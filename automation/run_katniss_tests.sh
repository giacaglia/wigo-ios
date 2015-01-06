#!/bin/bash

# run_tests.sh
# Created by Sohail Ahmed
# @idStar

# This script is a companion to the script ui_automation_runner.sh, which is designed not to be edited.
# In this very script however, you'll actually modify some variables below to specify values for
# what you would like run, where to find your test, where to dump results, etc.


# ===== DEVICES AND SIMULATORS =====

# Define all of your simulators and devices here.

# ===== REACHING THE TEST RUNNER =====

# You may choose to keep this app specific script co-located with your app, and your copy of the
# ui_automation_runner script in some other more generic location. Whatever you choose, that needs to be reflected
# as an absolute or relative path to the current file:
AUTOMATION_RUNNER_SCRIPT_PATH="./ui_automation_runner.sh"


# ===== YOUR APP AND TEST FILE SETTINGS =====

# The name of your app. Use your Xcode project name. This is not necessarily the icon display name visible in Springboard.
# Leave off the ".app" extension so that you can reference the same app name when switching between device and simulator.
TEST_APP_NAME="wigo"
# Set which simulator or device you want Instruments Automation to run with:
KATNISS=`./find_simulator.sh Katniss`
SIMULATOR_NAME_OR_DEVICE_UDID=${KATNISS##*Devices/}

# The directory in which we can find the test file you'll specify below:
JAVASCRIPT_TEST_FILES_DIRECTORY="${PWD}/scripts/"

# The JavaScript test file you'd like to run. For a suite of tests, have this file simply import and
# execute other JavaScript tests, so that you can conceivably run a full suite of tests with one command:
JAVASCRIPT_TEST_FILE="test_katniss_going_out.js"

# The directory into which the instruments command line tool should dump its verbose output:
TEST_RESULTS_OUTPUT_PATH="${PWD}/test_runs/"

if [ ! -d ${TEST_RESULTS_OUTPUT_PATH} ]; then
  mkdir ${TEST_RESULTS_OUTPUT_PATH}
fi

open -a "iOS Simulator" --args -CurrentDeviceUDID ${SIMULATOR_NAME_OR_DEVICE_UDID}

sleep 10

function cleanup {
  osascript -e 'tell app "iOS Simulator" to quit'
}

trap cleanup EXIT

# ---------- DO NOT EDIT ANYTHING BELOW THIS LINE, UNLESS YOU KNOW WHAT YOU'RE DOING -----------

"$AUTOMATION_RUNNER_SCRIPT_PATH" \
    "$SIMULATOR_NAME_OR_DEVICE_UDID" \
    "$TEST_APP_NAME" \
    "$JAVASCRIPT_TEST_FILE" \
    "$JAVASCRIPT_TEST_FILES_DIRECTORY" \
    "$TEST_RESULTS_OUTPUT_PATH"
