import { promptAction } from '@kit.ArkUI';
import { DishVO, SetMealVO } from '../../../model/entity/ShopModel';
import { CartService } from '../../../service/CartService';

/**
 * 菜品卡片组件
 */
@Component
export struct DishCard {
  dish: DishVO | undefined;
  @Prop isShopOpen: boolean; // 新增：接收店铺营业状态
  @Prop isSetmeal: boolean = false; // ✨ 新增：是否为套餐
  public onOpenFlavorDialog: (dish: DishVO) => void = () => {
  };
  // 📡 监听广播：只要 AppStorage 里的 'CartUpdateSignal' 变了，就执行 onUpdate
  @StorageProp('CartUpdateSignal') @Watch('updateQuantity') cartSignal: number = 0;
  // 🔢 本地状态：当前菜品的数量
  @State quantity: number = 0;
  // 获取 Service 实例 (仅用于调用方法，不用于监听)
  private cartService = CartService.getInstance();

  aboutToAppear(): void {
    // 初始化时先算一次
    this.updateQuantity();
  }

  // ⚡ 当信号变化时，重新计算数量
  updateQuantity() {
    if (!this.dish ) {
      return;
    }

    // 判断逻辑：如果有规格，我们显示总数；没规格，显示单品数量
    // (通常列表页显示的是该菜品所有规格的总数，或者只操作默认规格)
    // 这里我们统一逻辑：DishCard 显示该 DishID 下的所有数量
    this.quantity = this.cartService.getTotalQuantityForDish(this.dish.id);

    // 如果需要精确匹配无规格的：
    // this.quantity = this.cartService.getDishQuantity(this.dish.id, '');
  }

  build() {
    // ✨ 安全守卫：在 dish 数据确认存在之前，什么都不渲染，防止崩溃！
    if (!this.dish ) {
      Column()
    } else {
      // ✨ build() 方法现在非常纯粹，只负责UI描述！
      Row({ space: 10 }) {
        Image(this.dish.image)
          .width(80)
          .height(80)
          .borderRadius(5)
          .objectFit(ImageFit.Cover)
          .backgroundColor('#EEEEEE')

        Column({ space: 5 }) {
          Text(this.dish.name).fontSize(16).fontWeight(FontWeight.Bold)
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.dish.description).fontSize(10).fontColor('#999999')
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })

          Blank().layoutWeight(1)

          Row() {
            Text('¥').fontSize(12).fontColor('#E94E20').baselineOffset(-2)
            Text(this.dish.price.toFixed(2)).fontSize(18).fontColor('#E94E20').fontWeight(FontWeight.Bold)

            Blank()

            if ( this.dish.flavors && this.dish.flavors.length > 0 ) {
              Stack({ alignContent: Alignment.TopEnd }) {
                Button('选规格')
                  .type(ButtonType.Capsule)
                  .backgroundColor('#FFCC00')
                  .fontColor('#333333')
                  .height(28)
                  .padding({ left: 12, right: 12 })
                  .fontSize(12)
                  .enabled(this.isShopOpen) // Disable if shop is closed
                  .onClick(() => {
                    this.onOpenFlavorDialog(this.dish!);
                  })

                // 🔴 数量徽章 (监听 this.quantity)
                if ( this.quantity > 0 ) {
                  Text(this.quantity.toString())
                    .fontSize(10)
                    .fontColor(Color.White)
                    .backgroundColor('#FF3B30')
                    .borderRadius(8)
                    .padding({ left: 4, right: 4 })
                    .height(16)
                    .textAlign(TextAlign.Center)
                    .offset({ x: 8, y: -8 })
                }
              }
            } else {
              // ✨ 逻辑修正：无规格的菜品，应该用 quantity
              if ( this.quantity > 0 ) {
                Row({ space: 8 }) {
                  // ➖ 减号
                  Button() {
                    Image($r('app.media.ic_decrease'))
                      .width(24)
                      .height(24)
                      .fillColor('#AAAAAA') // 假设您有减号图，或者用 Text('-')
                  }
                  .width(28)
                  .height(28)
                  .type(ButtonType.Circle)
                  .backgroundColor('transparent')
                  .border({ width: 1, color: '#DDDDDD' }) // 减号通常是空心或灰底
                  .enabled(this.isShopOpen) // Disable if shop is closed
                  .onClick(() => {
                    this.cartService.decreaseItemByDish(this.dish!.id, '');
                  })

                  // 🔢 数量
                  Text(this.quantity.toString()).fontSize(16).fontWeight(FontWeight.Medium)

                  // ➕ 加号
                  Button() {
                    Image($r('app.media.ic_increase')).width(24).height(24) // 假设您有加号图，或者用 Text('+')
                  }
                  .width(28)
                  .height(28)
                  .type(ButtonType.Circle)
                  .backgroundColor('#FFCC00')
                  .enabled(this.isShopOpen) // Disable if shop is closed
                  .onClick(() => {
                    this.addToCart();
                  })
                }
                .alignItems(VerticalAlign.Center)
              } else {
                Button() {
                  Image($r('app.media.ic_increase')).width(24).height(24)
                }
                .width(28)
                .height(28)
                .type(ButtonType.Circle)
                .backgroundColor('#FFCC00')
                .enabled(this.isShopOpen) // Disable if shop is closed
                .onClick(() => {
                  this.addToCart();
                  promptAction.showToast({ message: '加购成功' }); // 可选：要不要提示看体验
                })
              }
            }
          }
          .width('100%')
        }
        .layoutWeight(1)
        .height(80)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding(10)
    }
  }
  addToCart() {
    if (!this.dish) return;
    if (this.isSetmeal) {
      // 构造 SetMealVO (虽然有点笨拙，但类型安全)
      const setmeal = new SetMealVO(
        this.dish.id, 
        this.dish.categoryId, 
        this.dish.name, 
        this.dish.price, 
        this.dish.status, 
        this.dish.description, 
        this.dish.image
      );
      this.cartService.addSetmeal(setmeal);
    } else {
      this.cartService.addItem(this.dish, '');
    }
  }
}