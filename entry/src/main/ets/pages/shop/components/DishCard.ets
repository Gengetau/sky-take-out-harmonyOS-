import { promptAction } from '@kit.ArkUI';
import { getLocalImage } from '../../../common/utils/ResourceMap';
import { DishVO } from '../../../model/entity/ShopModel';
import { CartService } from '../../../service/CartService';

/**
 * 菜品卡片组件
 */
@Component
export struct DishCard {
  dish: DishVO | undefined;
  // ✨ 【最终奥义】从传送带上“消费” cartService 状态
  @Consume('cartService') cartService: CartService;
  public onOpenFlavorDialog: (dish: DishVO) => void = () => {
  };

  aboutToAppear(): void {
    // console.info(`喵！[Trace] DishCard aboutToAppear() for dish: ${this.dish?.id}`);
  }

  // ✨ 普通的 get 方法，其响应性由 @Consume 提供的 cartService 来保证
  get totalQuantity(): number {
    // console.info(`喵！[Trace] DishCard get totalQuantity for dish: ${this.dish?.id}`);
    if (!this.dish ) {
      return 0;
    }
    const count = this.cartService.getTotalQuantityForDish(this.dish.id);
    return count;
  }

  get quantity(): number {
    // console.info(`喵！[Trace] DishCard get quantity for dish: ${this.dish?.id}`);
    if (!this.dish ) {
      return 0;
    }
    const count = this.cartService.getDishQuantity(this.dish.id, '');
    return count;
  }

  build() {
    // ✨ 安全守卫：在 dish 数据确认存在之前，什么都不渲染，防止崩溃！
    if (!this.dish ) {
      Column()
    } else {
      // ✨ build() 方法现在非常纯粹，只负责UI描述！
      Row({ space: 10 }) {
        Image(getLocalImage(this.dish.image))
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
                  .onClick(() => {
                    this.onOpenFlavorDialog(this.dish!);
                  })

                // ✨ 逻辑修正：带规格的菜品，徽章数量应该用 totalQuantity
                if ( this.totalQuantity > 0 ) {
                  Text(this.totalQuantity.toString())
                    .fontSize(10)
                    .fontColor(Color.White)
                    .backgroundColor('#FF3B30')
                    .height(16)
                    .constraintSize({ minWidth: 16 }) // 正确的设置最小宽度的方法
                    .padding({ left: 4, right: 4 })
                    .borderRadius(8)
                    .textAlign(TextAlign.Center)
                    .offset({ x: 8, y: -8 })
                }
              }
            } else {
              // ✨ 逻辑修正：无规格的菜品，应该用 quantity
              if ( this.quantity > 0 ) {
                Row({ space: 8 }) {
                  Button() {
                    Image($r('app.media.ic_decrease'))
                      .width(20).height(20)
                  }
                  .width(28)
                  .height(28)
                  .type(ButtonType.Circle)
                  .backgroundColor('#FFCC00')
                  .onClick(() => {
                    console.info(`喵！[Trace] DECREASE button clicked for dish: ${ this.dish!.id }`);
                    this.cartService.decreaseItemByDish(this.dish!.id, '');
                  })

                  // ✨ 逻辑修正：显示 quantity
                  Text(this.quantity.toString())
                    .fontSize(16).fontWeight(FontWeight.Medium)

                  Button() {
                    Image($r('app.media.ic_increase'))
                      .width(20).height(20)
                  }
                  .width(28)
                  .height(28)
                  .type(ButtonType.Circle)
                  .backgroundColor('#FFCC00')
                  .onClick(() => {
                    console.info(`喵！[Trace] INCREASE button clicked for dish: ${ this.dish!.id }`);
                    this.cartService.addItem(this.dish!, '');
                  })
                }
                .alignItems(VerticalAlign.Center)
              } else {
                Button() {
                  Image($r('app.media.ic_increase'))
                    .width(20).height(20)
                }
                .width(28)
                .height(28)
                .type(ButtonType.Circle)
                .backgroundColor('#FFCC00')
                .onClick(() => {
                  console.info(`喵！[Trace] ADD button clicked for dish: ${ this.dish!.id }`);
                  this.cartService.addItem(this.dish!, '');
                  promptAction.showToast({ message: `${ this.dish!.name } 已加入购物车` });
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
}