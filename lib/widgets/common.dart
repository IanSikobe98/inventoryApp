import 'package:flutter/material.dart';

import '../models/shoe_batch.dart';
import '../theme/app_theme.dart';

/// Horizontal page padding: roomier on wide screens.
double screenPadding(BuildContext context) =>
    MediaQuery.of(context).size.width >= 900 ? 32 : 16;

void showToast(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: error ? AppColors.alert : AppColors.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
}

/// A cream card with a hairline border: the app's basic surface.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.title,
    this.tag,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final String? title;
  final String? tag;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(title!, style: AppText.display(size: 16)),
                if (tag != null) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(tag!,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(
                            size: 11.5, color: AppColors.inkSoft)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.label,
    this.background = AppColors.paper2,
    this.foreground = AppColors.inkSoft,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: AppText.body(
              size: 11, weight: FontWeight.w600, color: foreground)),
    );
  }
}

class StockPill extends StatelessWidget {
  const StockPill({super.key, required this.batch});

  final ShoeBatch batch;

  @override
  Widget build(BuildContext context) {
    if (batch.outOfStock) {
      return const Pill(
          label: 'Out of stock',
          background: AppColors.alertBg,
          foreground: AppColors.alert);
    }
    if (batch.lowStock) {
      return const Pill(
          label: 'Low stock',
          background: AppColors.alertBg,
          foreground: AppColors.alert);
    }
    return const Pill(
        label: 'In stock',
        background: AppColors.pineTint,
        foreground: AppColors.pine);
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.sub,
    this.warn = false,
  });

  final String label;
  final String value;
  final String? sub;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: warn ? AppColors.rustSoft : AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppText.body(
                    size: 11, weight: FontWeight.w600, color: AppColors.inkSoft)
                .copyWith(letterSpacing: 0.6),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: AppText.display(
                    size: 26, color: warn ? AppColors.alert : AppColors.ink)),
          ),
          if (sub != null) ...[
            const SizedBox(height: 4),
            Text(sub!,
                style: AppText.body(size: 12, color: AppColors.inkSoft)),
          ],
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.placeholder),
            const SizedBox(height: 10),
            Text(message,
                textAlign: TextAlign.center,
                style: AppText.body(color: AppColors.inkSoft)),
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined,
                  size: 44, color: AppColors.alert),
              const SizedBox(height: 12),
              Text('Something went wrong',
                  style: AppText.display(size: 18)),
              const SizedBox(height: 6),
              Text(message,
                  textAlign: TextAlign.center,
                  style: AppText.body(color: AppColors.inkSoft)),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Try again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class LoadingBox extends StatelessWidget {
  const LoadingBox({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(48),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.rust),
        ),
      );
}

/// Red banner for errors inside forms.
class InlineError extends StatelessWidget {
  const InlineError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.alertBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppColors.alert),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: AppText.body(size: 13, color: AppColors.alert)),
          ),
        ],
      ),
    );
  }
}

class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, this.subtitle, this.action});

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.display(size: 28)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!,
                    style: AppText.body(size: 13, color: AppColors.inkSoft)),
              ],
            ],
          ),
        ),
        if (action != null) ...[const SizedBox(width: 12), action!],
      ],
    );
  }
}

/// Standard scrolling page: header, then children, with pull-to-refresh.
class ScreenFrame extends StatelessWidget {
  const ScreenFrame({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    required this.children,
    this.onRefresh,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final List<Widget> children;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final pad = screenPadding(context);
    final list = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(pad, 24, pad, 48),
      children: [
        ScreenHeader(title: title, subtitle: subtitle, action: action),
        const SizedBox(height: 20),
        ...children,
      ],
    );
    if (onRefresh == null) return list;
    return RefreshIndicator(
      color: AppColors.rust,
      onRefresh: onRefresh!,
      child: list,
    );
  }
}

/// Lays widgets out in [columns] equal columns with a gap, wrapping as needed.
Widget equalGrid(List<Widget> children, int columns, {double gap = 14}) {
  return LayoutBuilder(builder: (context, box) {
    final width = (box.maxWidth - gap * (columns - 1)) / columns;
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [for (final c in children) SizedBox(width: width, child: c)],
    );
  });
}

/// Two side-by-side panels on wide screens, stacked on narrow ones.
Widget twoColumn(Widget left, Widget right,
    {int leftFlex = 13, int rightFlex = 10, double gap = 14}) {
  return LayoutBuilder(builder: (context, box) {
    if (box.maxWidth >= 860) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: leftFlex, child: left),
          SizedBox(width: gap),
          Expanded(flex: rightFlex, child: right),
        ],
      );
    }
    return Column(children: [left, SizedBox(height: gap), right]);
  });
}
