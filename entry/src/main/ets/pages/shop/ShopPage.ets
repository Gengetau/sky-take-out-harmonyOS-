import { promptAction } from '@kit.ArkUI';
import { getLocalImage } from '../../common/utils/ResourceMap';
import { CategoryWithDishes } from '../../model/entity/MockData';
import { DishVO } from '../../model/entity/ShopModel';
import { CartService } from '../../service/CartService';
import { ShopService } from '../../service/ShopService';
import { CartBar } from './components/CartBar';
import { DishCard } from './components/DishCard';
import { FlavorDialog } from './components/FlavorDialog';
import { ShopHeader } from './components/ShopHeader';

/**
 * 商店主页面
 */
@Component
export struct ShopPage {
  @Consume('pageStack') pageStack: NavPathStack;
  // 1.数据源
  @State categoryList: CategoryWithDishes[] = [];
  // 2.状态变量
  @State currentCategoryIndex: number = 0; // 当前选中的分类索引
  @State isLoading: boolean = true; // 加个 loading 状态
  // 3.控制器
  private rightScroller: Scroller = new Scroller();
  // 4.服务实例
  // ✨ 【最终奥义】将 cartService “提供”给所有后代组件
  @Provide('cartService') cartService: CartService = CartService.getInstance();
  // 5.标志变量
  private isClickScroll: boolean = false;
  @State currentDish: DishVO | null = null;
  // 定义弹窗控制器
  private flavorController: CustomDialogController = new CustomDialogController({
    builder: FlavorDialog({
      dish: this.currentDish!, // 传进去
      onConfirm: (flavors: string) => {
        if ( this.currentDish ) {
          this.cartService.addItem(this.currentDish, flavors);
          promptAction.showToast({ message: `${ this.currentDish.name } 已加入购物车` });
        }
      }
    }),
    alignment: DialogAlignment.Bottom, // 底部弹出
    customStyle: true // 使用自定义样式 (去默认圆角和边距)
  });

  async aboutToAppear() {
    this.loadData();
  }

  async loadData() {
    this.isLoading = true;
    //  调用我们查询方法
    const data = await ShopService.getShopData();

    if ( data.length > 0 ) {
      this.categoryList = data;
    }
    this.isLoading = false;
  }

  build() {
    NavDestination() {
      Column() {
        // 店招牌
        ShopHeader()

        if ( this.isLoading ) {
          // ⏳ 加载中显示一个 Loading
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
              ForEach(this.categoryList, (item: CategoryWithDishes, index: number) => {
                ListItem() {
                  // 分类item布局
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
                  // 点击左侧事件
                  this.selectCategory(index);
                })
              })
            }
            .width('25%') // 左侧占25%
            .height('100%')
            .backgroundColor('#F8F8F8')
            .scrollBar(BarState.Off) // 滚动条关闭

            // 右侧：菜品列表
            List({ scroller: this.rightScroller }) {
              ForEach(this.categoryList, (group: CategoryWithDishes, groupIndex: number) => {
                // 分组组件，一个分类对应一个Group
                ListItemGroup({ header: this.RightGroupHeader(group.category.name) }) {
                  ForEach(group.dishes, (dish: DishVO) => {
                    ListItem() {
                      // 【最终方案】不再需要传递 cartService
                      DishCard({
                        dish: dish,
                        // ✨ 正确的父子通讯方式：父组件把一个函数（能力）传给子组件
                        onOpenFlavorDialog: (dishToOpen: DishVO) => {
                          this.currentDish = dishToOpen;
                          this.flavorController.open();
                        }
                      })
                    }
                  }, (dish: DishVO) => dish.id.toString()) // ✨ 关键修正：为ForEach的每一项提供唯一的key！
                }
              })
            }
            .width('75%')
            .height('100%')
            .backgroundColor(Color.White)
            .scrollBar(BarState.Off)
            .sticky(StickyStyle.Header) // 让分组标题吸顶
            .onScrollIndex((firstIndex: number) => {
              // 滑动右侧逻辑:  反向更新左侧
              if (!this.isClickScroll ) {
                this.currentCategoryIndex = firstIndex;
              }
            })
            // 监听滚动停止，重置标志变量
            .onScrollStop(() => {
              this.isClickScroll = false;
            })
          }
          .layoutWeight(1) // 占满中间空间
          .alignItems(VerticalAlign.Top)
        }

        // 底部购物车
        CartBar({ cartService: this.cartService })
          .height(120)
      }
      .height('100%')
      .backgroundColor(Color.White)
    }
    .hideTitleBar(true)
  }

  // 辅助构建器：右侧分组标题
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

  //  核心逻辑：点击左侧，右侧滚动
  selectCategory(index: number) {
    this.isClickScroll = true; // 标记：这是点击触发的滚动
    this.currentCategoryIndex = index;

    // 让右侧列表滚动到 指定分组的头部
    // ListItemGroup 的索引逻辑：index 对应的就是第几个 Group
    this.rightScroller.scrollToIndex(index, true); // true 表示平滑滚动
  }
}