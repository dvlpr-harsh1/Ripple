import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ChatTextfield extends StatefulWidget {
  String label;
  TextInputType? keyBoardType;
  TextEditingController controller;
  bool obscureIcon;
  ChatTextfield({
    required this.label,
    required this.controller,
    this.keyBoardType,
    this.obscureIcon = false,
    super.key,
  });

  @override
  State<ChatTextfield> createState() => _ChatTextfieldState();
}

class _ChatTextfieldState extends State<ChatTextfield> {
  bool obscureText = true;

  void _onTap() {
    setState(() {
      obscureText = !obscureText;
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: TextFormField(
        controller: widget.controller,
        keyboardType: widget.keyBoardType ?? TextInputType.text,
        obscuringCharacter: '*',
        obscureText: widget.obscureIcon ? obscureText : false,
        decoration: InputDecoration(
          label: Text(widget.label),
          suffixIcon: widget.obscureIcon
              ? IconButton(
                  onPressed: _onTap,
                  icon: obscureText
                      ? Icon(CupertinoIcons.eye_slash)
                      : Icon(CupertinoIcons.eye),
                )
              : null,
        ),
      ),
    );
  }
}
