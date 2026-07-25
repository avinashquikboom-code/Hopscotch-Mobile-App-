import 'package:flutter/material.dart';

/// Reusable order summary card widget displaying itemized charges and tax breakdown.
/// Makes it visually clear whether tax is INCLUDED (MRP) or EXCLUSIVE (added extra).
Widget buildOrderSummary({
  required BuildContext context,
  required double subtotal,
  required double deliveryCharge,
  required double taxAmount,
  required String taxType, // 'INCLUSIVE' or 'EXCLUSIVE'
  required double totalAmount,
  String currencySymbol = '₹',
}) {
  final isInclusive = taxType.toUpperCase().contains('INCLUSIVE');

  String formatPrice(double amount) {
    return '$currencySymbol${amount.toStringAsFixed(2)}';
  }

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

      // FIX: clarify inclusive tax isn't an addition
      if (isInclusive)
        _summaryRow(
          'GST (already included)',
          formatPrice(taxAmount),
          context,
          isInfo: true, // muted/italic style, not a bold addable line
        )
      else
        _summaryRow('GST (added)', formatPrice(taxAmount), context),

      const Divider(height: 16),
      _summaryRow('Total Amount', formatPrice(totalAmount), context, isBold: true),

      // Extra clarity line — directly clarifies "why total didn't change"
      if (isInclusive)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Price shown is inclusive of ${formatPrice(taxAmount)} GST',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
    ],
  );
}

Widget _summaryRow(
  String label,
  String value,
  BuildContext context, {
  bool isBold = false,
  bool isInfo = false,
  Color? valueColor,
}) {
  final colorScheme = Theme.of(context).colorScheme;

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 15 : 13.5,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color: isInfo ? Colors.grey.shade500 : (isBold ? colorScheme.onSurface : Colors.grey.shade700),
            fontStyle: isInfo ? FontStyle.italic : FontStyle.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 17 : 13.5,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ??
                (isBold
                    ? colorScheme.primary
                    : (isInfo ? Colors.grey.shade500 : colorScheme.onSurface)),
          ),
        ),
      ],
    ),
  );
}
