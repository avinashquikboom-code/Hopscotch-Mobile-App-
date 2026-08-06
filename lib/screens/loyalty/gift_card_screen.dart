import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopscotch/providers/loyalty_provider.dart';

class GiftCardScreen extends ConsumerStatefulWidget {
  const GiftCardScreen({super.key});

  @override
  ConsumerState<GiftCardScreen> createState() => _GiftCardScreenState();
}

class _GiftCardScreenState extends ConsumerState<GiftCardScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isRedeeming = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(loyaltyProvider.notifier).fetchGiftCardsData();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _redeemCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid Gift Card voucher code')),
      );
      return;
    }

    setState(() => _isRedeeming = true);
    final success = await ref.read(loyaltyProvider.notifier).redeemGiftCard(code);
    setState(() => _isRedeeming = false);

    if (mounted) {
      if (success) {
        _codeController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gift Card $code successfully redeemed & added to your Wallet!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid or expired Gift Card code.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loyaltyState = ref.watch(loyaltyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Gift Cards', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active Gift Card Balance Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE91E63), Color(0xFFC2185B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Active Gift Card Balance', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                      Icon(Icons.card_giftcard, color: Colors.white, size: 24),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${loyaltyState.giftCardBalance.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Redeem Voucher Form Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Redeem Gift Voucher', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('Enter your 16-character voucher code to credit funds instantly.', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'Gift Card Code',
                        hintText: 'e.g. GIFT-2026-FCIS',
                        prefixIcon: const Icon(Icons.confirmation_number_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isRedeeming ? null : _redeemCode,
                        child: _isRedeeming
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Claim Gift Card', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Gift Card History Section
            const Text('Gift Card History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            loyaltyState.giftCardHistory.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(Icons.card_giftcard_outlined, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text('No gift card history', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: loyaltyState.giftCardHistory.length,
                    separatorBuilder: (ctx, i) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final item = loyaltyState.giftCardHistory[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.pink.shade50,
                          child: const Icon(Icons.card_giftcard, color: Colors.pink, size: 20),
                        ),
                        title: Text(item.code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text('Status: ${item.status.toUpperCase()}', style: const TextStyle(fontSize: 12)),
                        trailing: Text(
                          '₹${item.amount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.pink),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
