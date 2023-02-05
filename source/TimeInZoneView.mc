import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

var ZoneAColor = Graphics.COLOR_GREEN;
var ZoneBColor = Graphics.COLOR_GREEN;
var ZoneCColor = Graphics.COLOR_GREEN;

class TimeInZoneView extends WatchUi.DataField {

    hidden var settingsA as Settings;
    hidden var settingsB as Settings;
    hidden var settingsC as Settings;

    var current = 0;
    var time;

    var isBelowTargetA = true;
    var isBelowTargetB = true;
    var isBelowTargetC = true;

    var zoneAMs;
    var zoneBMs;
    var zoneCMs;

    function initialize(settingsA, settingsB, settingsC) {
        DataField.initialize();
        self.settingsA = settingsA;
        self.settingsB = settingsB;
        self.settingsC = settingsC;
        onTimerReset();
    }

    function onTimerReset() as Void {
        time = null;
        zoneAMs = 0;
        zoneBMs = 0;
        zoneCMs = 0;
    }

    function setSettingsA(settings) {
        self.settingsA = settings;
    }

    function setSettingsB(settings) {
        self.settingsB = settings;
    }

    function setSettingsC(settings) {
        self.settingsC = settings;
    }

    // The given info object contains all the current workout information.
    // Calculate a value and save it locally in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info as Activity.Info) as Void {
        current = 0;
        isBelowTargetA = true;
        isBelowTargetB = true;
        isBelowTargetC = true;

        if (info has :currentPower && info.currentPower != null) {
            current = info.currentPower as Number;

            if (info has :timerTime && info.timerTime != null) {
                var previousTime = time;
                time = info.timerTime;

                if (previousTime != null && time > previousTime) {
                    var incrementMs = time - previousTime;

                    if (current >= settingsA.power) {
                        isBelowTargetA = false;
                        zoneAMs += incrementMs;
                    }
                    if (current >= settingsB.power) {
                        isBelowTargetB = false;
                        zoneBMs += incrementMs;
                    }
                    if (current >= settingsC.power) {
                        isBelowTargetC = false;
                        zoneCMs += incrementMs;
                    }
                }
            }
        }
    }

    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    function onUpdate(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        
        var zoneAColor = Graphics.COLOR_GREEN;
        var zoneBColor = Graphics.COLOR_GREEN;
        var zoneCColor = Graphics.COLOR_GREEN;

        var foregroundColorA = Graphics.COLOR_BLACK;
        var foregroundColorB = Graphics.COLOR_BLACK;
        var foregroundColorC = Graphics.COLOR_BLACK;

        if (isBelowTargetA) {
            zoneAColor = Graphics.COLOR_RED;
            foregroundColorA = Graphics.COLOR_WHITE;
        }

        if (isBelowTargetB) {
            zoneBColor = Graphics.COLOR_RED;
            foregroundColorB = Graphics.COLOR_WHITE;
        }

        if (isBelowTargetC) {
            zoneCColor = Graphics.COLOR_RED;
            foregroundColorC = Graphics.COLOR_WHITE;
        }

        var labelA = View.findDrawableById("labelA") as Text;
        var labelB = View.findDrawableById("labelB") as Text;
        var labelC = View.findDrawableById("labelC") as Text;

        dc.setColor(zoneAColor, zoneAColor);
        dc.fillRectangle(0, 0, width, height / 3);
        dc.setColor(zoneBColor, zoneBColor);
        dc.fillRectangle(0, height / 3, width, height / 3);
        dc.setColor(zoneCColor, zoneCColor);
        dc.fillRectangle(0, height * 2 / 3, width, height / 3);

        var zoneAPercentage = zoneAMs * 100.0 / settingsA.duration / 60.0 / 1000.0;
        var zoneBPercentage = zoneBMs * 100.0 / settingsB.duration / 60.0 / 1000.0;
        var zoneCPercentage = zoneCMs * 100.0 / settingsC.duration / 60.0 / 1000.0;

        dc.setColor(foregroundColorA, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, 0, Graphics.FONT_SMALL,
            settingsA.duration + "m > " + settingsA.power + "W: " + zoneAPercentage.format("%.1f") + "%",
            Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(foregroundColorB, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height / 3, Graphics.FONT_SMALL,
            settingsB.duration + "m > " + settingsB.power + "W: " + zoneBPercentage.format("%.1f") + "%",
            Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(foregroundColorC, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height * 2 / 3, Graphics.FONT_SMALL,
            settingsC.duration + "m > " + settingsC.power + "W: " + zoneCPercentage.format("%.1f") + "%",
            Graphics.TEXT_JUSTIFY_CENTER);
    }

}
