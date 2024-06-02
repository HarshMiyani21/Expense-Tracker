import 'package:expense_tracker/bar%20graph/bar_graph.dart';
import 'package:expense_tracker/components/my_list_tile.dart';
import 'package:expense_tracker/database/expense_database.dart';
import 'package:expense_tracker/helper/helper_functions.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController amountController = TextEditingController();

  Future<Map<String, double>>? _monthlyTotalsFuture;
  Future<double>? _calculateCurrentMonthTotal;

  @override
  void initState() {
    Provider.of<ExpenseDatabase>(context, listen: false).readExpenses();
    refreshData();
    super.initState();
  }

  void refreshData() {
    _monthlyTotalsFuture = Provider.of<ExpenseDatabase>(context, listen: false)
        .calculateMonthlyTotals();
    _calculateCurrentMonthTotal =
        Provider.of<ExpenseDatabase>(context, listen: false)
            .calculateCurrentMonthTotal();
  }

  void openNewExpenseox() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("New expense"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: "Name"),
            ),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(hintText: "Amount"),
            ),
          ],
        ),
        actions: [_cancelButton(), _createNewExpenseButton()],
      ),
    );
  }

  void openEditBox(Expense expense) {
    String existingName = expense.name;
    String existingAmount = expense.amount.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit expense"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(hintText: existingName),
            ),
            TextField(
              controller: amountController,
              decoration: InputDecoration(hintText: existingAmount),
            ),
          ],
        ),
        actions: [
          _cancelButton(),
          _editExpenseButton(expense),
        ],
      ),
    );
  }

  void openDeleteBox(Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete expense?"),
        actions: [
          _cancelButton(),
          _deleteExpenseButton(expense.id),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseDatabase>(builder: (context, value, child) {
      int startmonth = value.getStartMonth();
      int startyear = value.getStartYear();
      int currentMonth = DateTime.now().month;
      int currentYear = DateTime.now().year;

      int monthCount =
          calculateMonthCount(startyear, startmonth, currentYear, currentMonth);

      List<Expense> currentMonthExpenses = value.allExpense.where((expense) {
        return expense.date.year == currentYear &&
            expense.date.month == currentMonth;
      }).toList();

      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: FutureBuilder(
            future: _calculateCurrentMonthTotal,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\₹' + snapshot.data!.toStringAsFixed(2),
                    ),
                    Text(
                      getCurrentMonthName(),
                    ),
                  ],
                );
              } else {
                return Text('Loading...');
              }
            },
          ),
        ),
        backgroundColor: Colors.grey.shade300,
        floatingActionButton: FloatingActionButton(
          onPressed: openNewExpenseox,
          child: const Icon(Icons.add),
        ),
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 250,
                child: FutureBuilder(
                    future: _monthlyTotalsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        Map<String, double> monthlyTotals = snapshot.data ?? {};
                        List<double> monthlySummary =
                            List.generate(monthCount, (index) {
                          int year = startyear + (startmonth + index - 1) ~/ 12;
                          int month = (startmonth + index - 1) % 12 + 1;
                          String yearMonthkey = '$year-$month';
                          return monthlyTotals[yearMonthkey] ?? 0.0;
                        });
                        return MyBarGraph(
                            monthlySummary: monthlySummary,
                            startMonth: startmonth);
                      } else {
                        return const Center(
                          child: Text('Loading...'),
                        );
                      }
                    }),
              ),
              SizedBox(
                height: 25,
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: currentMonthExpenses.length,
                  itemBuilder: (context, index) {
                    int reversed = currentMonthExpenses.length - 1 - index;
                    Expense individualExpense = currentMonthExpenses[reversed];
                    return MyListTile(
                      title: individualExpense.name,
                      trailing: formatAmount(individualExpense.amount),
                      onEditPressed: (context) =>
                          openEditBox(individualExpense),
                      onDeletePressed: (context) =>
                          openDeleteBox(individualExpense),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _cancelButton() {
    return MaterialButton(
      onPressed: () {
        Navigator.pop(context);
        nameController.clear();
        amountController.clear();
      },
      child: const Text("Cancel"),
    );
  }

  Widget _createNewExpenseButton() {
    return MaterialButton(
      onPressed: () async {
        if (nameController.text.isNotEmpty &&
            amountController.text.isNotEmpty) {
          Navigator.pop(context);
          Expense newExpense = Expense(
            name: nameController.text,
            amount: convertStringToDouble(amountController.text),
            date: DateTime.now(),
          );
          await context.read<ExpenseDatabase>().createNewExpense(newExpense);
          refreshData();
          nameController.clear();
          amountController.clear();
        }
      },
      child: Text("Save"),
    );
  }

  Widget _editExpenseButton(Expense expense) {
    return MaterialButton(
      onPressed: () async {
        if (nameController.text.isNotEmpty ||
            amountController.text.isNotEmpty) {
          Navigator.pop(context);
          Expense updatedExpense = Expense(
            name: nameController.text.isNotEmpty
                ? nameController.text
                : expense.name,
            amount: amountController.text.isNotEmpty
                ? convertStringToDouble(amountController.text)
                : expense.amount,
            date: DateTime.now(),
          );
          int existingId = expense.id;
          await context
              .read<ExpenseDatabase>()
              .updateExpense(existingId, updatedExpense);
          refreshData();
        }
      },
      child: Text('Save'),
    );
  }

  Widget _deleteExpenseButton(int id) {
    return MaterialButton(
      onPressed: () async {
        Navigator.pop(context);
        await context.read<ExpenseDatabase>().deleteExpense(id);
        refreshData();
      },
      child: Text('Delete'),
    );
  }
}
