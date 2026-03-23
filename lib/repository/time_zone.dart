import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

bool _initialized = false;

tz.Location ensureTimeZoneInitialized({String timeZone = 'Asia/Shanghai'}) {
  if (!_initialized) {
    tz_data.initializeTimeZones();
    _initialized = true;
  }
  final location = tz.getLocation(timeZone);
  tz.setLocalLocation(location);
  return location;
}
