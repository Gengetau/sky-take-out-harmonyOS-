import { promptAction } from '@kit.ArkUI';
import { CategoryWithItems } from '../../model/entity/MockData';
import { DishVO, ShopVO } from '../../model/entity/ShopModel';
import { CartService } from '../../service/CartService';
import { ShopService } from '../../service/ShopService';
import { ConfirmOrderView } from '../main/ConfirmOrderPage'; 
import { CartBar } from './components/CartBar';
import { DishCard } from './components/DishCard';
import { FlavorDialog } from './components/FlavorDialog';
import { ShopHeader } from './components/ShopHeader';

/**
 * 商店主页面 - 多商店平台重构版 ✨
 */
@Component
export struct ShopPage {
  @Consume('pageStack') pageStack: NavPathStack;
  
  // 1.数据源
  @State categoryList: CategoryWithItems[] = [];
  @State shopInfo: ShopVO | null = null;
  @State shopId: number = 0;

  // 2.状态变量
  @State currentCategoryIndex: number = 0; 
  @State isLoading: boolean = true; 
  @State isShopOpen: boolean = false; 
  @State showConfirmOrder: boolean = false;
  
  // 3.控制器
  private rightScroller: Scroller = new Scroller();
  
  // 4.服务实例
  @Provide('cartService') cartService: CartService = CartService.getInstance();
  
  // 5.标志变量
  private isClickScroll: boolean = false;
  @State currentDish: DishVO | null = null;
  
  // 定义弹窗控制器
  private flavorController: CustomDialogController = new CustomDialogController({
    builder: FlavorDialog({
      dish: this.currentDish!, 
      onConfirm: (flavors: string) => {
        if ( this.currentDish ) {
          this.cartService.addItem(this.currentDish, flavors);
          promptAction.showToast({ message: `${ this.currentDish.name } 已加入购物车` });
        }
      }
    }),
    alignment: DialogAlignment.Center, 
    customStyle: true 
  });

  async aboutToAppear() {
    // 🔍 从路由参数中获取 shopId
    const params = this.pageStack.getParamByName('ShopPage') as number[];
    if (params && params.length > 0) {
      this.shopId = params[params.length - 1]; 
    }
    
    this.loadData();
  }

  async loadData() {
    this.isLoading = true;

    try {
      const results = await Promise.all([
        ShopService.getShopStatus(),
        ShopService.getShopData(),
        this.shopId > 0 ? ShopService.getShopDetail(this.shopId) : Promise.resolve(null)
      ]);

      this.isShopOpen = results[0] === 1;
      
      const data = results[1];
      if ( data.length > 0 ) {
        this.categoryList = data;
      }
      
      this.shopInfo = results[2];
      if (this.shopInfo) {
        this.isShopOpen = this.shopInfo.status === 1;
      }

    } catch (e) {
      console.error('加载店铺数据失败喵', e);
    } finally {
      this.isLoading = false;
    }
  }

  // ✨ 关键重构：将 shopId 和 shopInfo 注入确认页
  @Builder
  ConfirmOrderBuilder() {
    ConfirmOrderView({
      shopId: this.shopId,
      shopInfo: this.shopInfo,
      onClose: () => {
        this.showConfirmOrder = false;
      }
    })
  }

  build() {
    NavDestination() {
      Column() {
        // 🏠 动态店招牌喵
        ShopHeader({ 
          isShopOpen: this.isShopOpen,
          shopInfo: this.shopInfo
        })

        if ( this.isLoading ) {
          Column() {
            LoadingProgress().width(40).height(40).color('#0D9FFB')
            Text('正在准备美食喵...').fontSize(12).fontColor(Color.Gray).margin({ top: 10 })
          }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
        } else {
          // 联动列表
          Row() {
            // 左侧：分类列表
            List({ initialIndex: 0 }) {
              ForEach(this.categoryList, (item: CategoryWithItems, index: number) => {
                ListItem() {
                  Text(item.category.name)
                    .fontSize(14)
                    .fontColor(this.currentCategoryIndex === index ? '#333333' : '#666666')
                    .fontWeight(this.currentCategoryIndex === index ? FontWeight.Bold : FontWeight.Normal)
                    .width('100%')
                    .textAlign(TextAlign.Center)
                }
                .height(50)
                .backgroundColor(this.currentCategoryIndex === index ? '#FFFFFF' : '#F8F8F8')
                .onClick(() => {
                  this.selectCategory(index);
                })
              })
            }
            .width('25%') 
            .height('100%')
            .backgroundColor('#F8F8F8')
            .scrollBar(BarState.Off) 

            // 右侧：菜品列表
            List({ scroller: this.rightScroller }) {
              ForEach(this.categoryList, (group: CategoryWithItems, groupIndex: number) => {
                ListItemGroup({ header: this.RightGroupHeader(group.category.name) }) {
                  ForEach(group.items, (dish: DishVO) => {
                    ListItem() {
                      DishCard({
                        dish: dish,
                        isShopOpen: this.isShopOpen, 
                        isSetmeal: group.category.type === 2, 
                        onOpenFlavorDialog: (dishToOpen: DishVO) => {
                          this.currentDish = dishToOpen;
                          this.flavorController.open();
                        }
                      })
                    }
                  }, (dish: DishVO) => dish.id.toString()) 
                }
              })
            }
            .width('75%')
            .height('100%')
            .backgroundColor(Color.White)
            .scrollBar(BarState.Off)
            .sticky(StickyStyle.Header) 
            .onScrollIndex((firstIndex: number) => {
              if (!this.isClickScroll ) {
                this.currentCategoryIndex = firstIndex;
              }
            })
            .onScrollStop(() => {
              this.isClickScroll = false;
            })
          }
          .layoutWeight(1) 
          .alignItems(VerticalAlign.Top)
        }

        // 底部购物车
        CartBar({
          isShopOpen: this.isShopOpen,
          onCheckout: () => {
            this.showConfirmOrder = true;
          }
        })
      }
      .height('100%')
      .backgroundColor(Color.White)
      .bindSheet($$this.showConfirmOrder, this.ConfirmOrderBuilder(), {
        height: SheetSize.LARGE, 
        dragBar: true, 
        backgroundColor: '#F1F3F5',
        onDisappear: () => {
          this.showConfirmOrder = false;
        }
      })
    }
    .hideTitleBar(true)
  }

  @Builder
  RightGroupHeader(title: string) {
    Row() {
      Text(title).fontSize(12)
        .fontColor('#666666')
    }
    .width('100%')
    .height(30)
    .padding({ left: 10 })
    .backgroundColor('#F3F4F6')
  }

  selectCategory(index: number) {
    this.isClickScroll = true; 
    this.currentCategoryIndex = index;
    this.rightScroller.scrollToIndex(index, true); 
  }
}