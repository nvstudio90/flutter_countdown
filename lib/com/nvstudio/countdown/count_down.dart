// Created by Ngoclv on 6/1/2020 15:52
// Copyright © 2020 Ngoclv
import 'dart:async';


///define function handle format time
typedef DateTimeFormatter = String Function(int);

///
///parser millisecond to day, hour, minus, second
///
void parser(int millisUntilFinished, List<int> timeArrays) {
  var tmp = millisUntilFinished;
  final day = (tmp / Duration.millisecondsPerDay).floor();
  tmp = tmp - day * Duration.millisecondsPerDay;
  final hour = (tmp / Duration.millisecondsPerHour).floor();
  tmp = tmp - hour * Duration.millisecondsPerHour;
  final minus = (tmp / Duration.millisecondsPerMinute).floor();
  tmp = tmp - minus * Duration.millisecondsPerMinute;
  final second = (tmp / Duration.millisecondsPerSecond).floor();
  timeArrays[0] = day;
  timeArrays[1] = hour;
  timeArrays[2] = minus;
  timeArrays[3] = second;
}

///convert number to string
String formatNumber(int number) => number > 9 ? '$number' : '0$number';

///simple format date time
String simpleFormatTime(int day, int hour, int minus, int second) {
  if (day > 0) {
    return "$day:${formatNumber(hour)}:${formatNumber(minus)}:${formatNumber(second)}";
  }
  return "${formatNumber(hour)}:${formatNumber(minus)}:${formatNumber(second)}";
}

///simple implement format count down time
String simpleCountDownFormatter(int timeInMillisecondUtilFinish) {
  final timeArrays = [0, 0, 0, 0];
  parser(timeInMillisecondUtilFinish, timeArrays);
  return simpleFormatTime(
      timeArrays[0], timeArrays[1], timeArrays[2], timeArrays[3]);
}

///manage stream for count down
class CountDownController implements CountDownCallback {
  late Duration _countTime;
  late Duration _stepTime;
  DateTimeFormatter? _formatter;
  bool _isCounting = false;
  CountDownTimer? _countDownTimer;
  final List<CountDownCallback> _callbacks = [];

  late int _timeUntilFinish;

  CountDownController(
      {required Duration countTime,
      required Duration stepTime,
      DateTimeFormatter? formatter}) {
    this._countTime = countTime;
    this._stepTime = stepTime;
    this._formatter = formatter;
    if (_formatter == null) {
      _formatter = simpleCountDownFormatter;
    }
    _timeUntilFinish = _countTime.inMilliseconds;
  }

  ///start count down
  void start() {
    stop();
    _isCounting = true;
    _countDownTimer = CountDownTimeFormatter(
        duration: _countTime,
        interval: _stepTime,
        callback: this,
        formatter: _formatter)
      ..start();
  }

  ///stop count count down
  void stop() {
    _isCounting = false;
    _countDownTimer?.cancel();
    _countDownTimer = null;
  }

  void addCallback(CountDownCallback callback) {
    if (!_callbacks.contains(callback)) {
      _callbacks.add(callback);
    }
  }

  void removeCallback(CountDownCallback callback) {
    _callbacks.remove(callback);
  }

  set formatter(f) {
    if (f != _formatter) {
      _formatter = f;
    }
  }

  bool get isCounting => _isCounting;

  @override
  void onFinish() {
    for (CountDownCallback callback in _callbacks) {
      callback.onFinish();
    }
    _isCounting = false;
  }

  @override
  void onStart() {
    for (CountDownCallback callback in _callbacks) {
      callback.onStart();
    }
    _isCounting = true;
  }

  @override
  void onTick(int millisecondUtilFinish, String? formatted) {
    _timeUntilFinish = millisecondUtilFinish;
    for (CountDownCallback callback in _callbacks) {
      callback.onTick(millisecondUtilFinish, formatted);
    }
  }

  ///get total time until finish
  get timeInMillisecondUtilFinish => _timeUntilFinish;

  void close() {
    stop();
    _callbacks.clear();
  }
}

///impl count down support format time
class CountDownTimeFormatter extends CountDownTimer {
  DateTimeFormatter? _formatter;

  CountDownTimeFormatter(
      {required Duration duration,
       required Duration interval,
      DateTimeFormatter? formatter,
      CountDownCallback? callback})
      : _formatter = formatter,
        super(duration: duration, interval: interval, callback: callback);

  @override
  void onTick(int millisecondUtilFinish, String? formatted) {
    String? dateTimeInFormat = _formatter?.call(millisecondUtilFinish);
    _callback?.onTick(millisecondUtilFinish, dateTimeInFormat);
  }
}

class CountDownTimer implements CountDownCallback {
  late final int _durationInMicrosecond;
  late final int _intervalInMicrosecond;
  final CountDownCallback? _callback;

  Timer? _timer;
  DateTime? _timeBegin;

  CountDownTimer(
      {required Duration duration,
      required Duration interval,
      CountDownCallback? callback})
      : _durationInMicrosecond = duration.inMicroseconds,
        _intervalInMicrosecond = interval.inMicroseconds,
        _callback = callback;

  int microsecondToMillisecond(int micro) => micro ~/ 1000;

  ///start count down
  void start() {
    if (_timer == null) {
      onStart();
      _timeBegin = DateTime.now();
      _handlePeriodic(_durationInMicrosecond);
    }
  }

  void _handlePeriodic(int duration) {
    final int delay =
        duration <= _intervalInMicrosecond ? duration : _intervalInMicrosecond;
    onTick(microsecondToMillisecond(_leftTime), null);
    _timer = Timer.periodic(Duration(microseconds: delay), (t) {
      int left = _leftTime;
      if (left <= 0) {
        cancel();
        onTick(0, null);
        onFinish();
      } else {
        onTick(microsecondToMillisecond(left), null);
        if (left < delay) {
          cancel();
          _handlePeriodic(left);
        }
      }
    });
  }

  int get _leftTime {
    int consumeInMicrosecond =
        DateTime.now().difference(_timeBegin!).inMicroseconds;
    int left = _durationInMicrosecond - consumeInMicrosecond;
    return left < 0 ? 0 : left;
  }

  ///cancel count down if it running
  void cancel() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }
  }

  ///call
  @override
  void onTick(int millisecondUtilFinish, String? formatted) {
    _callback?.onTick(millisecondUtilFinish, null);
  }

  @override
  void onStart() {
    _callback?.onStart();
  }

  @override
  void onFinish() {
    _callback?.onFinish();
  }
}

///count down callback
abstract class CountDownCallback {

  void onStart();

  void onTick(int millisecondUtilFinish, String? formatted);

  void onFinish();
}

class TimeData {
  final int millisecondUtilFinish;
  final String? formatted;

  TimeData({required this.millisecondUtilFinish, this.formatted});
}
