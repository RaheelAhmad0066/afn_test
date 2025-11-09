import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:afn_test_admin/constants/constants.dart';
import 'package:afn_test_admin/constants/responsive.dart';
import 'package:afn_test_admin/controllers/controller.dart';
import 'package:afn_test_admin/screens/components/profile_info.dart';
import 'package:afn_test_admin/screens/components/search_field.dart';

class CustomAppbar extends StatelessWidget {
  const CustomAppbar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<Controller>();
    
    return Row(
      children: [
        if (!Responsive.isDesktop(context))
          IconButton(
            onPressed: controller.controlMenu,
            icon: Icon(Icons.menu,color: textColor.withOpacity(0.5),),
          ),
        Expanded(child: SearchField()),
        ProfileInfo()
      ],
    );
  }
}
