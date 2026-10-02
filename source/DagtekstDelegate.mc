import Toybox.WatchUi;
import Toybox.Lang;

class DagtekstDelegate extends WatchUi.BehaviorDelegate {

    private var _app as DagtekstApp;
    private var _view as DagtekstView;

    function initialize(app as DagtekstApp, view as DagtekstView) {
        BehaviorDelegate.initialize();
        _app = app;
        _view = view;
    }

    // Key event handlers for watches with physical buttons or scroll wheel
    function onNextPage() as Boolean {
        _view.scroll(60);
        return true;
    }

    function onPreviousPage() as Boolean {
        _view.scroll(-60);
        return true;
    }

    function onSelect() as Boolean {
        _app.fetchDailyText();
        return true;
    }

    // Touchscreen gesture handlers for Vívoactive 6
    function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Boolean {
        var direction = swipeEvent.getDirection();
        if (direction == WatchUi.SWIPE_UP) {
            _view.scroll(80);
            return true;
        } else if (direction == WatchUi.SWIPE_DOWN) {
            _view.scroll(-80);
            return true;
        } else if (direction == WatchUi.SWIPE_RIGHT) {
            // Refresh on right swipe
            _app.fetchDailyText();
            return true;
        }
        return false;
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        // Tap screen to trigger refresh if desired
        return false;
    }
}
