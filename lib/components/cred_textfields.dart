import 'package:flutter/material.dart';

Widget buildCredTextField(
  String labelText, {
  TextEditingController? controller,
  TextInputType? keyboardType,
  bool isPassword = false,
  bool? hasTitle= true,
}) =>
    SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          hasTitle! ?Text(
            labelText,
            style: TextStyle(height: 3),
          ):SizedBox(),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: isPassword,
            decoration: InputDecoration(
              contentPadding:
                  EdgeInsets.symmetric(vertical: 24.0, horizontal: 16),
              labelText: labelText,
              labelStyle: const TextStyle(color: Colors.black38),
              filled: true,
              fillColor: Colors.black12,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              hintText: labelText == "EMAIL" ? "example@email.com" : null,
              hintStyle: const TextStyle(color: Colors.black38),
              suffixIcon: isPassword
                  ? Icon(Icons.visibility_off, color: Colors.black38)
                  : null,
            ),
          ),
        ],
      ),
    );

CircleAvatar otherLoginMethods(icon, color) => CircleAvatar(
      radius: 35,
      backgroundColor: color,
      child: Icon(
        icon,
        color: Colors.white,
        size: 35,
      ),
    );
