import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;

class WOLParser {

    // Unescape common HTML entities
    public static function unescapeHtml(text as String) as String {
        if (text == null) {
            return "";
        }
        var s = text;

        s = replaceString(s, "&nbsp;", " ");
        s = replaceString(s, "&#160;", " ");
        s = replaceString(s, "&amp;", "&");
        s = replaceString(s, "&lt;", "<");
        s = replaceString(s, "&gt;", ">");
        s = replaceString(s, "&quot;", "\"");
        s = replaceString(s, "&#039;", "'");
        s = replaceString(s, "&apos;", "'");
        s = replaceString(s, "&mdash;", "—");
        s = replaceString(s, "&ndash;", "–");
        s = replaceString(s, "&#8212;", "—");
        s = replaceString(s, "&#8211;", "–");

        return s;
    }

    // Strip HTML tags using find/substring
    public static function stripTags(html as String) as String {
        if (html == null || html.length() == 0) {
            return "";
        }
        var result = "";
        var current = html;
        var tagOpen = current.find("<");

        while (tagOpen != null) {
            if (tagOpen > 0) {
                result += current.substring(0, tagOpen);
            }
            var tagClose = current.find(">");
            if (tagClose != null && tagClose > tagOpen) {
                current = current.substring(tagClose + 1, current.length());
            } else {
                // Malformed tag, truncate or break
                current = "";
                break;
            }
            tagOpen = current.find("<");
        }
        result += current;

        return unescapeHtml(result);
    }

    // Custom string replace function for Monkey C
    public static function replaceString(str as String, search as String, replacement as String) as String {
        if (str == null || search == null || search.length() == 0) {
            return str;
        }
        var result = "";
        var index = str.find(search);
        var current = str;

        while (index != null) {
            if (index > 0) {
                result += current.substring(0, index);
            }
            result += replacement;
            current = current.substring(index + search.length(), current.length());
            index = current.find(search);
        }
        result += current;
        return result;
    }

    // Dutch month names map
    private static function getDutchMonthName(monthNum as Number) as String {
        switch (monthNum) {
            case 1:  return "januari";
            case 2:  return "februari";
            case 3:  return "maart";
            case 4:  return "april";
            case 5:  return "mei";
            case 6:  return "juni";
            case 7:  return "juli";
            case 8:  return "augustus";
            case 9:  return "september";
            case 10: return "oktober";
            case 11: return "november";
            case 12: return "december";
            default: return "";
        }
    }

    // Dutch day names map
    private static function getDutchDayName(dayOfWeek as Number) as String {
        // Gregorian day_of_week: 1 = Sunday, 2 = Monday, ... 7 = Saturday
        switch (dayOfWeek) {
            case 1: return "zondag";
            case 2: return "maandag";
            case 3: return "dinsdag";
            case 4: return "woensdag";
            case 5: return "donderdag";
            case 6: return "vrijdag";
            case 7: return "zaterdag";
            default: return "";
        }
    }

    // Get today's Dutch date string, e.g. "donderdag 1 oktober"
    public static function getTodayDutchDate() as String {
        var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var dayName = getDutchDayName(info.day_of_week);
        var monthName = getDutchMonthName(info.month);
        return dayName + " " + info.day + " " + monthName;
    }

    // Format ISO date snippet, e.g. "2026-10-01"
    public static function getTodayIsoDate() as String {
        var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var monthStr = info.month < 10 ? "0" + info.month : "" + info.month;
        var dayStr = info.day < 10 ? "0" + info.day : "" + info.day;
        return info.year + "-" + monthStr + "-" + dayStr;
    }

    // Parse HTML content from wol.jw.org/nl and extract daily text dictionary
    public static function parseHtml(html as String) as Dictionary or Null {
        if (html == null || html.length() == 0) {
            return null;
        }

        var todayIso = getTodayIsoDate(); // e.g. "2026-10-01"
        var todayDutch = getTodayDutchDate().toLower(); // e.g. "donderdag 1 oktober"

        // Locate daily text block in HTML
        var targetBlock = null;
        var fallbackBlock = null;

        var tabPos = html.find("tabContent");
        while (tabPos != null) {
            var blockStart = tabPos;
            var nextTab = html.substring(blockStart + 10, html.length()).find("tabContent");
            var blockEnd = (nextTab != null) ? (blockStart + 10 + nextTab) : html.length();
            var block = html.substring(blockStart, blockEnd);

            if (fallbackBlock == null) {
                fallbackBlock = block;
            }

            // Check if this block contains today's ISO date or today's Dutch date
            if (block.find(todayIso) != null || block.toLower().find(todayDutch) != null) {
                targetBlock = block;
                break;
            }

            html = html.substring(blockEnd, html.length());
            tabPos = html.find("tabContent");
        }

        if (targetBlock == null) {
            targetBlock = fallbackBlock;
        }

        if (targetBlock == null) {
            return null;
        }

        // Extract Date header (e.g. <h2>donderdag 1 oktober</h2>)
        var dateTitle = "";
        var h2Start = targetBlock.find("<h2");
        if (h2Start != null) {
            var h2Close = targetBlock.substring(h2Start, targetBlock.length()).find(">");
            if (h2Close != null) {
                var contentStart = h2Start + h2Close + 1;
                var h2End = targetBlock.substring(contentStart, targetBlock.length()).find("</h2>");
                if (h2End != null) {
                    dateTitle = stripTags(targetBlock.substring(contentStart, contentStart + h2End));
                }
            }
        }

        // Extract Theme Scripture (e.g. <p class="themeScrp">...</p>)
        var scripture = "";
        var scrpStart = targetBlock.find("themeScrp");
        if (scrpStart != null) {
            var pClose = targetBlock.substring(scrpStart, targetBlock.length()).find(">");
            if (pClose != null) {
                var scrpContentStart = scrpStart + pClose + 1;
                var pEnd = targetBlock.substring(scrpContentStart, targetBlock.length()).find("</p>");
                if (pEnd != null) {
                    scripture = stripTags(targetBlock.substring(scrpContentStart, scrpContentStart + pEnd));
                }
            }
        }

        // Extract Body Commentary (e.g. <div class="bodyTxt"><p class="sb">...</p></div>)
        var commentary = "";
        var bodyStart = targetBlock.find("bodyTxt");
        if (bodyStart == null) {
            bodyStart = targetBlock.find("class=\"sb\"");
        }
        if (bodyStart != null) {
            var sbStart = targetBlock.substring(bodyStart, targetBlock.length()).find("class=\"sb\"");
            if (sbStart != null) {
                var pClose2 = targetBlock.substring(bodyStart + sbStart, targetBlock.length()).find(">");
                if (pClose2 != null) {
                    var comContentStart = bodyStart + sbStart + pClose2 + 1;
                    var pEnd2 = targetBlock.substring(comContentStart, targetBlock.length()).find("</p>");
                    if (pEnd2 != null) {
                        commentary = stripTags(targetBlock.substring(comContentStart, comContentStart + pEnd2));
                    }
                }
            }
        }

        if (dateTitle.length() == 0 && scripture.length() == 0) {
            return null;
        }

        // Check date match boolean
        var isToday = false;
        if (dateTitle.toLower().find(todayDutch) != null || targetBlock.find(todayIso) != null) {
            isToday = true;
        }

        var dict = {
            "dateTitle" => dateTitle,
            "scripture" => scripture,
            "commentary" => commentary,
            "isToday" => isToday,
            "isoDate" => todayIso
        };

        return dict;
    }
}
