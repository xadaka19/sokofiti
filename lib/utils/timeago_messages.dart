import 'package:timeago/timeago.dart' as timeago;
import 'package:timeago_flutter/timeago_flutter.dart';

class TimeagoMessages {
  static final _messageMap = {
    'ar': timeago.ArMessages(),
    'fr': timeago.FrMessages(),
    'hi': timeago.HiMessages(),
    'pt': timeago.PtBrMessages(),
    'es': timeago.EsMessages(),
    'tr': timeago.TrMessages(),
  };

  static LookupMessages getMessages(String languageCode) =>
      _messageMap[languageCode.toLowerCase()] ?? timeago.EnMessages();
}
