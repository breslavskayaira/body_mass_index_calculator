import 'package:flutter/material.dart';

const kBackground = Color(0xFFF5F5F5);
const kAccent = Color(0xFF4CAF50);
const kResultBackground = Color(0xFFE8F5E9);
const kMuted = Color(0xFF757575);

BoxDecoration cardDecoration({Color shadow = Colors.black12}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(10),
    boxShadow: [
      BoxShadow(
        color: shadow,
        spreadRadius: 1,
        blurRadius: 5,
        offset: const Offset(0, 3),
      ),
    ],
  );
}

ButtonStyle primaryButtonStyle() {
  return ElevatedButton.styleFrom(
    backgroundColor: kAccent,
    foregroundColor: Colors.white,
    disabledBackgroundColor: kAccent.withValues(alpha: 0.6),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    padding: const EdgeInsets.symmetric(vertical: 15),
  );
}
