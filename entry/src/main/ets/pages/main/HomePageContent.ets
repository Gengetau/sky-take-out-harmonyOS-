import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { GeoPoint, LocationUtil } from '../../common/utils/LocationUtil';
import { LocationInfo } from '../../model/entity/LocationInfo';
import { ShopVO } from '../../model/entity/ShopModel';
import { ShopTypeVO } from '../../model/entity/ShopTypeModel';
import { HomeService } from '../../service/HomeService';
import { ShopService } from '../../service/ShopService';

/**
 * 首页 - 多商店平台重构版 ✨
 */
@Component
export struct HomePageContent {
  @Consume('pageStack') pageStack: NavPathStack;
  // 1. 轮播图数据
  private bannerList: Resource[] = [
    $r('app.media.banner1'),
    $r('app.media.banner2'),
    $r('app.media.banner3'),
    $r('app.media.banner4')
  ];
  // 2. 状态管理
  @State rawGridItems: ShopTypeVO[] = [];
  @State pagedGridItems: ShopTypeVO[][] = [];
  @State shops: ShopVO[] = [];
  @State isLoadingShops: boolean = false;
  @State currentTypeId: number = 1;
  // 📍 坐标信息
  @State longitude: number = 116.397428;
  @State latitude: number = 39.90923;
  @State locationName: string = '正在定位...';
  // 🔗 监听全局选中的位置
  @StorageLink('SelectedLocation') @Watch('onManualLocationChange') selectedLocation: LocationInfo | null = null;
  // 🎨 自定义位置选择弹窗控制器
  dialogController: CustomDialogController = new CustomDialogController({
    builder: LocationPickerDialog({
      onSelectGPS: () => {
        this.handleGetLocation()
      },
      onSelectMap: () => {
        this.pageStack.pushPath({ name: 'AddressMapPage' })
      }
    }),
    alignment: DialogAlignment.Bottom,
    customStyle: true,
    autoCancel: true,
    maskColor: '#80000000'
  })

  async aboutToAppear() {
    await this.queryShopTypes();
    if (!this.selectedLocation ) {
      this.handleGetLocation();
    } else {
      this.onManualLocationChange();
    }
  }

  onManualLocationChange() {
    if ( this.selectedLocation ) {
      this.latitude = this.selectedLocation.latitude;
      this.longitude = this.selectedLocation.longitude;
      this.locationName = this.selectedLocation.name;
      this.fetchShops(this.currentTypeId);
    }
  }

  async handleGetLocation() {
    const context = getContext(this) as common.UIAbilityContext;
    this.locationName = '正在定位...';
    try {
      const point: GeoPoint | null = await LocationUtil.getCurrentLocation(context);

      if ( point ) {
        this.latitude = point.latitude;
        this.longitude = point.longitude;

        const address = await LocationUtil.getAddressFromLocation(this.latitude, this.longitude);
        this.locationName = address;

        this.fetchShops(this.currentTypeId);
      } else {
        this.locationName = '定位失败';
        promptAction.showToast({ message: '定位权限未开启喵' });
      }
    } catch ( e ) {
      this.locationName = '定位失败喵';
    }
  }

  async queryShopTypes() {
    const data = await HomeService.getShopTypes();
    if ( data.length > 0 ) {
      this.rawGridItems = data;
      this.pagedGridItems = chunkArray(this.rawGridItems, 10);

      this.currentTypeId = data[0].id;
      this.fetchShops(this.currentTypeId);
    }
  }

  async fetchShops(typeId: number) {
    this.isLoadingShops = true;
    this.currentTypeId = typeId;
    try {
      const shopList = await ShopService.getShopList(typeId, this.longitude, this.latitude);
      this.shops = shopList;
    } catch ( e ) {
      console.error('获取商家列表失败喵', e);
    } finally {
      this.isLoadingShops = false;
    }
  }

  build() {
    Column() {
      // --- 1. 顶部全新布局 (地址独占一行喵) ---
      this.TopHeader()

      // --- 2. 可滚动区域 ---
      Scroll() {
        Column() {
          // (1) 轮播图 Banner
          Swiper() {
            ForEach(this.bannerList, (img: Resource) => {
              Image(img)
                .width('100%')
                .height(160)
                .objectFit(ImageFit.Cover)
                .borderRadius(12)
            })
          }
          .autoPlay(true)
          .interval(3000)
          .indicator(true)
          .width('100%')
          .margin({ top: 10 })

          // (2) 金刚区分类菜单
          Swiper() {
            ForEach(this.pagedGridItems, (pageItems: ShopTypeVO[]) => {
              Grid() {
                ForEach(pageItems, (item: ShopTypeVO) => {
                  GridItem() {
                    Column({ space: 6 }) {
                      Image(item.icon)
                        .width(40).height(40)
                        .objectFit(ImageFit.Contain)
                      Text(item.name)
                        .fontSize(12)
                        .fontColor(this.currentTypeId === item.id ? '#0D9FFB' : '#333')
                        .fontWeight(this.currentTypeId === item.id ? FontWeight.Bold : FontWeight.Normal)
                    }
                    .onClick(() => this.fetchShops(item.id))
                  }
                }, (item: ShopTypeVO) => item.id.toString())
              }
              .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
              .rowsTemplate('1fr 1fr')
              .rowsGap(10)
              .width('100%')
              .height(160)
            })
          }
          .height(200)
          .autoPlay(false)
          .loop(false)
          .indicator(
            Indicator.dot()
              .itemWidth(8)
              .itemHeight(4)
              .selectedItemWidth(12)
              .selectedItemHeight(4)
              .color('#CCCCCC')
              .selectedColor('#0D9FFB')
          )
          .margin({ top: 15 })

          // (3) 附近的商家标题
          Row() {
            Text('附近的商家')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333')
            Blank()
            Text('综合排序')
              .fontSize(12)
              .fontColor('#666')
            SymbolGlyph($r('sys.symbol.chevron_down')).fontSize(12).fontColor([ '#666' ])
          }
          .width('100%')
          .margin({ top: 20, bottom: 10 })

          // (4) 商家列表喵
          if ( this.isLoadingShops ) {
            Column() {
              LoadingProgress().width(40).height(40).color('#0D9FFB')
            }.width('100%').margin({ top: 20 })
          } else if ( this.shops.length > 0 ) {
            Column() {
              ForEach(this.shops, (shop: ShopVO) => {
                this.ShopItem(shop)
              })
            }
            .width('100%')
          } else {
            Column({ space: 10 }) {
              Image($r('app.media.miniLogo')).width(60).opacity(0.3)
              Text('附近暂时没有该类商家喵~').fontSize(14).fontColor('#999')
            }
            .width('100%')
            .margin({ top: 40 })
          }
        }
        .padding({ left: 12, right: 12, bottom: 30 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F6F6F6')
  }

  // 🎨 全新顶部组件喵
  @Builder
  TopHeader() {
    Column() {
      // 第一行：地址定位喵
      Row() {
        SymbolGlyph($r('sys.symbol.local_fill'))
          .fontSize(18)
          .fontColor([ '#333' ])
          .margin({ right: 6 })

        Text(this.locationName)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)

        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(14)
          .fontColor([ '#666' ])
      }
      .width('100%')
      .padding({
        left: 12,
        right: 12,
        top: 12,
        bottom: 8
      })
      .onClick(() => {
        // 打开美化后的自定义弹窗
        this.dialogController.open()
      })

      // 第二行：搜索框与消息喵
      Row({ space: 12 }) {
        Row() {
          Image($r('sys.symbol.magnifyingglass'))
            .width(16).height(16).fillColor('#999999')
            .margin({ left: 10, right: 5 })
          Text('搜索美食、商家')
            .fontSize(12).fontColor('#999999')
        }
        .layoutWeight(1)
        .height(36)
        .backgroundColor('#FFFFFF')
        .borderRadius(18)

        SymbolGlyph($r('sys.symbol.bell'))
          .fontSize(24)
          .fontColor([ '#333333' ])
      }
      .width('100%')
      .padding({
        left: 12,
        right: 12,
        top: 4,
        bottom: 12
      })
    }
    .backgroundColor('#F6F6F6')
  }

  // 🎨 商家卡片
  @Builder
  ShopItem(shop: ShopVO) {
    Row() {
      Image(shop.avatar || $r('app.media.shop_logo'))
        .width(100)
        .height(100)
        .borderRadius(8)
        .margin({ right: 12 })
        .objectFit(ImageFit.Cover)

      Column({ space: 5 }) {
        Text(shop.name)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row({ space: 8 }) {
          Row({ space: 2 }) {
            SymbolGlyph($r('sys.symbol.star_fill')).fontSize(12).fontColor([ '#FFCC00' ])
            Text(shop.score.toFixed(1)).fontSize(12).fontColor('#FFCC00').fontWeight(FontWeight.Bold)
          }

          Text(`月售 ${ shop.monthlySales }`).fontSize(12).fontColor('#666')
        }

        Row() {
          Text(`起送 ￥${ shop.deliveryPrice }`).fontSize(11).fontColor('#666')
          Divider().vertical(true).height(10).margin({ left: 6, right: 6 }).color('#DDD')
          Text(`配送 ￥${ shop.shippingFee }`).fontSize(11).fontColor('#666')
        }

        Row() {
          if ( shop.distance ) {
            Text(shop.distance).fontSize(11).fontColor('#0D9FFB')
            Divider().vertical(true).height(10).margin({ left: 6, right: 6 }).color('#DDD')
          }
          Text(`${ shop.averageDeliveryTime } 分钟`).fontSize(11).fontColor('#666')
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding(12)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ bottom: 12 })
    .onClick(() => {
      this.pageStack.pushPath({ name: 'ShopPage', param: shop.id }, true)
    })
  }
}

/**
 * ✨ 美化后的自定义位置选择弹窗
 */
@CustomDialog
struct LocationPickerDialog {
  controller: CustomDialogController
  onSelectGPS: () => void = () => {
  }
  onSelectMap: () => void = () => {
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('选择送货位置')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')

        Blank()

        // 关闭按钮
        SymbolGlyph($r('sys.symbol.xmark'))
          .fontSize(20)
          .fontColor([ '#999' ])
          .onClick(() => {
            this.controller.close()
          })
      }
      .width('100%')
      .padding({
        top: 20,
        bottom: 20,
        left: 20,
        right: 20
      })

      // 选项列表
      Column({ space: 12 }) {
        // 选项 1: 自动定位
        this.OptionItem({
          icon: $r('sys.symbol.position'),
          title: '重新定位当前位置',
          subtitle: '基于GPS自动获取',
          color: '#0D9FFB',
          onClick: () => {
            this.onSelectGPS()
            this.controller.close()
          }
        })

        // 选项 2: 地图选点
        this.OptionItem({
          icon: $r('sys.symbol.map'),
          title: '在地图上选择位置',
          subtitle: '手动拖动地图定位',
          color: '#FFCC00',
          onClick: () => {
            this.onSelectMap()
            this.controller.close()
          }
        })
      }
      .padding({ left: 16, right: 16, bottom: 30 })
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius({ topLeft: 24, topRight: 24 })
  }

  @Builder
  OptionItem(params: OptionItemParams) {
    Row() {
      // 图标容器
      Stack({ alignContent: Alignment.Center }) {
        Circle({ width: 44, height: 44 })
          .fill(params.color)
          .opacity(0.1)
        SymbolGlyph(params.icon)
          .fontSize(24)
          .fontColor([ params.color ])
      }
      .margin({ right: 16 })

      // 文字信息
      Column({ space: 4 }) {
        Text(params.title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333')
        Text(params.subtitle)
          .fontSize(12)
          .fontColor('#999')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 箭头
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(16)
        .fontColor([ '#CCC' ])
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#F9F9F9')
    .borderRadius(16)
    .onClick(() => {
      params.onClick()
    })
  }
}

interface OptionItemParams {
  icon: Resource;
  title: string;
  subtitle: string;
  color: string;
  onClick: () => void;
}

function chunkArray<T>(source: T[], size: number): T[][] {
  const result: T[][] = [];
  for ( let i = 0; i < source.length; i += size ) {
    result.push(source.slice(i, i + size));
  }
  return result;
}
