import 'package:flutter/material.dart';


Future<void> navigateTo(BuildContext context, path) async {
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => path),
  );
}