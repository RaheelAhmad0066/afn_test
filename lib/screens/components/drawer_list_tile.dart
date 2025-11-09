import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:afn_test_admin/constants/constants.dart';
import 'package:afn_test_admin/controllers/controller.dart';

class DrawerListTile extends StatelessWidget {
  const DrawerListTile({
    Key? key, 
    required this.title, 
    required this.svgSrc, 
    required this.tap,
    required this.index,
  }) : super(key: key);

  final String title, svgSrc;
  final VoidCallback tap;
  final int index;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<Controller>();
    
    return Obx(() => Container(
      decoration: BoxDecoration(
        color: controller.currentIndex.value == index 
          ? AppColors.accentYellowGreen.withOpacity(0.2) 
          : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        onTap: tap,
        horizontalTitleGap: 0.0,
        leading: SvgPicture.asset(
          svgSrc,
          color: controller.currentIndex.value == index 
            ? primaryColor 
            : grey,
          height: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: controller.currentIndex.value == index 
              ? primaryColor 
              : grey,
            fontWeight: controller.currentIndex.value == index 
              ? FontWeight.bold 
              : FontWeight.normal,
          ),
        ),
      ),
    ));
  }
}
