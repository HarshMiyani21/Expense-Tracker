import 'package:intl/intl.dart';

double convertStringToDouble(String string) {
  double? amount = double.tryParse(string);
  return amount ?? 0;
}

String formatAmount(double amount) {
  final format =
      NumberFormat.currency(locale: "en_IN", symbol: "\₹ ", decimalDigits: 0);
  return format.format(amount);
}

int calculateMonthCount(int startyear, startmonth, currentYear, currentMonth){
  int monthCount = (currentYear - startyear) * 12 + currentMonth - startmonth + 1;
  return monthCount;
}

String getCurrentMonthName(){
  DateTime now = DateTime.now();
  List<String> months = [
    "JAN",
    "FEB",
    "MAR",
    "APR",
    "MAY",
    "JUN",
    "JUL",
    "AUG",
    "SEP",
    "OCT",
    "NOV",
    "DEC",
  ];
  return months[now.month - 1];
}