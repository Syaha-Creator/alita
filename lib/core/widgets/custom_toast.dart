import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

enum ToastType { success, error, warning, info }

class CustomToast {
  static void showToast(String message, ToastType type, {int duration = 2}) {
    Color bgColor;
    switch (type) {
      case ToastType.success:
        bgColor = Colors.green;
        break;
      case ToastType.error:
        bgColor = Colors.red;
        break;
      case ToastType.warning:
        bgColor = Colors.orange;
        break;
      case ToastType.info:
        bgColor = Colors.blue;
        break;
    }

    Fluttertoast.showToast(
      msg: message,
      toastLength: duration == 1 ? Toast.LENGTH_SHORT : Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: bgColor,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}
