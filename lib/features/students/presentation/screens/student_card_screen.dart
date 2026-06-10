import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_app/core/providers/student_provider.dart';
import 'package:school_app/features/payments/domain/entities/student_finance_entity.dart';
import 'package:school_app/features/students/data/models/student_model.dart';

class StudentCardScreen extends StatefulWidget {
  final Student student;

  const StudentCardScreen({super.key, required this.student});

  @override
  State<StudentCardScreen> createState() => _StudentCardScreenState();
}

class _StudentCardScreenState extends State<StudentCardScreen> {
  StudentFinanceEntity? _finance;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFinance();
  }

  Future<void> _loadFinance() async {
    final finance = await context
        .read<StudentProvider>()
        .getStudentFinance(widget.student.id!);
    if (mounted) {
      setState(() {
        _finance = finance;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.student.fullName)),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeaderCard(context),
                  const SizedBox(height: 16),
                  _buildFinanceSection(context),
                  const SizedBox(height: 16),
                  _buildDebtSection(context),
                ],
              ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.student.fullName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(widget.student.phone),
            if (widget.student.joinDate != null) ...[
              const SizedBox(height: 4),
              Text(
                'Qo\'shilgan: ${widget.student.joinDate}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceSection(BuildContext context) {
    final f = _finance;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'To\'lov ma\'lumotlari',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _row('Guruh narxi', _format(f?.monthlyFee ?? 0)),
            if (f?.individualMonthlyFee != null)
              _row('Individual summa', _format(f!.individualMonthlyFee!)),
            _row('Amal qiluvchi oylik', _format(f?.effectiveMonthlyFee ?? 0)),
            _row('To\'lov turi', f?.paymentType.label ?? '-'),
            _row('To\'lov usuli', f?.paymentMethod.label ?? '-'),
            _row(
              'Depozit qoldig\'i',
              _format(f?.depositBalance ?? widget.student.depositBalance),
              highlight: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtSection(BuildContext context) {
    final f = _finance;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Qarzdorlik',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _row('Joriy oy qarzi', _format(f?.currentMonthCharge ?? 0)),
            _row('Shu oy to\'langan', _format(f?.currentMonthPaid ?? 0)),
            _row(
              'Shu oy to\'lanishi kerak',
              _format(f?.currentMonthDue ?? 0),
              highlight: true,
              color: Colors.orange.shade800,
            ),
            _row(
              'Jami qarz',
              _format(f?.totalDebt ?? 0),
              highlight: true,
              color: Colors.red.shade700,
            ),
            _row(
              'Oxirgi to\'lov',
              f?.lastPaymentDate != null
                  ? f!.lastPaymentDate!.toString().substring(0, 10)
                  : 'Yo\'q',
            ),
            if (f != null) ...[
              const SizedBox(height: 8),
              Chip(
                label: Text(f.currentMonthStatus.label),
                backgroundColor:
                    f.currentMonthStatus.name == 'paid'
                        ? Colors.green.shade100
                        : Colors.red.shade100,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(
    String label,
    String value, {
    bool highlight = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          Text(
            value,
            style: TextStyle(
              fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _format(double amount) => '${amount.toStringAsFixed(0)} so\'m';
}
