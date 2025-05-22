import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toko_game/providers/currency_provider.dart';

class PriceText extends StatelessWidget {
  final double priceInIdr;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  const PriceText({
    super.key,
    required this.priceInIdr,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrencyProvider>(
      builder: (context, currencyProvider, _) {
        final convertedPrice = currencyProvider.convertPrice(priceInIdr);
        final formattedPrice = currencyProvider.formatPrice(convertedPrice);

        return Text(
          formattedPrice,
          style: style,
          maxLines: maxLines,
          overflow: overflow,
          textAlign: textAlign,
        );
      },
    );
  }
}
