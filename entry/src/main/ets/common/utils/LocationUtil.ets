import { abilityAccessCtrl, bundleManager, common, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

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
      // 检查是否所有权限都被授予
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
}
