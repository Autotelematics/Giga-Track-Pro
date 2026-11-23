import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:trackerapp/models/expense_record_model.dart';
import 'package:trackerapp/providers/expense_record_provider.dart';
import 'package:trackerapp/res/colors.dart';

class AddExpenseScreen extends StatefulWidget {
  final String vehicleId;
  final String vehicleName;

  const AddExpenseScreen({
    super.key,
    required this.vehicleId,
    required this.vehicleName,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();

  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  final ExpenseRecordProvider _provider = ExpenseRecordProvider();

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final expense = ExpenseRecord(
      date: _selectedDate,
      amount: double.parse(_amountController.text),
      category: _categoryController.text,
      description: _descriptionController.text,
      vehicleId: widget.vehicleId,
      vehicleName: widget.vehicleName,
    );

    _provider.addExpense(expense).then((_) {
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                /// 🔶 HEADER
                Row(
                  children: [
                    Icon(Icons.receipt_long, color: AppColors.buttonColor),
                    const SizedBox(width: 8),
                    const Text(
                      "Add Expense",
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                /// 🚗 VEHICLE INFO CARD
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.buttonColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _infoRow("Vehicle ID", widget.vehicleId),
                      _infoRow("Vehicle Name", widget.vehicleName),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                /// 📅 DATE PICKER
                InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: _boxDecoration(),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today,
                            color: AppColors.buttonColor),
                        const SizedBox(width: 10),
                        Text(
                          DateFormat('dd MMM yyyy')
                              .format(_selectedDate),
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                /// 💰 AMOUNT
                _inputField(
                  controller: _amountController,
                  label: "Amount",
                  icon: Icons.account_balance_wallet,
                  keyboard: TextInputType.number,
                  formatter: FilteringTextInputFormatter.digitsOnly,
                  validator: (v) => v!.isEmpty ? "Enter amount" : null,
                ),

                const SizedBox(height: 12),

                /// 📂 CATEGORY
                _inputField(
                  controller: _categoryController,
                  label: "Category",
                  icon: Icons.category,
                ),

                const SizedBox(height: 12),

                /// 📝 DESCRIPTION
                _inputField(
                  controller: _descriptionController,
                  label: "Description",
                  icon: Icons.notes,
                ),

                const SizedBox(height: 20),

                /// 🚀 SUBMIT BUTTON
                GestureDetector(
                  onTap: _submit,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          AppColors.buttonColor,
                          const Color(0xFFD35400),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                          AppColors.buttonColor.withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        "Add Expense",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🔹 Input Field
  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
    TextInputFormatter? formatter,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      validator: validator,
      inputFormatters: formatter != null ? [formatter] : [],
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.buttonColor),
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade100,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.buttonColor),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Row(
      children: [
        Text("$title: ",
            style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value)),
      ],
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
    );
  }
}