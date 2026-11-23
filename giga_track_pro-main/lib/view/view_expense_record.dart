import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trackerapp/models/expense_record_model.dart';
import 'package:trackerapp/providers/expense_record_provider.dart';
import 'package:trackerapp/res/colors.dart';

class ExpenseRecordsTable extends StatefulWidget {
  final String vehicleId;

  const ExpenseRecordsTable({super.key, required this.vehicleId});

  @override
  State<ExpenseRecordsTable> createState() => _ExpenseRecordsTableState();
}

class _ExpenseRecordsTableState extends State<ExpenseRecordsTable> {
  final ExpenseRecordProvider provider = ExpenseRecordProvider();

  @override
  void initState() {
    super.initState();
    provider.fetchExpenseRecords(widget.vehicleId);
  }

  void _showDetails(BuildContext context, ExpenseRecord record) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Expense Details",
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),

              const SizedBox(height: 10),

              _detailRow("Date",
                  DateFormat('dd MMM yyyy').format(record.date)),
              _detailRow("Amount", "Rs. ${record.amount}"),
              _detailRow("Category", record.category),
              _detailRow("Description", record.description),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                      ),
                      child: const Text("Close"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        provider.deleteExpense(
                            record.id!, record.vehicleId);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text("Delete"),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: provider,
      child: Consumer<ExpenseRecordProvider>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Vehicle Expenses"),
            ),
            body: vm.expenseRecords.isEmpty
                ? const Center(child: Text("No expenses found"))
                : Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.buttonColor,
                        const Color(0xFFD35400),
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      Text(
                        "Rs. ${vm.totalAmount}",
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                /// 📋 LIST
                Expanded(
                  child: ListView.builder(
                    itemCount: vm.expenseRecords.length,
                    itemBuilder: (context, i) {
                      final record = vm.expenseRecords[i];

                      return InkWell(
                        onTap: () => _showDetails(context, record),
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                              )
                            ],
                          ),
                          child: Row(
                            children: [

                              /// DATE
                              Expanded(
                                flex: 2,
                                child: Text(
                                  DateFormat('dd MMM')
                                      .format(record.date),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),

                              /// VEHICLE NAME
                              Expanded(
                                flex: 3,
                                child: Text(
                                  record.vehicleName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              /// AMOUNT
                              Expanded(
                                flex: 2,
                                child: Text(
                                  "Rs. ${record.amount}",
                                  style: TextStyle(
                                    color: AppColors.buttonColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              /// DELETE ICON
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () {
                                  vm.deleteExpense(
                                      record.id!, record.vehicleId);
                                },
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  /// 🔹 Detail Row
  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text("$title: ",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}