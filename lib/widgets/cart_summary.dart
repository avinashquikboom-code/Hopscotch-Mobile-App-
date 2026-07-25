import 'package:flutter/material.dart';

class TaxBreakdownItem {
  final String name;
  final double rate;
  final String taxType; // 'INCLUSIVE' or 'EXCLUSIVE'
  final double taxAmount;

  TaxBreakdownItem({
    required this.name,
    required this.rate,
    required this.taxType,
    required this.taxAmount,
  });
}

/// Reusable order summary card widget displaying itemized charges and tax breakdown.
/// Total ALWAYS equals Subtotal + Delivery Charge + GST.
Widget buildOrderSummary({
  required BuildContext context,
  required double subtotal,
  required double deliveryCharge,
  required double taxAmount,
  required String taxType,
  required double totalAmount,
  List<TaxBreakdownItem>? taxBreakdown,
  String currencySymbol = '₹',
}) {
  String formatPrice(double amount) {
    return '$currencySymbol${amount.toStringAsFixed(2)}';
  }

  final hasMultipleBreakdown = taxBreakdown != null && taxBreakdown.length > 1;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _summaryRow('Subtotal', formatPrice(subtotal), context),
      _summaryRow(
        'Delivery Charge',
        deliveryCharge > 0 ? formatPrice(deliveryCharge) : 'FREE',
        context,
        valueColor: deliveryCharge == 0 ? const Color(0xFF10B981) : null,
      ),

      if (hasMultipleBreakdown) ...[
        for (final item in taxBreakdown)
          _summaryRow(
            item.name,
            formatPrice(item.taxAmount),
            context,
          ),
      ] else if (taxBreakdown != null && taxBreakdown.isNotEmpty) ...[
        _summaryRow(
          taxBreakdown.first.name,
          formatPrice(taxAmount),
          context,
        ),
      ] else ...[
        _summaryRow('GST / Tax', formatPrice(taxAmount), context),
      ],

      const Divider(height: 16),
      _summaryRow('Total Amount', formatPrice(totalAmount), context, isBold: true),
    ],
  );
}

Widget _summaryRow(
  String label,
  String value,
  BuildContext context, {
  bool isBold = false,
  Color? valueColor,
}) {
  final colorScheme = Theme.of(context).colorScheme;

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 15 : 13.5,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color: isBold ? colorScheme.onSurface : Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 17 : 13.5,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ?? (isBold ? colorScheme.primary : colorScheme.onSurface),
          ),
        ),
      ],
    ),
  );
}
