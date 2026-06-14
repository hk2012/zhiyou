import '../../../core/domain/app_domain_models.dart';

class VenueSummary {
  const VenueSummary({
    required this.location,
    required this.updatedAt,
    required this.todayIndex,
    required this.indexLabel,
    required this.indexReason,
    required this.weather,
    required this.recommendedWindow,
    required this.nearbyCount,
  });

  final String location;
  final String updatedAt;
  final int todayIndex;
  final String indexLabel;
  final String indexReason;
  final String weather;
  final String recommendedWindow;
  final int nearbyCount;
}

class VenueFilterOption {
  const VenueFilterOption({
    required this.id,
    required this.label,
    required this.description,
    required this.iconKey,
    required this.group,
  });

  final String id;
  final String label;
  final String description;
  final String iconKey;
  final String group;
}

class FishingVenue {
  const FishingVenue({
    required this.id,
    required this.name,
    required this.area,
    required this.address,
    required this.distanceLabel,
    required this.distanceKm,
    required this.rating,
    required this.popularity,
    required this.priceFrom,
    required this.memberPriceFrom,
    required this.todayIndex,
    required this.todayLabel,
    required this.openHours,
    required this.status,
    required this.leftSeats,
    required this.fishSpecies,
    required this.tags,
    required this.sceneTypes,
    required this.facilities,
    required this.bookingSupported,
    required this.nightFishing,
    required this.smartDeviceFriendly,
    required this.parking,
    required this.dining,
    required this.familyFriendly,
    required this.activitySupported,
    required this.mainImageKind,
    required this.headline,
    required this.description,
    required this.chargeRule,
    required this.contactPhone,
    required this.navigationHint,
    required this.memberBenefit,
    required this.recommendedDevices,
    required this.recommendedProductIds,
    required this.deviceInsight,
    required this.events,
    required this.packages,
    required this.bookingSlots,
    required this.reviews,
    required this.catchFeeds,
  });

  final String id;
  final String name;
  final String area;
  final String address;
  final String distanceLabel;
  final double distanceKm;
  final double rating;
  final int popularity;
  final int priceFrom;
  final int memberPriceFrom;
  final int todayIndex;
  final String todayLabel;
  final String openHours;
  final VenueStatus status;
  final int leftSeats;
  final List<String> fishSpecies;
  final List<String> tags;
  final List<String> sceneTypes;
  final List<String> facilities;
  final bool bookingSupported;
  final bool nightFishing;
  final bool smartDeviceFriendly;
  final bool parking;
  final bool dining;
  final bool familyFriendly;
  final bool activitySupported;
  final VenueImageKind mainImageKind;
  final String headline;
  final String description;
  final String chargeRule;
  final String contactPhone;
  final String navigationHint;
  final String memberBenefit;
  final List<String> recommendedDevices;
  final List<String> recommendedProductIds;
  final VenueDeviceInsight deviceInsight;
  final List<VenueEvent> events;
  final List<VenuePackage> packages;
  final List<VenueBookingSlot> bookingSlots;
  final List<VenueReview> reviews;
  final List<VenueCatchFeed> catchFeeds;

  bool matchesFilter(String id) {
    switch (id) {
      case 'nearest':
        return true;
      case 'popular':
        return popularity >= 86;
      case 'bookable':
        return bookingSupported;
      case 'price_100':
        return priceFrom <= 100;
      case 'night':
        return nightFishing;
      case 'blackpit':
        return sceneTypes.contains('黑坑');
      case 'wild':
        return sceneTypes.contains('野钓');
      case 'family':
        return familyFriendly;
      case 'device_friendly':
        return smartDeviceFriendly;
      case 'parking':
        return parking;
      case 'dining':
        return dining;
      case 'today_good':
        return todayIndex >= 80;
      case 'event':
        return activitySupported;
      default:
        if (id.startsWith('fish_')) {
          return fishSpecies.contains(id.replaceFirst('fish_', ''));
        }
        return true;
    }
  }

  DomainVenue toDomainVenue() {
    return DomainVenue(
      id: id,
      name: name,
      area: area,
      address: address,
      status: _toDomainVenueStatus(status),
      distanceKm: distanceKm,
      rating: rating,
      priceFrom: priceFrom,
      memberPriceFrom: memberPriceFrom,
      todayIndex: todayIndex,
      fishSpecies: fishSpecies,
      tags: tags,
      supportsBooking: bookingSupported,
      supportsNightFishing: nightFishing,
      supportsSmartDevice: smartDeviceFriendly,
      summary: description,
      openHours: openHours,
      facilities: facilities,
      recommendedDeviceTypes: recommendedDevices
          .map(_deviceTypeFromLabel)
          .toList(growable: false),
      packages: packages
          .map(
            (item) => DomainVenuePackage(
              id: item.id,
              venueId: id,
              title: item.title,
              description: item.description,
              price: item.price,
              memberPrice: item.memberPrice,
              includes: item.includes,
            ),
          )
          .toList(growable: false),
      slots: bookingSlots
          .map(
            (item) => DomainVenueSlot(
              id: item.id,
              venueId: id,
              label: item.label,
              timeRange: item.timeRange,
              price: item.price,
              memberPrice: item.memberPrice,
              leftSeats: item.leftSeats,
              status: _toDomainSlotStatus(item.status),
            ),
          )
          .toList(growable: false),
      reviews: [
        for (var index = 0; index < reviews.length; index++)
          DomainVenueReview(
            id: '${id}_review_$index',
            venueId: id,
            userName: reviews[index].user,
            rating: reviews[index].rating,
            content: reviews[index].content,
            tags: reviews[index].tags,
          ),
      ],
    );
  }
}

enum VenueStatus { open, paused, full }

enum VenueImageKind { lake, pond, night, family, competition }

class VenueDeviceInsight {
  const VenueDeviceInsight({
    required this.waterTemperature,
    required this.airPressure,
    required this.biteFrequency,
    required this.smartFloatRecords,
    required this.uploadedReports,
    required this.summary,
  });

  final String waterTemperature;
  final String airPressure;
  final String biteFrequency;
  final int smartFloatRecords;
  final int uploadedReports;
  final String summary;
}

class VenueBookingSlot {
  const VenueBookingSlot({
    required this.id,
    required this.label,
    required this.timeRange,
    required this.price,
    required this.memberPrice,
    required this.leftSeats,
    required this.status,
  });

  final String id;
  final String label;
  final String timeRange;
  final int price;
  final int memberPrice;
  final int leftSeats;
  final BookingSlotStatus status;
}

enum BookingSlotStatus { available, few, full }

class VenueEvent {
  const VenueEvent({
    required this.id,
    required this.title,
    required this.time,
    required this.description,
    required this.price,
    required this.memberPrice,
    required this.tags,
  });

  final String id;
  final String title;
  final String time;
  final String description;
  final int price;
  final int memberPrice;
  final List<String> tags;
}

class VenuePackage {
  const VenuePackage({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.memberPrice,
    required this.includes,
  });

  final String id;
  final String title;
  final String description;
  final int price;
  final int memberPrice;
  final List<String> includes;
}

class VenueReview {
  const VenueReview({
    required this.user,
    required this.rating,
    required this.content,
    required this.tags,
  });

  final String user;
  final double rating;
  final String content;
  final List<String> tags;
}

class VenueCatchFeed {
  const VenueCatchFeed({
    required this.user,
    required this.fish,
    required this.weight,
    required this.time,
    required this.device,
  });

  final String user;
  final String fish;
  final String weight;
  final String time;
  final String device;
}

class VenueMallRecommendation {
  const VenueMallRecommendation({
    required this.productId,
    required this.name,
    required this.reason,
    required this.memberPrice,
  });

  final String productId;
  final String name;
  final String reason;
  final int memberPrice;
}

DomainVenueStatus _toDomainVenueStatus(VenueStatus status) {
  return switch (status) {
    VenueStatus.open => DomainVenueStatus.open,
    VenueStatus.paused => DomainVenueStatus.paused,
    VenueStatus.full => DomainVenueStatus.full,
  };
}

DomainSlotStatus _toDomainSlotStatus(BookingSlotStatus status) {
  return switch (status) {
    BookingSlotStatus.available => DomainSlotStatus.available,
    BookingSlotStatus.few => DomainSlotStatus.few,
    BookingSlotStatus.full => DomainSlotStatus.full,
  };
}

DomainDeviceType _deviceTypeFromLabel(String label) {
  if (label.contains('鱼漂')) return DomainDeviceType.smartFloat;
  if (label.contains('钓箱')) return DomainDeviceType.smartTackleBox;
  if (label.contains('钓台')) return DomainDeviceType.smartPlatform;
  if (label.contains('钓伞')) return DomainDeviceType.smartUmbrella;
  if (label.contains('探鱼')) return DomainDeviceType.fishFinder;
  if (label.contains('灯')) return DomainDeviceType.nightLight;
  return DomainDeviceType.other;
}

const venueSummary = VenueSummary(
  location: '杭州西湖区',
  updatedAt: '2 分钟前',
  todayIndex: 86,
  indexLabel: '适合出钓',
  indexReason: '气压稳定，智能鱼漂记录显示清晨咬口更集中。',
  weather: '多云 24°C · 东南风 2 级',
  recommendedWindow: '05:40-08:30 / 17:00-19:10',
  nearbyCount: 12,
);

const venueFilterOptions = [
  VenueFilterOption(
    id: 'nearest',
    label: '距离最近',
    description: '按当前位置排序',
    iconKey: 'near',
    group: '排序',
  ),
  VenueFilterOption(
    id: 'popular',
    label: '人气最高',
    description: '近 7 日预约和评价优先',
    iconKey: 'hot',
    group: '排序',
  ),
  VenueFilterOption(
    id: 'bookable',
    label: '支持预约',
    description: '可直接预约钓位',
    iconKey: 'booking',
    group: '交易',
  ),
  VenueFilterOption(
    id: 'fish_鲫鱼',
    label: '鲫鱼',
    description: '目标鱼种',
    iconKey: 'fish',
    group: '鱼种',
  ),
  VenueFilterOption(
    id: 'fish_鲤鱼',
    label: '鲤鱼',
    description: '目标鱼种',
    iconKey: 'fish',
    group: '鱼种',
  ),
  VenueFilterOption(
    id: 'fish_翘嘴',
    label: '翘嘴',
    description: '路亚目标鱼',
    iconKey: 'fish',
    group: '鱼种',
  ),
  VenueFilterOption(
    id: 'price_100',
    label: '百元内',
    description: '价格友好',
    iconKey: 'price',
    group: '价格',
  ),
  VenueFilterOption(
    id: 'night',
    label: '夜钓',
    description: '开放夜钓时段',
    iconKey: 'night',
    group: '场景',
  ),
  VenueFilterOption(
    id: 'blackpit',
    label: '黑坑',
    description: '竞技和回鱼规则明确',
    iconKey: 'pond',
    group: '场景',
  ),
  VenueFilterOption(
    id: 'wild',
    label: '野钓',
    description: '自然水域和安全路线',
    iconKey: 'wild',
    group: '场景',
  ),
  VenueFilterOption(
    id: 'family',
    label: '亲子',
    description: '岸边安全和配套友好',
    iconKey: 'family',
    group: '设施',
  ),
  VenueFilterOption(
    id: 'device_friendly',
    label: '设备友好',
    description: '支持智能鱼漂/探鱼器数据记录',
    iconKey: 'device',
    group: '智能设备',
  ),
  VenueFilterOption(
    id: 'parking',
    label: '停车场',
    description: '停车到钓位 300m 内',
    iconKey: 'parking',
    group: '设施',
  ),
  VenueFilterOption(
    id: 'dining',
    label: '有餐饮',
    description: '补给和简餐可用',
    iconKey: 'dining',
    group: '设施',
  ),
  VenueFilterOption(
    id: 'today_good',
    label: '今日适钓',
    description: '指数 80 分以上',
    iconKey: 'index',
    group: '智能推荐',
  ),
  VenueFilterOption(
    id: 'event',
    label: '活动赛事',
    description: '有赛事或活动',
    iconKey: 'event',
    group: '商业活动',
  ),
];

const venueMallRecommendations = [
  VenueMallRecommendation(
    productId: 'smart-float-pro',
    name: '智能鱼漂 Pro',
    reason: '适合轻口鲫鱼和夜钓提醒',
    memberPrice: 359,
  ),
  VenueMallRecommendation(
    productId: 'fish-finder-sonar-pro',
    name: '便携探鱼器 Pro',
    reason: '陌生水域先看水深和结构',
    memberPrice: 799,
  ),
  VenueMallRecommendation(
    productId: 'night-light-max',
    name: '夜钓灯 Max',
    reason: '夜钓钓位推荐搭配',
    memberPrice: 259,
  ),
];

const fishingVenues = [
  FishingVenue(
    id: 'west-lake-smart-pond',
    name: '西湖花港智能钓场',
    area: '杭州西湖区',
    address: '西湖区花港南侧水域服务点',
    distanceLabel: '3.2km',
    distanceKm: 3.2,
    rating: 4.8,
    popularity: 94,
    priceFrom: 68,
    memberPriceFrom: 58,
    todayIndex: 88,
    todayLabel: '清晨口好',
    openHours: '05:30-22:00',
    status: VenueStatus.open,
    leftSeats: 8,
    fishSpecies: ['鲫鱼', '鲤鱼', '白条'],
    tags: ['可预约', '设备友好', '亲子安全'],
    sceneTypes: ['黑坑', '亲子'],
    facilities: ['停车场', '餐饮', '洗手间', '夜钓灯位'],
    bookingSupported: true,
    nightFishing: true,
    smartDeviceFriendly: true,
    parking: true,
    dining: true,
    familyFriendly: true,
    activitySupported: true,
    mainImageKind: VenueImageKind.lake,
    headline: '智能鱼漂记录显示清晨咬口集中',
    description: '适合新手和亲子用户，钓位规则清晰，支持智能鱼漂数据同步和夜钓灯位预约。',
    chargeRule: '日场 68 元起，夜场 88 元起，会员可享钓位折扣。',
    contactPhone: '0571-8800-1026',
    navigationHint: '停车场步行 120m，到达南侧 3-8 号钓位。',
    memberBenefit: 'Pro 会员钓位立减 10 元，设备租赁 8 折。',
    recommendedDevices: ['智能鱼漂', '夜钓灯', '智能钓箱'],
    recommendedProductIds: [
      'smart-float-pro',
      'night-light-max',
      'smart-box-36l',
    ],
    deviceInsight: VenueDeviceInsight(
      waterTemperature: '18.6°C',
      airPressure: '1008hPa',
      biteFrequency: '12次/小时',
      smartFloatRecords: 128,
      uploadedReports: 36,
      summary: '轻口信号集中在 06:10-08:20，建议调低灵敏度并使用小钩细线。',
    ),
    events: [
      VenueEvent(
        id: 'west-lake-weekend-family',
        title: '周末亲子智能鱼漂体验',
        time: '周六 09:00',
        description: '含基础教学、智能鱼漂绑定和安全钓位。',
        price: 99,
        memberPrice: 79,
        tags: ['亲子', '教学', '设备体验'],
      ),
    ],
    packages: [
      VenuePackage(
        id: 'west-lake-device-pass',
        title: '智能鱼漂 + 日场钓位',
        description: '钓位、鱼漂租赁和作钓报告一次打包。',
        price: 128,
        memberPrice: 108,
        includes: ['日场钓位', '智能鱼漂租赁', '作钓报告'],
      ),
    ],
    bookingSlots: [
      VenueBookingSlot(
        id: 'wl-morning',
        label: '清晨黄金位',
        timeRange: '05:30-09:30',
        price: 68,
        memberPrice: 58,
        leftSeats: 3,
        status: BookingSlotStatus.few,
      ),
      VenueBookingSlot(
        id: 'wl-night',
        label: '夜钓灯位',
        timeRange: '18:30-22:00',
        price: 88,
        memberPrice: 76,
        leftSeats: 5,
        status: BookingSlotStatus.available,
      ),
    ],
    reviews: [
      VenueReview(
        user: '路亚阿杭',
        rating: 4.8,
        content: '钓位清楚，智能鱼漂记录很完整，适合带新手。',
        tags: ['干净', '设备好用'],
      ),
    ],
    catchFeeds: [
      VenueCatchFeed(
        user: '小林',
        fish: '鲫鱼',
        weight: '0.7kg',
        time: '今天 07:18',
        device: '智能鱼漂 Pro',
      ),
    ],
  ),
  FishingVenue(
    id: 'xianghu-night-lure',
    name: '湘湖夜钓路亚基地',
    area: '杭州萧山区',
    address: '湘湖下孙文化村东侧',
    distanceLabel: '5.6km',
    distanceKm: 5.6,
    rating: 4.7,
    popularity: 91,
    priceFrom: 88,
    memberPriceFrom: 78,
    todayIndex: 82,
    todayLabel: '傍晚追口',
    openHours: '06:00-23:30',
    status: VenueStatus.open,
    leftSeats: 6,
    fishSpecies: ['翘嘴', '鲈鱼', '鳜鱼'],
    tags: ['夜钓', '路亚', '赛事'],
    sceneTypes: ['野钓', '竞技'],
    facilities: ['停车场', '夜钓灯', '向导', '装备租赁'],
    bookingSupported: true,
    nightFishing: true,
    smartDeviceFriendly: true,
    parking: true,
    dining: false,
    familyFriendly: false,
    activitySupported: true,
    mainImageKind: VenueImageKind.night,
    headline: '傍晚窗口适合快搜浅滩外沿',
    description: '适合路亚玩家和夜钓用户，提供探鱼器租赁、向导和赛事报名。',
    chargeRule: '夜场 88 元起，赛事日按活动规则收费。',
    contactPhone: '0571-8818-6620',
    navigationHint: '停车后沿湖步道 260m，注意木栈道湿滑。',
    memberBenefit: 'Pro 会员报名赛事减 20 元，探鱼器租赁 8 折。',
    recommendedDevices: ['探鱼器', '夜钓灯', '智能钓伞'],
    recommendedProductIds: [
      'fish-finder-sonar-pro',
      'night-light-max',
      'smart-umbrella-air',
    ],
    deviceInsight: VenueDeviceInsight(
      waterTemperature: '19.4°C',
      airPressure: '1005hPa',
      biteFrequency: '8次/小时',
      smartFloatRecords: 76,
      uploadedReports: 24,
      summary: '17:40 后中上层活跃，探鱼器记录显示浅滩外沿有鱼群经过。',
    ),
    events: [
      VenueEvent(
        id: 'xianghu-lure-cup',
        title: '夜钓路亚积分赛',
        time: '周五 19:00',
        description: '按鱼种积分，支持 App 自动记录鱼获。',
        price: 168,
        memberPrice: 138,
        tags: ['赛事', '夜钓', '路亚'],
      ),
    ],
    packages: [
      VenuePackage(
        id: 'xianghu-night-kit',
        title: '夜钓路亚套票',
        description: '夜钓位、夜钓灯和探鱼器租赁组合。',
        price: 198,
        memberPrice: 168,
        includes: ['夜钓钓位', '探鱼器租赁', '夜钓灯'],
      ),
    ],
    bookingSlots: [
      VenueBookingSlot(
        id: 'xh-dusk',
        label: '傍晚路亚位',
        timeRange: '17:30-20:30',
        price: 88,
        memberPrice: 78,
        leftSeats: 4,
        status: BookingSlotStatus.available,
      ),
      VenueBookingSlot(
        id: 'xh-event',
        label: '赛事体验位',
        timeRange: '19:00-22:30',
        price: 168,
        memberPrice: 138,
        leftSeats: 2,
        status: BookingSlotStatus.few,
      ),
    ],
    reviews: [
      VenueReview(
        user: '夜钓老周',
        rating: 4.7,
        content: '赛事氛围好，探鱼器租赁省了很多试水时间。',
        tags: ['路亚友好', '夜钓'],
      ),
    ],
    catchFeeds: [
      VenueCatchFeed(
        user: '阿哲',
        fish: '翘嘴',
        weight: '1.2kg',
        time: '昨天 20:42',
        device: '探鱼器 Pro',
      ),
    ],
  ),
  FishingVenue(
    id: 'qiantang-wild-bay',
    name: '钱塘支流野钓湾',
    area: '钱塘区',
    address: '钱塘江支流回湾安全钓位',
    distanceLabel: '8.1km',
    distanceKm: 8.1,
    rating: 4.4,
    popularity: 78,
    priceFrom: 48,
    memberPriceFrom: 48,
    todayIndex: 69,
    todayLabel: '谨慎出钓',
    openHours: '06:00-18:00',
    status: VenueStatus.paused,
    leftSeats: 0,
    fishSpecies: ['鳜鱼', '鲤鱼', '黄颡'],
    tags: ['野钓', '风险提醒', '风浪小'],
    sceneTypes: ['野钓'],
    facilities: ['停车点', '安全提示牌'],
    bookingSupported: false,
    nightFishing: false,
    smartDeviceFriendly: false,
    parking: false,
    dining: false,
    familyFriendly: false,
    activitySupported: false,
    mainImageKind: VenueImageKind.pond,
    headline: '雨后水位变化快，建议暂缓涉水',
    description: '自然水域，适合有经验钓友，当前更适合查看鱼情和安全提醒。',
    chargeRule: '免费水域，无平台预约服务。',
    contactPhone: '暂无钓场电话',
    navigationHint: '停车点较远，需步行 420m，雨后不建议下坡。',
    memberBenefit: '会员可保存风险提醒和出钓计划。',
    recommendedDevices: ['探鱼器', '智能钓伞'],
    recommendedProductIds: ['fish-finder-sonar-pro', 'smart-umbrella-air'],
    deviceInsight: VenueDeviceInsight(
      waterTemperature: '20.1°C',
      airPressure: '1002hPa',
      biteFrequency: '估算',
      smartFloatRecords: 18,
      uploadedReports: 7,
      summary: '设备数据不足，主要依赖历史鱼获和天气估算，不建议夜间单人前往。',
    ),
    events: [],
    packages: [],
    bookingSlots: [
      VenueBookingSlot(
        id: 'qt-paused',
        label: '安全观察',
        timeRange: '今日暂停预约',
        price: 0,
        memberPrice: 0,
        leftSeats: 0,
        status: BookingSlotStatus.full,
      ),
    ],
    reviews: [
      VenueReview(
        user: '守湾人',
        rating: 4.1,
        content: '有鱼，但路况和水位需要特别谨慎。',
        tags: ['野钓', '注意安全'],
      ),
    ],
    catchFeeds: [
      VenueCatchFeed(
        user: '小彭',
        fish: '黄颡',
        weight: '0.4kg',
        time: '前天 18:10',
        device: '手动记录',
      ),
    ],
  ),
  FishingVenue(
    id: 'qingshan-family-lake',
    name: '青山湖家庭露营钓场',
    area: '临安区',
    address: '青山湖北岸浅滩营地',
    distanceLabel: '12.4km',
    distanceKm: 12.4,
    rating: 4.6,
    popularity: 84,
    priceFrom: 98,
    memberPriceFrom: 88,
    todayIndex: 76,
    todayLabel: '看风向',
    openHours: '06:00-22:00',
    status: VenueStatus.full,
    leftSeats: 0,
    fishSpecies: ['鲈鱼', '翘嘴', '鲫鱼'],
    tags: ['亲子', '露营', '停车'],
    sceneTypes: ['野钓', '亲子'],
    facilities: ['停车场', '餐饮', '露营区', '洗手间'],
    bookingSupported: true,
    nightFishing: true,
    smartDeviceFriendly: true,
    parking: true,
    dining: true,
    familyFriendly: true,
    activitySupported: true,
    mainImageKind: VenueImageKind.family,
    headline: '家庭露营友好，今日钓位已约满',
    description: '适合家庭半日游和露营，配套完善，开放夜钓灯位和儿童安全区。',
    chargeRule: '营地钓位 98 元起，亲子套餐 168 元起。',
    contactPhone: '0571-8876-3018',
    navigationHint: '停车点 180m，营地入口领取腕带后入场。',
    memberBenefit: 'Pro 会员亲子套餐减 20 元，装备清单自动生成。',
    recommendedDevices: ['智能钓伞', '智能钓箱', '夜钓灯'],
    recommendedProductIds: [
      'smart-umbrella-air',
      'smart-box-36l',
      'night-light-max',
    ],
    deviceInsight: VenueDeviceInsight(
      waterTemperature: '18.9°C',
      airPressure: '1007hPa',
      biteFrequency: '6次/小时',
      smartFloatRecords: 62,
      uploadedReports: 19,
      summary: '风向变化较快，智能钓伞风力提醒和钓箱装备清单更有价值。',
    ),
    events: [
      VenueEvent(
        id: 'qingshan-family-day',
        title: '亲子露营钓鱼日',
        time: '周日 10:00',
        description: '含安全教学、亲子钓位和营地餐饮券。',
        price: 188,
        memberPrice: 168,
        tags: ['亲子', '露营', '活动券'],
      ),
    ],
    packages: [
      VenuePackage(
        id: 'qingshan-family-pass',
        title: '亲子营地钓位套餐',
        description: '钓位、餐饮券、儿童安全装备和作钓记录。',
        price: 168,
        memberPrice: 148,
        includes: ['亲子钓位', '餐饮券', '安全装备', '作钓记录'],
      ),
    ],
    bookingSlots: [
      VenueBookingSlot(
        id: 'qs-full',
        label: '今日家庭位',
        timeRange: '10:00-16:00',
        price: 168,
        memberPrice: 148,
        leftSeats: 0,
        status: BookingSlotStatus.full,
      ),
    ],
    reviews: [
      VenueReview(
        user: '带娃钓鱼',
        rating: 4.6,
        content: '配套完整，孩子玩得安全，周末要提前预约。',
        tags: ['亲子', '餐饮方便'],
      ),
    ],
    catchFeeds: [
      VenueCatchFeed(
        user: '可乐爸爸',
        fish: '鲈鱼',
        weight: '0.9kg',
        time: '昨天 17:02',
        device: '智能钓伞',
      ),
    ],
  ),
];

FishingVenue? venueById(String id) {
  for (final venue in fishingVenues) {
    if (venue.id == id) return venue;
  }
  return null;
}

FishingVenue? venueByName(String name) {
  for (final venue in fishingVenues) {
    if (venue.name == name) return venue;
  }
  return null;
}

List<FishingVenue> recommendedVenues() {
  final venues = [...fishingVenues];
  venues.sort((a, b) => b.todayIndex.compareTo(a.todayIndex));
  return venues;
}
