import 'package:flutter/material.dart';

import 'add_fee_screen.dart';
import 'fee_list_screen.dart';
import 'pending_fee_screen.dart';
import 'paid_fee_screen.dart';
import 'fee_report_screen.dart';
import 'receipt_screen.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  int? _hoveredIndex;

  final List<_FinanceAction> _actions = const [
    _FinanceAction(
      title: 'Add Fee',
      subtitle: 'Create a new fee record',
      icon: Icons.add_card_rounded,
      screen: AddFeeScreen(),
    ),
    _FinanceAction(
      title: 'Fee List',
      subtitle: 'View and manage fee records',
      icon: Icons.receipt_long_rounded,
      screen: FeeListScreen(),
    ),
    _FinanceAction(
      title: 'Pending Fees',
      subtitle: 'View outstanding payments',
      icon: Icons.pending_actions_rounded,
      screen: PendingFeeScreen(),
    ),
    _FinanceAction(
      title: 'Paid Fees',
      subtitle: 'View completed payments',
      icon: Icons.check_circle_outline_rounded,
      screen: PaidFeeScreen(),
    ),
    _FinanceAction(
      title: 'Reports',
      subtitle: 'Analyze fee collection',
      icon: Icons.bar_chart_rounded,
      screen: FeeReportScreen(),
    ),
    _FinanceAction(
      title: 'Receipt',
      subtitle: 'Generate fee receipts',
      icon: Icons.description_rounded,
      screen: ReceiptScreen(),
    ),
  ];

  void _openScreen(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        titleSpacing: 24,
        title: const Text(
          'Finance Management',
          style: TextStyle(
            color: Color(0xFF172033),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF172033)),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount;

          if (constraints.maxWidth >= 1100) {
            crossAxisCount = 3;
          } else if (constraints.maxWidth >= 700) {
            crossAxisCount = 2;
          } else {
            crossAxisCount = 1;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 22),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _actions.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    mainAxisExtent: 92,
                  ),
                  itemBuilder: (context, index) {
                    final action = _actions[index];

                    return _buildActionCard(context, index, action);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF3)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FF),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Color(0xFF356AE6),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Finance & Fee Management',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF172033),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Manage fees, payments, receipts and financial reports.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7A8497),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    int index,
    _FinanceAction action,
  ) {
    final bool isHovered = _hoveredIndex == index;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() {
          _hoveredIndex = index;
        });
      },
      onExit: (_) {
        setState(() {
          _hoveredIndex = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, isHovered ? -3 : 0, 0),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _openScreen(context, action.screen),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isHovered
                      ? const Color(0xFFD5DDEA)
                      : const Color(0xFFE8ECF3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isHovered ? 0.07 : 0.025),
                    blurRadius: isHovered ? 12 : 7,
                    offset: Offset(0, isHovered ? 5 : 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      action.icon,
                      size: 23,
                      color: const Color(0xFF356AE6),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          action.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF172033),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          action.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF7A8497),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isHovered
                          ? const Color(0xFF356AE6)
                          : const Color(0xFFF3F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 15,
                      color: isHovered ? Colors.white : const Color(0xFF7A8497),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FinanceAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget screen;

  const _FinanceAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.screen,
  });
}
