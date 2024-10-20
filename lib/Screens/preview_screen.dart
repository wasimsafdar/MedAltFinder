import 'dart:io';
import 'package:flutter/material.dart';

class PreviewScreen extends StatefulWidget {
  final String responseText;
  const PreviewScreen({super.key, required this.responseText});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: const Color.fromARGB(255, 96, 187, 244),
      ),
      body: Container(
        padding: const EdgeInsets.all(15),
        width: double.infinity,
        height: MediaQuery.of(context).size.height,
        child: Expanded(
          child: Scrollbar(
            child: SingleChildScrollView(
              child: Text(
                textAlign: TextAlign.justify,
                widget.responseText,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
