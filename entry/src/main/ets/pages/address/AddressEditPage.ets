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
  // 编辑模式传入的 ID，0 表示新增
  @Prop editId: number = 0;
  
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
  // 原始详细地址 (不含门牌号)
  @State rawDetail: string = '';

  async aboutToAppear() {
    // 如果是编辑模式，先加载数据
    if (this.editId > 0) {
      this.loadAddressDetail();
    } else {
      // 新增模式，初始定位
      this.requestLocation();
    }
    this.initMap();
  }

  async loadAddressDetail() {
    this.isLoading = true;
    try {
      const address = await OrderService.getAddressById(this.editId);
      if (address) {
        this.consignee = address.consignee;
        this.sex = address.sex;
        this.phone = address.phone;
        this.label = address.label || '家';
        this.provinceName = address.provinceName;
        this.cityName = address.cityName;
        this.districtName = address.districtName;
        
        // 简单处理：detail 通常包含 "主要地址 门牌号"
        // 这里为了简单，我们假设 detail 是主要地址，houseNumber 需要单独存或者让用户自己拆分？
        // 后端 detail 字段其实是完整的地址描述
        // 为了回显，我们暂且把 detail 显示在地址栏，houseNumber 留空或者尝试拆分
        // 实际上后端应该没有单独存 lat/lng? (如果有就好办了)
        // 假设后端没有经纬度，我们需要根据 detail 逆地理编码反查坐标? 或者如果不动地图就不用管
        // 这里的 detail 是包含门牌号的吗？看接口文档新增时: detail + houseNumber 拼一起存的
        // 所以回显时比较麻烦。简单做法：detail 直接显示，houseNumber 空着
        
        this.currentAddressDesc = address.detail; 
        // 尝试从 detail 中剥离出门牌号比较困难，暂时留空让用户补充或者手动修改
        
        // 如果后端有经纬度最好，没有的话可能需要重新定位或者根据地址查坐标 (GeoCoding)
        // 这里暂时不移动地图，除非有经纬度字段
      }
    } catch (err) {
      promptAction.showToast({ message: '加载地址失败' });
    } finally {
      this.isLoading = false;
    }
  }

  initMap() {
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
            // 只有在非回显模式或者用户主动移动后才更新地址
            // 简单点：只要动了就更新
            this.reverseGeocoding(this.mapLat, this.mapLng);
          }
        });
      }
    };
  }

  async requestLocation() {
    // 只有新增模式才自动定位
    if (this.editId > 0) return; 

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
        // 移动地图更新了地址，门牌号应该清空？还是保留？
        // 通常用户移动地图是为了修正在地图上的位置，门牌号还是保留比较好
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
      // 拼接完整详情地址 (如果是编辑，currentAddressDesc 可能是回显的含门牌号的地址，这里可能重复拼接，需要注意)
      // 简单处理：如果 currentAddressDesc 已经包含了 houseNumber 的内容，就不拼了？难判断
      // 还是按标准：currentAddressDesc 是定位点/POI名，houseNumber 是补充
      const detailAddr = this.currentAddressDesc + ( this.houseNumber ? ' ' + this.houseNumber : '' );

      const addressData: AddressBook = {
        id: this.editId || 0, // 如果是新增则为 0
        consignee: this.consignee,
        sex: this.sex,
        phone: this.phone,
        provinceName: this.provinceName || '北京市',
        cityName: this.cityName || '北京市',
        districtName: this.districtName || '海淀区',
        provinceCode: '110000',
        cityCode: '110100',
        districtCode: '110101',
        detail: detailAddr,
        label: this.label,
        isDefault: 0 // 保持默认逻辑，由后端或列表页控制
      };

      if (this.editId > 0) {
        await OrderService.updateAddress(addressData);
        promptAction.showToast({ message: '修改成功喵！' });
      } else {
        await OrderService.addAddress(addressData);
        promptAction.showToast({ message: '保存成功喵！' });
      }

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