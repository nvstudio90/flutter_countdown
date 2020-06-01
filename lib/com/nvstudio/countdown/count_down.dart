// Created by Ngoclv on 6/1/2020 15:52
// Copyright © 2020 Ngoclv
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

///define function handle format time
typedef DateTimeFormatter = String Function(int);

///define function for build custom display count down time
typedef Builder = Widget Function(int, String);

///
///parser millisecond to day, hour, minus, second
///
void parser(int millisUntilFinished, List<int> timeArrays) {
  assert(timeArrays != null && timeArrays.length >= 4);
  final day = (millisUntilFinished / Duration.millisecondsPerDay).floor();
  final tmpDay = day * Duration.millisecondsPerDay;
  final hour =
  ((millisUntilFinished - tmpDay) / Duration.millisecondsPerHour).floor();
  final tmpHour = hour * Duration.millisecondsPerHour;
  final minus = ((millisUntilFinished - tmpDay - tmpHour) /
      Duration.millisecondsPerMinute)
      .floor();
  final tmpMinus = (minus * Duration.millisecondsPerMinute).round();
  final second = ((millisUntilFinished - tmpDay - tmpHour - tmpMinus) /
      Duration.millisecondsPerSecond)
      .round();
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
String simpleCountDownFormat(int timeInMillisecondUtilFinish) {
  final timeArrays = [0, 0, 0, 0];
  parser(timeInMillisecondUtilFinish, timeArrays);
  return simpleFormatTime(
      timeArrays[0], timeArrays[1], timeArrays[2], timeArrays[3]);
}

///manage stream for count down
class CountDownController implements CountDownCallback {
  Duration _countTime;
  Duration _stepTime;
  DateTimeFormatter _formatter;
  CountDownCallback _callback;
  bool _isCounting = false;

  StreamController<List> _streamController = StreamController<List>.broadcast();
  CountDownTimer _countDownTimer;

  int _timeUntilFinish;

  CountDownController(
      {@required Duration countTime,
        @required Duration stepTime,
        DateTimeFormatter formatter,
        CountDownCallback callback}) {
    this._countTime = countTime;
    this._stepTime = stepTime;
    this._formatter = formatter;
    this._callback = callback;
    assert(countTime != null);
    assert(stepTime != null);
    if (_formatter == null) {
      _formatter = simpleCountDownFormat;
    }
    _timeUntilFinish = _countTime.inMilliseconds;
  }

  ///start count down
  void start() {
    stop();
    assert(_countTime != null);
    assert(_stepTime != null);
    assert(_streamController.isClosed != true);
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

  Stream<List> get stream => _streamController.stream;

  bool get isCounting => _isCounting;

  @override
  void onFinish() {
    _callback?.onFinish();
    _isCounting = false;
  }

  @override
  void onStart() {
    _callback?.onStart();
    _isCounting = true;
  }

  @override
  void onTick(int millisecondUtilFinish, String formatted) {
    _timeUntilFinish = millisecondUtilFinish;
    _streamController.add([millisecondUtilFinish, formatted]);
    _callback?.onTick(millisecondUtilFinish, formatted);
  }

  ///get total time until finish
  get timeInMillisecondUtilFinish => _timeUntilFinish;

  void close() {
    stop();
    _streamController.close();
  }
}

///simple implement count down widget
class SimpleCountDown extends StatefulWidget {
  final TextStyle textStyle;
  final DateTimeFormatter formatter;
  final Builder builder;
  final CountDownController controller;
  final bool autoStart;

  SimpleCountDown(
      {@required this.controller,
        this.autoStart = true,
        this.builder,
        this.textStyle,
        this.formatter = simpleCountDownFormat}) : assert(controller != null);

  @override
  State<StatefulWidget> createState() {
    return _CountDownState();
  }
}

class _CountDownState extends State<SimpleCountDown> {

  List _data = [0, ''];

  @override
  void initState() {
    super.initState();
    widget.controller.stream.listen((data){
      _data = data;
      setState(() {});
    });
    if (widget.autoStart) widget.controller.start();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.builder != null) {
      return widget.builder(_data[0], _data[1]);
    }
    return Text(
      _data[1],
      style: widget.textStyle,
    );
  }

  @override
  void dispose() {
    if (widget.autoStart) widget.controller.close();
    super.dispose();
  }
}

///impl count down support format time
class CountDownTimeFormatter extends CountDownTimer {
  DateTimeFormatter _formatter;

  CountDownTimeFormatter(
      {@required Duration duration,
        @required Duration interval,
        DateTimeFormatter formatter,
        CountDownCallback callback})
      : _formatter = formatter,
        super(duration: duration, interval: interval, callback: callback);

  @override
  void onTick(int millisecondUtilFinish, String formatted) {
    String dateTimeInFormat =
    _formatter != null ? _formatter(millisecondUtilFinish) : null;
    _callback?.onTick(millisecondUtilFinish, dateTimeInFormat);
  }
}

class CountDownTimer implements CountDownCallback {
  final int _durationInMicrosecond;
  final int _intervalInMicrosecond;
  final CountDownCallback _callback;

  Timer _timer;
  DateTime _timeBegin;

  CountDownTimer(
      {@required Duration duration,
        @required Duration interval,
        CountDownCallback callback})
      : _durationInMicrosecond = duration.inMicroseconds,
        _intervalInMicrosecond = interval.inMicroseconds,
        _callback = callback;

  int microsecondToMillisecond(int micro) => (micro / 1000).round();

  ///start count down
  void start() {
    if (_timer == null) {
      onStart();
      onTick((microsecondToMillisecond(_durationInMicrosecond)), null);
      _timeBegin = DateTime.now();
      _handlePeriodic(_durationInMicrosecond);
    } else {
      if (_timer.isActive) {
        print('count down is running...');
      } else {
        print('count down stopped');
      }
    }
  }

  void _handlePeriodic(int duration) {
    final int delay =
    duration <= _intervalInMicrosecond ? duration : _intervalInMicrosecond;
    _timer = Timer.periodic(Duration(microseconds: delay), (t) {
      int consumeInMicrosecond =
          DateTime.now().difference(_timeBegin).inMicroseconds;
      int left = _durationInMicrosecond - consumeInMicrosecond;
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

  ///cancel count down if it running
  void cancel() {
    if (_timer != null) {
      _timer.cancel();
      _timer = null;
    }
  }

  ///call
  @override
  void onTick(int millisecondUtilFinish, String formatted) {
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

  void onTick(int millisecondUtilFinish, String formatted);

  void onFinish();
}