import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hopscotch/api/loyalty_api.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletWithdrawScreen extends StatefulWidget {
  final double availableBalance;

  const WalletWithdrawScreen({super.key, required this.availableBalance});

  @override
  State<WalletWithdrawScreen> createState() => _WalletWithdrawScreenState();
}

class _WalletWithdrawScreenState extends State<WalletWithdrawScreen>
    with SingleTickerProviderStateMixin {
  static const _minWithdrawal = 100.0;
  static const _prefKeyName = 'withdraw_bank_name';
  static const _prefKeyNumber = 'withdraw_bank_number';
  static const _prefKeyIFSC = 'withdraw_bank_ifsc';

  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();

  bool _isSubmitting = false;
  bool _showConfirm = false;
  bool _saveBankDetails = true;

  late TabController _tabController;
  List<dynamic> _withdrawals = [];
  bool _loadingHistory = false;

  final LoyaltyApi _api = LoyaltyApi();
  final _currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSavedBankDetails();
    _fetchHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountCtrl.dispose();
    _nameCtrl.dispose();
    _numberCtrl.dispose();
    _ifscCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSavedBankDetails() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameCtrl.text = prefs.getString(_prefKeyName) ?? '';
      _numberCtrl.text = prefs.getString(_prefKeyNumber) ?? '';
      _ifscCtrl.text = prefs.getString(_prefKeyIFSC) ?? '';
    });
  }

  Future<void> _saveBankDetailsToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyName, _nameCtrl.text.trim());
    await prefs.setString(_prefKeyNumber, _numberCtrl.text.trim());
    await prefs.setString(_prefKeyIFSC, _ifscCtrl.text.trim().toUpperCase());
  }

  Future<void> _fetchHistory() async {
    setState(() => _loadingHistory = true);
    try {
      final list = await _api.getWithdrawals();
      if (mounted) setState(() => _withdrawals = list ?? []);
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  void _onProceed() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _showConfirm = true);
  }

  Future<void> _submitWithdrawal() async {
    setState(() => _isSubmitting = true);
    try {
      final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
      final result = await _api.requestWithdrawal(
        amount: amount,
        bankAccountName: _nameCtrl.text.trim(),
        bankAccountNumber: _numberCtrl.text.trim(),
        bankIFSC: _ifscCtrl.text.trim().toUpperCase(),
      );
      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);

      if (result != null) {
        if (_saveBankDetails) await _saveBankDetailsToPrefs();
        await _fetchHistory();
        if (!mounted) return;
        setState(() => _showConfirm = false);
        _amountCtrl.clear();
        _tabController.animateTo(1); // Switch to history tab
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '✅ Withdrawal of ${_currencyFmt.format(amount)} requested! '
              'Processing in 3-5 business days.',
            ),
            backgroundColor: AppTheme.primaryColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
        navigator.pop(true); // Pop with refresh signal
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Withdrawal failed. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : const Color(0xFFF7FAF9),
      appBar: AppBar(
        title: const Text('Withdraw Money', style: TextStyle(fontWeight: FontWeight.w800)),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'Request'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestTab(context, colorScheme, isDark),
          _buildHistoryTab(context, colorScheme, isDark),
        ],
      ),
    );
  }

  Widget _buildRequestTab(BuildContext context, ColorScheme colorScheme, bool isDark) {
    if (_showConfirm) return _buildConfirmationView(context, colorScheme, isDark);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Available Balance Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available Balance',
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _currencyFmt.format(widget.availableBalance),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '⏱  Processed in 3-5 business days',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Amount
            _sectionLabel('Withdrawal Amount'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
              decoration: _inputDecoration(
                colorScheme,
                isDark,
                prefixText: '₹  ',
                hintText: 'Min ₹${_minWithdrawal.toInt()}',
              ),
              validator: (v) {
                final amt = double.tryParse(v?.trim() ?? '');
                if (amt == null || amt <= 0) return 'Enter a valid amount';
                if (amt < _minWithdrawal) return 'Minimum withdrawal is ₹${_minWithdrawal.toInt()}';
                if (amt > widget.availableBalance) {
                  return 'Amount exceeds available balance (${_currencyFmt.format(widget.availableBalance)})';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Bank Details
            _sectionLabel('Bank Account Details'),
            const SizedBox(height: 4),
            Text(
              'Your funds will be transferred to this account.',
              style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.55)),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDecoration(colorScheme, isDark,
                  labelText: 'Account Holder Name', hintText: 'As per bank records'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Account holder name is required' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _numberCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _inputDecoration(colorScheme, isDark,
                  labelText: 'Account Number', hintText: '12-digit account number'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Account number is required';
                if (v.trim().length < 9) return 'Enter a valid account number';
                return null;
              },
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _ifscCtrl,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                LengthLimitingTextInputFormatter(11),
              ],
              decoration: _inputDecoration(colorScheme, isDark,
                  labelText: 'IFSC Code', hintText: 'e.g. HDFC0001234'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'IFSC code is required';
                if (!RegExp(r'^[A-Za-z]{4}0[A-Za-z0-9]{6}$').hasMatch(v.trim())) {
                  return 'Invalid IFSC format (e.g. HDFC0001234)';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Save bank details toggle
            Row(
              children: [
                Checkbox(
                  value: _saveBankDetails,
                  onChanged: (v) => setState(() => _saveBankDetails = v ?? true),
                  activeColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _saveBankDetails = !_saveBankDetails),
                    child: Text(
                      'Save bank details for next time',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            // Fraud warning
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.amber.shade700, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Verify your bank details carefully. Incorrect account details may result in failed transfer and processing delays.',
                      style: TextStyle(fontSize: 12, color: Colors.amber.shade900, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _onProceed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Review & Confirm',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationView(BuildContext context, ColorScheme colorScheme, bool isDark) {
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.account_balance_rounded, color: AppTheme.primaryColor, size: 30),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Confirm Withdrawal',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  'Please review before confirming',
                  style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.55)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Summary card
          _summaryCard(colorScheme, isDark, [
            ('Amount', _currencyFmt.format(amount), true),
            ('Account Holder', _nameCtrl.text.trim(), false),
            ('Account Number', _maskAccountNumber(_numberCtrl.text.trim()), false),
            ('IFSC Code', _ifscCtrl.text.trim().toUpperCase(), false),
            ('Processing Time', '3-5 business days', false),
            ('Balance After', _currencyFmt.format(widget.availableBalance - amount), false),
          ]),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Once confirmed, ₹${amount.toStringAsFixed(0)} will be reserved from your wallet immediately. This action cannot be undone — money will be transferred to the above account.',
                    style: TextStyle(fontSize: 12, color: Colors.red.shade800, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Buttons
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitWithdrawal,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Confirm Withdrawal',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _isSubmitting ? null : () => setState(() => _showConfirm = false),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colorScheme.outline),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Go Back & Edit', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(BuildContext context, ColorScheme colorScheme, bool isDark) {
    if (_loadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_withdrawals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                size: 64, color: colorScheme.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text(
              'No withdrawal requests yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your withdrawal history will appear here.',
              style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.35)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchHistory,
      color: AppTheme.primaryColor,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _withdrawals.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _buildWithdrawalCard(_withdrawals[i], colorScheme, isDark),
      ),
    );
  }

  Widget _buildWithdrawalCard(Map<String, dynamic> w, ColorScheme colorScheme, bool isDark) {
    final status = (w['status'] as String?) ?? 'PENDING';
    final amount = double.tryParse(w['amount']?.toString() ?? '0') ?? 0;
    final requestedAt = w['requestedAt'] != null
        ? DateFormat('dd MMM yyyy').format(DateTime.parse(w['requestedAt']))
        : '—';
    final adminNote = w['adminNote'] as String?;

    final (statusColor, statusIcon, statusLabel) = switch (status) {
      'APPROVED' => (Colors.blue, Icons.thumb_up_rounded, 'Approved'),
      'COMPLETED' => (Colors.green, Icons.check_circle_rounded, 'Completed'),
      'REJECTED' => (Colors.red, Icons.cancel_rounded, 'Rejected'),
      _ => (Colors.orange, Icons.hourglass_top_rounded, 'Pending'),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _currencyFmt.format(amount),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 13, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${w['bankAccountName'] ?? ''} · ****${_last4(w['bankAccountNumber']?.toString() ?? '')}',
            style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
          Text(
            'IFSC: ${w['bankIFSC'] ?? ''} · $requestedAt',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.45)),
          ),
          if (adminNote != null && adminNote.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.comment_rounded, size: 14, color: statusColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      adminNote,
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.7)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryCard(
    ColorScheme colorScheme,
    bool isDark,
    List<(String, String, bool)> rows,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final i = entry.key;
          final (label, value, isHighlight) = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        value,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: isHighlight ? 16 : 13,
                          fontWeight: isHighlight ? FontWeight.w900 : FontWeight.w600,
                          color: isHighlight ? AppTheme.primaryColor : colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (i < rows.length - 1)
                Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.15)),
            ],
          );
        }).toList(),
      ),
    );
  }

  InputDecoration _inputDecoration(
    ColorScheme colorScheme,
    bool isDark, {
    String? labelText,
    String? hintText,
    String? prefixText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixText: prefixText,
      prefixStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: AppTheme.primaryColor,
      ),
      filled: true,
      fillColor: isDark ? colorScheme.surfaceContainerHighest : AppTheme.primaryColor.withValues(alpha: 0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.2),
      );

  String _maskAccountNumber(String n) => n.length > 4 ? '****${n.substring(n.length - 4)}' : n;
  String _last4(String n) => n.length >= 4 ? n.substring(n.length - 4) : n;
}
