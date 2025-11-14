import 'package:flutter/material.dart';

class AppScreenManager {
  double screenWidth = 0.0;
  double calendarHeight = 0.0;

  void setScreenWidthAndCalendarHeight(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // Take into account any padding (status bar, notch, etc.)
    double safePadding = MediaQuery.of(context).padding.top + MediaQuery.of(context).padding.bottom;

    // Calculate a dynamic height based on screen size minus the padding
    double availableHeight = screenHeight - safePadding;

    // Adjust height for smaller devices, tablets, and desktops
    if (screenWidth < 600) {
      // Small devices like phones
      calendarHeight = availableHeight * 0.7;  // Take 70% of available height for smaller screens
    } else if (screenWidth >= 600 && screenWidth < 1200) {
      // Tablets or medium-sized devices
      calendarHeight = availableHeight * 0.8;  // Take 80% of available height for medium screens
    } else {
      // Larger devices like desktops
      calendarHeight = availableHeight * 0.85;  // Take 85% of available height for larger screens
    }
  }
}
