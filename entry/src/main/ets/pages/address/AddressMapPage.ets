import { common } from '@kit.AbilityKit';
import { geoLocationManager } from '@kit.LocationKit';
import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';
import { LocationUtil } from '../../common/utils/LocationUtil';
import { LocationInfo } from '../../model/entity/LocationInfo';
import router from '@ohos.router';

@Component
export struct AddressMapPage {
  @Consume('pageStack') pageStack: NavPathStack;
  @State isLoading: boolean = true;
  @State currentAddress: string = '正在定位...';
  @State locationInfo: LocationInfo | null = null;
  
  // 地图相关控制器和选项
  private mapOption?: mapCommon.MapOptions;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapController?: map.MapComponentController;

  // 默认北京坐标，后续会被定位覆盖
  @State latitude: number = 39.9042;
  @State longitude: number = 116.4074;

  aboutToAppear() {
    // 初始化地图参数
    this.mapOption = {
      position: {
        target: {
          latitude: this.latitude,
          longitude: this.longitude
        },
        zoom: 15
      }
    };

    // 地图加载完成的回调
    this.callback = async (err, mapController) => {
      if (!err && mapController) {
        this.mapController = mapController;
        // 启用我的位置显示
        this.mapController.setMyLocationEnabled(true);
        this.mapController.setMyLocationControlsEnabled(true);
        
        // 监听相机移动结束事件，用于获取中心点坐标进行逆地理编码
        this.mapController.on("cameraIdle", () => {
          const cameraPosition = this.mapController?.getCameraPosition();
          if (cameraPosition) {
            this.latitude = cameraPosition.target.latitude;
            this.longitude = cameraPosition.target.longitude;
            this.reverseGeocoding(this.latitude, this.longitude);
          }
        });

        // 地图加载好了再开始定位
        this.requestLocation();
      } else {
        console.error('MapController init failed', err);
      }
    };
  }

  async requestLocation() {
    const context = getContext(this) as common.UIAbilityContext;
    const hasPermission = await LocationUtil.requestLocationPermission(context);
    
    if (hasPermission) {
      this.isLoading = true;
      try {
        // 获取单次定位
        const location = await geoLocationManager.getCurrentLocation();
        this.latitude = location.latitude;
        this.longitude = location.longitude;
        
        // 移动地图相机到定位点
        if (this.mapController) {
          this.mapController.animateCamera(map.newCameraPosition({
            target: {
              latitude: this.latitude,
              longitude: this.longitude
            },
            zoom: 17,
            tilt: 0,
            bearing: 0
          }));
        }

        // 进行逆地理编码
        await this.reverseGeocoding(this.latitude, this.longitude);
        
      } catch (err) {
        console.error('定位失败:', JSON.stringify(err));
        this.currentAddress = '定位失败，请检查网络或GPS';
      } finally {
        this.isLoading = false;
      }
    } else {
      this.currentAddress = '未获得定位权限';
      this.isLoading = false;
    }
  }

  // 真实的逆地理编码
  async reverseGeocoding(lat: number, lng: number) {
    this.isLoading = true;
    try {
      const reverseGeocodeRequest: geoLocationManager.ReverseGeoCodeRequest = {
        latitude: lat,
        longitude: lng,
        maxItems: 1
      };
      
      const addresses = await geoLocationManager.getAddressesFromLocation(reverseGeocodeRequest);
      
      if (addresses && addresses.length > 0) {
        const address = addresses[0];
        // 拼接详细地址
        let fullAddress = address.placeName || '';
        if (!fullAddress) {
           fullAddress = (address.roadName || '') + (address.subLocality || '') + (address.locality || '');
        }

        this.locationInfo = {
          latitude: lat,
          longitude: lng,
          province: address.administrativeArea || '',
          city: address.locality || '',
          district: address.subLocality || '',
          name: address.placeName || address.roadName || '未知地点',
          address: fullAddress
        };
        this.currentAddress = this.locationInfo.name || this.locationInfo.address;
      } else {
        this.currentAddress = '未知位置';
      }
    } catch (err) {
      console.error('逆地理编码失败:', JSON.stringify(err));
      // 失败时保留坐标，显示默认文案，避免UI空白
      this.currentAddress = '无法获取详细地址';
    } finally {
      this.isLoading = false;
    }
  }

  onConfirm() {
    if (this.locationInfo) {
      AppStorage.setOrCreate('SelectedLocation', this.locationInfo);
      this.pageStack.pop();
    }
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Bottom }) {
        // 1. 底层：真实地图组件
        Stack({ alignContent: Alignment.Center }) {
          MapComponent({ mapOptions: this.mapOption, mapCallback: this.callback })
            .width('100%')
            .height('100%')
          
          // 地图中心大头针
          SymbolGlyph($r('sys.symbol.local_fill'))
            .fontSize(40)
            .fontColor(['#E84026'])
            .margin({ bottom: 40 }) 
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
          .position({ x: '85%', y: '5%' })
          .onClick(() => {
            this.requestLocation();
          })
        }
        .width('100%')
        .height('100%')

        // 2. 顶层：地址详情卡片
        Column() {
          Text(this.isLoading ? '定位中...' : this.currentAddress)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 20, bottom: 10 })
          
          Text(this.locationInfo ? this.locationInfo.address : '')
            .fontSize(14)
            .fontColor('#666666')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ bottom: 20 })

          Button('确认选择')
            .width('90%')
            .backgroundColor('#FFCC00')
            .fontColor('#333333')
            .enabled(!this.isLoading && this.locationInfo !== null)
            .onClick(() => this.onConfirm())
        }
        .width('100%')
        .height(180)
        .backgroundColor(Color.White)
        .borderRadius({ topLeft: 16, topRight: 16 })
        .shadow({ radius: 10, color: '#40000000', offsetY: -5 })
      }
      .width('100%')
      .height('100%')
    }
    .title('选择收货地址')
    .hideTitleBar(false)
  }
}