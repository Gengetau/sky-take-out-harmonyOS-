import { SetmealService, SetmealDTO, SetmealDishDTO, SetmealVO } from '../../service/SetmealService';
import { CategoryService } from '../../service/CategoryService';
import { DishService } from '../../service/DishService';
import { CategoryVO } from '../../model/CategoryModel';
import { DishVO } from '../../model/DishModel';
import { FileUtil } from '../../common/FileUtil';
import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';

// ✨ 分类选择弹窗 (复用)
@CustomDialog
struct CategorySelectDialog {
  controller: CustomDialogController;
  categories: CategoryVO[] = [];
  onSelect: (category: CategoryVO) => void = () => {};

  build() {
    Column() {
      Row() {
        Text('选择所属分类').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#333333')
        Blank()
        Image($r('app.media.startIcon')).width(20).height(20).opacity(0.5).onClick(() => this.controller.close())
      }.width('100%').margin({ bottom: 20 })

      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
        ForEach(this.categories, (item: CategoryVO) => {
          Text(item.name).fontSize(14).fontColor('#333333').padding({ left: 15, right: 15, top: 10, bottom: 10 })
            .backgroundColor('#F7F7F7').borderRadius(20).margin({ right: 10, bottom: 12 })
            .onClick(() => { this.onSelect(item); this.controller.close(); })
        }, (item: CategoryVO) => item.id.toString())
      }.width('100%')
    }.padding(20).backgroundColor(Color.White).borderRadius(16).width('90%')
  }
}

// ✨ 妮娅特色的菜品选择弹窗喵！🍱
@CustomDialog
struct DishSelectDialog {
  controller: CustomDialogController;
  @State categories: CategoryVO[] = [];
  @State currentCatId: number = 0;
  @State dishList: DishVO[] = [];
  @State selectedMap: Map<number, SetmealDishDTO> = new Map(); // 用 Map 记录选中的状态喵
  onConfirm: (dishes: SetmealDishDTO[]) => void = () => {};

  aboutToAppear() {
    this.loadData();
  }

  async loadData() {
    try {
      this.categories = await CategoryService.getList(1);
      if (this.categories.length > 0) {
        this.currentCatId = this.categories[0].id;
        await this.loadDishes();
      }
    } catch (e) {}
  }

  async loadDishes() {
    this.dishList = await DishService.getList(this.currentCatId);
  }

  updateCount(dish: DishVO, delta: number) {
    let item = this.selectedMap.get(dish.id);
    if (!item) {
      if (delta < 0) return;
      item = new SetmealDishDTO(dish.id, 0);
      item.name = dish.name;
      item.price = dish.price;
    }
    item.copies += delta;
    if (item.copies <= 0) {
      this.selectedMap.delete(dish.id);
    } else {
      this.selectedMap.set(dish.id, item);
    }
    // 强制触发 UI 刷新 (Map 内部变化不响应)喵
    const newMap = new Map<number, SetmealDishDTO>();
    this.selectedMap.forEach((v, k) => newMap.set(k, v));
    this.selectedMap = newMap;
  }

  build() {
    Column() {
      Text('选择套餐包含的菜品').fontSize(18).fontWeight(FontWeight.Bold).margin({ bottom: 15 })
      
      Row() {
        // 左侧分类
        List() {
          ForEach(this.categories, (cat: CategoryVO) => {
            ListItem() {
              Text(cat.name).fontSize(12).fontColor(this.currentCatId === cat.id ? '#333333' : '#999999')
                .fontWeight(this.currentCatId === cat.id ? FontWeight.Bold : FontWeight.Normal)
                .padding(10).width('100%').textAlign(TextAlign.Center)
                .backgroundColor(this.currentCatId === cat.id ? Color.White : '#F5F5F5')
            }
            .onClick(() => {
              this.currentCatId = cat.id;
              this.loadDishes();
            })
          }, (cat: CategoryVO) => cat.id.toString())
        }.width(80).height(300).backgroundColor('#F5F5F5')

        // 右侧菜品
        List() {
          ForEach(this.dishList, (dish: DishVO) => {
            ListItem() {
              Row() {
                Column() {
                  Text(dish.name).fontSize(14).fontColor('#333333')
                  Text(`￥${dish.price}`).fontSize(12).fontColor(Color.Red).margin({ top: 4 })
                }.alignItems(HorizontalAlign.Start).layoutWeight(1)

                Row({ space: 8 }) {
                  if (this.selectedMap.has(dish.id)) {
                    Text('—').fontSize(18).fontColor($r('app.color.theme_color')).onClick(() => this.updateCount(dish, -1))
                    Text(`${this.selectedMap.get(dish.id)?.copies}`).fontSize(14).fontWeight(FontWeight.Bold)
                  }
                  Text('＋').fontSize(18).fontColor($r('app.color.theme_color')).onClick(() => this.updateCount(dish, 1))
                }
              }.width('100%').padding(10)
            }
          }, (dish: DishVO) => dish.id.toString())
        }.layoutWeight(1).height(300)
      }.width('100%').height(300).border({ width: 1, color: '#F0F0F0' })

      Row({ space: 15 }) {
        Button('取消').layoutWeight(1).backgroundColor('#F5F5F5').fontColor('#666666').onClick(() => this.controller.close())
        Button('确定').layoutWeight(1).backgroundColor($r('app.color.theme_color')).fontColor(Color.Black)
          .onClick(() => {
            const result: SetmealDishDTO[] = [];
            this.selectedMap.forEach(v => result.push(v));
            this.onConfirm(result);
            this.controller.close();
          })
      }.width('100%').margin({ top: 20 })
    }.padding(20).backgroundColor(Color.White).borderRadius(16).width('95%')
  }
}

@Component
struct FormItem {
  private label: string = '';
  @BuilderParam content: () => void;
  build() {
    Column() {
      Text(this.label).fontSize(14).fontColor('#666666').margin({ bottom: 8 })
      Column() { if (this.content) this.content(); }.width('100%').padding({ top: 5, bottom: 5 }).border({ width: { bottom: 1 }, color: '#F0F0F0' })
    }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 15 })
  }
}

@Component
export struct SetmealEditPage {
  @Consume('pageStack') pageStack: NavPathStack;
  @State setmeal: SetmealVO | null = null;
  @State categories: CategoryVO[] = [];
  @State name: string = '';
  @State price: string = '';
  @State categoryId: number = 0;
  @State categoryName: string = '请选择分类';
  @State image: string = '';
  @State description: string = '';
  @State selectedDishes: SetmealDishDTO[] = [];
  @State isUploading: boolean = false;
  @State isSaving: boolean = false;

  categoryDialog: CustomDialogController | null = new CustomDialogController({
    builder: CategorySelectDialog({
      categories: this.categories,
      onSelect: (cat: CategoryVO) => { this.categoryId = cat.id; this.categoryName = cat.name; }
    }),
    alignment: DialogAlignment.Center, autoCancel: true, customStyle: true
  });

  // ✨ 菜品选择弹窗控制器
  dishSelectDialog: CustomDialogController | null = new CustomDialogController({
    builder: DishSelectDialog({
      onConfirm: (dishes: SetmealDishDTO[]) => { this.selectedDishes = dishes; }
    }),
    alignment: DialogAlignment.Bottom, autoCancel: true, customStyle: true
  });

  aboutToAppear() {
    const params = this.pageStack.getParamByName('SetmealEditPage') as SetmealVO[];
    if (params && params.length > 0) {
      const lastParam = params[params.length - 1];
      if (lastParam) { this.setmeal = lastParam; this.initForm(this.setmeal); }
    }
    this.loadCategories();
  }

  async initForm(vo: SetmealVO) {
    this.name = vo.name; this.price = vo.price.toString(); this.categoryId = vo.categoryId;
    this.categoryName = vo.categoryName || ''; this.image = vo.image; this.description = vo.description;
    try {
      const detail = await SetmealService.getById(vo.id);
      if (detail && detail.setmealDishes) { this.selectedDishes = JSON.parse(JSON.stringify(detail.setmealDishes)); }
    } catch (e) {}
  }

  async loadCategories() {
    try { this.categories = await CategoryService.getList(2); } catch (e) {}
  }

  async handleUpload() {
    const context = getContext(this) as common.UIAbilityContext;
    try {
      const localPath = await FileUtil.pickAndCacheImage(context);
      this.isUploading = true;
      const remoteUrl = await DishService.uploadImage(localPath);
      this.image = remoteUrl;
      promptAction.showToast({ message: '上传成功喵！' });
    } catch (e) {
      const error = e as Error;
      if (error.message !== '未选择图片喵') promptAction.showToast({ message: '上传失败: ' + error.message });
    } finally { this.isUploading = false; }
  }

  async handleSave() {
    if (!this.name || !this.price || !this.categoryId || !this.image) {
      promptAction.showToast({ message: '请填写基本信息喵！' }); return;
    }
    this.isSaving = true;
    try {
      const dto = new SetmealDTO(this.categoryId, this.name, parseFloat(this.price), this.image, this.description, this.selectedDishes, this.setmeal ? this.setmeal.id : undefined);
      if (this.setmeal) { await SetmealService.update(dto); promptAction.showToast({ message: '修改成功喵！' }); }
      else { await SetmealService.add(dto); promptAction.showToast({ message: '新增成功喵！' }); }
      this.pageStack.pop();
    } catch (e) {} finally { this.isSaving = false; }
  }

  @Builder NameInput() { TextInput({ placeholder: '请输入套餐名称', text: this.name }).onChange(val => this.name = val).backgroundColor(Color.Transparent).width('100%') }
  @Builder PriceInput() { TextInput({ placeholder: '请输入售价', text: this.price }).type(InputType.Number).onChange(val => this.price = val).backgroundColor(Color.Transparent).width('100%') }
  @Builder DescriptionInput() { TextArea({ placeholder: '请输入描述', text: this.description }).onChange(val => this.description = val).backgroundColor(Color.Transparent).height(80).width('100%') }
  @Builder CategoryRow() {
    Row() {
      Text(this.categoryName).fontColor(this.categoryId ? '#333333' : '#999999').layoutWeight(1)
      Image($r('app.media.startIcon')).width(16).height(16).opacity(0.3)
    }.width('100%').onClick(() => this.categoryDialog?.open())
  }

  build() {
    NavDestination() {
      Column() {
        Scroll() {
          Column() {
            Column() {
              if (this.image) { Image(this.image).width('100%').height(180).objectFit(ImageFit.Cover).borderRadius(8).onClick(() => this.handleUpload()) }
              else {
                Column({ space: 10 }) {
                  Image($r('app.media.startIcon')).width(40).height(40).opacity(0.3)
                  Text(this.isUploading ? '上传中...' : '上传套餐封面').fontColor('#999999')
                }
                .width('100%').height(180).backgroundColor('#F5F5F5').borderRadius(8).justifyContent(FlexAlign.Center).onClick(() => !this.isUploading && this.handleUpload())
              }
            }.width('100%').margin({ bottom: 20 })

            FormItem({ label: '套餐名称', content: () => { this.NameInput() } })
            FormItem({ label: '套餐分类', content: () => { this.CategoryRow() } })
            FormItem({ label: '套餐售价', content: () => { this.PriceInput() } })

            // 套餐菜品管理
            Column() {
              Row() {
                Text('包含菜品').fontSize(14).fontColor('#666666')
                Blank()
                Text('+ 选择菜品').fontSize(14).fontColor($r('app.color.theme_color'))
                  .onClick(() => this.dishSelectDialog?.open())
              }.width('100%').margin({ bottom: 10 })
              
              if (this.selectedDishes.length === 0) {
                Text('还未添加菜品喵').fontSize(12).fontColor('#CCCCCC').margin({ top: 10, bottom: 15 })
              } else {
                ForEach(this.selectedDishes, (item: SetmealDishDTO, index: number) => {
                  Row() {
                    Text(item.name || `菜品ID:${item.dishId}`).fontSize(14).fontColor('#333333')
                    Blank()
                    Text(`x${item.copies}`).fontSize(14).fontColor('#666666')
                  }.width('100%').margin({ bottom: 8 })
                }, (item: SetmealDishDTO, index: number) => index.toString() + (item.dishId?.toString() || ''))
              }
            }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 15 })

            FormItem({ label: '套餐描述', content: () => { this.DescriptionInput() } })
          }
          .padding(15)
        }.layoutWeight(1)
        Button(this.isSaving ? '保存中...' : '保 存').width('90%').height(45).backgroundColor($r('app.color.theme_color')).fontColor(Color.Black).margin({ bottom: 20 }).enabled(!this.isSaving).onClick(() => this.handleSave())
      }.width('100%').height('100%').backgroundColor(Color.White)
    }.title(this.setmeal ? '修改套餐' : '新增套餐')
  }
}
