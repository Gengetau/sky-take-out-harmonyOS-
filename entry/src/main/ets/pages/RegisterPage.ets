import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { geoLocationManager } from '@kit.LocationKit';
import { RegisterDTO, ShopTypeVO } from '../model/ShopModel';
import { ShopService } from '../service/ShopService';

@Component
export struct RegisterPage {
  @Consume('pageStack') pageStack: NavPathStack;
  @State name: string = '';
  @State address: string = '';
  @State phone: string = '';
  @State shopTypeId: number = 0;
  @State isLoading: boolean = false;
  @State shopTypes: ShopTypeVO[] = [];
  @State selectedTypeIndex: number = -1;
  @State longitude: number = 121.5;
  @State latitude: number = 31.2;

  async aboutToAppear() {
    this.loadShopTypes();
  }

  async loadShopTypes() {
    try {
      this.shopTypes = await ShopService.getShopTypes();
      if ( this.shopTypes.length > 0 ) {
        this.shopTypeId = this.shopTypes[0].id;
        this.selectedTypeIndex = 0;
      }
    } catch ( e ) {
      console.error('加载店铺类型失败', e);
      this.shopTypes = [ {
        id: 1,
        name: '美食',
        icon: '',
        sort: 1
      } ];
      this.selectedTypeIndex = 0;
      this.shopTypeId = 1;
    }
  }

  async getLocation() {
    const context = getContext(this) as common.UIAbilityContext;
    const atManager = abilityAccessCtrl.createAtManager();
    const permissions: Permissions[] = [ 'ohos.permission.LOCATION', 'ohos.permission.APPROXIMATELY_LOCATION' ];

    try {
      const grantStatus = await atManager.requestPermissionsFromUser(context, permissions);
      const isGranted = grantStatus.authResults.every(result => result === 0);

      if ( isGranted ) {
        promptAction.showToast({ message: '正在定位中...' });

        const request: geoLocationManager.CurrentLocationRequest = {
          'priority': geoLocationManager.LocationRequestPriority.FIRST_FIX,
          'scenario': geoLocationManager.LocationRequestScenario.UNSET,
          'maxAccuracy': 0
        };

        const location = await geoLocationManager.getCurrentLocation(request);
        this.latitude = location.latitude;
        this.longitude = location.longitude;
        promptAction.showToast({ message: `定位成功: ${ this.latitude.toFixed(2) }, ${ this.longitude.toFixed(2) }` });
      } else {
        promptAction.showToast({ message: '请授予定位权限以获取位置喵' });
      }
    } catch ( err ) {
      const error = err as BusinessError;
      console.error(`定位失败: code=${ error.code }, message=${ error.message }`);
      promptAction.showToast({ message: '定位失败，使用默认坐标喵' });
    }
  }

  async handleRegister() {
    if (!this.name || !this.address || !this.phone ) {
      promptAction.showToast({ message: '请填写完整信息喵！' });
      return;
    }

    this.isLoading = true;
    try {
      // 🐾 使用具体的 RegisterDTO 类实例化数据喵
      const data = new RegisterDTO(
        this.name,
        this.address,
        this.phone,
        this.shopTypeId,
        '', // avatar
        this.longitude,
        this.latitude
      );

      await ShopService.register(data);

      AlertDialog.show({
        title: '提交成功',
        message: '您的入驻申请已提交！初始账号为手机号，密码为123456喵。',
        confirm: {
          value: '去登录',
          action: () => {
            this.pageStack.pop();
          }
        }
      });
    } catch ( e ) {
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    NavDestination() {
      Column() {
        Text('商家入驻')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 30, bottom: 30 })
          .alignSelf(ItemAlign.Start)
          .padding({ left: 20 })

        List() {
          ListItem() {
            this.InputItem('店铺名称', '请输入店铺名称', this.name, (val) => this.name = val)
          }

          ListItem() {
            this.InputItem('店铺地址', '请输入详细地址', this.address, (val) => this.address = val)
          }

          ListItem() {
            Column() {
              Text('店铺位置')
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
                .margin({ bottom: 8 })
                .width('100%')

              Row() {
                Text(`经度:${ this.longitude.toFixed(2) } 纬度:${ this.latitude.toFixed(2) }`)
                  .fontSize(14)
                  .fontColor('#333333')
                  .layoutWeight(1)

                Button('获取定位')
                  .height(30)
                  .fontSize(12)
                  .backgroundColor($r('app.color.theme_color'))
                  .fontColor(Color.Black)
                  .onClick(() => {
                    this.getLocation();
                  })
              }
              .width('100%')
              .height(50)
              .padding({ left: 10, right: 10 })
              .backgroundColor(Color.White)
              .borderRadius(8)
            }
            .padding({ left: 20, right: 20, bottom: 20 })
          }

          ListItem() {
            this.InputItem('联系电话', '请输入手机号', this.phone, (val) => this.phone = val, InputType.PhoneNumber)
          }

          ListItem() {
            Column() {
              Text('店铺类型')
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
                .margin({ bottom: 8 })
                .width('100%')

              if ( this.shopTypes.length > 0 ) {
                // 🐾 使用 as SelectOption 解决类型检查问题喵
                Select(this.shopTypes.map((item: ShopTypeVO) => {
                  return { value: item.name } as SelectOption;
                }))
                  .selected(this.selectedTypeIndex)
                  .value(this.shopTypes[this.selectedTypeIndex]?.name || '请选择')
                  .font({ size: 16 })
                  .fontColor($r('app.color.text_main'))
                  .selectedOptionFont({ size: 16 })
                  .optionFont({ size: 16 })
                  .onSelect((index: number) => {
                    this.selectedTypeIndex = index;
                    this.shopTypeId = this.shopTypes[index].id;
                  })
                  .width('100%')
                  .height(50)
                  .backgroundColor(Color.White)
                  .borderRadius(8)
              } else {
                Text('加载类型中...')
                  .fontSize(14)
                  .fontColor('#999999')
              }
            }
            .padding({ left: 20, right: 20, bottom: 20 })
          }
        }
        .width('100%')
        .layoutWeight(1)

        Button(this.isLoading ? '提交中...' : '提交申请')
          .width('90%')
          .height(50)
          .backgroundColor($r('app.color.theme_color'))
          .fontColor(Color.Black)
          .fontSize(18)
          .margin({ bottom: 30 })
          .enabled(!this.isLoading)
          .onClick(() => this.handleRegister())
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.page_background'))
    }
    .title('入驻申请')
  }

  @Builder
  InputItem(label: string, placeholder: string, value: string, onChange: (val: string) => void,
    type: InputType = InputType.Normal) {
    Column() {
      Text(label)
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .margin({ bottom: 8 })
        .width('100%')

      TextInput({ placeholder: placeholder, text: value })
        .type(type)
        .height(50)
        .backgroundColor(Color.White)
        .borderRadius(8)
        .onChange(onChange)
    }
    .padding({ left: 20, right: 20, bottom: 20 })
  }
}
