import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';

class AmountDisplay extends StatelessWidget {
  final double amount;
  final bool isIncome;
  final bool showSign;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? color;

  const AmountDisplay({
    super.key,
    required this.amount,
    this.isIncome = true,
    this.showSign = false,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w600,
    this.color,
  });

  static final _fmt = NumberFormat('#,##0.00');

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ?? (isIncome ? AppColors.income : AppColors.expense);
    final sign = showSign ? (isIncome ? '+' : '-') : '';
    return Text(
      '$sign\$${_fmt.format(amount)}',
      style: TextStyle(
        color: effectiveColor,
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
    );
  }
}
