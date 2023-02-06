import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class TimeInZoneView extends WatchUi.DataField {
    private const MaxNumberOfZones = 3;
    private const NumberOfReadings = 30;

    private var settings as Array<ZoneSettings>;
    private var numberOfZones as Number = MaxNumberOfZones;
    private var readings as Array<Number> = new Array<Number>[NumberOfReadings];
    private var isBelowTarget as Array<Boolean> = new Array<Boolean>[MaxNumberOfZones];
    private var zoneMs as Array<Number> = new Array<Number>[MaxNumberOfZones];
    private var readingIndex as Number = 0;
    private var time as Number?;
    private var font as FontDefinition = Graphics.FONT_LARGE;
    private var label as String = "";
    private var textDimensions as Array<Number> = new Array<Number>[2];

    public function initialize(settings as Array<ZoneSettings>) {
        DataField.initialize();
        self.settings = settings;
        self.numberOfZones = countNumberOfZones();
    }

    public function setSettings(settings as Array<ZoneSettings>) as Void {
        initialize(settings);
        onTimerReset();
    }

    public function onTimerReset() as Void {
        readings = new Array<Number>[NumberOfReadings];
        zoneMs = new Array<Number>[MaxNumberOfZones];
        time = null;
    }

    public function compute(info as Activity.Info) as Void {
        readingIndex++;
        
        if (readingIndex >= NumberOfReadings) {
            readingIndex = 0;
        }

        readings[readingIndex] = 0;
        isBelowTarget = [ true, true, true ] as Array<Boolean>;

        if (settings[0].type == 0 && info has :currentPower && info.currentPower != null) {
            readings[readingIndex] = info.currentPower as Number;
            System.println("Reading: " + readings[readingIndex] + "W");
        } else if (settings[0].type == 1 && info has :currentHeartRate && info.currentHeartRate != null) {
            readings[readingIndex] = info.currentHeartRate as Number;
            System.println("Reading: " + readings[readingIndex] + " bpm");
        } else {
            return;
        }

        if (info has :timerTime && info.timerTime != null) {
            var previousTime = time;
            time = info.timerTime;

            if (previousTime == null || time == null || time <= previousTime) {
                return;
            }

            var incrementMs = (time as Number) - (previousTime as Number);
            var average = calculateAverage();

            for (var zone=0; zone<MaxNumberOfZones; zone++) {   
                if (!settings[zone].include) {
                    continue;
                }            

                if (settings[zone].type == 0 && average < settings[zone].power) {
                    continue;
                }

                if (settings[zone].type == 1 && average < settings[zone].heartRate) {
                    continue;
                }

                isBelowTarget[zone] = false;

                if (zoneMs[zone] == null) {
                    zoneMs[zone] = incrementMs;
                } else {
                    zoneMs[zone] += incrementMs;
                }
            }
        }
    }

    public function onUpdate(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var zoneColor = [ Graphics.COLOR_GREEN, Graphics.COLOR_GREEN, Graphics.COLOR_GREEN ] as Array<ColorValue>;
        var foregroundColor = [ Graphics.COLOR_BLACK, Graphics.COLOR_BLACK, Graphics.COLOR_BLACK ] as Array<ColorValue>;
        var zonePercentage = new Array<Float>[MaxNumberOfZones];
        var average = calculateAverage();
        var zoneGuiSlot = 0;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);            
        dc.clear();

        for (var zone=0; zone<MaxNumberOfZones; zone++) {            
            if (!settings[zone].include) {
                continue;
            }            
                    
            if (isBelowTarget[zone]) {
                zoneColor[zone] = Graphics.COLOR_RED;
                foregroundColor[zone] = Graphics.COLOR_WHITE;
            }

            var ms = zoneMs[zone];

            if (ms == null) {
                zonePercentage[zone] = .0;
            } else {
                zonePercentage[zone] = ms * 100.0 / settings[zone].duration / 60.0 / 1000.0;
            }

            var zoneGuiHeight = Math.round(height / numberOfZones.toFloat()).toNumber();

            fitText(dc, width, zoneGuiHeight, settings[zone], zonePercentage[zone]);
            var verticalOffset = (height / numberOfZones - textDimensions[1]) / 2;

            dc.setColor(zoneColor[zone], zoneColor[zone]);
            dc.fillRectangle(0, height * zoneGuiSlot / numberOfZones, width, height / numberOfZones);

            dc.setColor(foregroundColor[zone], Graphics.COLOR_TRANSPARENT);            
            dc.drawText(width / 2, zoneGuiHeight * zoneGuiSlot + (verticalOffset as Number), font,
                label, Graphics.TEXT_JUSTIFY_CENTER);

            zoneGuiSlot++;
        }
    }

    private function calculateAverage() as Float {
        var sum = 0;

        for (var i=0; i<NumberOfReadings; i++) {
            var reading = readings[i];

            if (reading != null) {
                sum += reading;
            }
        }

        return sum / NumberOfReadings.toFloat();
    }

    private function countNumberOfZones() as Number {
        var sum = 0;

        for (var zone=0; zone<MaxNumberOfZones; zone++) {
            if (settings[zone].include) {
                sum++;
            }
        }

        return sum;
    }

    private function fitText(dc as Dc, width as Number, height as Number, settings as ZoneSettings, percentage as Float) as Void {
        var fonts = [ Graphics.FONT_LARGE, Graphics.FONT_MEDIUM, Graphics.FONT_SMALL, Graphics.FONT_TINY, Graphics.FONT_XTINY ] as Array<FontDefinition>;
        var durationText = settings.duration + "m >";
        var percentageText = percentage.format("%.1f") + "%";
        var targetText = settings.power + "W:";

        if (settings.type == 1) {
            targetText = settings.heartRate + " bpm:";
        }

        for (var i=0; i<fonts.size(); i++) {
            font = fonts[i];

            label = durationText + " " + targetText + " " + percentageText;
            textDimensions = dc.getTextDimensions(label, font);
            
            if (textDimensions[0] > width) {
                label = durationText + " " + targetText + "\n" + percentageText;
                textDimensions = dc.getTextDimensions(label, font);

                if (textDimensions[0] > width) {
                    label = durationText + "\n" + targetText + "\n" + percentageText;
                    textDimensions = dc.getTextDimensions(label, font);
                }
            }

            if (textDimensions[0] <= width && textDimensions[1] <= height) {
                return;
            }
        }

        for (var i=0; i<fonts.size(); i++) {
            font = fonts[i];

            label = targetText + " " + percentageText;
            textDimensions = dc.getTextDimensions(label, font);
            
            if (textDimensions[0] > width) {
                label = targetText + "\n" + percentageText;
                textDimensions = dc.getTextDimensions(label, font);
            }

            if (textDimensions[0] <= width && textDimensions[1] <= height) {
                return;
            }
        }
    }
}
