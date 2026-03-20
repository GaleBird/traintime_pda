import 'package:watermeter/repository/preference.dart' as preference;

const List<String> _xidianTimeList = [
  "08:30",
  "09:15",
  "09:20",
  "10:05",
  "10:25",
  "11:10",
  "11:15",
  "12:00",
  "14:00",
  "14:45",
  "14:50",
  "15:35",
  "15:55",
  "16:40",
  "16:45",
  "17:30",
  "19:00",
  "19:45",
  "19:55",
  "20:35",
  "20:40",
  "21:25",
];

const List<String> _gxuTimeList = [
  "08:00",
  "08:45",
  "08:55",
  "09:40",
  "10:00",
  "10:45",
  "10:55",
  "11:40",
  "14:30",
  "15:15",
  "15:20",
  "16:05",
  "16:25",
  "17:10",
  "17:15",
  "18:00",
  "18:10",
  "18:45",
  "18:50",
  "19:25",
  "19:40",
  "20:25",
  "20:30",
  "21:15",
  "21:20",
  "22:05",
];

bool get isGxuMode => preference.getBool(preference.Preference.isGxuMode);

List<String> get timeList => isGxuMode ? _gxuTimeList : _xidianTimeList;

bool get useContinuousClassLayout => false;
