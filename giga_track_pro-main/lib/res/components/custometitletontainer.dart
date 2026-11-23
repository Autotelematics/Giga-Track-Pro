import 'package:flutter/material.dart';

class CustomTitleContainer extends StatelessWidget {
  final String titleText;

  const CustomTitleContainer({super.key, required this.titleText});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Container(
        padding: const EdgeInsets.all(2.0),

        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(7.0),
          border: Border.all(
            color: const Color(0x4d9e9e9e),
            width: 0,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 3, 15, 3),
          child: Text(
            titleText,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
