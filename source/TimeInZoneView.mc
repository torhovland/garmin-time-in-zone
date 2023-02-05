import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class TimeInZoneView extends WatchUi.DataField {
    private var settings as Array<ZoneSettings>;
    private var current = 0;
    private var time;
    private var isBelowTarget = [ true, true, true ];
    private var zoneMs = [ 0, 0, 0 ];

    function initialize(settings as Array<ZoneSettings>) {
        DataField.initialize();
        self.settings = settings;
    }

    function onTimerReset() as Void {
        time = null;
        zoneMs = [ 0, 0, 0 ];
    }

    function setSettings(settings as Array<ZoneSettings>) as Void {
        self.settings = settings;
    }

    // The given info object contains all the current workout information.
    // Calculate a value and save it locally in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info as Activity.Info) as Void {
        current = 0;
        isBelowTarget = [ true, true, true ];

        if (info has :currentPower && info.currentPower != null) {
            current = info.currentPower as Number;

            if (info has :timerTime && info.timerTime != null) {
                var previousTime = time;
                time = info.timerTime;

                if (previousTime != null && time > previousTime) {
                    var incrementMs = time - previousTime;

                    for (var zone=0; zone<3; zone++) {
                        if (current >= settings[zone].power) {
                            isBelowTarget[zone] = false;
                            zoneMs[zone] += incrementMs;
                        }
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
        
        var zoneColor = [ Graphics.COLOR_GREEN, Graphics.COLOR_GREEN, Graphics.COLOR_GREEN ];
        var foregroundColor = [ Graphics.COLOR_BLACK, Graphics.COLOR_BLACK, Graphics.COLOR_BLACK ];
        var zonePercentage = [0, 0, 0] as Array<Number>;

        for (var zone=0; zone<3; zone++) {
            if (isBelowTarget[zone]) {
                zoneColor[zone] = Graphics.COLOR_RED;
                foregroundColor[zone] = Graphics.COLOR_WHITE;
            }

            zonePercentage[zone] = zoneMs[zone] * 100.0 / settings[zone].duration / 60.0 / 1000.0;

            dc.setColor(zoneColor[zone], zoneColor[zone]);
            dc.fillRectangle(0, height * zone / 3, width, height / 3);

            dc.setColor(foregroundColor[zone], Graphics.COLOR_TRANSPARENT);
            dc.drawText(width / 2, height * zone / 3, Graphics.FONT_SMALL,
                settings[zone].duration + "m > " + settings[zone].power + "W: " + zonePercentage[zone].format("%.1f") + "%",
                Graphics.TEXT_JUSTIFY_CENTER);
        }
    }
}
