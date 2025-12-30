import { CartService, ShopCartGroup } from '../../service/CartService';
import { ShopService } from '../../service/ShopService';
import { CartItem, ShopVO } from '../../model/entity/ShopModel';
import { promptAction } from '@kit.ArkUI';

/**
 * 🛒 购物车页面展示用的扩展接口喵
 */
interface ShopCartUIModel extends ShopCartGroup {
  shopInfo?: ShopVO | null; 
}

/**
 * 🛒 购物车主页面 (多商店聚合版)
 */
@Component
export struct CartPage {
  @Consume('pageStack') pageStack: NavPathStack;
  @State shopCartUIModels: ShopCartUIModel[] = [];
  @State isLoading: boolean = true;
  @StorageProp('CartUpdateSignal') @Watch('loadCartData') cartSignal: number = 0;

  async aboutToAppear() {
    this.loadCartData();
  }

  /**
   * 🔄 加载并聚合购物车数据喵
   */
  async loadCartData() {
    this.isLoading = true;
    const cartService = CartService.getInstance();
    const groups = await cartService.getAllShopCarts();
    
    // 补全店铺信息 (店名、Logo等)
    const tasks = groups.map(async (group: ShopCartGroup) => {
      const shopInfo = await ShopService.getShopDetail(group.shopId);
      const model: ShopCartUIModel = {
        shopId: group.shopId,
        count: group.count,
        amount: group.amount,
        items: group.items,
        shopInfo: shopInfo
      };
      return model;
    });

    this.shopCartUIModels = await Promise.all(tasks);
    this.isLoading = false;
  }

  build() {
    Column() {
      // 1. 标题栏喵
      Row() {
        Text('购物车').fontSize(20).fontWeight(FontWeight.Bold).fontColor('#333')
        Blank()
        if (this.shopCartUIModels.length > 0) {
          Text('清空所有')
            .fontSize(14)
            .fontColor('#999')
            .onClick(() => this.handleClearAll())
        }
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(Color.White)

      // 2. 内容区喵
      if (this.isLoading) {
        Column() {
          LoadingProgress().width(40).height(40).color('#FFCC00')
        }.layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.shopCartUIModels.length > 0) {
        List({ space: 12 }) {
          ForEach(this.shopCartUIModels, (model: ShopCartUIModel) => {
            ListItem() {
              this.ShopCartCard(model)
            }
          })
          ListItem().height(20) 
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 12, right: 12, top: 12 })
        .backgroundColor('#F7F8FA')
        .edgeEffect(EdgeEffect.Spring)
      } else {
        Column({ space: 15 }) {
          Image($r('app.media.miniLogo')).width(100).opacity(0.2)
          Text('购物车还是空空的喵...').fontSize(14).fontColor('#999')
          Button('去点餐')
            .backgroundColor('#FFCC00')
            .fontColor('#333')
            .height(40)
            .width(120)
            .onClick(() => {
              AppStorage.setOrCreate('currentTabIndex', 0);
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F8FA')
  }

  /**
   * 🎨 店铺购物车卡片组件喵
   */
  @Builder
  ShopCartCard(model: ShopCartUIModel) {
    Column() {
      // (1) 店铺头部喵
      Row() {
        Image(model.shopInfo?.avatar || $r('app.media.shop_logo'))
          .width(24).height(24).borderRadius(4).margin({ right: 8 })
        
        Text(model.shopInfo?.name || `商家 ${model.shopId}`)
          .fontSize(15).fontWeight(FontWeight.Bold).fontColor('#333')
          .layoutWeight(1)
        
        SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(14).fontColor(['#999'])
      }
      .width('100%')
      .padding({ bottom: 12 })
      .onClick(() => {
        this.pageStack.pushPath({ name: 'ShopPage', param: model.shopId });
      })

      // (2) 商品预览
      Column({ space: 10 }) {
        ForEach(model.items.slice(0, 3), (item: CartItem) => {
          Row() {
            Image(item.image)
              .width(40).height(40).borderRadius(4).margin({ right: 10 })
              .objectFit(ImageFit.Cover)
            
            Column() {
              Text(item.name).fontSize(14).fontColor('#333').maxLines(1)
              if (item.flavors) {
                Text(item.flavors).fontSize(10).fontColor('#999').margin({ top: 2 })
              }
            }.layoutWeight(1).alignItems(HorizontalAlign.Start)

            Text(`x${item.count}`).fontSize(14).fontColor('#666')
          }
          .width('100%')
        })
        
        if (model.items.length > 3) {
          Text(`查看全部 ${model.items.length} 件商品...`)
            .fontSize(12).fontColor('#999').margin({ left: 50 })
        }
      }

      Divider().margin({ top: 12, bottom: 12 }).color('#F2F2F2')

      // (3) 底部合计与按钮喵
      Row() {
        Text(`共 ${model.count} 件`).fontSize(12).fontColor('#999')
        Blank()
        Text('合计').fontSize(14).fontColor('#333')
        Text(`￥${model.amount.toFixed(2)}`)
          .fontSize(18).fontWeight(FontWeight.Bold).fontColor('#333')
          .margin({ left: 4, right: 12 })
        
        Button('去结算')
          .height(32)
          .padding({ left: 16, right: 16 })
          .backgroundColor('#FFCC00')
          .fontColor('#333')
          .fontSize(14)
          .onClick(() => {
            this.pageStack.pushPath({ name: 'ShopPage', param: model.shopId });
          })
      }
      .width('100%')
    }
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
  }

  handleClearAll() {
    AlertDialog.show({
      title: '清空确认喵？',
      message: '确定要清空所有店铺的购物车吗喵？😿',
      primaryButton: { value: '再想想', action: () => {} },
      secondaryButton: {
        value: '清空',
        fontColor: Color.Red,
        action: () => {
          CartService.getInstance().clearAllCarts();
          promptAction.showToast({ message: '购物车已经空空如也了喵~' });
        }
      }
    })
  }
}