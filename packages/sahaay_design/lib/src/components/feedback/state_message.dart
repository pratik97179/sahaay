import 'package:flutter/material.dart';

import '../../foundations/sizing.dart';
import '../../tokens/components.dart';
import '../../tokens/sahaay_tokens.dart';
import '../scaled_icon.dart';

/// Shown when a collection has nothing in it yet, such as "No medicines
/// yet." (`docs/design-system.md` §11.5). Calm and quiet; an optional
/// [action] offers the next step.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.message,
    required this.icon,
    this.action,
    super.key,
  });

  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) => _StateMessage(
    tokens: context.sahaay.emptyState,
    icon: icon,
    message: message,
    action: action,
  );
}

/// Shown in place of content that could not be loaded. The icon is brick,
/// but the words carry the meaning; an optional [action] offers a way on,
/// such as "Try again".
class ErrorState extends StatelessWidget {
  const ErrorState({
    required this.message,
    this.icon = Icons.error_outline,
    this.action,
    super.key,
  });

  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) => _StateMessage(
    tokens: context.sahaay.errorState,
    icon: icon,
    message: message,
    action: action,
    liveRegion: true,
  );
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.tokens,
    required this.icon,
    required this.message,
    this.action,
    this.liveRegion = false,
  });

  final StateMessageTokens tokens;
  final IconData icon;
  final String message;
  final Widget? action;
  final bool liveRegion;

  @override
  Widget build(BuildContext context) {
    final t = context.sahaay;
    final action = this.action;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: t.section.titleGap),
      child: Semantics(
        liveRegion: liveRegion,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaledIcon(
              icon,
              besideText: tokens.message,
              color: tokens.icon,
              factor: Sizing.stateIconToText,
            ),
            SizedBox(height: t.field.labelGap),
            Text(message, style: tokens.message, textAlign: TextAlign.center),
            if (action != null) ...[SizedBox(height: t.field.gap), action],
          ],
        ),
      ),
    );
  }
}
