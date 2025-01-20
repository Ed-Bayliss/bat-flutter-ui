// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppMenuButton extends StatelessWidget {
  const AppMenuButton({
    Key? key,
    this.onTap,
  }) : super(key: key);
  final void Function()? onTap;
  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var height = size.height;
    var width = size.width;
    return InkWell(
      onTap: onTap,
      overlayColor: MaterialStateProperty.all<Color>(Colors.transparent),
      child: Container(
        alignment: Alignment.center,
        clipBehavior: Clip.hardEdge,
        height: height * 0.04,
        width: width * 0.089,
        decoration: BoxDecoration(
          color: Colors.transparent, // Makes the color transparent
          borderRadius: BorderRadius.circular(height * 0.012),
        ),
        child: _buildBurgerLines(height, width),
      ),
    );
  }

  Widget _buildBurgerLines(double height, double width) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLine(width),
        _buildLine(width - 100),
      ],
    );
  }

  Widget _buildLine(double width) {
    return Align(
      alignment: Alignment.centerLeft, // Align the line to the left
      child: Container(
        height: 1.5, // Thickness of each line
        width: width * 0.07, // Adjust the width for the burger lines
        color: Colors.black, // Color of the lines (can be customized)
      ),
    );
  }
}
