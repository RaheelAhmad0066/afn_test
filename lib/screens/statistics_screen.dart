import 'package:flutter/material.dart';
import 'package:afn_test_admin/constants/constants.dart';
import 'package:afn_test_admin/screens/components/custom_appbar.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppbar(),
            Expanded(
              child: Center(
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
            ),
          ],
        ),
      ),
    );
  }
}
