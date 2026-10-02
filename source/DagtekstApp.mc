import Toybox.Application;
import Toybox.Communications;
import Toybox.Application.Storage;
import Toybox.WatchUi;
import Toybox.Lang;

class DagtekstApp extends Application.AppBase {

    private var _view as DagtekstView or Null;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        _view = new DagtekstView();
        var delegate = new DagtekstDelegate(self, _view as DagtekstView);

        // First try loading cached data
        loadCachedData();

        // Fetch fresh daily text from WOL
        fetchDailyText();

        return [_view, delegate];
    }

    public function fetchDailyText() as Void {
        if (_view != null) {
            _view.setLoading("Laden van WOL...");
        }

        var url = "https://wol.jw.org/nl";
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "User-Agent" => "Mozilla/5.0 (Garmin Vívoactive 6 App)"
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_TEXT_PLAIN
        };

        Communications.makeWebRequest(url, null, options, method(:onReceiveHtml));
    }

    public function onReceiveHtml(responseCode as Number, data as String or Dictionary or Null) as Void {
        if (responseCode == 200 && data != null && data instanceof String) {
            var parsed = WOLParser.parseHtml(data as String);
            if (parsed != null) {
                // Save to cache
                saveToCache(parsed);

                var isToday = parsed.get("isToday") as Boolean;
                var statusMsg = isToday ? "" : "Datum van tekst is niet vandaag.";
                if (_view != null) {
                    _view.setData(parsed, statusMsg);
                }
                return;
            }
        }

        // If fetch failed or parse returned null, try cached data
        if (!loadCachedData()) {
            if (_view != null) {
                _view.setData(null, "Fout bij ophalen (" + responseCode + ")");
            }
        }
    }

    private function saveToCache(data as Dictionary) as Void {
        try {
            Storage.setValue("cached_date_title", data.get("dateTitle"));
            Storage.setValue("cached_scripture", data.get("scripture"));
            Storage.setValue("cached_commentary", data.get("commentary"));
            Storage.setValue("cached_iso_date", data.get("isoDate"));
        } catch (ex) {
            // Storage error handling
        }
    }

    private function loadCachedData() as Boolean {
        var isoDate = Storage.getValue("cached_iso_date") as String?;
        var dateTitle = Storage.getValue("cached_date_title") as String?;
        var scripture = Storage.getValue("cached_scripture") as String?;
        var commentary = Storage.getValue("cached_commentary") as String?;

        if (dateTitle != null && scripture != null) {
            var todayIso = WOLParser.getTodayIsoDate();
            var statusMsg = (isoDate != null && isoDate.equals(todayIso)) ? "Opgeslagen (Offline)" : "Opgeslagen (Oude datum)";

            var dict = {
                "dateTitle" => dateTitle,
                "scripture" => scripture,
                "commentary" => commentary != null ? commentary : "",
                "isToday" => (isoDate != null && isoDate.equals(todayIso))
            };

            if (_view != null) {
                _view.setData(dict, statusMsg);
            }
            return true;
        }

        return false;
    }
}

function getApp() as DagtekstApp {
    return Application.getApp() as DagtekstApp;
}
