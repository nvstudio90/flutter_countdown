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

class _CountDownState extends State<SimpleCountDown> {

  TimeData __timeData;

  @override
  void initState() {
    super.initState();
    widget.controller.stream.listen((data){
      __timeData = data;
      setState(() {});
    });
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
}