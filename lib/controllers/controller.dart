import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Controller extends GetxController {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  var currentIndex = 0.obs; // Current selected menu index

  GlobalKey<ScaffoldState> get scaffoldKey => _scaffoldKey;

  void controlMenu() {
    if (_scaffoldKey.currentState != null) {
      if (!_scaffoldKey.currentState!.isDrawerOpen) {
        _scaffoldKey.currentState!.openDrawer();
      } else {
        _scaffoldKey.currentState!.closeDrawer();
      }
    }
  }

  void changePage(int index) {
    currentIndex.value = index;
    // Close drawer after selection
    if (_scaffoldKey.currentState != null && 
        _scaffoldKey.currentState!.isDrawerOpen) {
      _scaffoldKey.currentState!.closeDrawer();
    }
  }
}
