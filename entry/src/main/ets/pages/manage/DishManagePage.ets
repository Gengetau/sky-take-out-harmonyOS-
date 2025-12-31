import { CategoryService } from '../../service/CategoryService';
import { DishService } from '../../service/DishService';
import { CategoryVO } from '../../model/CategoryModel';
import { DishVO } from '../../model/DishModel';
import { promptAction } from '@kit.ArkUI';

@Component
export struct DishManagePage {
  @Consume('pageStack') pageStack: NavPathStack;
  @State categories: CategoryVO[] = [];
  @State currentCategoryId: number = 0;
  @State dishes: DishVO[] = [];
  @State isLoading: boolean = true;

  aboutToAppear() {
    this.loadData();
  }

  // 监听路由栈变化，如果从编辑页返回，刷新数据喵
  onPageShow() {
    if (this.currentCategoryId) {
      this.loadDishes();
    }
  }

  async loadData() {
    this.isLoading = true;
    try {
      this.categories = await CategoryService.getList(1);
      if (this.categories.length > 0) {
        this.currentCategoryId = this.categories[0].id;
        await this.loadDishes();
      }
    } catch (e) {
    } finally {
      this.isLoading = false;
    }
  }

  async loadDishes() {
    try {
      this.dishes = await DishService.getList(this.currentCategoryId);
    } catch (e) {
    }
  }

  async toggleStatus(dish: DishVO) {
    const targetStatus = dish.status === 1 ? 0 : 1;
    try {
      await DishService.setStatus(dish.id, targetStatus);
      dish.status = targetStatus;
      await this.loadDishes();
      promptAction.showToast({ message: targetStatus === 1 ? '已起售喵！' : '已停售喵。' });
    } catch (e) {
    }
  }

  async handleDelete(id: number) {
    AlertDialog.show({
      title: '删除菜品',
      message: '确认要删除这个菜品吗？删除后不可恢复喵。',
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: {
        value: '删除',
        fontColor: Color.Red,
        action: async () => {
          try {
            await DishService.deleteBatch(id.toString());
            promptAction.showToast({ message: '删除成功喵！' });
            await this.loadDishes();
          } catch (e) {}
        }
      }
    })
  }

  build() {
    NavDestination() {
      Stack() {
        Row() {
          // 左侧分类栏
          Column() {
            List() {
              ForEach(this.categories, (item: CategoryVO) => {
                ListItem() {
                  Text(item.name)
                    .fontSize(14)
                    .fontColor(this.currentCategoryId === item.id ? $r('app.color.theme_color') : '#666666')
                    .fontWeight(this.currentCategoryId === item.id ? FontWeight.Bold : FontWeight.Normal)
                    .width('100%')
                    .textAlign(TextAlign.Center)
                    .padding({ top: 15, bottom: 15 })
                    .backgroundColor(this.currentCategoryId === item.id ? Color.White : '#F5F5F5')
                }
                .onClick(() => {
                  if (this.currentCategoryId !== item.id) {
                    this.currentCategoryId = item.id;
                    this.loadDishes();
                  }
                })
              }, (item: CategoryVO) => item.id.toString())
            }
            .width('100%')
            .height('100%')
          }
          .width(80)
          .backgroundColor('#F5F5F5')
          .height('100%')

          // 右侧菜品列表
          Column() {
            if (this.dishes.length === 0) {
               Column() {
                 Text('暂无菜品喵').fontColor('#999999').margin({top: 50})
               }.width('100%').height('100%')
            } else {
              List() {
                ForEach(this.dishes, (item: DishVO) => {
                  ListItem() {
                    Row() {
                      Image(item.image)
                        .width(60)
                        .height(60)
                        .borderRadius(4)
                        .backgroundColor('#eeeeee')
                        .margin({ right: 10 })
                      
                      Column() {
                        Text(item.name)
                          .fontSize(16)
                          .fontWeight(FontWeight.Medium)
                          .fontColor('#333333')
                        Text(`￥${item.price}`)
                          .fontSize(14)
                          .fontColor(Color.Red)
                          .margin({ top: 4 })
                      }
                      .layoutWeight(1)
                      .alignItems(HorizontalAlign.Start)

                      Toggle({ type: ToggleType.Switch, isOn: item.status === 1 })
                        .selectedColor($r('app.color.theme_color'))
                        .onChange(() => {
                          this.toggleStatus(item);
                        })
                    }
                    .width('100%')
                    .padding(10)
                    .backgroundColor(Color.White)
                    .margin({ bottom: 1 })
                    .onClick(() => {
                      this.pageStack.pushPath({ name: 'DishEditPage', param: item });
                    })
                  }
                  .swipeAction({ end: this.SwipeDeleteButton(item.id) })
                }, (item: DishVO) => item.id.toString())
              }
              .width('100%')
              .height('100%')
            }
          }
          .layoutWeight(1)
          .backgroundColor(Color.White)
          .height('100%')
        }
        .width('100%')
        .height('100%')

        // 悬浮新增按钮
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.startIcon')) // 加号图标
            .width(30).height(30).fillColor(Color.Black)
        }
        .width(60).height(60)
        .backgroundColor($r('app.color.theme_color'))
        .position({ x: '80%', y: '85%' })
        .shadow({ radius: 10, color: '#40000000', offsetY: 5 })
        .onClick(() => {
          this.pageStack.pushPath({ name: 'DishEditPage' });
        })
      }
    }
    .title('菜品管理')
    .onShown(() => {
      // 每次页面重新显示时加载，保证数据最新
      if (this.currentCategoryId) {
        this.loadDishes();
      }
    })
  }

  @Builder
  SwipeDeleteButton(id: number) {
    Button('删除')
      .backgroundColor(Color.Red)
      .fontColor(Color.White)
      .width(80)
      .height('100%')
      .type(ButtonType.Normal)
      .onClick(() => this.handleDelete(id))
  }
}