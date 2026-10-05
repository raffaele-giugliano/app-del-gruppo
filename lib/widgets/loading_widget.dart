import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  final String? errorMessage;

  const LoadingWidget({super.key, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}