import { common } from '@kit.AbilityKit';
import { geoLocationManager } from '@kit.LocationKit';
import { LocationUtil } from '../../common/utils/LocationUtil';
import { LocationInfo } from '../../model/entity/LocationInfo';
import router from '@ohos.router';

@Component
export struct AddressMapPage {
  @Consume('pageStack') pageStack: NavPathStack;
  @State isLoading: boolean = true;
  @State currentAddress: string = '正在定位...';
  @State locationInfo: LocationInfo | null = null;
  
  // 模拟地图中心坐标
  @State latitude: number = 39.9042;
  @State longitude: number = 116.4074;

  async aboutToAppear() {
    this.requestLocation();
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
        
        // TODO: 这里应该调用逆地理编码接口 (Map Kit 或 Web API)
        // 暂时 Mock 返回地址
        await this.mockReverseGeocoding(this.latitude, this.longitude);
        
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

  // 模拟逆地理编码
  async mockReverseGeocoding(lat: number, lng: number) {
    // 模拟网络延迟
    await new Promise<void>(r => setTimeout(r, 1000));
    
    this.locationInfo = {
      latitude: lat,
      longitude: lng,
      province: '北京市',
      city: '北京市',
      district: '海淀区',
      name: '中关村软件园',
      address: '北京市海淀区东北旺西路8号'
    };
    this.currentAddress = this.locationInfo.name;
  }

  onConfirm() {
    if (this.locationInfo) {
      // 通过 AppStorage 或者回调传递数据回上一页
      // 这里我们用 AppStorage 简单传一下，或者 pop 时带参数(NavPathStack不方便带回传)
      AppStorage.setOrCreate('SelectedLocation', this.locationInfo);
      this.pageStack.pop();
    }
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Bottom }) {
        // 1. 底层：模拟地图背景 (用个灰色背景加网格代替)
        Stack({ alignContent: Alignment.Center }) {
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor('#E0E0E0') // 地图底色
          
          // 模拟网格线
          Grid() {
            ForEach([1,2,3,4,5,6], (i: number) => {
              GridItem().backgroundColor('#D0D0D0').width('100%').height('100%').margin(1)
            })
          }
          .columnsTemplate('1fr 1fr 1fr')
          .rowsTemplate('1fr 1fr 1fr')
          .width('100%').height('100%')

          // 地图中心大头针
          Image($r('app.media.startIcon')) // 暂时借用个图标
            .width(40).height(40)
            .margin({ bottom: 40 }) // 让针尖对准中心
            .zIndex(10)
        }
        .width('100%')
        .height('100%')

        // 2. 顶层：地址详情卡片
        Column() {
          Text(this.isLoading ? '定位中...' : this.currentAddress)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 20, bottom: 10 })
          
          Text(this.locationInfo ? this.locationInfo.address : '')
            .fontSize(14)
            .fontColor('#666666')
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
  }
}
