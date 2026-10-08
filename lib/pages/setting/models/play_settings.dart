import 'dart:io' show Platform;

import 'package:PiliPlus/common/widgets/custom_icon.dart';
import 'package:PiliPlus/models/common/super_chat_type.dart';
import 'package:PiliPlus/models/common/video/subtitle_pref_type.dart';
import 'package:PiliPlus/pages/main/controller.dart';
import 'package:PiliPlus/pages/setting/models/model.dart';
import 'package:PiliPlus/pages/setting/pages/fullscreen_sc_size.dart';
import 'package:PiliPlus/pages/setting/utils/local_font_setting.dart';
import 'package:PiliPlus/pages/setting/widgets/select_dialog.dart';
import 'package:PiliPlus/pages/setting/widgets/slider_dialog.dart';
import 'package:PiliPlus/pages/setting/widgets/danmaku_merge_settings_dialog.dart';
import 'package:PiliPlus/plugin/pl_player/models/bottom_progress_behavior.dart';
import 'package:PiliPlus/plugin/pl_player/models/fullscreen_mode.dart';
import 'package:PiliPlus/plugin/pl_player/models/play_repeat.dart';
import 'package:PiliPlus/services/service_locator.dart';
import 'package:PiliPlus/utils/extension/num_ext.dart';
import 'package:PiliPlus/utils/local_font_manager.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

List<SettingsModel> get playSettings => [
  const SwitchModel(
    title: '弹幕开关',
    subtitle: '是否展示弹幕',
    leading: Icon(CustomIcons.dm_settings),
    setKey: SettingBoxKey.enableShowDanmaku,
    defaultVal: true,
  ),
  const SwitchModel(
    title: '记忆弹幕开关状态',
    subtitle: '关闭后，每次打开新视频都使用上方的默认弹幕开关状态',
    leading: Icon(Icons.history_toggle_off_outlined),
    setKey: SettingBoxKey.rememberDanmakuSwitchState,
    defaultVal: false,
  ),
  NormalModel(
    title: '弹幕中文字体',
    getSubtitle: () =>
        '当前：${LocalFontManager.selectionLabel(.danmakuChinese)}',
    leading: const Icon(Icons.translate),
    onTap: (context, setState) => showLocalFontSetting(
      context,
      slot: .danmakuChinese,
      onChanged: setState,
    ),
  ),
  NormalModel(
  title: '弹幕英文字体',
  getSubtitle: () =>
      '当前：${LocalFontManager.selectionLabel(.danmakuEnglish)}',
  leading: const Icon(Icons.font_download_outlined),
  onTap: (context, setState) => showLocalFontSetting(
    context,
    slot: .danmakuEnglish,
    onChanged: setState,
  ),
),
NormalModel(
  title: '重复弹幕合并',
  getSubtitle: () =>
      '当前：${Pref.danmakuMergeMode.label}',
  leading: const Icon(Icons.compress_outlined),
  onTap: (context, setState) async {
    final changed =
        await showDanmakuMergeSettingsDialog(
      context,
    );

    if (changed) {
      setState();
    }
  },
),
if (PlatformUtils.isMobile)
  const SwitchModel(
      title: '启用点击弹幕',
      subtitle: '点击弹幕悬停，支持点赞、复制、举报操作',
      leading: Icon(Icons.touch_app_outlined),
      setKey: SettingBoxKey.enableTapDm,
      defaultVal: true,
    ),
  NormalModel(
    onTap: (context, setState) => Get.toNamed('/playSpeedSet'),
    leading: const Icon(Icons.speed_outlined),
    title: '倍速设置',
    subtitle: '设置视频播放速度',
  ),
  NormalModel(
    title: '长按倍速触发延迟',
    getSubtitle: () => '当前：${Pref.longPressSpeedTriggerDelay}ms',
    leading: const Icon(Icons.timer_outlined),
    onTap: _showLongPressSpeedTriggerDelayDialog,
  ),
  const SwitchModel(
    title: '显示倍速浮窗',
    subtitle: '长按倍速时显示当前倍速提示',
    leading: Icon(Icons.speed),
    setKey: SettingBoxKey.showLongPressSpeedToast,
    defaultVal: true,
  ),
  if (Platform.isAndroid)
    NormalModel(
      onTap: _showAngleDegreesDialog,
      leading: const Icon(MdiIcons.angleAcute),
      title: '倾斜角度阈值',
      getSubtitle: () => '当前:「${Pref.angleDegrees}°」',
    ),
  const SwitchModel(
    title: '自动播放',
    subtitle: '进入详情页自动播放',
    leading: Icon(Icons.motion_photos_auto_outlined),
    setKey: SettingBoxKey.autoPlayEnable,
    defaultVal: false,
  ),
  const SwitchModel(
    title: '全屏显示锁定按钮',
    leading: Icon(Icons.lock_outline),
    setKey: SettingBoxKey.showFsLockBtn,
    defaultVal: true,
  ),
  const SwitchModel(
    title: '全屏显示截图按钮',
    leading: Icon(Icons.photo_camera_outlined),
    setKey: SettingBoxKey.showFsScreenshotBtn,
    defaultVal: true,
  ),
  SplitModel(
    watchKey: SettingBoxKey.skipOpDurationSeconds,
    normalModel: NormalModel.split(
      title: '全屏显示跳过 OP 按钮',
      getSubtitle: () =>
          '当前：${Pref.skipOpDurationSeconds}秒；点击设置跳过时长',
      leading: const Icon(Icons.fast_forward_rounded),
    ),
    switchModel: const SwitchModel.split(
      setKey: SettingBoxKey.showFsSkipOpBtn,
      defaultVal: true,
      onTap: _showSkipOpDurationDialog,
    ),
  ),
  SwitchModel(
    title: '全屏显示电池电量',
    leading: const Icon(Icons.battery_3_bar),
    setKey: SettingBoxKey.showBatteryLevel,
    defaultVal: PlatformUtils.isMobile,
  ),
  const SwitchModel(
    title: '电池电量显示百分比',
    subtitle: '关闭后显示竖排电量图标',
    leading: Icon(Icons.battery_full),
    setKey: SettingBoxKey.showBatteryPercentage,
    defaultVal: true,
  ),
  const SwitchModel(
    title: '显示 mpv 帧率与丢帧',
    subtitle:
        '帧率：根据最近 10 帧估算的每秒输出画面数；'
        '已丢帧：因来不及显示而累计跳过的画面数，不含解码阶段丢帧',
    leading: Icon(Icons.speed_outlined),
    setKey: SettingBoxKey.showMpvOutputFps,
    defaultVal: false,
  ),
  const SwitchModel(
    title: '显示缓冲速度',
    subtitle: '缓冲速度每 500ms 刷新；无法获取有效速度时仅显示“加载中”',
    leading: Icon(Icons.cloud_download_outlined),
    setKey: SettingBoxKey.showBufferingInfo,
    defaultVal: true,
  ),
  const SwitchModel(
    title: '双击快退/快进',
    subtitle: '左侧双击快退/右侧双击快进，关闭则双击均为暂停/播放',
    leading: Icon(Icons.touch_app_outlined),
    setKey: SettingBoxKey.enableQuickDouble,
    defaultVal: true,
  ),
  const SwitchModel(
    title: '左右侧滑动调节亮度/音量',
    leading: Icon(MdiIcons.tuneVerticalVariant),
    setKey: SettingBoxKey.enableSlideVolumeBrightness,
    defaultVal: true,
  ),
  if (Platform.isAndroid)
    const SwitchModel(
      title: '调节系统亮度',
      leading: Icon(Icons.brightness_6_outlined),
      setKey: SettingBoxKey.setSystemBrightness,
      defaultVal: false,
    ),
  const SwitchModel(
    title: '中间滑动进入/退出全屏',
    leading: Icon(MdiIcons.panVertical),
    setKey: SettingBoxKey.enableSlideFS,
    defaultVal: true,
  ),
  NormalModel(
    title: '双指缩放识别角度',
    getSubtitle: () =>
        '当前：${Pref.pinchGestureAngleThreshold.toStringAsFixed(0)}°；越大越容易触发',
    leading: const Icon(Icons.pinch),
    onTap: _showPinchGestureAngleThresholdDialog,
  ),
  if (PlatformUtils.isMobile)
    NormalModel(
      title: '播放器音量',
      leading: const Icon(Icons.volume_up),
      getSubtitle: () => '当前:「${Pref.playerVolume.toStringAsFixed(0)}%」',
      onTap: showPlayerVolumeDialog,
    )
  else
    NormalModel(
      title: '最高音量',
      leading: const Icon(Icons.volume_up),
      getSubtitle: () => '当前:「${(Pref.maxVolume * 100).toStringAsFixed(0)}%」',
      onTap: _showMaxVolumeDialog,
    ),
  getVideoFilterSelectModel(
    title: '双击快进/快退时长',
    suffix: 's',
    key: SettingBoxKey.fastForBackwardDuration,
    values: [5, 10, 15],
    defaultValue: 10,
    isFilter: false,
  ),
  const SwitchModel(
    title: '滑动快进/快退使用相对时长',
    leading: Icon(Icons.swap_horiz_outlined),
    setKey: SettingBoxKey.useRelativeSlide,
    defaultVal: false,
  ),
  getVideoFilterSelectModel(
    title: '滑动快进/快退时长',
    subtitle: '从播放器一端滑到另一端的快进/快退时长',
    suffix: Pref.useRelativeSlide ? '%' : 's',
    key: SettingBoxKey.sliderDuration,
    values: [25, 50, 90, 100],
    defaultValue: 90,
    isFilter: false,
  ),
  NormalModel(
    title: '水平滑动快进/快退触发距离',
    getSubtitle: () =>
        '当前：${Pref.horizontalSeekGestureThreshold.toStringAsFixed(0)}dp；越小越容易触发',
    leading: const Icon(Icons.swipe_outlined),
    onTap: _showHorizontalSeekGestureThresholdDialog,
  ),
  const SwitchModel(
    title: '使用B站官方进度时间样式',
    subtitle: '当前时间和总时长显示在进度条两侧，并压缩底栏与渐变阴影高度',
    leading: Icon(Icons.video_label_outlined),
    setKey: SettingBoxKey.biliProgressTimeStyle,
    defaultVal: false,
  ),
  NormalModel(
    title: '进度条手柄圆形大小',
    getSubtitle: () =>
        '当前：${Pref.playerProgressThumbScale.toStringAsFixed(1)}×；放大后更容易拖动',
    leading: const Icon(Icons.radio_button_checked),
    onTap: _showPlayerProgressThumbScaleDialog,
  ),
  NormalModel(
    title: '点击进度条垂直触摸范围',
    getSubtitle: () =>
        '当前：上下各扩展${Pref.playerProgressBarTouchPadding.toStringAsFixed(0)}dp；不改变可视尺寸',
    leading: const Icon(Icons.unfold_more),
    onTap: _showPlayerProgressBarTouchPaddingDialog,
  ),
  NormalModel(
    title: '播放器上下按钮横向边距',
    getSubtitle: () =>
        '当前：${Pref.playerControlHorizontalPadding.toStringAsFixed(0)}dp',
    leading: const Icon(Icons.horizontal_distribute_outlined),
    onTap: _showPlayerControlHorizontalPaddingDialog,
  ),
  NormalModel(
    title: '播放器上下边栏整体厚度',
    getSubtitle: () =>
        '当前：${Pref.playerControlBarThicknessScale.toStringAsFixed(1)}×；同步调整内容纵向密度',
    leading: const Icon(Icons.height),
    onTap: _showPlayerControlBarThicknessScaleDialog,
  ),
  NormalModel(
    title: '播放器上下边栏渐变弥散宽度',
    getSubtitle: () =>
        '当前：${Pref.playerControlBarGradientExtent.toStringAsFixed(0)}dp',
    leading: const Icon(Icons.gradient),
    onTap: _showPlayerControlBarGradientExtentDialog,
  ),
  SwitchModel(
    title: '拖动进度条显示预览浮窗',
    subtitle: '控制拖动底部进度条滑块时的预览浮窗',
    leading: const Icon(Icons.preview_outlined),
    setKey: SettingBoxKey.showSeekPreviewOnSlider,
    defaultVal: Pref.showSeekPreview,
  ),
  SwitchModel(
    title: '左右滑动手势显示预览浮窗',
    subtitle: '控制在画面上横向滑动快进或快退时的预览浮窗',
    leading: const Icon(Icons.swipe_outlined),
    setKey: SettingBoxKey.showSeekPreviewOnGesture,
    defaultVal: Pref.showSeekPreview,
  ),
  const SwitchModel(
    title: '提前下载进度预览资源',
    subtitle: '起播或预载播放器时下载全部雪碧图和对应索引',
    leading: Icon(Icons.downloading_outlined),
    setKey: SettingBoxKey.preloadVideoShot,
    defaultVal: true,
  ),
  const SwitchModel(
    title: '当前时间浮窗集成到预览窗',
    subtitle: '开启后，时间浮窗在预览窗内部显示并随预览窗移动；没有预览窗时仍单独显示',
    leading: Icon(Icons.layers_outlined),
    setKey: SettingBoxKey.seekTimeInPreview,
    defaultVal: false,
  ),
  const SwitchModel(
  title: '拖动进度条时预览窗跟随滑块',
  subtitle: '拖动底部进度条时，预览窗随滑块水平移动',
  leading: Icon(Icons.swipe),
  setKey: SettingBoxKey.seekPreviewFollowSlider,
  defaultVal: false,
),
  const SwitchModel(
  title: '横滑快进/快退时预览窗跟随手柄',
  subtitle: '在画面上横向滑动时，预览窗随目标进度的进度条手柄移动',
  leading: Icon(Icons.swap_horiz),
  setKey: SettingBoxKey.seekPreviewFollowGesture,
  defaultVal: false,
),
  NormalModel(
    title: '进度预览窗大小',
    getSubtitle: () => '当前：${Pref.seekPreviewScale.toStringAsFixed(1)}×',
    leading: const Icon(Icons.photo_size_select_large),
    onTap: _showSeekPreviewScaleDialog,
  ),
  NormalModel(
    title: '进度预览窗与进度条间距',
    getSubtitle: () =>
        '当前：${Pref.seekPreviewProgressBarGap.toStringAsFixed(0)}dp',
    leading: const Icon(Icons.vertical_align_center_outlined),
    onTap: _showSeekPreviewProgressBarGapDialog,
  ),
  const SwitchModel(
    title: '非全屏拖动进度条显示预览窗',
    subtitle: '关闭后，全屏拖动进度条仍显示预览窗',
    leading: Icon(Icons.fullscreen_exit_outlined),
    setKey: SettingBoxKey.showSeekPreviewInNonFullscreen,
    defaultVal: true,
  ),
  NormalModel(
    title: '自动启用字幕',
    leading: const Icon(Icons.closed_caption_outlined),
    getSubtitle: () => '当前选择偏好：${Pref.subtitlePreferenceV2.desc}',
    onTap: _showSubtitleDialog,
  ),
  if (PlatformUtils.isDesktop)
    SwitchModel(
      title: '最小化时暂停/还原时播放',
      leading: const Icon(Icons.pause_circle_outline),
      setKey: SettingBoxKey.pauseOnMinimize,
      defaultVal: false,
      onChanged: (value) {
        try {
          Get.find<MainController>().pauseOnMinimize = value;
        } catch (_) {}
      },
    ),
  const SwitchModel(
    title: '启用键盘控制',
    leading: Icon(Icons.keyboard_alt_outlined),
    setKey: SettingBoxKey.keyboardControl,
    defaultVal: true,
  ),
  NormalModel(
    title: 'SuperChat (醒目留言) 显示类型',
    leading: const Icon(Icons.live_tv),
    getSubtitle: () => '当前:「${Pref.superChatType.title}」',
    onTap: _showSuperChatDialog,
  ),
  NormalModel(
    title: '全屏 SC 大小',
    subtitle: 'SuperChat (醒目留言) 大小设置',
    leading: const Icon(Icons.open_in_full),
    onTap: (_, _) => Get.to(const FullScreenScSize()),
  ),
  const SwitchModel(
    title: '竖屏扩大展示',
    subtitle: '小屏竖屏视频宽高比由16:9扩大至1:1（不支持收起）；横屏适配时，扩大至9:16',
    leading: Icon(Icons.expand_outlined),
    setKey: SettingBoxKey.enableVerticalExpand,
    defaultVal: false,
  ),
  const SwitchModel(
    title: '自动全屏',
    subtitle: '视频开始播放时进入全屏',
    leading: Icon(Icons.fullscreen_outlined),
    setKey: SettingBoxKey.enableAutoEnter,
    defaultVal: false,
  ),
  NormalModel(
  title: '全屏画质切换强制接管',
  getSubtitle: () {
    final seconds =
        Pref.videoPlayerSwitchForceTimeoutSeconds;

    return seconds == 0
        ? '当前：关闭；仅在完全同步后切换'
        : '当前：${seconds}秒；超时后切换并进入缓冲';
  },
  leading: const Icon(Icons.sync_problem_outlined),
  onTap: _showVideoPlayerSwitchForceTimeoutDialog,
),
  const SwitchModel(
    title: '自动退出全屏',
    subtitle: '视频结束播放时退出全屏',
    leading: Icon(Icons.fullscreen_exit_outlined),
    setKey: SettingBoxKey.enableAutoExit,
    defaultVal: true,
  ),
  NormalModel(
  title: '播放控件显示时间',
  getSubtitle: () =>
      '当前：${Pref.playerControlDisplayDurationSeconds}秒；'
      '无操作后自动隐藏',
  leading: const Icon(Icons.timer_outlined),
  onTap: _showPlayerControlDisplayDurationDialog,
),
  if (PlatformUtils.isMobile)
    const SwitchModel(
      title: '后台播放',
      subtitle: '进入后台时继续播放',
      leading: Icon(Icons.motion_photos_pause_outlined),
      setKey: SettingBoxKey.continuePlayInBackground,
      defaultVal: false,
    ),
  if (Platform.isAndroid) ...[
    SwitchModel(
      title: '后台画中画',
      subtitle: '进入后台时以小窗形式（PiP）播放',
      leading: const Icon(Icons.picture_in_picture_outlined),
      setKey: SettingBoxKey.autoPiP,
      defaultVal: false,
      onChanged: (val) {
        if (val && !videoPlayerServiceHandler!.enableBackgroundPlay) {
          SmartDialog.showToast('建议开启后台音频服务');
        }
      },
    ),
    const SwitchModel(
      title: '画中画不加载弹幕',
      subtitle: '当弹幕开关开启时，小窗屏蔽弹幕以获得较好的体验',
      leading: Icon(CustomIcons.dm_off),
      setKey: SettingBoxKey.pipNoDanmaku,
      defaultVal: false,
    ),
  ],
  const SwitchModel(
    title: '全屏手势反向',
    subtitle: '默认播放器中部向上滑动进入全屏，向下退出\n开启后向下全屏，向上退出',
    leading: Icon(Icons.swap_vert),
    setKey: SettingBoxKey.fullScreenGestureReverse,
    defaultVal: false,
  ),
  const SwitchModel(
    title: '全屏展示点赞/投币/收藏等操作按钮',
    leading: Icon(MdiIcons.dotsHorizontalCircleOutline),
    setKey: SettingBoxKey.showFSActionItem,
    defaultVal: true,
  ),
  const SwitchModel(
    title: '观看人数',
    subtitle: '展示同时在看人数',
    leading: Icon(Icons.people_outlined),
    setKey: SettingBoxKey.enableOnlineTotal,
    defaultVal: false,
  ),
  NormalModel(
    title: '默认全屏方向',
    leading: const Icon(Icons.open_with_outlined),
    getSubtitle: () => '当前全屏方向：${Pref.fullScreenMode.desc}',
    onTap: _showFullScreenModeDialog,
  ),
  NormalModel(
    title: '底部进度条展示',
    leading: const Icon(Icons.border_bottom_outlined),
    getSubtitle: () => '当前展示方式：${Pref.btmProgressBehavior.desc}',
    onTap: _showProgressBehaviorDialog,
  ),
  if (PlatformUtils.isMobile)
    SwitchModel(
      title: '后台音频服务',
      subtitle: '避免画中画没有播放暂停功能',
      leading: const Icon(Icons.volume_up_outlined),
      setKey: SettingBoxKey.enableBackgroundPlay,
      defaultVal: true,
      onChanged: (value) =>
          videoPlayerServiceHandler!.enableBackgroundPlay = value,
    ),
  PopupModel(
    title: '播放顺序',
    leading: const Icon(Icons.repeat),
    value: () => Pref.playRepeat,
    items: PlayRepeat.values,
    onSelected: (value, setState) => GStorage.video
        .put(VideoBoxKey.playRepeat, value.index)
        .whenComplete(setState),
  ),
  const SwitchModel(
    title: '播放器设置仅对当前生效',
    subtitle: '弹幕、字幕及部分设置中没有的设置除外',
    leading: Icon(Icons.video_settings_outlined),
    setKey: SettingBoxKey.tempPlayerConf,
    defaultVal: false,
  ),
];

Future<void> _showLongPressSpeedTriggerDelayDialog(
  BuildContext context,
  VoidCallback setState,
) async {
  final res = await showDialog<double>(
    context: context,
    builder: (context) => SliderDialog(
      title: const Text('长按倍速触发延迟'),
      value: Pref.longPressSpeedTriggerDelay.toDouble(),
      min: 100,
      max: 1000,
      divisions: 18,
      precise: 0,
      suffix: 'ms',
    ),
  );
  if (res != null) {
    await GStorage.setting.put(
      SettingBoxKey.longPressSpeedTriggerDelay,
      res.toInt(),
    );
    setState();
  }
}

Future<void> _showSkipOpDurationDialog(BuildContext context) async {
  final result = await showDialog<double>(
    context: context,
    builder: (context) => SliderDialog(
      title: const Text('跳过 OP 时长'),
      value: Pref.skipOpDurationSeconds.toDouble(),
      min: 1,
      max: 300,
      divisions: 299,
      precise: 0,
      suffix: '秒',
    ),
  );
  if (result != null) {
    await GStorage.setting.put(
      SettingBoxKey.skipOpDurationSeconds,
      result.round(),
    );
  }
}

Future<void> _showPlayerControlDisplayDurationDialog(
  BuildContext context,
  VoidCallback setState,
) async {
  final result = await showDialog<double>(
    context: context,
    builder: (context) => SliderDialog(
      title: const Text('播放控件显示时间'),
      value: Pref.playerControlDisplayDurationSeconds.toDouble(),
      min: 1,
      max: 60,
      divisions: 59,
      precise: 0,
      suffix: '秒',
    ),
  );

  if (result == null) {
    return;
  }

  await GStorage.setting.put(
    SettingBoxKey.playerControlDisplayDurationSeconds,
    result.round(),
  );

  // 新数值已经保存，删除旧布尔键，完成惰性迁移。
  await GStorage.setting.delete(
    SettingBoxKey.enableLongShowControl,
  );

  setState();
}
Future<void> _showVideoPlayerSwitchForceTimeoutDialog(
  BuildContext context,
  VoidCallback setState,
) async {
  final result = await showDialog<double>(
    context: context,
    builder: (context) => SliderDialog(
      title: const Text('全屏画质切换强制接管'),
      value:
          Pref.videoPlayerSwitchForceTimeoutSeconds.toDouble(),
      min: 0,
      max: 60,
      divisions: 60,
      precise: 0,
      suffix: '秒',
    ),
  );

  if (result == null) {
    return;
  }

  await GStorage.setting.put(
    SettingBoxKey.videoPlayerSwitchForceTimeoutSeconds,
    result.round(),
  );

  setState();
}
Future<void> _showPinchGestureAngleThresholdDialog(
  BuildContext context,
  VoidCallback setState,
) async {
  final res = await showDialog<double>(
    context: context,
    builder: (context) => SliderDialog(
      title: const Text('双指缩放识别角度'),
      value: Pref.pinchGestureAngleThreshold,
      min: 15,
      max: 90,
      divisions: 15,
      precise: 0,
      suffix: '°',
    ),
  );
  if (res != null) {
    await GStorage.setting.put(
      SettingBoxKey.pinchGestureAngleThreshold,
      res,
    );
    setState();
  }
}

Future<void> _showHorizontalSeekGestureThresholdDialog(
  BuildContext context,
  VoidCallback setState,
) async {
  final res = await showDialog<double>(
    context: context,
    builder: (context) => SliderDialog(
      title: const Text('水平滑动快进/快退触发距离'),
      value: Pref.horizontalSeekGestureThreshold,
      min: 1,
      max: 100,
      divisions: 99,
      precise: 0,
      suffix: 'dp',
    ),
  );
  if (res != null) {
    await GStorage.setting.put(
      SettingBoxKey.horizontalSeekGestureThreshold,
      res,
    );
    setState();
  }
}

Future<void> _showPlayerProgressThumbScaleDialog(
  BuildContext context,
  VoidCallback setState,
) async {
  final res = await showDialog<double>(
    context: context,
    builder: (context) => SliderDialog(
      title: const Text('进度条手柄圆形大小'),
      value: Pref.playerProgressThumbScale,
      min: 0.5,
      max: 2.0,
      divisions: 15,
      precise: 1,
      suffix: '×',
    ),
  );
  if (res != null) {
    await GStorage.setting.put(
      SettingBoxKey.playerProgressThumbScale,
      res,
    );
    setState();
  }
}

Future<void> _showPlayerProgressBarTouchPaddingDialog(
  BuildContext context,
  VoidCallback setState,
) async {
  final res = await showDialog<double>(
    context: context,
    builder: (context) => SliderDialog(
      title: const Text('点击进度条垂直触摸范围'),
      value: Pref.playerProgressBarTouchPadding,
      min: 0,
      max: 32,
      divisions: 32,
      precise: 0,
      suffix: 'dp',
    ),
  );
  if (res != null) {
    await GStorage.setting.put(
      SettingBoxKey.playerProgressBarTouchPadding,
      res,
    );
    setState();
  }
}

Future<void> _showSeekPreviewScaleDialog(
  BuildContext context,
  VoidCallback setState,
) async {
  final res = await showDialog<double>(
    context: context,
    builder: (context) => SliderDialog(
      title: const Text('进度预览窗大小'),
      value: Pref.seekPreviewScale,
      min: 0.5,
      max: 2.0,
      divisions: 15,
      precise: 1,
      suffix: '×',
    ),
  );
  if (res != null) {
    await GStorage.setting.put(SettingBoxKey.seekPreviewScale, res);
    setState();
  }
}

Future<void> _showSeekPreviewProgressBarGapDialog(
  BuildContext context,
  VoidCallback setState,
) async {
  final res = await showDialog<double>(
    context: context,
    builder: (context) => SliderDialog(
      title: const Text('进度预览窗与进度条间距'),
      value: Pref.seekPreviewProgressBarGap,
      min: 0,
      max: 160,
      divisions: 32,
      precise: 0,
      suffix: 'dp',
    ),
  );
  if (res != null) {
    await GStorage.setting.put(
      SettingBoxKey.seekPreviewProgressBarGap,
      res,
    );
    setState();
  }
}

Future<void> _showPlayerControlHorizontalPaddingDialog(
  BuildContext context,
  VoidCallback setState,
) async {
  final res = await showDialog<double>(
    context: context,
    builder: (context) => SliderDialog(
      title: const Text('播放器上下按钮横向边距'),
      value: Pref.playerControlHorizontalPadding,
      min: 0,
      max: 32,
      divisions: 32,
      precise: 0,
      suffix: 'dp',
    ),
  );
  if (res != null) {
    await GStorage.setting.put(
      SettingBoxKey.playerControlHorizontalPadding,
      res,
    );
    setState();
  }
}

Future<void> _showPlayerControlBarThicknessScaleDialog(
  BuildContext context,
  VoidCallback setState,
) async {
  final res = await showDialog<double>(
    context: context,
    builder: (context) => SliderDialog(
      title: const Text('播放器上下边栏整体厚度'),
      value: Pref.playerControlBarThicknessScale,
      min: 0.8,
      max: 1.5,
      divisions: 7,
      precise: 1,
      suffix: '×',
    ),
  );
  if (res != null) {
    await GStorage.setting.put(
      SettingBoxKey.playerControlBarThicknessScale,
      res,
    );
    setState();
  }
}

Future<void> _showPlayerControlBarGradientExtentDialog(
  BuildContext context,
  VoidCallback setState,
) async {
  final res = await showDialog<double>(
    context: context,
    builder: (context) => SliderDialog(
      title: const Text('播放器上下边栏渐变弥散宽度'),
      value: Pref.playerControlBarGradientExtent,
      min: 0,
      max: 96,
      divisions: 24,
      precise: 0,
      suffix: 'dp',
    ),
  );
  if (res != null) {
    await GStorage.setting.put(
      SettingBoxKey.playerControlBarGradientExtent,
      res,
    );
    setState();
  }
}

Future<void> _showSubtitleDialog(
  BuildContext context,
  VoidCallback setState,
) async {
  final res = await showDialog<SubtitlePrefType>(
    context: context,
    builder: (context) => SelectDialog<SubtitlePrefType>(
      title: '字幕选择偏好',
      value: Pref.subtitlePreferenceV2,
      values: SubtitlePrefType.values.map((e) => (e, e.desc)).toList(),
    ),
  );
  if (res != null) {
    await GStorage.setting.put(
      SettingBoxKey.subtitlePreferenceV2,
      res.index,
    );
    setState();
  }
}

Future<void> _showSuperChatDialog(
  BuildContext context,
  VoidCallback setState,
) async {
  final res = await showDialog<SuperChatType>(
    context: context,
    builder: (context) => SelectDialog<SuperChatType>(
      title: 'SuperChat (醒目留言) 显示类型',
      value: Pref.superChatType,
      values: SuperChatType.values.map((e) => (e, e.title)).toList(),
    ),
  );
  if (res != null) {
    await GStorage.setting.put(SettingBoxKey.superChatType, res.index);
    setState();
  }
}

Future<void> _showFullScreenModeDialog(
  BuildContext context,
  VoidCallback setState,
) async {
  final res = await showDialog<FullScreenMode>(
    context: context,
    builder: (context) => SelectDialog<FullScreenMode>(
      title: '默认全屏方向',
      value: Pref.fullScreenMode,
      values: FullScreenMode.values.map((e) => (e, e.desc)).toList(),
    ),
  );
  if (res != null) {
    await GStorage.setting.put(SettingBoxKey.fullScreenMode, res.index);
    setState();
  }
}

Future<void> _showProgressBehaviorDialog(
  BuildContext context,
  VoidCallback setState,
) async {
  final res = await showDialog<BtmProgressBehavior>(
    context: context,
    builder: (context) => SelectDialog<BtmProgressBehavior>(
      title: '底部进度条展示',
      value: Pref.btmProgressBehavior,
      values: BtmProgressBehavior.values.map((e) => (e, e.desc)).toList(),
    ),
  );
  if (res != null) {
    await GStorage.setting.put(
      SettingBoxKey.btmProgressBehavior,
      res.index,
    );
    setState();
  }
}

Future<void> _showAngleDegreesDialog(
  BuildContext context,
  VoidCallback setState,
) async {
  final res = await showDialog<double>(
    context: context,
    builder: (context) => SliderDialog(
      title: const Text('倾斜角度阈值'),
      min: 10.0,
      max: 90.0,
      divisions: 90,
      precise: 0,
      value: Pref.angleDegrees.toDouble(),
      suffix: '°',
    ),
  );
  if (res != null) {
    await GStorage.setting.put(SettingBoxKey.angleDegrees, res.toInt());
    setState();
  }
}

Future<void> showPlayerVolumeDialog(
  BuildContext context,
  VoidCallback setState, {
  ValueChanged<double>? onChanged,
}) {
  return showVolumeDialog(
    context,
    title: const Text('播放器音量'),
    value: Pref.playerVolume,
    onChanged: (value) => GStorage.setting
        .put(SettingBoxKey.playerVolume, value)
        .whenComplete(() {
          setState();
          onChanged?.call(value);
        }),
  );
}

Future<void> _showMaxVolumeDialog(
  BuildContext context,
  VoidCallback setState,
) {
  return showVolumeDialog(
    context,
    title: const Text('最高音量'),
    value: Pref.maxVolume * 100,
    onChanged: (rawValue) {
      final maxVolume = (rawValue / 100).toPrecision(2);
      if (Pref.desktopVolume > maxVolume) {
        GStorage.setting.put(SettingBoxKey.desktopVolume, maxVolume);
      }
      GStorage.setting
          .put(SettingBoxKey.maxVolume, maxVolume)
          .whenComplete(setState);
    },
  );
}

const kMinVolume = 100.0;
const kMaxVolume = 300.0;

Future<void> showVolumeDialog(
  BuildContext context, {
  required Widget title,
  required double value,
  required ValueChanged<double> onChanged,
}) async {
  final res = await showDialog<double>(
    context: context,
    builder: (context) => SliderDialog(
      title: title,
      min: kMinVolume,
      max: kMaxVolume,
      divisions: 40,
      precise: 0,
      value: value,
      suffix: '%',
    ),
  );
  if (res != null) {
    onChanged(res);
  }
}
