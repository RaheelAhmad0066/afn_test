import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:afn_test_admin/constants/constants.dart';
import 'package:afn_test_admin/constants/responsive.dart';
import 'package:afn_test_admin/controllers/controller.dart';
import 'package:afn_test_admin/screens/components/dashboard_content.dart';
import 'package:afn_test_admin/screens/components/custom_appbar.dart';
import 'package:afn_test_admin/screens/blog_post_screen.dart';
import 'components/drawer_menu.dart';

class DashBoardScreen extends StatelessWidget {
  const DashBoardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ensure controller is initialized
    if (!Get.isRegistered<Controller>()) {
      Get.put(Controller());
    }
    
    final controller = Get.find<Controller>();
    
    return Scaffold(
      backgroundColor: bgColor,
      drawer: DrawerMenu(),
      key: controller.scaffoldKey,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (Responsive.isDesktop(context)) Expanded(child: DrawerMenu(),),
            Expanded(
              flex: 5,
              child: Obx(() => _buildPageContent(controller.currentIndex.value)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPageContent(int index) {
    switch (index) {
      case 0:
        return DashboardContent();
      case 1:
        return BlogPostScreen();
      case 2:
        return _buildMessageContent();
      case 3:
        return _buildStatisticsContent();
      case 4:
        return _buildSettingsContent();
      default:
        return DashboardContent();
    }
  }

  Widget _buildMessageContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(appPadding),
      child: Column(
        children: [
          CustomAppbar(),
          SizedBox(height: 40),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.message,
                  size: 80,
                  color: primaryColor,
                ),
                SizedBox(height: 20),
                Text(
                  'Messages',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'View and manage messages',
                  style: TextStyle(
                    fontSize: 16,
                    color: lightTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(appPadding),
      child: Column(
        children: [
          CustomAppbar(),
          SizedBox(height: 40),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bar_chart,
                  size: 80,
                  color: primaryColor,
                ),
                SizedBox(height: 20),
                Text(
                  'Statistics',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'View detailed statistics',
                  style: TextStyle(
                    fontSize: 16,
                    color: lightTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(appPadding),
      child: Column(
        children: [
          CustomAppbar(),
          SizedBox(height: 40),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.settings,
                  size: 80,
                  color: primaryColor,
                ),
                SizedBox(height: 20),
                Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Configure your settings',
                  style: TextStyle(
                    fontSize: 16,
                    color: lightTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}