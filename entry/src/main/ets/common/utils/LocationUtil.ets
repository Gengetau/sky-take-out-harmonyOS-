import { abilityAccessCtrl, bundleManager, common, Permissions } from '@kit.AbilityKit';
import { geoLocationManager } from '@kit.LocationKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 坐标对象
 */
export interface GeoPoint {
  latitude: number;
  longitude: number;
}

/**
 * 定位与权限工具类
 */
export class LocationUtil {
  
  /**
   * 申请定位权限
   */
  static async requestLocationPermission(context: common.UIAbilityContext): Promise<boolean> {
    const atManager = abilityAccessCtrl.createAtManager();
    const permissions: Permissions[] = [
      'ohos.permission.APPROXIMATELY_LOCATION',
      'ohos.permission.LOCATION'
    ];

    try {
      const result = await atManager.requestPermissionsFromUser(context, permissions);
      const isGranted = result.authResults.every(auth => auth === 0);
      return isGranted;
    } catch (err) {
      console.error('申请权限失败:', JSON.stringify(err));
      return false;
    }
  }

  /**
   * 检查是否已有权限
   */
  static async checkPermission(permission: Permissions): Promise<boolean> {
    const atManager = abilityAccessCtrl.createAtManager();
    const bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
    const tokenId = bundleInfo.appInfo.accessTokenId;

    try {
      const grantStatus = await atManager.checkAccessToken(tokenId, permission);
      return grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch (err) {
      return false;
    }
  }

  /**
   * 🌍 获取当前位置 (单次定位)
   */
  static async getCurrentLocation(context: common.UIAbilityContext): Promise<GeoPoint | null> {
    const hasPermission = await LocationUtil.requestLocationPermission(context);
    if (!hasPermission) {
      return null;
    }

    try {
      const requestInfo: geoLocationManager.CurrentLocationRequest = {
        'priority': geoLocationManager.LocationRequestPriority.FIRST_FIX,
        'scenario': geoLocationManager.LocationRequestScenario.UNSET,
        'maxAccuracy': 0
      };
      
      const location = await geoLocationManager.getCurrentLocation(requestInfo);
      return {
        latitude: location.latitude,
        longitude: location.longitude
      };
    } catch (err) {
      return null;
    }
  }

  /**
   * 🗺️ 逆地理编码：经纬度转详细地址 (新增)
   */
  static async getAddressFromLocation(latitude: number, longitude: number): Promise<string> {
    try {
      const reverseGeocodeRequest: geoLocationManager.ReverseGeoCodeRequest = {
        'latitude': latitude,
        'longitude': longitude,
        'maxItems': 1,
        'locale': 'zh'
      };
      const addresses = await geoLocationManager.getAddressesFromLocation(reverseGeocodeRequest);
      
      if (addresses && addresses.length > 0) {
        const addr = addresses[0];
        // 优先取建筑物/地标名，其次取路名喵
        return addr.placeName || addr.roadName || addr.subLocality || '未知位置';
      }
      return '位置解析中';
    } catch (err) {
      console.error('解析地址失败喵', err);
      return '位置解析失败';
    }
  }
}
