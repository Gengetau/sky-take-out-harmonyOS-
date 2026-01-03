import { promptAction } from '@kit.ArkUI';
import { ShopService } from '../service/ShopService';
import { ShopInfoVO } from '../model/ShopModel';

export class EditFieldParam {
  title: string;
  field: string;
  oldValue: string;
  isNumber: boolean;

  constructor(title: string, field: string, oldValue: string, isNumber: boolean) {
    this.title = title;
    this.field = field;
    this.oldValue = oldValue;
    this.isNumber = isNumber;
  }
}

/**
 * 通用字段编辑页 (严谨类型版喵！)
 */
@Component
export struct EditFieldPage {
  @Consume('pageStack') pageStack: NavPathStack;
  @State title: string = '';
  @State field: string = '';
  @State newValue: string = '';
  @State isNumber: boolean = false;
  @State isLoading: boolean = false;

  initParams(params: EditFieldParam) {
    this.title = params.title;
    this.field = params.field;
    this.newValue = params.oldValue;
    this.isNumber = params.isNumber;
  }

  async handleSave() {
    if (!this.newValue.trim()) {
      promptAction.showToast({ message: '内容不能为空喵！' });
      return;
    }

    this.isLoading = true;
    try {
      // 🐾 显式构造符合 Partial<ShopInfoVO> 接口的对象喵
      const updateData: Partial<ShopInfoVO> = {};
      
      // 根据 field 字段名进行显式赋值喵
      if (this.field === 'name') {
        updateData.name = this.newValue;
      } else if (this.field === 'phone') {
        updateData.phone = this.newValue;
      } else if (this.field === 'address') {
        updateData.address = this.newValue;
      } else if (this.field === 'description') {
        updateData.description = this.newValue;
      } else if (this.field === 'deliveryPrice') {
        updateData.deliveryPrice = parseFloat(this.newValue);
      } else if (this.field === 'shippingFee') {
        updateData.shippingFee = parseFloat(this.newValue);
      }

      await ShopService.updateShopInfo(updateData);
      
      promptAction.showToast({ message: '修改成功喵！' });
      this.pageStack.pop(); 
    } catch (e) {
      // 错误已在 HttpUtil 中 Toast 喵
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    NavDestination() {
      Column() {
        TextInput({ text: this.newValue, placeholder: '请输入' + this.title })
          .type(this.isNumber ? InputType.Number : InputType.Normal)
          .height(50)
          .width('90%')
          .backgroundColor(Color.White)
          .borderRadius(8)
          .margin({ top: 30 })
          .onChange(val => this.newValue = val)

        Button(this.isLoading ? '保存中...' : '保 存')
          .width('90%')
          .height(45)
          .backgroundColor($r('app.color.theme_color'))
          .fontColor(Color.Black)
          .margin({ top: 30 })
          .onClick(() => this.handleSave())
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.page_background'))
    }
    .title('修改' + this.title)
    .onReady((ctx: NavDestinationContext) => {
      const params = ctx.pathInfo.param as EditFieldParam;
      if (params) {
        this.initParams(params);
      }
    })
  }
}
