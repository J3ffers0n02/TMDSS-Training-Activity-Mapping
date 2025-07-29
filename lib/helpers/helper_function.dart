import 'package:flutter/material.dart';

void displayMessageToUser(String message, BuildContext context,
    {int durationInSeconds = 3}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.inverseSurface),
      ),
      duration: Duration(seconds: durationInSeconds),
      backgroundColor: Theme.of(context).colorScheme.primary,
    ),
  );
}