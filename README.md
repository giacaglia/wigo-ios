wigo-ios
========

![Alt text](/Images/Highlights.jpg?raw=true "Highlights")

Notes on setting up the auto-builder.

Follow the instructions here for setting up the teamcity agent:

https://confluence.jetbrains.com/display/TCD8/Setting+up+and+Running+Additional+Build+Agents#SettingupandRunningAdditionalBuildAgents-UsingLaunchDaemonsStartupFilesonMacOSx

Similar instructions exist for the teamcity server itself.

The user that we want everything to run as is 'teamcity'.  That is extremely important.

Note also that OS upgrades might cause provisioning profiles to be lost, in which case you need to re-login Xcode to get the profiles to be refreshed.

Keep In Mind
============
If there are code signing failures, log into the build server through SSH rather than through Screen Sharing, as those use different environments.  Try running code signing on the command line.  Presumably it will fail, and then you can try various remedies until it works.  An example of what code signing looks like is 
```/usr/bin/codesign --force --sign 6CB3BBE3B8B88201497AFE1EED8E9041C8281543 --entitlements /Users/teamcity/TeamCity/buildAgent/work/46fda6ab0c1ed4de/build/Wigo.build/Distribution-iphoneos/wigoBlade.build/WiGo.app.xcent /Users/teamcity/Library/Developer/Xcode/DerivedData/Wigo-fkuwexbvexdzcrbljcbehcofdnvs/Build/Intermediates/ArchiveIntermediates/wigoBlade/InstallationBuildProductsLocation/Applications/WiGo.app```
