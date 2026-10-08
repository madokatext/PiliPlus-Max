import 'dart:io';
import 'package:PiliPlus/models/common/danmaku_merge_mode.dart';
import 'package:PiliPlus/common/widgets/gesture/horizontal_drag_gesture_recognizer.dart'
    show deviceTouchSlop;
import 'package:PiliPlus/common/widgets/pair.dart';
import 'package:PiliPlus/http/constants.dart';
import 'package:PiliPlus/models/common/bar_hide_type.dart';
import 'package:PiliPlus/models/common/dynamic/dynamic_badge_mode.dart';
import 'package:PiliPlus/models/common/dynamic/dynamics_type.dart';
import 'package:PiliPlus/models/common/dynamic/up_panel_position.dart';
import 'package:PiliPlus/models/common/follow_order_type.dart';
import 'package:PiliPlus/models/common/home_card_aspect_ratio.dart';
import 'package:PiliPlus/models/common/member/tab_type.dart';
import 'package:PiliPlus/models/common/msg/msg_unread_type.dart';
import 'package:PiliPlus/models/common/nav_bar_config.dart';
import 'package:PiliPlus/models/common/reply/reply_sort_type.dart';
import 'package:PiliPlus/models/common/recommend_history_filter_settings.dart';
import 'package:PiliPlus/models/common/sponsor_block/segment_type.dart';
import 'package:PiliPlus/models/common/sponsor_block/skip_type.dart';
import 'package:PiliPlus/models/common/super_chat_type.dart';
import 'package:PiliPlus/models/common/super_resolution_type.dart';
import 'package:PiliPlus/models/common/theme/theme_color_type.dart';
import 'package:PiliPlus/models/common/theme/theme_type.dart';
import 'package:PiliPlus/models/common/video/audio_quality.dart';
import 'package:PiliPlus/models/common/video/cdn_type.dart';
import 'package:PiliPlus/models/common/video/live_quality.dart';
import 'package:PiliPlus/models/common/video/subtitle_pref_type.dart';
import 'package:PiliPlus/models/common/video/video_decode_type.dart';
import 'package:PiliPlus/models/common/video/video_quality.dart';
import 'package:PiliPlus/models/user/danmaku_rule.dart';
import 'package:PiliPlus/models/user/info.dart';
import 'package:PiliPlus/pages/setting/pages/fullscreen_sc_size.dart'
    show kFullScreenSCWidth;
import 'package:PiliPlus/plugin/pl_player/models/audio_output_type.dart';
import 'package:PiliPlus/plugin/pl_player/models/bottom_progress_behavior.dart';
import 'package:PiliPlus/plugin/pl_player/models/fullscreen_mode.dart';
import 'package:PiliPlus/plugin/pl_player/models/hwdec_type.dart';
import 'package:PiliPlus/plugin/pl_player/models/play_repeat.dart';
import 'package:PiliPlus/utils/device_utils.dart';
import 'package:PiliPlus/utils/extension/iterable_ext.dart';
import 'package:PiliPlus/utils/global_data.dart';
import 'package:PiliPlus/utils/login_utils.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:crypto/crypto.dart';
import 'package:flex_seed_scheme/flex_seed_scheme.dart' show FlexSchemeVariant;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';

abstract final class Pref {
  static final Box _setting = GStorage.setting;
  static final Box _video = GStorage.video;
  static final Box _localCache = GStorage.localCache;

  static double _getClampedDouble(
    String key,
    double defaultValue,
    double min,
    double max,
  ) {
    final value = _setting.get(key, defaultValue: defaultValue);
    return (value is num ? value.toDouble() : defaultValue)
        .clamp(min, max)
        .toDouble();
  }

  static UserInfoData? get userInfoCache =>
      GStorage.userInfo.get('userInfoCache');

  static List<double> get dynamicDetailRatio => List<double>.from(
    _setting.get(
      SettingBoxKey.dynamicDetailRatio,
      defaultValue: const [60.0, 40.0],
    ),
  );

  static Set<int> get blackMids =>
      _localCache.get(LocalCacheKey.blackMids, defaultValue: <int>{});

  static set blackMids(Set<int> blackMidsSet) =>
      _localCache.put(LocalCacheKey.blackMids, blackMidsSet);

  static RuleFilter get danmakuFilterRule => _localCache.get(
    LocalCacheKey.danmakuFilterRules,
    defaultValue: RuleFilter.empty(),
  );

  static void setBlackMid(int mid) => _localCache.put(
    LocalCacheKey.blackMids,
    GlobalData().blackMids..add(mid),
  );

  static void removeBlackMid(int mid) => _localCache.put(
    LocalCacheKey.blackMids,
    GlobalData().blackMids..remove(mid),
  );

  static MemberTabType get memberTab =>
      MemberTabType.values[_setting.get(
        SettingBoxKey.memberTab,
        defaultValue: 0,
      )];

  static int get _themeTypeInt => _setting.get(
    SettingBoxKey.themeMode,
    defaultValue: ThemeType.system.index,
  );

  static ThemeType get themeType => ThemeType.values[_themeTypeInt];

  static ThemeMode get themeMode => switch (_themeTypeInt) {
    0 => ThemeMode.light,
    1 => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  static List<double> get springDescription => List<double>.from(
    _setting.get(SettingBoxKey.springDescription) ??
        // duration: 0.3, bounce: 0.0
        const [1.0, 438.64908449286037, 41.88790204786391],
  );
  //   [0.5, 100.0, 2.2 * math.sqrt(50)], // [mass, stiffness, damping]

  static List<double> get speedList => List<double>.from(
    _video.get(
      VideoBoxKey.speedsList,
      defaultValue: const [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 3.0],
    ),
  );

  static List<Pair<SegmentType, SkipType>> get blockSettings {
    final list = _setting.get(SettingBoxKey.blockSettings) as List?;
    if (list == null || list.length != SegmentType.values.length) {
      return SegmentType.values
          .map((i) => Pair(first: i, second: SkipType.skipOnce))
          .toList();
    }
    return SegmentType.values
        .map(
          (item) => Pair(
            first: item,
            second: SkipType.values[list[item.index]],
          ),
        )
        .toList();
  }

  static List<Color> get blockColor {
    final list = _setting.get(SettingBoxKey.blockColor) as List?;
    if (list == null || list.length != SegmentType.values.length) {
      return SegmentType.values.map((i) => i.color).toList();
    }
    return SegmentType.values.map(
      (item) {
        final String e = list[item.index];
        final color = e.isNotEmpty ? int.tryParse('FF$e', radix: 16) : null;
        return color != null ? Color(color) : item.color;
      },
    ).toList();
  }

  static bool get feedBackEnable =>
      _setting.get(SettingBoxKey.feedBackEnable, defaultValue: false);

  static int get picQuality =>
      _setting.get(SettingBoxKey.defaultPicQa, defaultValue: 10);

  static DynamicBadgeMode get dynamicBadgeType =>
      DynamicBadgeMode.values[_setting.get(
        SettingBoxKey.dynamicBadgeMode,
        defaultValue: DynamicBadgeMode.number.index,
      )];

  static DynamicBadgeMode get msgBadgeMode =>
      DynamicBadgeMode.values[_setting.get(
        SettingBoxKey.msgBadgeMode,
        defaultValue: DynamicBadgeMode.number.index,
      )];

  static Set<MsgUnReadType> get msgUnReadTypeV2 =>
      (_setting.get(SettingBoxKey.msgUnReadTypeV2) as List?)
          ?.map((index) => MsgUnReadType.values[index])
          .toSet() ??
      MsgUnReadType.values.toSet();

  static NavigationBarType get defaultHomePage =>
      NavigationBarType.values[defaultHomePageIndex];

  static int get defaultHomePageIndex => _setting.get(
    SettingBoxKey.defaultHomePage,
    defaultValue: NavigationBarType.home.index,
  );

  static int get previewQ =>
      _setting.get(SettingBoxKey.previewQuality, defaultValue: 100);

  static double get replyFontSize => _getClampedDouble(
    SettingBoxKey.replyFontSize,
    14.0,
    10.0,
    22.0,
  );

  static double get collapsedReplyFontScale => _getClampedDouble(
    SettingBoxKey.collapsedReplyFontScale,
    0.9,
    0.7,
    1.3,
  );

  static double get replyLineSpacingScale => _getClampedDouble(
    SettingBoxKey.replyLineSpacingScale,
    1.0,
    0.7,
    1.5,
  );

  static double get smallCardWidth =>
      _setting.get(SettingBoxKey.smallCardWidth, defaultValue: 240.0);

  static double get recommendCardWidth =>
      _setting.get(SettingBoxKey.recommendCardWidth, defaultValue: 240.0);

  static HomeCardAspectRatio get homeCardAspectRatio =>
      HomeCardAspectRatio.fromStorage(
        _setting.get(SettingBoxKey.homeCardAspectRatio),
      );

  static bool get recommendDurationInStatRow => _setting.get(
    SettingBoxKey.recommendDurationInStatRow,
    defaultValue: false,
  );

  static double get recommendStatSpacing => _getClampedDouble(
    SettingBoxKey.recommendStatSpacing,
    4.0,
    0.0,
    24.0,
  );

  static double get cardRadius {
    final value = _setting.get(
      SettingBoxKey.cardRadius,
      defaultValue: 10.0,
    );
    return value is num
        ? value.toDouble().clamp(0.0, 32.0).toDouble()
        : 10.0;
  }

  static double get homeTabBarHeight => _getClampedDouble(
    SettingBoxKey.homeTabBarHeight,
    42.0,
    28.0,
    72.0,
  );

  static double? get legacyBottomBarBottomPadding {
    final value = _setting.get(SettingBoxKey.legacyBottomBarBottomPadding);
    return value is num ? value.toDouble().clamp(0.0, 48.0).toDouble() : null;
  }

static double get verticalScrollInertiaScale => _getClampedDouble(
  SettingBoxKey.verticalScrollInertiaScale,
  1.0,
  0.5,
  2.0,
);

static double get verticalScrollDecelerationScale => _getClampedDouble(
  SettingBoxKey.verticalScrollDecelerationScale,
  1.0,
  0.05,
  2.0,
);
    
  static UpPanelPosition get upPanelPosition =>
      UpPanelPosition.values[_setting.get(
        SettingBoxKey.upPanelPosition,
        defaultValue: UpPanelPosition.leftFixed.index,
      )];

  static FullScreenMode get fullScreenMode {
    int? index = _setting.get(SettingBoxKey.fullScreenMode);
    if (index == null) {
      final FullScreenMode mode = horizontalScreen && DeviceUtils.isTablet
          ? .none
          : .auto;
      _setting.put(SettingBoxKey.fullScreenMode, mode.index);
      return mode;
    }
    return FullScreenMode.values[index];
  }

  static BtmProgressBehavior get btmProgressBehavior =>
      BtmProgressBehavior.values[_setting.get(
        SettingBoxKey.btmProgressBehavior,
        defaultValue: BtmProgressBehavior.alwaysShow.index,
      )];

  static SubtitlePrefType get subtitlePreferenceV2 =>
      SubtitlePrefType.values[_setting.get(
        SettingBoxKey.subtitlePreferenceV2,
        defaultValue: SubtitlePrefType.off.index,
      )];

  static bool get useRelativeSlide =>
      _setting.get(SettingBoxKey.useRelativeSlide, defaultValue: false);

  static int get sliderDuration =>
      _setting.get(SettingBoxKey.sliderDuration, defaultValue: 90);

  static double get horizontalSeekGestureThreshold => _getClampedDouble(
    SettingBoxKey.horizontalSeekGestureThreshold,
    1.0,
    1.0,
    100.0,
  );

  static int get defaultVideoQa => _setting.get(
    SettingBoxKey.defaultVideoQa,
    defaultValue: VideoQuality.super8k.code,
  );

  static int get defaultVideoQaCellular => _setting.get(
    SettingBoxKey.defaultVideoQaCellular,
    defaultValue: VideoQuality.high1080.code,
  );

  static int get defaultVideoQaHalfScreen => _setting.get(
    SettingBoxKey.defaultVideoQaHalfScreen,
    defaultValue: defaultVideoQa,
  );
static int get videoPlayerSwitchForceTimeoutSeconds {
  final value = _setting.get(
    SettingBoxKey.videoPlayerSwitchForceTimeoutSeconds,
    defaultValue: 5,
  );

  return (value is num ? value.toInt() : 5)
      .clamp(0, 60)
      .toInt();
}
  static int get defaultAudioQa => _setting.get(
    SettingBoxKey.defaultAudioQa,
    defaultValue: AudioQuality.hiRes.code,
  );

  static int get defaultAudioQaCellular => _setting.get(
    SettingBoxKey.defaultAudioQaCellular,
    defaultValue: AudioQuality.k192.code,
  );

  static List<VideoDecodeFormatType> get preferCodecs {
    // TODO: remove next 2 version
    if (_setting.get('defaultDecode') case String codecStr) {
      String? codecStr2 = _setting.get('secondDecode');
      _setting.deleteAll(const ['defaultDecode', 'secondDecode']);
      final codecs = [
        VideoDecodeFormatType.values.firstWhere(
          (i) => i.codes.contains(codecStr),
        ),
        if (codecStr2 != null && codecStr2 != codecStr)
          VideoDecodeFormatType.values.firstWhere(
            (i) => i.codes.contains(codecStr2),
          ),
      ];
      _setting.put(
        SettingBoxKey.preferCodecs,
        codecs.map((i) => i.name).toList(),
      );
      return codecs;
    }

    final codecs = _setting.get(SettingBoxKey.preferCodecs);
    if (codecs is List) {
      return codecs.map((i) => VideoDecodeFormatType.values.byName(i)).toList();
    }
    return const <VideoDecodeFormatType>[.AVC, .AV1];
  }

  static String get hardwareDecoding => _setting.get(
    SettingBoxKey.hardwareDecoding,
    defaultValue: Platform.isAndroid
        ? HwDecType.androidDefault
        : HwDecType.auto.hwdec,
  );

  static String get videoSync =>
      _setting.get(SettingBoxKey.videoSync, defaultValue: 'display-resample');

  static String get autosync => _setting.get(
    SettingBoxKey.autosync,
    defaultValue: Platform.isAndroid ? '30' : '0',
  );

  static String get customMpvOptions =>
      _setting.get(SettingBoxKey.customMpvOptions, defaultValue: '');

  static bool get useMpvVideoScaling =>
      _setting.get(SettingBoxKey.useMpvVideoScaling, defaultValue: false);

  static bool get coverFullscreenTransitionWithBlack => _setting.get(
    SettingBoxKey.coverFullscreenTransitionWithBlack,
    defaultValue: false,
  );

  static String get mpvLogLevel {
    final value = _setting.get(
      SettingBoxKey.mpvLogLevel,
      defaultValue: 'error',
    );
    return switch (value) {
      'error' || 'warn' || 'info' || 'v' || 'debug' || 'trace' => value,
      _ => 'error',
    };
  }

  static List<CDNService> get cdnServices {
    final saved = _setting.get(SettingBoxKey.CDNServices);
    final names = saved is List
        ? saved.whereType<String>()
        : [
            if (_setting.get(SettingBoxKey.CDNService)
                case final String cdnName)
              cdnName,
          ];
    final services = <CDNService>[];
    for (final name in names) {
      for (final service in CDNService.values) {
        if (service.name == name && !services.contains(service)) {
          services.add(service);
          break;
        }
      }
      if (services.length == 3) {
        break;
      }
    }
    return services.isEmpty
        ? const [
            CDNService.backupUrl,
            CDNService.ali,
            CDNService.alib,
          ]
        : services;
  }

  static CDNService get defaultCDNService => cdnServices.first;

  static int get cdnRotationIndex {
    final value = _setting.get(
      SettingBoxKey.cdnRotationIndex,
      defaultValue: 0,
    );
    return value is int && value >= 0 ? value : 0;
  }

  static String get banWordForRecommend =>
      _setting.get(SettingBoxKey.banWordForRecommend, defaultValue: '');

  static String get banWordForReply =>
      _setting.get(SettingBoxKey.banWordForReply, defaultValue: '');

  static String get banWordForZone =>
      _setting.get(SettingBoxKey.banWordForZone, defaultValue: '');

  static bool get appRcmd =>
      _setting.get(SettingBoxKey.appRcmd, defaultValue: true);

static int get rcmdRefreshCount {
  final value = _setting.get(
    SettingBoxKey.rcmdRefreshCount,
    defaultValue: 20,
  );
  return (value is num ? value.toInt() : 20).clamp(4, 30).toInt();
}

  static bool get showRecommendRefreshStatsToast => _setting.get(
    SettingBoxKey.showRecommendRefreshStatsToast,
    defaultValue: false,
  );

  static RecommendHistoryFilterSettings get recommendHistoryFilterSettings =>
      RecommendHistoryFilterSettings.fromStorage(
        _setting.get(SettingBoxKey.recommendHistoryFilterSettings),
      );
    
  static String get systemProxyHost =>
      _setting.get(SettingBoxKey.systemProxyHost, defaultValue: '');

  static String get systemProxyPort =>
      _setting.get(SettingBoxKey.systemProxyPort, defaultValue: '');

  static DynamicsTabType get defaultDynamicType =>
      DynamicsTabType.values[defaultDynamicTypeIndex];

  static int get defaultDynamicTypeIndex => _setting.get(
    SettingBoxKey.defaultDynamicType,
    defaultValue: DynamicsTabType.all.index,
  );

  static bool get showDynInteraction =>
      _setting.get(SettingBoxKey.showDynInteraction, defaultValue: true);

  static double get blockLimit =>
      _setting.get(SettingBoxKey.blockLimit, defaultValue: 0.0);

  static double get refreshDragPercentage =>
      _setting.get(SettingBoxKey.refreshDragPercentage, defaultValue: 0.25);

  static double get refreshDisplacement => _setting.get(
    SettingBoxKey.refreshDisplacement,
    defaultValue: PlatformUtils.isMobile ? 20.0 : 40.0,
  );

  static String get blockUserID {
    String? blockUserID = _setting.get(SettingBoxKey.blockUserID);
    if (blockUserID == null || blockUserID.isEmpty) {
      blockUserID = Digest(
        List.generate(16, (_) => Utils.random.nextInt(256)),
      ).toString();
      _setting.put(SettingBoxKey.blockUserID, blockUserID);
    }
    return blockUserID;
  }

  static bool get blockToast =>
      _setting.get(SettingBoxKey.blockToast, defaultValue: true);

  static String get blockServer => _setting.get(
    SettingBoxKey.blockServer,
    defaultValue: HttpString.sponsorBlockBaseUrl,
  );

  static bool get blockTrack =>
      _setting.get(SettingBoxKey.blockTrack, defaultValue: !kDebugMode);

  static bool get checkDynamic =>
      _setting.get(SettingBoxKey.checkDynamic, defaultValue: true);

  static int get dynamicPeriod =>
      _setting.get(SettingBoxKey.dynamicPeriod, defaultValue: 5);

  static FlexSchemeVariant get schemeVariant =>
      FlexSchemeVariant.values[_setting.get(
        SettingBoxKey.schemeVariant,
        defaultValue: FlexSchemeVariant.material3Legacy.index,
      )];

  static double get danmakuFontScaleFS => _setting.get(
    SettingBoxKey.danmakuFontScaleFS,
    defaultValue: 1.2,
  );

  static bool get danmakuMassiveMode =>
      _setting.get(SettingBoxKey.danmakuMassiveMode, defaultValue: true);

  static bool get liveDanmakuMassiveMode => _setting.get(
    SettingBoxKey.liveDanmakuMassiveMode,
    defaultValue: false,
  );

  static bool get danmakuFixedV =>
      _setting.get(SettingBoxKey.danmakuFixedV, defaultValue: false);

  static bool get danmakuStatic2Scroll =>
      _setting.get(SettingBoxKey.danmakuStatic2Scroll, defaultValue: false);

  static double get subtitleFontScale =>
      _setting.get(SettingBoxKey.subtitleFontScale, defaultValue: 1.0);

  static double get subtitleFontScaleFS =>
      _setting.get(SettingBoxKey.subtitleFontScaleFS, defaultValue: 1.5);

  static bool get showViewPoints =>
      _setting.get(SettingBoxKey.showViewPoints, defaultValue: true);

  static bool get showRelatedVideo =>
      _setting.get(SettingBoxKey.showRelatedVideo, defaultValue: true);

  static bool get showVideoReply =>
      _setting.get(SettingBoxKey.showVideoReply, defaultValue: true);

  static bool get showBangumiReply =>
      _setting.get(SettingBoxKey.showBangumiReply, defaultValue: true);

  static bool get alwaysExpandIntroPanel =>
      _setting.get(SettingBoxKey.alwaysExpandIntroPanel, defaultValue: false);

  static bool get expandIntroPanelH =>
      _setting.get(SettingBoxKey.expandIntroPanelH, defaultValue: false);

  static bool get horizontalSeasonPanel => _setting.get(
    SettingBoxKey.horizontalSeasonPanel,
    defaultValue: horizontalScreen,
  );

  static bool get horizontalMemberPage => _setting.get(
    SettingBoxKey.horizontalMemberPage,
    defaultValue: horizontalScreen,
  );

  static int? get replyLengthLimit {
    int length = _setting.get(SettingBoxKey.replyLengthLimit, defaultValue: 6);
    if (length <= 0) {
      return null;
    }
    return length;
  }

  static int get defaultPicQa =>
      _setting.get(SettingBoxKey.defaultPicQa, defaultValue: 10);

  static double get danmakuLineHeight =>
      _setting.get(SettingBoxKey.danmakuLineHeight, defaultValue: 1.6);

  static bool get showArgueMsg =>
      _setting.get(SettingBoxKey.showArgueMsg, defaultValue: true);

  static bool get reverseFromFirst =>
      _setting.get(SettingBoxKey.reverseFromFirst, defaultValue: true);

  static int get subtitlePaddingH =>
      _setting.get(SettingBoxKey.subtitlePaddingH, defaultValue: 24);

  static int get subtitlePaddingB =>
      _setting.get(SettingBoxKey.subtitlePaddingB, defaultValue: 24);

  static double get subtitleBgOpacity =>
      _setting.get(SettingBoxKey.subtitleBgOpacity, defaultValue: 0.67);

  static double get subtitleStrokeWidth =>
      _setting.get(SettingBoxKey.subtitleStrokeWidth, defaultValue: 2.0);

  static int get subtitleFontWeight =>
      _setting.get(SettingBoxKey.subtitleFontWeight, defaultValue: 5);

  static bool get badCertificateCallback =>
      _setting.get(SettingBoxKey.badCertificateCallback, defaultValue: false);

  static bool get continuePlayingPart =>
      _setting.get(SettingBoxKey.continuePlayingPart, defaultValue: true);

  static bool get cdnSpeedTest =>
      _setting.get(SettingBoxKey.cdnSpeedTest, defaultValue: true);

  static bool get autoUpdate =>
      _setting.get(SettingBoxKey.autoUpdate, defaultValue: true);

  static bool get horizontalPreview =>
      _setting.get(SettingBoxKey.horizontalPreview, defaultValue: false);

  static bool get openInBrowser =>
      _setting.get(SettingBoxKey.openInBrowser, defaultValue: false);

  static bool get videoDetailUseAv =>
      _setting.get(SettingBoxKey.videoDetailUseAv, defaultValue: false);

  static bool get externalVideoLinkOpenInDetail => _setting.get(
    SettingBoxKey.externalVideoLinkOpenInDetail,
    defaultValue: false,
  );

  static bool get openClipboardLinkOnResume => _setting.get(
    SettingBoxKey.openClipboardLinkOnResume,
    defaultValue: false,
  );

  static bool get refreshHomeOnRestart => _setting.get(
    SettingBoxKey.refreshHomeOnRestart,
    defaultValue: false,
  );

  static bool get showMineQuote =>
      _setting.get(SettingBoxKey.showMineQuote, defaultValue: true);

  static bool get savedRcmdTip =>
      _setting.get(SettingBoxKey.savedRcmdTip, defaultValue: true);

  static bool get showVipDanmaku =>
      _setting.get(SettingBoxKey.showVipDanmaku, defaultValue: true);

  static DanmakuMergeMode get danmakuMergeMode {
  final value = _setting.get(SettingBoxKey.danmakuMergeMode);

  if (value is int &&
      value >= 0 &&
      value < DanmakuMergeMode.values.length) {
    return DanmakuMergeMode.values[value];
  }

  // 新键不存在时迁移旧版布尔设置。
  final legacyMerge = _setting.get(
    SettingBoxKey.mergeDanmaku,
    defaultValue: false,
  );

  return legacyMerge == true
      ? DanmakuMergeMode.segment
      : DanmakuMergeMode.off;
}

// 保留旧 getter，避免其它尚未调整的代码报错。
// 它现在只代表旧式分段合并。
static bool get mergeDanmaku =>
    danmakuMergeMode == DanmakuMergeMode.segment;

static int get burstDanmakuTriggerCount {
  final value = _setting.get(
    SettingBoxKey.burstDanmakuTriggerCount,
    defaultValue: 100,
  );

  return (value is num ? value.toInt() : 100)
      .clamp(2, 9999)
      .toInt();
}

static double get burstDanmakuWindowSeconds => _getClampedDouble(
  SettingBoxKey.burstDanmakuWindowSeconds,
  5.0,
  0.5,
  60.0,
);

static double get burstDanmakuCooldownSeconds => _getClampedDouble(
  SettingBoxKey.burstDanmakuCooldownSeconds,
  2.0,
  0.5,
  60.0,
);

static double get burstDanmakuFontScale => _getClampedDouble(
  SettingBoxKey.burstDanmakuFontScale,
  1.2,
  1.0,
  2.0,
);

  static bool get showHotRcmd =>
      _setting.get(SettingBoxKey.showHotRcmd, defaultValue: false);

  static String get audioNormalization =>
      _setting.get(SettingBoxKey.audioNormalization, defaultValue: '0');

  static String get fallbackNormalization =>
      _setting.get(SettingBoxKey.fallbackNormalization, defaultValue: '0');

  static SuperResolutionType get superResolutionType {
    SuperResolutionType? superResolutionType;
    final index = _setting.get(SettingBoxKey.superResolutionType);
    if (index != null) {
      superResolutionType = SuperResolutionType.values.elementAtOrNull(index);
    }
    return superResolutionType ?? SuperResolutionType.disable;
  }

  static bool get preInitPlayer =>
      _setting.get(SettingBoxKey.preInitPlayer, defaultValue: false);

  static bool get preloadVideoShot =>
      _setting.get(SettingBoxKey.preloadVideoShot, defaultValue: true);

  static bool get mainTabBarView =>
      _setting.get(SettingBoxKey.mainTabBarView, defaultValue: false);

  static bool get searchSuggestion =>
      _setting.get(SettingBoxKey.searchSuggestion, defaultValue: true);

  static bool get showDecorate =>
      _setting.get(SettingBoxKey.showDecorate, defaultValue: true);

  static bool get showMedal =>
      _setting.get(SettingBoxKey.showMedal, defaultValue: true);

  static bool get enableLivePhoto =>
      _setting.get(SettingBoxKey.enableLivePhoto, defaultValue: true);

  static bool get showSeekPreview =>
      _setting.get(SettingBoxKey.showSeekPreview, defaultValue: true);

  // Use the former combined preference as the migration default so existing
  // users keep their previous preview behavior until either new switch is set.
  static bool get showSeekPreviewOnSlider => _setting.get(
    SettingBoxKey.showSeekPreviewOnSlider,
    defaultValue: showSeekPreview,
  );

  static bool get showSeekPreviewOnGesture => _setting.get(
    SettingBoxKey.showSeekPreviewOnGesture,
    defaultValue: showSeekPreview,
  );

  static bool get seekTimeInPreview => _setting.get(
    SettingBoxKey.seekTimeInPreview,
    defaultValue: false,
  );

  static bool get biliProgressTimeStyle => _setting.get(
    SettingBoxKey.biliProgressTimeStyle,
    defaultValue: false,
  );

  static double get playerProgressThumbScale => _getClampedDouble(
    SettingBoxKey.playerProgressThumbScale,
    1.0,
    0.5,
    2.0,
  );

  static double get playerProgressBarTouchPadding => _getClampedDouble(
    SettingBoxKey.playerProgressBarTouchPadding,
    0.0,
    0.0,
    32.0,
  );

  static double get playerControlHorizontalPadding => _getClampedDouble(
    SettingBoxKey.playerControlHorizontalPadding,
    12.0,
    0.0,
    32.0,
  );

  static double get playerControlBarThicknessScale => _getClampedDouble(
    SettingBoxKey.playerControlBarThicknessScale,
    1.0,
    0.8,
    1.5,
  );

  static double get playerControlBarGradientExtent => _getClampedDouble(
    SettingBoxKey.playerControlBarGradientExtent,
    0.0,
    0.0,
    96.0,
  );

  static bool get seekPreviewFollowSlider => _setting.get(
  SettingBoxKey.seekPreviewFollowSlider,
  defaultValue: false,
);

static bool get seekPreviewFollowGesture => _setting.get(
  SettingBoxKey.seekPreviewFollowGesture,
  defaultValue: false,
);

  static double get seekPreviewScale => _getClampedDouble(
    SettingBoxKey.seekPreviewScale,
    1.0,
    0.5,
    2.0,
  );

  static double get seekPreviewProgressBarGap => _getClampedDouble(
    SettingBoxKey.seekPreviewProgressBarGap,
    20.0,
    0.0,
    160.0,
  );

  static bool get showSeekPreviewInNonFullscreen => _setting.get(
    SettingBoxKey.showSeekPreviewInNonFullscreen,
    defaultValue: true,
  );

  static bool get showDmChart =>
      _setting.get(SettingBoxKey.showDmChart, defaultValue: false);

  static bool get enableCommAntifraud =>
      _setting.get(SettingBoxKey.enableCommAntifraud, defaultValue: false);

  static bool get biliSendCommAntifraud =>
      Platform.isAndroid &&
      _setting.get(SettingBoxKey.biliSendCommAntifraud, defaultValue: false);

  static bool get enableCreateDynAntifraud =>
      _setting.get(SettingBoxKey.enableCreateDynAntifraud, defaultValue: false);

  static bool get coinWithLike =>
      _setting.get(SettingBoxKey.coinWithLike, defaultValue: false);

  static bool get isPureBlackTheme =>
      _setting.get(SettingBoxKey.isPureBlackTheme, defaultValue: false);

  static bool get antiGoodsDyn =>
      _setting.get(SettingBoxKey.antiGoodsDyn, defaultValue: false);

  static bool get antiGoodsReply =>
      _setting.get(SettingBoxKey.antiGoodsReply, defaultValue: false);

  static bool get expandDynLivePanel =>
      _setting.get(SettingBoxKey.expandDynLivePanel, defaultValue: false);

  static bool get slideDismissReplyPage => _setting.get(
    SettingBoxKey.slideDismissReplyPage,
    defaultValue: Platform.isIOS,
  );

  static bool get showFSActionItem =>
      _setting.get(SettingBoxKey.showFSActionItem, defaultValue: true);

  static bool get enableShrinkVideoSize =>
      _setting.get(SettingBoxKey.enableShrinkVideoSize, defaultValue: true);

  static double get pinchGestureAngleThreshold => _getClampedDouble(
    SettingBoxKey.pinchGestureAngleThreshold,
    90.0,
    15.0,
    90.0,
  );

  static bool get showDynActionBar =>
      _setting.get(SettingBoxKey.showDynActionBar, defaultValue: true);

  static bool get darkVideoPage =>
      _setting.get(SettingBoxKey.darkVideoPage, defaultValue: false);

  static bool get enableSlideVolumeBrightness => _setting.get(
    SettingBoxKey.enableSlideVolumeBrightness,
    defaultValue: true,
  );

  // 旧逻辑 dy > 3 * dx，相当于手势方向与竖直方向夹角小于 atan(1 / 3)。
  static double get volumeGestureAngleThreshold => _getClampedDouble(
    SettingBoxKey.volumeGestureAngleThreshold,
    18.43494882292201,
    5.0,
    60.0,
  );

  static double get brightnessGestureAngleThreshold => _getClampedDouble(
    SettingBoxKey.brightnessGestureAngleThreshold,
    18.43494882292201,
    5.0,
    60.0,
  );

  static double get volumeGestureSpeed => _getClampedDouble(
    SettingBoxKey.volumeGestureSpeed,
    1.0,
    0.25,
    4.0,
  );

  static double get brightnessGestureSpeed => _getClampedDouble(
    SettingBoxKey.brightnessGestureSpeed,
    1.0,
    0.25,
    4.0,
  );

  static bool get volumeBrightnessGestureProgressBar => _setting.get(
    SettingBoxKey.volumeBrightnessGestureProgressBar,
    defaultValue: false,
  );

  // 旧共享设置保留为新设置的迁移默认值。
  static double get playerGestureToastVerticalPercent => _getClampedDouble(
    SettingBoxKey.playerGestureToastVerticalPercent,
    10.0,
    0.0,
    100.0,
  );

  static double get seekTimeToastVerticalPercent => _getClampedDouble(
    SettingBoxKey.seekTimeToastVerticalPercent,
    playerGestureToastVerticalPercent,
    0.0,
    100.0,
  );

  static double get longPressSpeedToastVerticalPercent => _getClampedDouble(
    SettingBoxKey.longPressSpeedToastVerticalPercent,
    playerGestureToastVerticalPercent,
    0.0,
    100.0,
  );

  static double get playerGestureToastFontSize => _getClampedDouble(
    SettingBoxKey.playerGestureToastFontSize,
    13.0,
    8.0,
    32.0,
  );

  static double get seekTimeToastFontSize => _getClampedDouble(
    SettingBoxKey.seekTimeToastFontSize,
    playerGestureToastFontSize,
    8.0,
    32.0,
  );

  static double get longPressSpeedToastFontSize => _getClampedDouble(
    SettingBoxKey.longPressSpeedToastFontSize,
    playerGestureToastFontSize,
    8.0,
    32.0,
  );

  static bool get enableSlideFS =>
      _setting.get(SettingBoxKey.enableSlideFS, defaultValue: true);

  static int get retryCount =>
      _setting.get(SettingBoxKey.retryCount, defaultValue: 2);

  static int get retryDelay =>
      _setting.get(SettingBoxKey.retryDelay, defaultValue: 500);

  static int get liveQuality => _setting.get(
    SettingBoxKey.liveQuality,
    defaultValue: LiveQuality.origin.code,
  );

  static int get liveQualityCellular => _setting.get(
    SettingBoxKey.liveQualityCellular,
    defaultValue: LiveQuality.superHD.code,
  );

  static int get appFontWeight =>
      _setting.get(SettingBoxKey.appFontWeight, defaultValue: -1);

  static bool get enableDragSubtitle =>
      _setting.get(SettingBoxKey.enableDragSubtitle, defaultValue: false);

  static int get fastForBackwardDuration =>
      _setting.get(SettingBoxKey.fastForBackwardDuration, defaultValue: 10);

  static bool get recordSearchHistory =>
      _setting.get(SettingBoxKey.recordSearchHistory, defaultValue: true);

  static bool get autoHistoryArchive =>
      _setting.get(SettingBoxKey.autoHistoryArchive, defaultValue: true);

  static int get historyArchiveIntervalDays {
    final value = _setting.get(
      SettingBoxKey.historyArchiveIntervalDays,
      defaultValue: 7,
    );
    return (value is num ? value.toInt() : 7).clamp(1, 30).toInt();
  }

  static bool get silentHistoryArchive =>
      _setting.get(SettingBoxKey.silentHistoryArchive, defaultValue: true);

  static String get webdavUri =>
      _setting.get(SettingBoxKey.webdavUri, defaultValue: '');

  static String get webdavUsername =>
      _setting.get(SettingBoxKey.webdavUsername, defaultValue: '');

  static String get webdavPassword =>
      _setting.get(SettingBoxKey.webdavPassword, defaultValue: '');

  static String get webdavDirectory =>
      _setting.get(SettingBoxKey.webdavDirectory, defaultValue: '/');

  static bool get showPgcTimeline =>
      _setting.get(SettingBoxKey.showPgcTimeline, defaultValue: true);

  static num get maxCacheSize =>
      _setting.get(SettingBoxKey.maxCacheSize) ?? 1 << 30;

  static bool get optTabletNav =>
      _setting.get(SettingBoxKey.optTabletNav, defaultValue: true);

  static bool get horizontalScreen {
    bool? horizontalScreen = _setting.get(SettingBoxKey.horizontalScreen);
    if (horizontalScreen == null) {
      final isTablet = DeviceUtils.isTablet;
      _setting.put(SettingBoxKey.horizontalScreen, isTablet);
      return isTablet;
    }
    return horizontalScreen;
  }

  static String get banWordForDyn =>
      _setting.get(SettingBoxKey.banWordForDyn, defaultValue: '');

  static bool get enableLog =>
      _setting.get(SettingBoxKey.enableLog, defaultValue: true);

  static bool get disableAudioCDN =>
      _setting.get(SettingBoxKey.disableAudioCDN, defaultValue: false);

  static int get minDurationForRcmd =>
      _setting.get(SettingBoxKey.minDurationForRcmd, defaultValue: 0);

  static int get minPlayForRcmd =>
      _setting.get(SettingBoxKey.minPlayForRcmd, defaultValue: 0);

  static int get minLikeRatioForRecommend =>
      _setting.get(SettingBoxKey.minLikeRatioForRecommend, defaultValue: 0);

  static bool get exemptFilterForFollowed =>
      _setting.get(SettingBoxKey.exemptFilterForFollowed, defaultValue: true);

  static bool get applyFilterToRelatedVideos => _setting.get(
    SettingBoxKey.applyFilterToRelatedVideos,
    defaultValue: true,
  );

  static bool get enableBackgroundPlay =>
      _setting.get(SettingBoxKey.enableBackgroundPlay, defaultValue: true);

  static bool get disableLikeMsg =>
      _setting.get(SettingBoxKey.disableLikeMsg, defaultValue: false);

  static bool get enableWordRe =>
      _setting.get(SettingBoxKey.enableWordRe, defaultValue: false);

  static bool get autoExitFullscreen =>
      _setting.get(SettingBoxKey.enableAutoExit, defaultValue: true);

  static bool get autoPlayEnable =>
      _setting.get(SettingBoxKey.autoPlayEnable, defaultValue: false);

  static bool get pipNoDanmaku =>
      _setting.get(SettingBoxKey.pipNoDanmaku, defaultValue: false);

  static bool get enableVerticalExpand =>
      _setting.get(SettingBoxKey.enableVerticalExpand, defaultValue: false);

  static double get defaultTextScale =>
      _setting.get(SettingBoxKey.defaultTextScale, defaultValue: 1.0);

  static double get uiScale =>
      _setting.get(SettingBoxKey.uiScale, defaultValue: 1.0);

  static bool get dynamicsWaterfallFlow => _setting.get(
    SettingBoxKey.dynamicsWaterfallFlow,
    defaultValue: horizontalScreen,
  );

  static bool get hideTopBar => _setting.get(
    SettingBoxKey.hideTopBar,
    defaultValue: PlatformUtils.isMobile,
  );

  static bool get hideBottomBar => _setting.get(
    SettingBoxKey.hideBottomBar,
    defaultValue: PlatformUtils.isMobile,
  );

  static BarHideType get barHideType =>
      BarHideType.values[_setting.get(
        SettingBoxKey.barHideType,
        defaultValue: BarHideType.sync.index,
      )];

  static bool get enableSearchWord =>
      _setting.get(SettingBoxKey.enableSearchWord, defaultValue: false);

  static bool get useSideBar =>
      _setting.get(SettingBoxKey.useSideBar, defaultValue: false);

  static bool get dynamicsShowAllFollowedUp => _setting.get(
    SettingBoxKey.dynamicsShowAllFollowedUp,
    defaultValue: false,
  );

  static bool get enableShowDanmaku =>
      _setting.get(SettingBoxKey.enableShowDanmaku, defaultValue: true);

  static bool get rememberDanmakuSwitchState => _setting.get(
    SettingBoxKey.rememberDanmakuSwitchState,
    defaultValue: false,
  );

  static bool get enableShowLiveDanmaku =>
      _setting.get(SettingBoxKey.enableShowLiveDanmaku, defaultValue: true);

  static bool get enableQuickFav =>
      _setting.get(SettingBoxKey.enableQuickFav, defaultValue: false);

  static bool get p1080 =>
      _setting.get(SettingBoxKey.p1080, defaultValue: true);

  static int get customColor {
    final value = _setting.get(SettingBoxKey.customColor, defaultValue: 0);
    return value is int
        ? value.clamp(0, colorThemeTypes.length - 1).toInt()
        : 0;
  }

  static bool get _legacyDynamicColor =>
      !Platform.isIOS &&
      _setting.get(SettingBoxKey.dynamicColor, defaultValue: true);

  static ThemeColorMode get themeColorMode {
    final value = _setting.get(SettingBoxKey.themeColorMode);
    if (value is int &&
        value >= 0 &&
        value < ThemeColorMode.values.length) {
      final mode = ThemeColorMode.values[value];
      if (!Platform.isIOS || mode != ThemeColorMode.dynamic) {
        return mode;
      }
    }
    return _legacyDynamicColor
        ? ThemeColorMode.dynamic
        : ThemeColorMode.preset;
  }

  static bool get dynamicColor => themeColorMode == ThemeColorMode.dynamic;

  static Color _getThemeSeed(String key, Color fallback) {
    final value = _setting.get(key);
    return value is int ? Color(value) : fallback;
  }

  static ThemeSeedColors get customThemeSeeds => (
    primary: _getThemeSeed(
      SettingBoxKey.customPrimarySeed,
      defaultCustomThemeSeeds.primary,
    ),
    secondary: _getThemeSeed(
      SettingBoxKey.customSecondarySeed,
      defaultCustomThemeSeeds.secondary,
    ),
    tertiary: _getThemeSeed(
      SettingBoxKey.customTertiarySeed,
      defaultCustomThemeSeeds.tertiary,
    ),
  );

  static String customThemeToneKey(
    Brightness brightness,
    ThemeToneRole role,
  ) =>
      '${SettingBoxKey.customThemeTonePrefix}.${brightness.name}.${role.name}';

  static double customThemeToneOffset(
    Brightness brightness,
    ThemeToneRole role,
  ) => _getClampedDouble(
    customThemeToneKey(brightness, role),
    0,
    -30,
    30,
  );

  static Map<ThemeToneRole, double> customThemeToneOffsets(
    Brightness brightness,
  ) => {
    for (final role in ThemeToneRole.values)
      role: customThemeToneOffset(brightness, role),
  };

  static Map<ThemeUiElement, ThemeSchemeColor?>
  get customThemeUiColorAssignments {
    final stored = _setting.get(SettingBoxKey.customThemeColorAssignments);
    if (stored is! Map) {
      return {
        for (final element in ThemeUiElement.values)
          element: element.defaultColor,
      };
    }

    return {
      for (final element in ThemeUiElement.values)
        element: _decodeThemeUiColorAssignment(stored, element),
    };
  }

  static ThemeSchemeColor? _decodeThemeUiColorAssignment(
    Map<dynamic, dynamic> stored,
    ThemeUiElement element,
  ) {
    // 兼容上一版以 Material 颜色槽名称为目标键的设置：同一默认颜色下
    // 拆出的具体 UI 元素会继承原颜色槽的选择或未配置状态。
    final key = stored.containsKey(element.name)
        ? element.name
        : stored.containsKey(element.defaultColor.name)
        ? element.defaultColor.name
        : null;
    if (key == null) return element.defaultColor;
    final sourceName = stored[key];
    if (sourceName == '') return null;
    if (sourceName is String) {
      try {
        return ThemeSchemeColor.values.byName(sourceName);
      } catch (_) {}
    }
    return element.defaultColor;
  }

  static bool get enableSystemProxy =>
      _setting.get(SettingBoxKey.enableSystemProxy, defaultValue: false);

  static bool get enableHttp2 =>
      _setting.get(SettingBoxKey.enableHttp2, defaultValue: false);

  static ReplySortType get replySortType =>
      ReplySortType.values[_setting.get(
        SettingBoxKey.replySortType,
        defaultValue: ReplySortType.hot.index,
      )];

  static DynamicBadgeMode get dynamicBadgeMode =>
      DynamicBadgeMode.values[_setting.get(
        SettingBoxKey.dynamicBadgeMode,
        defaultValue: DynamicBadgeMode.number.index,
      )];

  static bool get enableMYBar =>
      _setting.get(SettingBoxKey.enableMYBar, defaultValue: true);

  static Transition get pageTransition =>
      Transition.values[_setting.get(
        SettingBoxKey.pageTransition,
        defaultValue: Transition.native.index,
      )];

  static bool get enableQuickDouble =>
      _setting.get(SettingBoxKey.enableQuickDouble, defaultValue: true);

  static bool get fullScreenGestureReverse =>
      _setting.get(SettingBoxKey.fullScreenGestureReverse, defaultValue: false);

  static bool get autoPiP =>
      _setting.get(SettingBoxKey.autoPiP, defaultValue: false);

  static bool get enableSponsorBlock =>
      _setting.get(SettingBoxKey.enableSponsorBlock, defaultValue: false);

  static bool get enableHA =>
      _setting.get(SettingBoxKey.enableHA, defaultValue: true);

  static Set<int> get danmakuBlockType => Set<int>.from(
    _setting.get(SettingBoxKey.danmakuBlockType, defaultValue: const <int>{}),
  );

  static int get danmakuWeight =>
      _setting.get(SettingBoxKey.danmakuWeight, defaultValue: 0);
static int get highLikeDanmakuThreshold {
  final value = _setting.get(
    SettingBoxKey.highLikeDanmakuThreshold,
    defaultValue: 100,
  );

  return (value is num ? value.toInt() : 100)
      .clamp(0, 999999)
      .toInt();
}
  static double get danmakuShowArea =>
      _setting.get(SettingBoxKey.danmakuShowArea, defaultValue: 0.5);

  static double get danmakuOpacity =>
      _setting.get(SettingBoxKey.danmakuOpacity, defaultValue: 1.0);

  static double get danmakuFontScale => _setting.get(
    SettingBoxKey.danmakuFontScale,
    defaultValue: 0.9,
  );

  static double get danmakuDuration =>
      _setting.get(SettingBoxKey.danmakuDuration, defaultValue: 7.0);

  static double get danmakuStaticDuration =>
      _setting.get(SettingBoxKey.danmakuStaticDuration, defaultValue: 4.0);

  static double get danmakuStrokeWidth => _setting.get(
    SettingBoxKey.danmakuStrokeWidth,
    defaultValue: PlatformUtils.isMobile ? 1.5 : 2.5,
  );
static double get danmakuShadowRadius => _getClampedDouble(
  SettingBoxKey.danmakuShadowRadius,
  0.0,
  0.0,
  10.0,
);
  static int get danmakuFontWeight => _setting.get(
    SettingBoxKey.danmakuFontWeight,
    defaultValue: PlatformUtils.isMobile ? 5 : 6,
  );

  static bool get enableLongShowControl =>
    _setting.get(
      SettingBoxKey.enableLongShowControl,
      defaultValue: false,
    );

/// 播放控件无操作后的自动隐藏时间，单位为秒。
///
/// 新键不存在时读取旧版布尔开关：
/// - 旧开关开启：30 秒
/// - 旧开关关闭或不存在：3 秒
static int get playerControlDisplayDurationSeconds {
  final value = _setting.get(
    SettingBoxKey.playerControlDisplayDurationSeconds,
  );

  if (value is num) {
    return value.toInt().clamp(1, 60).toInt();
  }

  return enableLongShowControl ? 30 : 3;
}
    
  static double get bufferSize =>
      _setting.get(SettingBoxKey.bufferSize, defaultValue: 4.0);

  static double get bufferSec =>
      _setting.get(SettingBoxKey.bufferSec, defaultValue: 16.0);

  static Map<String, String> initBuffer([double playbackSpeed = 1.0]) {
    final bufSec = Pref.bufferSec * playbackSpeed;
    final bufSiz = (Pref.bufferSize * 0x100000).toStringAsFixed(0);
    return {
      'cache': 'yes',
      'cache-secs': bufSec.toStringAsFixed(3),
      'demuxer-hysteresis-secs': (bufSec / 1.5).toStringAsFixed(3),
      'demuxer-max-bytes': bufSiz,
      'demuxer-max-back-bytes': bufSiz,
    };
  }

  static Map<String, String> initLiveBuffer() {
    return {
      'cache': 'yes',
      'demuxer-max-bytes': (Pref.bufferSize * 0x200000).toStringAsFixed(0),
      'demuxer-max-back-bytes': '0',
    };
  }

  static String get audioOutput => _setting.get(
    SettingBoxKey.audioOutput,
    defaultValue: AudioOutput.defaultValue,
  );

  static bool get audioTrackIsPrimaryOutput =>
      audioOutput.split(',').first.trim().toLowerCase() ==
      AudioOutput.audiotrack.name;

  static bool get enableAi =>
      _setting.get(SettingBoxKey.enableAi, defaultValue: false);

  static bool get enableOnlineTotal =>
      _setting.get(SettingBoxKey.enableOnlineTotal, defaultValue: false);

  static bool get autoEnterFullScreen =>
      _setting.get(SettingBoxKey.enableAutoEnter, defaultValue: false);

  static bool get enableAutoLongPressSpeed =>
      _setting.get(SettingBoxKey.enableAutoLongPressSpeed, defaultValue: false);

  static bool get showLongPressSpeedToast => _setting.get(
    SettingBoxKey.showLongPressSpeedToast,
    defaultValue: true,
  );

  static int get longPressSpeedTriggerDelay {
    final defaultValue = PlatformUtils.isMobile && enableTapDm ? 300 : 500;
    final value = _setting.get(SettingBoxKey.longPressSpeedTriggerDelay);
    return (value is num ? value.toInt() : defaultValue)
        .clamp(100, 1000)
        .toInt();
  }

  static double get playSpeedDefault =>
      _video.get(VideoBoxKey.playSpeedDefault, defaultValue: 1.0);

  static double get longPressSpeedDefault =>
      _video.get(VideoBoxKey.longPressSpeedDefault, defaultValue: 3.0);

  static bool get defaultShowComment =>
      _setting.get(SettingBoxKey.defaultShowComment, defaultValue: false);

  static bool get enableTrending =>
      _setting.get(SettingBoxKey.enableHotKey, defaultValue: true);

  static bool get enableSearchRcmd =>
      _setting.get(SettingBoxKey.enableSearchRcmd, defaultValue: true);

  static bool get enableSaveLastData =>
      _setting.get(SettingBoxKey.enableSaveLastData, defaultValue: true);

  static double get defaultToastOp =>
      _setting.get(SettingBoxKey.defaultToastOp, defaultValue: 1.0);

  static PlayRepeat get playRepeat =>
      PlayRepeat.values[_video.get(
        VideoBoxKey.playRepeat,
        defaultValue: PlayRepeat.pause.index,
      )];

  static int get cacheVideoFit =>
      _video.get(VideoBoxKey.cacheVideoFit, defaultValue: 1);

  static bool get continuePlayInBackground =>
      _setting.get(SettingBoxKey.continuePlayInBackground, defaultValue: false);

  static bool get directExitOnBack =>
      _setting.get(SettingBoxKey.directExitOnBack, defaultValue: false);

  static bool get historyPause =>
      _localCache.get(LocalCacheKey.historyPause, defaultValue: false);

  static int? get historyPauseAccountMid {
    final value = _localCache.get(LocalCacheKey.historyPauseAccountMid);
    return value is num ? value.toInt() : null;
  }

  static int? get quickFavId => _setting.get(SettingBoxKey.quickFavId);

  static bool get tempPlayerConf =>
      _setting.get(SettingBoxKey.tempPlayerConf, defaultValue: false);

  static Color? get reduceLuxColor {
    final int? color = _setting.get(SettingBoxKey.reduceLuxColor);
    if (color != null && color != 0xFFFFFFFF) {
      return Color(color);
    }
    return null;
  }

  static bool get showFsScreenshotBtn =>
      _setting.get(SettingBoxKey.showFsScreenshotBtn, defaultValue: true);

  static bool get showFsLockBtn =>
      _setting.get(SettingBoxKey.showFsLockBtn, defaultValue: true);

  static bool get showFsSkipOpBtn =>
      _setting.get(SettingBoxKey.showFsSkipOpBtn, defaultValue: true);

  static int get skipOpDurationSeconds {
    final value = _setting.get(SettingBoxKey.skipOpDurationSeconds);
    if (value is num && value.isFinite) {
      return value.toInt().clamp(1, 300).toInt();
    }
    return 80;
  }

  static bool get silentDownImg =>
      _setting.get(SettingBoxKey.silentDownImg, defaultValue: false);

  static String get buvid {
    String? buvid = _localCache.get(LocalCacheKey.buvid);
    if (buvid == null) {
      buvid = LoginUtils.generateBuvid();
      _localCache.put(LocalCacheKey.buvid, buvid);
    }
    return buvid;
  }

  static bool get showMemberShop =>
      _setting.get(SettingBoxKey.showMemberShop, defaultValue: false);

  static SuperChatType get superChatType =>
      SuperChatType.values[_setting.get(
        SettingBoxKey.superChatType,
        defaultValue: SuperChatType.valid.index,
      )];

  static double get fullScreenSCWidth => _setting.get(
    SettingBoxKey.fullScreenSCWidth,
    defaultValue: kFullScreenSCWidth,
  );

  static bool get minimizeOnExit =>
      _setting.get(SettingBoxKey.minimizeOnExit, defaultValue: true);

  static Size get windowSize {
    final List<double>? size = (_setting.get(SettingBoxKey.windowSize) as List?)
        ?.fromCast<double>();
    return size == null ? const Size(1180.0, 720.0) : Size(size[0], size[1]);
  }

  static List<double>? get windowPosition =>
      (_setting.get(SettingBoxKey.windowPosition) as List?)?.fromCast<double>();

  static bool get isWindowMaximized =>
      _setting.get(SettingBoxKey.isWindowMaximized, defaultValue: false);

  static bool get keyboardControl =>
      _setting.get(SettingBoxKey.keyboardControl, defaultValue: true);

  static bool get pauseOnMinimize =>
      _setting.get(SettingBoxKey.pauseOnMinimize, defaultValue: false);

  static bool get showWindowTitleBar =>
      _setting.get(SettingBoxKey.showWindowTitleBar, defaultValue: true);

  static double get desktopVolume =>
      _setting.get(SettingBoxKey.desktopVolume, defaultValue: 1.0);

  static SkipType get pgcSkipType =>
      SkipType.values[_setting.get(SettingBoxKey.pgcSkipType) ??
          SkipType.skipOnce.index];

  static PlayRepeat get audioPlayMode =>
      PlayRepeat.values[_setting.get(SettingBoxKey.audioPlayMode) ??
          PlayRepeat.listOrder.index];

  static bool get enablePlayAll =>
      _setting.get(SettingBoxKey.enablePlayAll, defaultValue: true);

  static bool get enableTapDm =>
      _setting.get(SettingBoxKey.enableTapDm, defaultValue: true);

  static bool get showTrayIcon =>
      _setting.get(SettingBoxKey.showTrayIcon, defaultValue: true);

  static bool get setSystemBrightness =>
      _setting.get(SettingBoxKey.setSystemBrightness, defaultValue: false);

  static String? get downloadPath => _setting.get(SettingBoxKey.downloadPath);

  static String? get liveCdnUrl => _setting.get(SettingBoxKey.liveCdnUrl);

  static bool get showBatteryLevel => _setting.get(
    SettingBoxKey.showBatteryLevel,
    defaultValue: PlatformUtils.isMobile,
  );

  static bool get showBatteryPercentage => _setting.get(
    SettingBoxKey.showBatteryPercentage,
    defaultValue: true,
  );

  static bool get showMpvOutputFps => _setting.get(
    SettingBoxKey.showMpvOutputFps,
    defaultValue: false,
  );

  static bool get showBufferingInfo => _setting.get(
    SettingBoxKey.showBufferingInfo,
    defaultValue: true,
  );

  static bool get showPlayerInstanceStatus => _setting.get(
    SettingBoxKey.showPlayerInstanceStatus,
    defaultValue: false,
  );

  static FollowOrderType get followOrderType =>
      FollowOrderType.values[_setting.get(
        SettingBoxKey.followOrderType,
        defaultValue: FollowOrderType.def.index,
      )];

  static bool get enableImgMenu =>
      _setting.get(SettingBoxKey.enableImgMenu, defaultValue: false);

  static bool get showDynDispute =>
      _setting.get(SettingBoxKey.showDynDispute, defaultValue: false);

   static double get touchSlopH => _setting.get(
    SettingBoxKey.touchSlopH,
    defaultValue: deviceTouchSlop + 6.0,
  );

  /// 横向标签页快滑速度阈值，单位为逻辑像素每秒。
  ///
  /// Flutter 默认触摸 fling 最低速度为 50.0，因此默认值保持 50，
  /// 尽量维持当前未自定义时的行为。
  static double get tabSwipeVelocityThreshold => _getClampedDouble(
    SettingBoxKey.tabSwipeVelocityThreshold,
    50.0,
    10.0,
    3000.0,
  );

  /// 慢滑切换标签页所需的页面宽度百分比。
  ///
  /// 默认 50%，对应 PageScrollPhysics 原有的四舍五入逻辑。
  static double get tabSwipeDistanceThresholdPercent => _getClampedDouble(
    SettingBoxKey.tabSwipeDistanceThresholdPercent,
    50.0,
    5.0,
    95.0,
  );

  static bool get saveReply =>
      _setting.get(SettingBoxKey.saveReply, defaultValue: true);

  static bool get floatingNavBar =>
      _setting.get(SettingBoxKey.floatingNavBar, defaultValue: false);

  static bool get removeSafeArea =>
      _setting.get(SettingBoxKey.removeSafeArea, defaultValue: false);

  static bool get verticalFullscreenBottomBarSafeArea => _setting.get(
    SettingBoxKey.verticalFullscreenBottomBarSafeArea,
    defaultValue: false,
  );

  static double get verticalFullscreenBottomBarSafeHeight =>
      _getClampedDouble(
        SettingBoxKey.verticalFullscreenBottomBarSafeHeight,
        24.0,
        0.0,
        80.0,
      );

  static int get angleDegrees =>
      _setting.get(SettingBoxKey.angleDegrees, defaultValue: 30);

  static double get playerVolume => // mobile
      _setting.get(SettingBoxKey.playerVolume, defaultValue: 100.0);

  static double get maxVolume => // desktop
      _setting.get(SettingBoxKey.maxVolume, defaultValue: 2.0);

  static List? get liveStream => _setting.get(SettingBoxKey.liveStream);
}
