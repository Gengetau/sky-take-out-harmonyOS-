import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { geoLocationManager } from '@kit.LocationKit';
import { LocationUtil } from '../../common/utils/LocationUtil';
import { AddressBook } from '../../model/entity/AddressBook';
import { OrderService } from '../../service/OrderService';

@Component
export struct AddressEditPage {
  @State isLoading: boolean = false;
  // 回调函数
  onClose: () => void = () => {
  };
  onSaveSuccess: () => void = () => {
  };
  // 地图相关状态
  @State mapLat: number = 39.9042;
  @State mapLng: number = 116.4074;
  @State currentAddressDesc: string = '正在定位...';
  // 表单数据
  @State consignee: string = '';
  @State sex: string = '1';
  @State phone: string = '';
  @State houseNumber: string = ''; // 门牌号
  @State label: string = '家';
  // 隐藏字段
  @State provinceName: string = '';
  @State cityName: string = '';
  @State districtName: string = '';

  async aboutToAppear() {
    this.requestLocation();
  }

  async requestLocation() {
    const context = getContext(this) as common.UIAbilityContext;
    const hasPermission = await LocationUtil.requestLocationPermission(context);

    if ( hasPermission ) {
      try {
        const location = await geoLocationManager.getCurrentLocation();
        this.mapLat = location.latitude;
        this.mapLng = location.longitude;
        this.mockReverseGeocoding();
      } catch ( err ) {
        this.currentAddressDesc = '定位失败';
      }
    } else {
      this.currentAddressDesc = '无定位权限';
    }
  }

  async mockReverseGeocoding() {
    this.currentAddressDesc = '正在获取地址...';
    setTimeout(() => {
      this.currentAddressDesc = '北京市海淀区中关村软件园';
      this.provinceName = '北京市';
      this.cityName = '北京市';
      this.districtName = '海淀区';
    }, 800);
  }

  async onSave() {
    if (!this.consignee || !this.phone || !this.currentAddressDesc ) {
      promptAction.showToast({ message: '请填写完整信息喵' });
      return;
    }

    this.isLoading = true;
    try {
      const newAddress: AddressBook = {
        id: 0,
        consignee: this.consignee,
        sex: this.sex,
        phone: this.phone,
        provinceName: this.provinceName || '北京市',
        cityName: this.cityName || '北京市',
        districtName: this.districtName || '海淀区',
        provinceCode: '110000',
        cityCode: '110100',
        districtCode: '110101',
        detail: this.currentAddressDesc + ( this.houseNumber ? ' ' + this.houseNumber : '' ),
        label: this.label,
        isDefault: 0
      };

      await OrderService.addAddress(newAddress);
      promptAction.showToast({ message: '保存成功喵！' });

      if ( this.onSaveSuccess ) {
        this.onSaveSuccess();
      }
      if ( this.onClose ) {
        this.onClose();
      }

    } catch ( err ) {
      // Error handled by HttpUtil
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // --- 1. 底层：全屏地图 (模拟) ---
      Stack({ alignContent: Alignment.Center }) {
        Column().width('100%').height('100%').backgroundColor('#E0E0E0')
        Grid() {
          ForEach([ 1, 2, 3, 4, 5, 6 ], (i: number) => {
            GridItem().backgroundColor('#D0D0D0').width('100%').height('100%').margin(1)
          })
        }
        .columnsTemplate('1fr 1fr')
        .rowsTemplate('1fr 1fr 1fr')
        .width('100%').height('100%')

        Image($r('app.media.startIcon'))
          .width(40).height(40)
          .margin({ bottom: 40 })
          .zIndex(10)
      }
      .width('100%').height('100%')

      // --- 2. 顶层：悬浮表单卡片 ---
      Column() {
        Row()
          .width(40)
          .height(5)
          .backgroundColor('#DDD')
          .borderRadius(2.5)
          .margin({ top: 10, bottom: 10 })

        Row() {
          Image($r('app.media.startIcon')).width(16).height(16).margin({ right: 5 })
          Text(this.currentAddressDesc)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .width('100%').padding({ left: 20, right: 20, bottom: 15 })

        Divider().color('#F1F3F5')

        List() {
          ListItem() {
            Row() {
              Text('门牌号').width(70).fontSize(14)
              TextInput({ placeholder: '例：8号楼808室', text: this.houseNumber })
                .layoutWeight(1).backgroundColor(Color.Transparent)
                .onChange((val) => this.houseNumber = val)
            }.padding({ left: 20, right: 20 }).height(50)
          }

          ListItem() {
            Row() {
              Text('联系人').width(70).fontSize(14)
              TextInput({ placeholder: '姓名', text: this.consignee })
                .layoutWeight(1).backgroundColor(Color.Transparent)
                .onChange((val) => this.consignee = val)
            }.padding({ left: 20, right: 20 }).height(50)
          }

          ListItem() {
            Row() {
              Text('').width(70)
              Row({ space: 20 }) {
                this.SexRadio('先生', '1')
                this.SexRadio('女士', '0')
              }
            }.padding({ left: 20, right: 20 }).height(40)
          }

          ListItem() {
            Row() {
              Text('手机号').width(70).fontSize(14)
              TextInput({ placeholder: '手机号码', text: this.phone })
                .type(InputType.PhoneNumber)
                .layoutWeight(1).backgroundColor(Color.Transparent)
                .onChange((val) => this.phone = val)
            }.padding({ left: 20, right: 20 }).height(50)
          }

          ListItem() {
            Row() {
              Text('标签').width(70).fontSize(14)
              Row({ space: 10 }) {
                this.LabelButton('家')
                this.LabelButton('公司')
                this.LabelButton('学校')
              }
            }.padding({ left: 20, right: 20 }).height(50)
          }
        }
        .width('100%')
        .layoutWeight(1)

        Button(this.isLoading ? '保存中...' : '保存地址')
          .width('90%')
          .height(45)
          .backgroundColor('#FFCC00')
          .fontColor('#333')
          .margin({ top: 10, bottom: 30 })
          .enabled(!this.isLoading)
          .onClick(() => this.onSave())
      }
      .width('100%')
      .height('70%') // 设置一个高度让地图露出来
      .backgroundColor(Color.White)
      .borderRadius({ topLeft: 20, topRight: 20 })
      .shadow({ radius: 20, color: '#40000000', offsetY: -10 })

      // 悬浮返回按钮
      Image($r('app.media.ic_decrease'))
        .width(36)
        .height(36)
        .padding(8)
        .rotate({ angle: 90 })
        .backgroundColor('#AA000000') // 半透明黑
        .fillColor(Color.White)
        .borderRadius(18)
        .position({ x: 20, y: 20 })
        .onClick(() => {
          if ( this.onClose ) {
            this.onClose();
          }
        })
    }
    .width('100%').height('100%')
  }

  @Builder
  SexRadio(text: string, val: string) {
    Row() {
      Radio({ value: val, group: 'sex' })
        .checked(this.sex === val)
        .onChange((isChecked) => {
          if ( isChecked ) {
            this.sex = val;
          }
        })
      Text(text).fontSize(14)
    }
  }

  @Builder
  LabelButton(text: string) {
    Text(text)
      .fontSize(12)
      .padding({
        left: 12,
        right: 12,
        top: 4,
        bottom: 4
      })
      .border({ width: 1, color: this.label === text ? '#FFCC00' : '#DDD' })
      .backgroundColor(this.label === text ? '#FFF8D1' : Color.White)
      .fontColor(this.label === text ? '#333' : '#666')
      .borderRadius(4)
      .onClick(() => this.label = text)
  }
}
