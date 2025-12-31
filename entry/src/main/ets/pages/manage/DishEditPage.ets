import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { FileUtil } from '../../common/FileUtil';
import { CategoryVO } from '../../model/CategoryModel';
import { DishFlavor, DishVO } from '../../model/DishModel';
import { CategoryService } from '../../service/CategoryService';
import { DishDTO, DishService } from '../../service/DishService';

// ✨ 口味模版定义
interface FlavorTemplate {
  name: string;
  value: string;
}

const FLAVOR_TEMPLATES: FlavorTemplate[] = [
  { name: '辣度', value: '["不辣","微辣","中辣","特辣"]' },
  { name: '甜味', value: '["无糖","少糖","半糖","多糖","全糖"]' },
  { name: '温度', value: '["热","常温","去冰","少冰","多冰"]' },
  { name: '忌口', value: '["不要葱","不要香菜","不要蒜","不要姜"]' },
  { name: '分量', value: '["大份","中份","小份"]' }
];

// ✨ 妮娅特色的分类选择弹窗
@CustomDialog
struct CategorySelectDialog {
  controller: CustomDialogController;
  categories: CategoryVO[] = [];
  onSelect: (category: CategoryVO) => void = () => {
  };

  build() {
    Column() {
      Row() {
        Text('选择所属分类')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
        Blank()
        Image($r('app.media.startIcon'))
          .width(20).height(20).opacity(0.5)
          .onClick(() => this.controller.close())
      }
      .width('100%').margin({ bottom: 20 })

      if ( this.categories.length === 0 ) {
        Text('暂无分类数据喵~').fontColor('#CCCCCC').margin(20)
      } else {
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
          ForEach(this.categories, (item: CategoryVO) => {
            Text(item.name)
              .fontSize(14)
              .fontColor('#333333')
              .padding({
                left: 15,
                right: 15,
                top: 10,
                bottom: 10
              })
              .backgroundColor('#F7F7F7')
              .borderRadius(20)
              .margin({ right: 10, bottom: 12 })
              .onClick(() => {
                this.onSelect(item);
                this.controller.close();
              })
          }, (item: CategoryVO) => item.id.toString())
        }
        .width('100%')
      }
    }
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .width('90%')
  }
}

// ✨ 妮娅特色的口味选择弹窗
@CustomDialog
struct FlavorSelectDialog {
  controller: CustomDialogController;
  onSelect: (template: FlavorTemplate) => void = () => {
  };

  build() {
    Column() {
      Row() {
        Text('选择口味模版')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
        Blank()
        Image($r('app.media.startIcon'))
          .width(20).height(20).opacity(0.5)
          .onClick(() => this.controller.close())
      }
      .width('100%').margin({ bottom: 20 })

      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
        ForEach(FLAVOR_TEMPLATES, (item: FlavorTemplate) => {
          Column() {
            Text(item.name).fontSize(16).fontWeight(FontWeight.Medium).fontColor('#333333')
            Text(this.getPreview(item.value))
              .fontSize(10).fontColor('#999999').margin({ top: 4 }).maxLines(1)
          }
          .width('48%')
          .padding(15)
          .margin({ bottom: 12 })
          .backgroundColor('#F7F7F7')
          .borderRadius(10)
          .alignItems(HorizontalAlign.Start)
          .onClick(() => {
            this.onSelect(item);
            this.controller.close();
          })
        })
      }
      .width('100%')
    }
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .width('90%')
  }

  getPreview(jsonStr: string): string {
    try {
      const arr = JSON.parse(jsonStr) as string[];
      return arr.join(' / ');
    } catch ( e ) {
      return '';
    }
  }
}

@Component
struct FormItem {
  private label: string = '';
  @BuilderParam content: () => void;

  build() {
    Column() {
      Text(this.label).fontSize(14).fontColor('#666666').margin({ bottom: 8 })
      Column() {
        if ( this.content ) {
          this.content();
        }
      }
      .width('100%').padding({ top: 5, bottom: 5 }).border({ width: { bottom: 1 }, color: '#F0F0F0' })
    }
    .alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 15 })
  }
}

@Component
export struct DishEditPage {
  @Consume('pageStack') pageStack: NavPathStack;
  @State dish: DishVO | null = null;
  @State categories: CategoryVO[] = [];
  @State name: string = '';
  @State price: string = '';
  @State categoryId: number = 0;
  @State categoryName: string = '请选择分类';
  @State image: string = '';
  @State description: string = '';
  @State flavors: DishFlavor[] = [];
  @State isUploading: boolean = false;
  @State isSaving: boolean = false;
  // ✨ 分类弹窗控制器
  categoryDialog: CustomDialogController | null = new CustomDialogController({
    builder: CategorySelectDialog({
      categories: this.categories,
      onSelect: (cat) => {
        this.categoryId = cat.id;
        this.categoryName = cat.name;
      }
    }),
    alignment: DialogAlignment.Center,
    autoCancel: true,
    customStyle: true
  });
  // ✨ 口味弹窗控制器
  flavorDialog: CustomDialogController | null = new CustomDialogController({
    builder: FlavorSelectDialog({
      onSelect: (template): void => this.addFlavorFromTemplate(template)
    }),
    alignment: DialogAlignment.Center,
    autoCancel: true,
    customStyle: true
  });

  aboutToAppear() {
    const params = this.pageStack.getParamByName('DishEditPage') as DishVO[];
    console.info(`喵！[DishEditPage] 接收到参数长度: ${ params?.length }`);
    if ( params && params.length > 0 ) {
      const lastParam = params[params.length - 1];
      if ( lastParam ) {
        console.info(`喵！[DishEditPage] 当前编辑菜品ID: ${ lastParam.id }, 名称: ${ lastParam.name }`);
        console.info(`喵！[DishEditPage] 初始参数中的口味数据: ${ JSON.stringify(lastParam.flavors) }`);
        this.dish = lastParam;
        this.initForm(this.dish);
      }
    }
    this.loadCategories();
  }

  async initForm(dish: DishVO) {
    // 先用列表传来的基础数据填充
    this.name = dish.name;
    this.price = dish.price.toString();
    this.categoryId = dish.categoryId;
    this.categoryName = dish.categoryName || '';
    this.image = dish.image;
    this.description = dish.description;

    // 关键点：如果列表里没有口味，或者为了保险起见，我们去请求一次详情喵！
    try {
      console.info('喵！[DishEditPage] 正在请求菜品完整详情以获取口味...');
      const fullDish = await DishService.getById(dish.id);
      console.info(`喵！[DishEditPage] 详情请求成功，获取到口味数量: ${ fullDish.flavors?.length || 0 }`);
      if ( fullDish.flavors ) {
        this.flavors = JSON.parse(JSON.stringify(fullDish.flavors));
      } else {
        this.flavors = [];
      }
    } catch ( e ) {
      console.error('喵！[DishEditPage] 获取详情失败:', e);
      // 降级方案：使用原本可能存在的（虽然大概率是空）
      this.flavors = dish.flavors ? JSON.parse(JSON.stringify(dish.flavors)) : [];
    }
  }

  async loadCategories() {
    try {
      this.categories = await CategoryService.getList(1);
      // 更新弹窗控制器中的数据 (由于 CustomDialog 渲染机制，重新赋值 categories 即可)
    } catch ( e ) {
    }
  }

  async handleUpload() {
    const context = getContext(this) as common.UIAbilityContext;
    try {
      const localPath = await FileUtil.pickAndCacheImage(context);
      this.isUploading = true;
      const remoteUrl = await DishService.uploadImage(localPath);
      this.image = remoteUrl;
      promptAction.showToast({ message: '图片上传成功喵！' });
    } catch ( e ) {
      const error = e as Error;
      if ( error.message !== '未选择图片喵' ) {
        promptAction.showToast({ message: '上传失败: ' + error.message });
      }
    } finally {
      this.isUploading = false;
    }
  }

  addFlavorFromTemplate(template: FlavorTemplate) {
    if ( this.flavors.some(f => f.name === template.name) ) {
      promptAction.showToast({ message: '已经添加过这个口味了喵~' });
      return;
    }
    this.flavors.push(new DishFlavor(template.name, template.value));
  }

  removeFlavor(index: number) {
    this.flavors.splice(index, 1);
  }

  async handleSave() {
    if (!this.name || !this.price || !this.categoryId || !this.image ) {
      promptAction.showToast({ message: '请填写完整信息喵！' });
      return;
    }
    this.isSaving = true;
    try {
      const dto = new DishDTO(this.name, this.categoryId, parseFloat(this.price), this.image, this.description,
        this.dish ? this.dish.status : 1, this.dish ? this.dish.id : undefined);
      dto.flavors = this.flavors;
      if ( this.dish ) {
        await DishService.update(dto);
        promptAction.showToast({ message: '修改成功喵！' });
      } else {
        await DishService.add(dto);
        promptAction.showToast({ message: '新增成功喵！' });
      }
      this.pageStack.pop();
    } catch ( e ) {
    } finally {
      this.isSaving = false;
    }
  }

  @Builder
  NameInput() {
    TextInput({ placeholder: '请输入菜品名称', text: this.name })
      .onChange(val => this.name = val)
      .backgroundColor(Color.Transparent)
      .width('100%')
  }

  @Builder
  CategorySelector() {
    Row() {
      Text(this.categoryName).fontColor(this.categoryId ? '#333333' : '#999999').layoutWeight(1)
      Image($r('app.media.startIcon')).width(16).height(16).opacity(0.3)
    }
    .width('100%')
    .onClick(() => {
      // 打开自定义分类选择弹窗
      if ( this.categoryDialog ) {
        // 更新弹窗中的数据
        this.categoryDialog.open();
      }
    })
  }

  @Builder
  PriceInput() {
    TextInput({ placeholder: '请输入售价', text: this.price })
      .type(InputType.Number)
      .onChange(val => this.price = val)
      .backgroundColor(Color.Transparent)
      .width('100%')
  }

  @Builder
  DescriptionInput() {
    TextArea({ placeholder: '请输入菜品描述', text: this.description })
      .onChange(val => this.description = val)
      .backgroundColor(Color.Transparent)
      .height(100)
      .width('100%')
  }

  @Builder
  FlavorItemView(flavor: DishFlavor, index: number) {
    Row() {
      Column() {
        Text(flavor.name).fontSize(16).fontWeight(FontWeight.Medium).fontColor('#333333')
        Text(this.getFlavorOptionsText(flavor.value))
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 4 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start).layoutWeight(1)

      Button('移除')
        .fontSize(12)
        .fontColor(Color.Red)
        .backgroundColor(Color.Transparent)
        .onClick(() => this.removeFlavor(index))
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#F9F9F9')
    .borderRadius(8)
    .margin({ bottom: 10 })
  }

  getFlavorOptionsText(jsonStr: string): string {
    try {
      const arr = JSON.parse(jsonStr) as string[];
      return arr.join(' / ');
    } catch ( e ) {
      return jsonStr;
    }
  }

  build() {
    NavDestination() {
      Column() {
        Scroll() {
          Column() {
            Column() {
              if ( this.image ) {
                Image(this.image)
                  .width('100%')
                  .height(200)
                  .objectFit(ImageFit.Cover)
                  .borderRadius(8)
                  .onClick(() => this.handleUpload())
              } else {
                Column({ space: 10 }) {
                  Image($r('app.media.startIcon')).width(40).height(40).opacity(0.3)
                  Text(this.isUploading ? '上传中...' : '上传菜品图片').fontColor('#999999')
                }
                .width('100%')
                .height(200)
                .backgroundColor('#F5F5F5')
                .borderRadius(8)
                .justifyContent(FlexAlign.Center)
                .onClick(() => !this.isUploading && this.handleUpload())
              }
            }
            .width('100%').margin({ bottom: 20 })

            FormItem({
              label: '菜品名称', content: () => {
                this.NameInput()
              }
            })
            FormItem({
              label: '所属分类', content: () => {
                this.CategorySelector()
              }
            })
            FormItem({
              label: '售价 (元)', content: () => {
                this.PriceInput()
              }
            })

            Column() {
              Row() {
                Text('菜品口味').fontSize(14).fontColor('#666666')
                Blank()
                Button('+ 添加口味模版')
                  .fontSize(12)
                  .height(28)
                  .backgroundColor(Color.Transparent)
                  .fontColor($r('app.color.theme_color'))
                  .onClick(() => {
                    if ( this.flavorDialog ) {
                      this.flavorDialog.open();
                    }
                  })
              }.width('100%').margin({ bottom: 10 })

              if ( this.flavors.length === 0 ) {
                Text('点击上方按钮快速添加常用口味喵').fontSize(12).fontColor('#CCCCCC').margin({ bottom: 15 })
              } else {
                ForEach(this.flavors, (item: DishFlavor, index: number) => {
                  this.FlavorItemView(item, index)
                }, (item: DishFlavor, index: number) => index + item.name)
              }
            }
            .alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 15 })

            FormItem({
              label: '菜品描述', content: () => {
                this.DescriptionInput()
              }
            })
          }
          .padding(15)
        }
        .layoutWeight(1)

        Button(this.isSaving ? '保存中...' : '保 存')
          .width('90%')
          .height(45)
          .backgroundColor($r('app.color.theme_color'))
          .fontColor(Color.Black)
          .margin({ bottom: 20 })
          .enabled(!this.isSaving)
          .onClick(() => this.handleSave())
      }
      .width('100%').height('100%').backgroundColor(Color.White)
    }
    .title(this.dish ? '修改菜品' : '新增菜品')
  }
}