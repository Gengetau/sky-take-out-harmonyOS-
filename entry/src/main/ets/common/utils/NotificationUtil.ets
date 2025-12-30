import { notificationManager } from '@kit.NotificationKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 系统通知工具类 🔔
 * 封装 NotificationKit 能力，提供便捷的通知发布接口
 */
export class NotificationUtil {
  
  /**
   * 申请通知权限
   * @param context UIAbilityContext
   */
  static async requestNotificationPermission(context: common.UIAbilityContext): Promise<void> {
    try {
      await notificationManager.requestEnableNotification(context);
      console.info('喵！通知权限申请已调用');
    } catch (err) {
      console.error(`申请通知权限失败喵: code: ${(err as BusinessError).code}, message: ${(err as BusinessError).message}`);
    }
  }

  /**
   * 发布基础文本通知
   * @param title 通知标题
   * @param text 通知内容
   * @param id 通知ID (可选，用于覆盖)
   */
  static async publishBasicNotification(title: string, text: string, id: number = 1001) {
    // 构造 NotificationRequest 对象
    const notificationRequest: notificationManager.NotificationRequest = {
      id: id,
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT, // 普通文本类型
        normal: {
          title: title,
          text: text,
          additionalText: 'Meow外卖' // 附加信息，通常显示在最后
        }
      },
      // 设置点击通知后的动作 (可选，比如拉起应用)
      // wantAgent: ... 
      deliveryTime: new Date().getTime(),
      showDeliveryTime: true,
      groupName: 'meow_delivery_msg', // 消息分组
      // slotType: notificationManager.SlotType.SOCIAL_COMMUNICATION // 社交类型通知，优先级较高
    };

    try {
      await notificationManager.publish(notificationRequest);
      console.info(`喵！通知发布成功: [${title}] ${text}`);
    } catch (err) {
      console.error(`发布通知失败喵: code: ${(err as BusinessError).code}, message: ${(err as BusinessError).message}`);
    }
  }
}
