/// Parsed result for create-order-letter header response.
class OrderLetterResponseParseResult {
  final int orderLetterId;
  final String noSp;

  const OrderLetterResponseParseResult({
    required this.orderLetterId,
    required this.noSp,
  });
}

/// Utilities to parse header response from create order letter API.
class OrderLetterResponseParser {
  const OrderLetterResponseParser._();

  static OrderLetterResponseParseResult parse(Map<String, dynamic> headerData) {
    final dynamic resultNode = headerData['result'];

    final int orderLetterId = ((() {
          if (resultNode is Map) {
            final fromOrderLetter =
                (resultNode['order_letter']?['id'] as num?)?.toInt();
            if (fromOrderLetter != null && fromOrderLetter > 0) {
              return fromOrderLetter;
            }
            final fromResult = (resultNode['id'] as num?)?.toInt();
            if (fromResult != null && fromResult > 0) return fromResult;
          }
          final fromData = (headerData['data']?['id'] as num?)?.toInt();
          if (fromData != null && fromData > 0) return fromData;
          return (headerData['id'] as num?)?.toInt();
        })() ??
        0);

    final String noSp = (resultNode is Map
                ? (resultNode['order_letter']?['no_sp'] ?? resultNode['no_sp'])
                : null)
            ?.toString() ??
        '#$orderLetterId';

    return OrderLetterResponseParseResult(
        orderLetterId: orderLetterId, noSp: noSp);
  }
}
