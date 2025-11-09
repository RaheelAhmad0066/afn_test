import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:afn_test_admin/constants/constants.dart';
import 'package:afn_test_admin/controllers/controller.dart';
import 'package:afn_test_admin/screens/components/drawer_list_tile.dart';

class DrawerMenu extends StatelessWidget {
  const DrawerMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<Controller>();
    
    return Drawer(
      backgroundColor: AppColors.backgroundColor,
      child: ListView(
        children: [
          Container(
            padding: EdgeInsets.all(appPadding),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
            ),
            child: Image.asset("assets/images/logowithtext.png"),
          ),
          SizedBox(height: 10),
          DrawerListTile(
            title: 'Dash Board',
            svgSrc: 'assets/icons/Dashboard.svg',
            index: 0,
            tap: () {
              controller.changePage(0);
            },
          ),
          DrawerListTile(
            title: 'Blog Post',
            svgSrc: 'assets/icons/BlogPost.svg',
            index: 1,
            tap: () {
              controller.changePage(1);
            },
          ),
          DrawerListTile(
            title: 'Message',
            svgSrc: 'assets/icons/Message.svg',
            index: 2,
            tap: () {
              controller.changePage(2);
            },
          ),
          DrawerListTile(
            title: 'Statistics',
            svgSrc: 'assets/icons/Statistics.svg',
            index: 3,
            tap: () {
              controller.changePage(3);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: appPadding * 2),
            child: Divider(
              color: grey.withOpacity(0.3),
              thickness: 0.5,
            ),
          ),
          DrawerListTile(
            title: 'Settings',
            svgSrc: 'assets/icons/Setting.svg',
            index: 4,
            tap: () {
              controller.changePage(4);
            },
          ),
          DrawerListTile(
            title: 'Logout',
            svgSrc: 'assets/icons/Logout.svg',
            index: 5,
            tap: () {
              // Logout functionality
              Get.dialog(
                AlertDialog(
                  title: Text('Logout'),
                  content: Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        // Add logout logic here
                        Get.back();
                        // Get.offAll(() => LoginScreen()); // If you have login screen
                      },
                      child: Text('Logout', style: TextStyle(color: red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
