import { CategoryService } from '../../service/CategoryService';
import { SetmealService, SetmealVO } from '../../service/SetmealService';
import { CategoryVO } from '../../model/CategoryModel';
import { promptAction } from '@kit.ArkUI';

@Component
export struct SetmealManagePage {
  @Consume('pageStack') pageStack: NavPathStack;
  @State categories: CategoryVO[] = [];
  @State currentCategoryId: number = 0;
  @State setmeals: SetmealVO[] = [];
  @State isLoading: boolean = true;

  aboutToAppear() {
    this.loadData();
  }

  async loadData() {
    this.isLoading = true;
    try {
      this.categories = await CategoryService.getList(2); // 2: 套餐分类
      if (this.categories.length > 0) {
        this.currentCategoryId = this.categories[0].id;
        await this.loadSetmeals();
      }
    } catch (e) {
    } finally {
      this.isLoading = false;
    }
  }

  async loadSetmeals() {
    try {
      this.setmeals = await SetmealService.getList(this.currentCategoryId);
    } catch (e) {
    }
  }

  async toggleStatus(setmeal: SetmealVO) {
    const targetStatus = setmeal.status === 1 ? 0 : 1;
    try {
      await SetmealService.setStatus(setmeal.id, targetStatus);
      await this.loadSetmeals();
      promptAction.showToast({ message: targetStatus === 1 ? '套餐已上架喵！' : '套餐已下架喵。' });
    } catch (e) {
    }
  }

  async handleDelete(id: number) {
    AlertDialog.show({
      title: '删除套餐',
      message: '确定要删除这个套餐吗喵？',
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: {
        value: '删除',
        fontColor: Color.Red,
        action: async () => {
          try {
            await SetmealService.deleteBatch(id.toString());
            promptAction.showToast({ message: '删除成功喵！' });
            await this.loadSetmeals();
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
                    this.loadSetmeals();
                  }
                })
              }, (item: CategoryVO) => item.id.toString())
            }
            .width('100%').height('100%')
          }
          .width(80).backgroundColor('#F5F5F5').height('100%')

          // 右侧套餐列表
          Column() {
            if (this.setmeals.length === 0) {
               Column() { Text('暂无套餐喵').fontColor('#999999').margin({top: 50}) }.width('100%').height('100%')
            } else {
              List() {
                ForEach(this.setmeals, (item: SetmealVO) => {
                  ListItem() {
                    Row() {
                      Image(item.image).width(60).height(60).borderRadius(4).backgroundColor('#eeeeee').margin({ right: 10 })
                      Column() {
                        Text(item.name).fontSize(16).fontWeight(FontWeight.Medium).fontColor('#333333')
                        Text(`￥${item.price}`).fontSize(14).fontColor(Color.Red).margin({ top: 4 })
                      }.layoutWeight(1).alignItems(HorizontalAlign.Start)

                      Toggle({ type: ToggleType.Switch, isOn: item.status === 1 })
                        .selectedColor($r('app.color.theme_color'))
                        .onChange(() => this.toggleStatus(item))
                    }
                    .width('100%').padding(10).backgroundColor(Color.White).margin({ bottom: 1 })
                    .onClick(() => this.pageStack.pushPath({ name: 'SetmealEditPage', param: item }))
                  }
                  .swipeAction({ end: this.SwipeDeleteButton(item.id) })
                }, (item: SetmealVO) => item.id.toString())
              }.width('100%').height('100%')
            }
          }
          .layoutWeight(1).backgroundColor(Color.White).height('100%')
        }
        .width('100%').height('100%')

        // 悬浮新增按钮
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.startIcon')).width(30).height(30).fillColor(Color.Black)
        }
        .width(60).height(60).backgroundColor($r('app.color.theme_color'))
        .position({ x: '80%', y: '85%' })
        .shadow({ radius: 10, color: '#40000000', offsetY: 5 })
        .onClick(() => this.pageStack.pushPath({ name: 'SetmealEditPage' }))
      }
    }
    .title('套餐管理')
    .onShown(() => { if (this.currentCategoryId) this.loadSetmeals(); })
  }

  @Builder
  SwipeDeleteButton(id: number) {
    Button('删除').backgroundColor(Color.Red).fontColor(Color.White).width(80).height('100%').type(ButtonType.Normal).onClick(() => this.handleDelete(id))
  }
}