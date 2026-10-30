import 'package:flutter/material.dart';

/// Transparent page scaffold for tabs already wrapped in [VaultBackground].
class VaultPage extends StatelessWidget {
  const VaultPage({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}
