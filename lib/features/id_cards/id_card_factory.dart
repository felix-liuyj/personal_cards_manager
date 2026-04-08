import '../../data/models/models.dart';

class IDCardConstraints {
  final DisplayMode displayMode;
  final double aspectRatio;
  final bool supportsExpand;
  final DisplayMode? expandedMode;
  final double? expandedAspectRatio;
  final bool supportsFullscreen;

  const IDCardConstraints({
    required this.displayMode,
    required this.aspectRatio,
    this.supportsExpand = false,
    this.expandedMode,
    this.expandedAspectRatio,
    this.supportsFullscreen = false,
  });
}

class IDCardFactory {
  /// 生成中国居民身份证的标准长宽比模型
  static IDCardConstraints getChineseID() {
    return const IDCardConstraints(
      displayMode: DisplayMode.cardHorizontal,
      aspectRatio: 1.58,
      supportsFullscreen: true,
    );
  }

  /// 生成护照统一摘要标准模型 (适用中美英三大护照)
  static IDCardConstraints getStandardPassport() {
    return const IDCardConstraints(
      displayMode: DisplayMode.passportCover,
      aspectRatio: 1.38,
      supportsExpand: true,
      expandedMode: DisplayMode.passportSpread,
      expandedAspectRatio: 2.0,
      supportsFullscreen: true,
    );
  }

  /// 生成标准的横卡证件 (适配绝大部分普通证照如驾照、社保卡等1.58范畴)
  static IDCardConstraints getStandardHorizontalCard({double fallbackRatio = 1.58}) {
    return IDCardConstraints(
      displayMode: DisplayMode.cardHorizontal,
      aspectRatio: fallbackRatio,
      supportsFullscreen: true,
    );
  }

  /// 核心管控方法：策略路由分配函数
  /// 当任意类型的证件被创立或更新时必须经过此中间件进行防呆修饰和自动约束下发。
  static void applyConstraints(IDCard cardEntity) {
    IDCardConstraints constraints;
    final String cty = cardEntity.countryCode?.toUpperCase() ?? '';
    final String doc = cardEntity.documentType?.toUpperCase() ?? '';

    // 视觉特写策略分配机制：
    if (doc == 'PASSPORT') {
      // 一律分配高窄摘要及宽频展开页
      constraints = getStandardPassport();
    } else if (cty == 'CN' && doc == 'ID') {
      constraints = getChineseID();
    } else if (cty == 'US' && doc == 'DRIVER_LICENSE') {
      constraints = getStandardHorizontalCard(fallbackRatio: 1.58);
    } else if (cty == 'UK' && doc == 'BRP') {
      constraints = getStandardHorizontalCard(fallbackRatio: 1.58);
    } else {
      // 缺省路由：兜底分派最为常规稳妥的水平卡形式
      constraints = getStandardHorizontalCard();
    }

    // 强行注入并将元数据写至持久化数据库实体：
    cardEntity.displayMode = constraints.displayMode;
    cardEntity.aspectRatio = constraints.aspectRatio;
    cardEntity.supportsExpand = constraints.supportsExpand;
    if (constraints.expandedMode != null) {
      cardEntity.expandedMode = constraints.expandedMode!;
    }
    if (constraints.expandedAspectRatio != null) {
      cardEntity.expandedAspectRatio = constraints.expandedAspectRatio!;
    }
    cardEntity.supportsFullscreen = constraints.supportsFullscreen;
  }
}
