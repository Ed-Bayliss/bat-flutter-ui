import 'package:burtonaletrail_app/AppColors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class DrawerListItem extends StatelessWidget {
  const DrawerListItem({
    Key? key,
    required this.isActive,
    required this.tileIcon,
    required this.tileText,
    this.onTap,
  }) : super(key: key);
  final bool isActive;
  final String tileIcon;
  final String tileText;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 30),
        height: size.height * 0.06,
        width: size.width * 0.7,
        decoration: BoxDecoration(
            color: isActive ? AppColors.primaryColor : null,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(size.height * 0.029),
              bottomRight: Radius.circular(size.height * 0.029),
            )),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Container(
                      width: size.width * 0.09,
                      alignment: Alignment.center,
                      child: SvgPicture.asset(
                        tileIcon,
                        color:
                            isActive ? Colors.white : const Color(0xFF8D99AE),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _horizontalSpace(size.width * 0.02),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Text(
                    tileText,
                    style: textStyle(size),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle textStyle(Size size) {
    return GoogleFonts.inter(
        fontWeight: FontWeight.w400,
        color: isActive ? Colors.white : const Color(0xFF8D99AE),
        fontSize: size.height * 0.018);
  }

  TextStyle nameTextStyle(Size size) {
    return GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        color: const Color(0xFF000000),
        fontSize: size.height * 0.020);
  }

  Widget _horizontalSpace(double width) {
    return SizedBox(
      width: width,
    );
  }
}