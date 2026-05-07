import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final bool centerTitle;
  final List<Widget>? actions;
  final bool showAppBar;
  final PreferredSizeWidget? appBar;
  final FloatingActionButton? fab;
  final Color? backgroundColor;

  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.centerTitle = true,
    this.actions,
    this.showAppBar = true,
    this.appBar,
    this.fab,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? const Color(0xFFFAFBFC),
      appBar: showAppBar
          ? appBar ??
              AppBar(
                title: title != null ? Text(title!) : null,
                centerTitle: centerTitle,
                actions: actions,
              )
          : null,
      body: body,
      floatingActionButton: fab,
    );
  }
}
