var testName = "Test Going Out";

UIALogger.logStart(testName);

try {

    var target = UIATarget.localTarget();

    var appName = target.frontMostApp().mainWindow().name;

    target.delay(2); // there must be a way of waiting for this to finish

    // go to "Where" tab
    target.frontMostApp().tabBar().buttons()["Where"].tap();

    target.delay(2); // there must be a way of waiting for this to finish

    var cellToScroll = target.frontMostApp().mainWindow().tableViews()[0].cells()["Go Somewhere"];

    if ( cellToScroll.checkIsValid() )
	{
	    cellToScroll.scrollToVisible();
	    // do other actions with object
	}
    else
	{
	    UIALogger.logMessage("object is invalid");
	    UIALogger.logFail(testName);
	}

    cellToScroll.tap();
    target.delay(2); // wait for the new view controller to pop up; probably a better way
    target.frontMostApp().keyboard().typeString("The Hunger Games");
    // target.delay(2); // wait some more, sigh
    target.frontMostApp().mainWindow().buttons()["Create"].tap();

    // target.delay(2); // wait for the GUI to settle down

    var katnissCell = target.frontMostApp().mainWindow().tableViews()[0].cells()[0].elements()[2];

    if (katnissCell.name() == "Katniss") {
	target.delay(2); // wait for the GUI to settle down
	UIALogger.logPass(testName);
    } else {
	target.captureScreenWithName("katniss_going_out_failed");
	target.delay(2); // wait for the GUI to settle down
	UIALogger.logFail(testName);
    }
}
catch(e) {
	target.captureScreenWithName("katniss_going_out_failed");
	target.delay(2); // wait for the GUI to settle down
	UIALogger.logFail(testName);
}