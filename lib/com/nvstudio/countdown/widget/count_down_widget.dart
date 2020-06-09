import 'package:flutter/material.dart';

import '../count_down.dart';

// Created by Ngoclv on 6/1/2020 16:14
// Copyright © 2020 Ngoclv

///define function for build custom display count down time
typedef Builder = Widget Function(int, String);

///implement simple count down widget
class SimpleCountDown extends StatefulWidget {

  final TextStyle textStyle;
  final Builder builder;
  final CountDownController controller;

  SimpleCountDown(
      {
        Key key,
        @required this.controller,
        this.builder,
        this.textStyle,
      }) : assert(controller != null),
           super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _CountDownState();
  }
}

class _CountDownState extends State<SimpleCountDown> implements CountDownCallback {

  TimeData __timeData;

  @override
  void initState() {
    super.initState();
    widget.controller.addCallback(this);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.builder != null) {
      return widget.builder(__timeData?.millisecondUtilFinish?? 0, __timeData?.formatted?? '');
    }
    return Text(
      __timeData?.formatted?? '',
      style: widget.textStyle?? TextStyle(
        color: Colors.black,
        fontSize: 16
      ),
    );
  }

  @override
  void dispose() {
    widget.controller.removeCallback(this);
    super.dispose();
  }

  @override
  void onFinish() {}

  @override
  void onStart() {}

  @override
  void onTick(int millisecondUtilFinish, String formatted) {
    __timeData = TimeData(millisecondUtilFinish: millisecondUtilFinish, formatted: formatted);
    setState(() {});
  }
}