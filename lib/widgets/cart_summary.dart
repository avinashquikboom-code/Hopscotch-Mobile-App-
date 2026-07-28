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

/// Reusable order summary card widget displaying itemized charges, discounts, wallet used, and tax breakdown.
Widget buildOrderSummary({
  required BuildContext context,
  required double subtotal,
  required double deliveryCharge,
  required double taxAmount,
  required String taxType,
  required double totalAmount,
  double rewardDiscount = 0.0,
  double walletUsed = 0.0,
  double couponDiscount = 0.0,
  int rewardPointsEarned = 0,
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
      if (couponDiscount > 0)
        _summaryRow('Coupon Discount', '-${formatPrice(couponDiscount)}', context, valueColor: Colors.green),
      if (rewardDiscount > 0)
        _summaryRow('Reward Discount', '-${formatPrice(rewardDiscount)}', context, valueColor: Colors.orange),
      if (walletUsed > 0)
        _summaryRow('Wallet Payment', '-${formatPrice(walletUsed)}', context, valueColor: Colors.purple),
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
        _summaryRow('Taxes', formatPrice(taxAmount), context),
      ],

      const Divider(height: 16),
      _summaryRow('Grand Total', formatPrice(totalAmount), context, isBold: true),

      if (rewardPointsEarned > 0) ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.stars, color: Colors.orange, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'You will earn $rewardPointsEarned Reward Points after successful delivery.',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                ),
              ),
            ],
          ),
        ),
      ],
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
