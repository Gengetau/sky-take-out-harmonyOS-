import { CategoryService, CategoryDTO } from '../../service/CategoryService';
import { CategoryVO } from '../../model/CategoryModel';
import { promptAction } from '@kit.ArkUI';

@Component
export struct CategoryManagePage {
  @Consume('pageStack') pageStack: NavPathStack;
  @State type: number = 1; // 1:菜品分类 2:套餐分类
  @State categories: CategoryVO[] = [];
  @State isDialogShow: boolean = false; // 控制弹窗显隐（模拟 CustomDialogController）
  @State editingCategory: CategoryVO | null = null; // 当前编辑的对象，null表示新增

  // 弹窗输入状态
  @State inputName: string = '';
  @State inputSort: string = '';

  dialogController: CustomDialogController | null = null;

  aboutToAppear() {
    this.loadData();
  }

  async loadData() {
    try {
      this.categories = await CategoryService.getList(this.type);
    } catch (e) {}
  }

  async toggleStatus(category: CategoryVO) {
    const targetStatus = category.status === 1 ? 0 : 1;
    try {
      await CategoryService.setStatus(category.id, targetStatus);
      await this.loadData();
      promptAction.showToast({ message: targetStatus === 1 ? '分类已启用喵！' : '分类已禁用喵。' });
    } catch (e) {}
  }

  // 打开弹窗
  openDialog(category?: CategoryVO) {
    this.editingCategory = category || null;
    this.inputName = category ? category.name : '';
    this.inputSort = category ? category.sort.toString() : '';
    
    // 初始化并打开弹窗
    if (this.dialogController === null) {
      this.dialogController = new CustomDialogController({
        builder: CategoryEditDialog({
          title: this.editingCategory ? '修改分类' : '新增分类',
          name: this.inputName,
          sort: this.inputSort,
          onConfirm: (name, sort): Promise<void> => this.handleSave(name, sort)
        }),
        autoCancel: true
      })
    }
    this.dialogController.open();
  }

  async handleSave(name: string, sort: string) {
    if (!name || !sort) {
      promptAction.showToast({ message: '请填写完整信息喵！' });
      return;
    }
    const sortNum = parseInt(sort);
    if (isNaN(sortNum)) {
      promptAction.showToast({ message: '排序必须是数字喵！' });
      return;
    }

    try {
      if (this.editingCategory) {
        // 修改
        const dto = new CategoryDTO(this.type, name, sortNum, this.editingCategory.id);
        await CategoryService.update(dto);
        promptAction.showToast({ message: '修改成功喵！' });
      } else {
        // 新增
        const dto = new CategoryDTO(this.type, name, sortNum);
        await CategoryService.add(dto);
        promptAction.showToast({ message: '新增成功喵！' });
      }
      this.dialogController = null; // 重置 Controller 以便下次重新创建（更新状态）
      await this.loadData();
    } catch (e) {
    }
  }

  async handleDelete(id: number) {
    AlertDialog.show({
      title: '删除分类',
      message: '确定要删除这个分类吗？如果有关联菜品可能无法删除喵。',
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: {
        value: '删除',
        fontColor: Color.Red,
        action: async () => {
          try {
            await CategoryService.deleteById(id);
            promptAction.showToast({ message: '删除成功喵！' });
            await this.loadData();
          } catch (e) {}
        }
      }
    })
  }

  build() {
    NavDestination() {
      Stack() {
        Column() {
          // 顶部切换栏
          Row() {
            this.TypeTab('菜品分类', 1)
            this.TypeTab('套餐分类', 2)
          }
          .width('100%')
          .height(50)
          .backgroundColor(Color.White)
          .margin({ bottom: 10 })

          // 分类列表
          List() {
            ForEach(this.categories, (item: CategoryVO) => {
              ListItem() {
                Row() {
                  Column() {
                    Text(item.name)
                      .fontSize(16)
                      .fontColor('#333333')
                      .fontWeight(FontWeight.Medium)
                    Text(`排序: ${item.sort}`)
                      .fontSize(12)
                      .fontColor('#999999')
                      .margin({ top: 4 })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)

                  Toggle({ type: ToggleType.Switch, isOn: item.status === 1 })
                    .selectedColor($r('app.color.theme_color'))
                    .onChange(() => {
                      this.toggleStatus(item);
                    })
                }
                .width('100%')
                .padding(15)
                .backgroundColor(Color.White)
                .margin({ bottom: 1 })
                // 长按编辑
                .gesture(
                  LongPressGesture().onAction(() => {
                    this.openDialog(item);
                  })
                )
              }
              .swipeAction({
                end: this.SwipeDeleteButton(item.id)
              })
            }, (item: CategoryVO) => item.id.toString())
          }
          .width('100%')
          .layoutWeight(1)
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#F5F5F5')

        // 悬浮新增按钮
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          Image($r('app.media.startIcon')) // 换成加号图标
            .width(30)
            .height(30)
            .fillColor(Color.Black)
        }
        .width(60)
        .height(60)
        .backgroundColor($r('app.color.theme_color'))
        .position({ x: '80%', y: '85%' })
        .shadow({ radius: 10, color: '#40000000', offsetY: 5 })
        .onClick(() => {
          this.openDialog(); // 新增模式
        })
      }
    }
    .title('分类管理')
  }

  @Builder
  TypeTab(title: string, type: number) {
    Column() {
      Text(title)
        .fontSize(16)
        .fontColor(this.type === type ? $r('app.color.theme_color') : '#666666')
        .fontWeight(this.type === type ? FontWeight.Bold : FontWeight.Normal)
      
      Rect()
        .width(20)
        .height(3)
        .fill($r('app.color.theme_color'))
        .opacity(this.type === type ? 1 : 0)
        .margin({ top: 5 })
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.type = type;
      this.loadData();
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
      .onClick(() => {
        this.handleDelete(id);
      })
  }
}

// 简单的输入弹窗
@CustomDialog
struct CategoryEditDialog {
  controller: CustomDialogController;
  title: string = '';
  @State name: string = '';
  @State sort: string = '';
  onConfirm: (name: string, sort: string) => void = () => {};

  build() {
    Column() {
      Text(this.title).fontSize(20).fontWeight(FontWeight.Bold).margin({ bottom: 20 })
      
      TextInput({ placeholder: '请输入分类名称', text: this.name })
        .onChange((val) => this.name = val)
        .height(50)
        .margin({ bottom: 10 })
      
      TextInput({ placeholder: '请输入排序值', text: this.sort })
        .type(InputType.Number)
        .onChange((val) => this.sort = val)
        .height(50)
        .margin({ bottom: 20 })

      Row() {
        Button('取消').backgroundColor('#F5F5F5').fontColor('#666666').layoutWeight(1).margin({ right: 10 })
          .onClick(() => this.controller.close())
        Button('保存').backgroundColor($r('app.color.theme_color')).fontColor('#333333').layoutWeight(1)
          .onClick(() => {
            this.onConfirm(this.name, this.sort);
            this.controller.close();
          })
      }.width('100%')
    }
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .width('80%')
  }
}