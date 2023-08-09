import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OTPTextField extends StatefulWidget {
  final int length;
  final ValueChanged<String> onCompleted;

  OTPTextField({required this.length, required this.onCompleted});

  @override
  _OTPTextFieldState createState() => _OTPTextFieldState();
}

class _OTPTextFieldState extends State<OTPTextField> {
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _controllers;
  String? otp;

  @override
  void initState() {
    super.initState();
    _focusNodes = List<FocusNode>.generate(
      widget.length,
      (index) => FocusNode(),
    );
    _controllers = List<TextEditingController>.generate(
      widget.length,
      (index) => TextEditingController(),
    );

    _focusNodes[0].requestFocus();
  }

  @override
  void dispose() {
    _focusNodes.forEach((node) => node.dispose());
    _controllers.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void _nextField(String value, int index) {
    if (value.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index].unfocus();
      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
    }
  }

  void _previousField(String value, int index) {
    if (value.isEmpty && index > 0) {
      _focusNodes[index].unfocus();
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }
  }

  String _getOTP() {
    String otp = '';
    _controllers.forEach((controller) => otp += controller.text);
    return otp;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.length,
        (index) => Container(
          width: 50.0,
          margin: EdgeInsets.symmetric(horizontal: 8.0),
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            autofocus: index == 0,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
              LengthLimitingTextInputFormatter(1),
            ],
            onChanged: (value) {
              _nextField(value, index);
              _previousField(value, index);
              if (_getOTP().length == widget.length) {
                widget.onCompleted(_getOTP());
              }
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4.0),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
