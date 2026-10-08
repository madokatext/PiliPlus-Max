import 'package:PiliPlus/common/widgets/view_safe_area.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:flutter/material.dart';

class PlayerControlBarBuilder extends StatelessWidget {
  const PlayerControlBarBuilder({
    super.key,
    required this.builder,
  });

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) => StreamBuilder(
    stream: GStorage.setting.watch().where(
      (event) =>
          event.key == SettingBoxKey.playerControlBarThicknessScale ||
          event.key == SettingBoxKey.fullScreenDanmakuToggleOnLeft,
    ),
    builder: (context, _) => builder(context),
  );
}

class AppBarAni extends StatelessWidget {
  const AppBarAni({
    super.key,
    required this.child,
    required this.controller,
    required this.isTop,
    required this.isFullScreen,
    required this.removeSafeArea,
    this.bottomPadding = 0,
    this.gradientExtent = 0,
  });

  final Widget child;
  final AnimationController controller;
  final bool isTop;
  final bool isFullScreen;
  final bool removeSafeArea;
  final double bottomPadding;
  final double gradientExtent;

  static final _topPos = Tween<Offset>(
    begin: const Offset(0.0, -1.0),
    end: Offset.zero,
  );

  static const _topDecoration = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: <Color>[
      Colors.transparent,
      Color(0xBF000000),
    ],
    tileMode: TileMode.mirror,
  );

  static final _bottomPos = Tween<Offset>(
    begin: const Offset(0, 1.2),
    end: Offset.zero,
  );

  static const _bottomDecoration = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      Colors.transparent,
      Color(0xBF000000),
    ],
    tileMode: TileMode.mirror,
  );

  @override
  Widget build(BuildContext context) {
    final bar = Padding(
      padding: EdgeInsets.only(bottom: isTop ? 0 : bottomPadding),
      child: removeSafeArea
          ? child
          : ViewSafeArea(
              left: isFullScreen,
              right: isFullScreen,
              child: child,
            ),
    );

    return SlideTransition(
      position: controller.drive(isTop ? _topPos : _bottomPos),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isTop ? _topDecoration : _bottomDecoration,
        ),
        child: Padding(
          padding: EdgeInsets.only(
            top: isTop ? 0 : gradientExtent,
            bottom: isTop ? gradientExtent : 0,
          ),
          child: bar,
        ),
      ),
    );
  }
}
