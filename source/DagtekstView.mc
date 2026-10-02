import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

class DagtekstView extends WatchUi.View {

    private var _dateTitle as String = "Laden...";
    private var _scripture as String = "";
    private var _commentary as String = "";
    private var _statusText as String = "";
    private var _isLoading as Boolean = true;
    private var _scrollY as Number = 0;
    private var _maxScrollY as Number = 0;

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Dc) as Void {
    }

    function setData(data as Dictionary, status as String) as Void {
        _isLoading = false;
        if (data != null) {
            _dateTitle = data.get("dateTitle") as String;
            _scripture = data.get("scripture") as String;
            _commentary = data.get("commentary") as String;
            _statusText = status;
        } else {
            _dateTitle = "Geen data";
            _scripture = "";
            _commentary = "";
            _statusText = status;
        }
        _scrollY = 0;
        WatchUi.requestUpdate();
    }

    function setLoading(loadingMsg as String) as Void {
        _isLoading = true;
        _dateTitle = "Dagtekst";
        _scripture = loadingMsg;
        _commentary = "";
        _statusText = "";
        _scrollY = 0;
        WatchUi.requestUpdate();
    }

    function scroll(deltaY as Number) as Void {
        _scrollY += deltaY;
        if (_scrollY < 0) {
            _scrollY = 0;
        } else if (_scrollY > _maxScrollY) {
            _scrollY = _maxScrollY;
        }
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        // Clear background
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var screenWidth = dc.getWidth();
        var screenHeight = dc.getHeight();
        var centerX = screenWidth / 2;
        var paddingX = 24;
        var maxTextWidth = screenWidth - (paddingX * 2);

        var fontTitle = Graphics.FONT_MEDIUM;
        var fontScripture = Graphics.FONT_SMALL;
        var fontBody = Graphics.FONT_XTINY;

        if (_isLoading) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, screenHeight / 3, fontTitle, "Dagtekst", Graphics.TEXT_JUSTIFY_CENTER);
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, screenHeight / 2, fontScripture, _scripture, Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }

        // Render contents with scrolling offset
        var currentY = paddingX + 10 - _scrollY;

        // Date Title (Header)
        dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, currentY, fontTitle, _dateTitle, Graphics.TEXT_JUSTIFY_CENTER);
        currentY += dc.getFontHeight(fontTitle) + 6;

        // Status / warning line if applicable
        if (_statusText != null && _statusText.length() > 0) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, currentY, Graphics.FONT_SYSTEM_XTINY, _statusText, Graphics.TEXT_JUSTIFY_CENTER);
            currentY += 20;
        }

        // Separator line
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(paddingX, currentY, screenWidth - paddingX, currentY);
        currentY += 10;

        // Theme Scripture
        if (_scripture.length() > 0) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            var scrpLines = wrapText(dc, _scripture, fontScripture, maxTextWidth);
            for (var i = 0; i < scrpLines.size(); i++) {
                dc.drawText(centerX, currentY, fontScripture, scrpLines[i] as String, Graphics.TEXT_JUSTIFY_CENTER);
                currentY += dc.getFontHeight(fontScripture);
            }
            currentY += 12;
        }

        // Separator line
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(paddingX, currentY, screenWidth - paddingX, currentY);
        currentY += 10;

        // Commentary Body Text
        if (_commentary.length() > 0) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            var bodyLines = wrapText(dc, _commentary, fontBody, maxTextWidth);
            for (var j = 0; j < bodyLines.size(); j++) {
                dc.drawText(paddingX, currentY, fontBody, bodyLines[j] as String, Graphics.TEXT_JUSTIFY_LEFT);
                currentY += dc.getFontHeight(fontBody);
            }
            currentY += 30; // Extra padding at bottom
        }

        // Calculate max scroll depth
        var totalContentHeight = currentY + _scrollY;
        _maxScrollY = totalContentHeight - screenHeight;
        if (_maxScrollY < 0) {
            _maxScrollY = 0;
        }

        // Draw scroll bar indicator if scrollable
        if (_maxScrollY > 0) {
            var scrollBarHeight = (screenHeight * screenHeight) / totalContentHeight;
            if (scrollBarHeight < 15) {
                scrollBarHeight = 15;
            }
            var scrollBarY = (_scrollY * (screenHeight - scrollBarHeight)) / _maxScrollY;
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(screenWidth - 6, scrollBarY, 4, scrollBarHeight);
        }
    }

    // Wrap text into multiple lines for standard display width without toCharArray()
    private function wrapText(dc as Dc, text as String, font as FontDefinition, maxWidth as Number) as Array<String> {
        var lines = [] as Array<String>;
        if (text == null || text.length() == 0) {
            return lines;
        }

        var words = splitString(text, " ");
        var currentLine = "";

        for (var i = 0; i < words.size(); i++) {
            var word = words[i] as String;
            var testLine = (currentLine.length() == 0) ? word : (currentLine + " " + word);

            if (dc.getTextWidthInPixels(testLine, font) <= maxWidth) {
                currentLine = testLine;
            } else {
                if (currentLine.length() > 0) {
                    lines.add(currentLine);
                }
                currentLine = word;
            }
        }

        if (currentLine.length() > 0) {
            lines.add(currentLine);
        }

        return lines;
    }

    // String split implementation without charArray
    private function splitString(str as String, delimiter as String) as Array<String> {
        var words = [] as Array<String>;
        if (str == null || str.length() == 0) {
            return words;
        }

        var current = str;
        var spacePos = current.find(delimiter);

        while (spacePos != null) {
            if (spacePos > 0) {
                words.add(current.substring(0, spacePos));
            }
            current = current.substring(spacePos + delimiter.length(), current.length());
            spacePos = current.find(delimiter);
        }

        if (current.length() > 0) {
            words.add(current);
        }

        return words;
    }
}
