import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

String formatLocalizedDate(DateTime value, Locale locale) {
  return DateFormat.yMMMMd(locale.toLanguageTag()).format(value);
}
