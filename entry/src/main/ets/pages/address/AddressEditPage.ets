import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { AsyncCallback } from '@kit.BasicServicesKit';
import { geoLocationManager } from '@kit.LocationKit';
import { map, mapCommon, MapComponent } from '@kit.MapKit';
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
  @State isMoving: boolean = false; // 是否正在移动地图
  // 地图控制器
  private mapOption?: mapCommon.MapOptions;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapController?: map.MapComponentController;
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

  aboutToAppear() {
    // 初始化地图参数
    this.mapOption = {
      position: {
        target: {
          latitude: this.mapLat,
          longitude: this.mapLng
        },
        zoom: 15
      }
    };

    // 地图加载完成的回调
    this.callback = async(err, mapController) => {
      if (!err && mapController ) {
        this.mapController = mapController;
        this.mapController.setMyLocationEnabled(true);
        this.mapController.setMyLocationControlsEnabled(true);

        // 调整地图Logo位置
        this.mapController.setLogoPadding({
          bottom: 200,
          left: 10,
          right: 10,
          top: 0
        });

        // 监听相机移动
        this.mapController.on("cameraMove", () => {
          // 移动时收起表单，只显示地址条
          this.isMoving = true;
        });

        // 监听相机移动结束事件
        this.mapController.on("cameraIdle", () => {
          // 停止后展开表单
          this.isMoving = false;
          const cameraPosition = this.mapController?.getCameraPosition();
          if ( cameraPosition ) {
            this.mapLat = cameraPosition.target.latitude;
            this.mapLng = cameraPosition.target.longitude;
            this.reverseGeocoding(this.mapLat, this.mapLng);
          }
        });

        // 初始定位
        this.requestLocation();
      }
    };
  }

  async requestLocation() {
    const context = getContext(this) as common.UIAbilityContext;
    const hasPermission = await LocationUtil.requestLocationPermission(context);

    if ( hasPermission ) {
      try {
        const location = await geoLocationManager.getCurrentLocation();
        this.mapLat = location.latitude;
        this.mapLng = location.longitude;

        // 移动相机
        if ( this.mapController ) {
          this.mapController.animateCamera(map.newCameraPosition({
            target: {
              latitude: this.mapLat,
              longitude: this.mapLng
            },
            zoom: 17,
            tilt: 0,
            bearing: 0
          }));
        }
      } catch ( err ) {
        this.currentAddressDesc = '定位失败';
      }
    } else {
      this.currentAddressDesc = '无定位权限';
    }
  }

  // 真实的逆地理编码
  async reverseGeocoding(lat: number, lng: number) {
    try {
      const reverseGeocodeRequest: geoLocationManager.ReverseGeoCodeRequest = {
        latitude: lat,
        longitude: lng,
        maxItems: 1
      };

      const addresses = await geoLocationManager.getAddressesFromLocation(reverseGeocodeRequest);

      if ( addresses && addresses.length > 0 ) {
        const address = addresses[0];
        let fullAddress = address.placeName || '';
        if (!fullAddress ) {
          fullAddress = ( address.roadName || '' ) + ( address.subLocality || '' ) + ( address.locality || '' );
        }

        this.provinceName = address.administrativeArea || '';
        this.cityName = address.locality || '';
        this.districtName = address.subLocality || '';
        this.currentAddressDesc = address.placeName || address.roadName || fullAddress || '未知地点';
      }
    } catch ( err ) {
      console.error('逆地理编码失败:', JSON.stringify(err));
    }
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
      // --- 1. 底层：真实地图组件 ---
      Stack({ alignContent: Alignment.Center }) {
        MapComponent({ mapOptions: this.mapOption, mapCallback: this.callback })
          .width('100%')
          .height('100%')

                // 大头针

                SymbolGlyph($r('sys.symbol.local_fill'))

                  .fontSize(40)

                  .fontColor(['#E84026']) // 经典红色定位钉

                  .margin({ bottom: '35%' }) 

                  .zIndex(10)

                  .hitTestBehavior(HitTestMode.None)

        

                // 右上角定位按钮

                Column() {

                  SymbolGlyph($r('sys.symbol.position'))

                    .fontSize(24)

                    .fontColor([Color.Black])

                }

                .width(44)

                .height(44)

                .backgroundColor(Color.White)

                .borderRadius(22)

                .shadow({ radius: 10, color: '#30000000', offsetX: 0, offsetY: 2 })

                .justifyContent(FlexAlign.Center)

                .position({ x: '85%', y: '10%' })

                .onClick(() => {

                  this.requestLocation();

                })
      }
      .width('100%').height('100%')

      // --- 2. 顶层：悬浮表单卡片 ---
      Column() {
        // 顶部把手条
        Row()
          .width(40)
          .height(5)
          .backgroundColor('#DDD')
          .borderRadius(2.5)
          .margin({ top: 10, bottom: 10 })

        // 地址显示区（始终显示）
        Row() {
          SymbolGlyph($r('sys.symbol.location_north_up_right_circle_fill'))
            .fontSize(20)
            .fontColor(['#FFCC00'])
            .margin({ right: 5 })
          Text(this.currentAddressDesc)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .width('100%').padding({ left: 20, right: 20, bottom: 15 })

        Divider().color('#F1F3F5')

        // 表单区（移动时会被遮挡或收起，这里通过高度控制可见性）
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
        .opacity(this.isMoving ? 0 : 1) // 移动时隐藏内容，避免视觉杂乱
        .animation({ duration: 200 })

        Button(this.isLoading ? '保存中...' : '保存地址')
          .width('90%')
          .height(45)
          .backgroundColor('#FFCC00')
          .fontColor('#333')
          .margin({ top: 10, bottom: 30 })
          .enabled(!this.isLoading)
          .opacity(this.isMoving ? 0 : 1)
          .animation({ duration: 200 })
          .onClick(() => this.onSave())
            }
            .width('100%')
            // 动态高度：移动时只留头部(约15%)，静止时展开(55%)
            .height(this.isMoving ? '15%' : '55%') 
            .backgroundColor(Color.White)
            .borderRadius({ topLeft: 20, topRight: 20 })
            .shadow({ radius: 20, color: '#40000000', offsetY: -10 })      // 添加丝滑动画
      .animation({
        duration: 300,
        curve: Curve.FastOutSlowIn
      })

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