import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextFieldWithIcons extends StatelessWidget {
  final String? text; // Use a String instead of TextEditingController
  final String hintText;
  final String fontFamily;
  final IconData prefixIcon;
  final IconData? suffixIcon;
  // final double height;

  CustomTextFieldWithIcons({
    required this.text, // Pass the text directly
    required this.hintText,
    required this.fontFamily,
    required this.prefixIcon,
    this.suffixIcon,
    // this.height = 70.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5.0, horizontal: 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            // height: height,
            padding: EdgeInsets.all(1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.0),
              color: Color.fromARGB(255, 234, 240, 246),
              border: Border.all(
                color: Color.fromARGB(255, 59, 99, 131),
                width: 3.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(255, 41, 52, 61).withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 1,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        padding: EdgeInsets.all(3.0),
                        child: Column(
                          children: [
                            Icon(
                              prefixIcon,
                              color: Color.fromARGB(255, 10, 81, 136),
                              size: 16.0,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 8.0,
                      ),
                      Text(
                        hintText,
                        style: TextStyle(
                          fontSize: 13.0,
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.only(
                              top: 6.0, // Padding for the top side
                              right: 16.0, // Padding for the right side
                              bottom: 10.0, // Padding for the bottom side
                              left: 16.0, // Padding for the left side
                            ),
                            alignment: Alignment.centerLeft,
                            child: GestureDetector(
                              onLongPress: () {
                                final clipboardText =
                                    text; // Use the text directly
                                Clipboard.setData(
                                    ClipboardData(text: clipboardText ?? ''));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Text copied to clipboard'),
                                  ),
                                );
                              },
                              child: Center(
                                child: Text(
                                  maxLines: null,
                                  text ??
                                      '', // Display the text using a Text widget
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontFamily: fontFamily,
                                    overflow: TextOverflow.visible,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
