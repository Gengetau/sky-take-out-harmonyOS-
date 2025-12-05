/**
 * 口味选择弹窗
 */
import { DishVO, DishFlavor, parseFlavorOptions } from '../../../model/entity/ShopModel';

@CustomDialog
export struct FlavorDialog {
  controller: CustomDialogController;
  // 修复：在严格模式下，使用可选链 '?' 并配合后续的空值判断
  dish?: DishVO;
  onConfirm?: (flavors: string) => void;

  // 记录用户选中的口味索引：key是flavorName, value是选中项的index
  // 例如：{ "辣度": 0, "加料": 1 } -> 代表选了第1个辣度，第2个加料
  @State selectedMap: Record<string, number> = {};

  aboutToAppear() {
    // 初始化选中状态，默认选第一个
    if (this.dish && this.dish.flavors) {
      this.dish.flavors.forEach(f => {
        this.selectedMap[f.name] = 0;
      });
    }
  }

  build() {
    Column() {
      // 1. 菜品信息 (加上空值判断)
      Text(this.dish?.name ?? '菜品详情').fontSize(20).fontWeight(FontWeight.Bold).margin({ top: 20, bottom: 10 })

      // 2. 规格列表 (双层循环)
      List() {
        // ForEach 的入参如果是 null 或 undefined 会报错，所以提供一个空数组作为兜底
        ForEach(this.dish?.flavors ?? [], (flavor: DishFlavor) => {
          ListItem() {
            Column({ space: 10 }) {
              Text(flavor.name).fontSize(14).fontColor('#666')

              // 规格选项 (Flex 换行布局)
              Flex({ wrap: FlexWrap.Wrap }) {
                // 最终改造：调用独立的工具函数
                ForEach(parseFlavorOptions(flavor.value), (val: string, index: number) => {
                  Text(val)
                    .fontSize(12)
                    .padding({ left: 15, right: 15, top: 6, bottom: 6 })
                    .margin({ right: 10, bottom: 10 })
                    .borderRadius(5)
                    // 选中态样式切换
                    .fontColor(this.selectedMap[flavor.name] === index ? '#333333' : '#666666')
                    .backgroundColor(this.selectedMap[flavor.name] === index ? '#FFCC00' : '#F5F5F5')
                    .border({ width: 1, color: this.selectedMap[flavor.name] === index ? '#FFCC00' : '#F5F5F5' })
                    .onClick(() => {
                      // 更新选中
                      this.selectedMap[flavor.name] = index;
                    })
                })
              }
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
            .padding({ bottom: 15 })
          }
        })
      }
      .layoutWeight(1) // 让中间区域可滚动
      .width('100%')
      .height(300)
      .padding({ left: 20, right: 20 })

      // 3. 底部按钮栏
      Row() {
        Row() {
          Text('¥').fontSize(14).fontColor('#E94E20').baselineOffset(-2)
          Text(this.dish?.price?.toFixed(2) ?? '0.00').fontSize(24).fontWeight(FontWeight.Bold).fontColor('#E94E20')
        }

        Button('加入购物车')
          .type(ButtonType.Capsule)
          .backgroundColor('#FFCC00')
          .fontColor('#333333')
          .width(120)
          .onClick(() => {
            // 拼装选中的口味字符串
            const result: string[] = [];
            if (this.dish && this.dish.flavors) {
              this.dish.flavors.forEach(f => {
                // 最终改造：同样使用独立的工具函数
                const list = parseFlavorOptions(f.value);
                const index = this.selectedMap[f.name] || 0;
                // 安全性检查：防止数组越界
                if (list && list.length > index) {
                  result.push(list[index]);
                }
              });
            }

            // 触发回调 (使用可选链调用)
            this.onConfirm?.(result.join(', '));
            this.controller.close();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding(20)
      .backgroundColor('#FFFFFF')
    }
    .height('60%') // 半屏弹窗
    .backgroundColor(Color.White)
    .borderRadius({ topLeft: 16, topRight: 16 })
  }
}