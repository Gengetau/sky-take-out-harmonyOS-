import { fileIo as fs } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';

export class FileUtil {
  /**
   * 从图库选择单张图片并拷贝到沙箱缓存
   * @param context UIAbilityContext
   * @returns 拷贝后的沙箱路径
   */
  static async pickAndCacheImage(context: common.UIAbilityContext): Promise<string> {
    const photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
    photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    photoSelectOptions.maxSelectNumber = 1;

    const photoPicker = new photoAccessHelper.PhotoViewPicker();
    const photoSelectResult = await photoPicker.select(photoSelectOptions);

    if (photoSelectResult.photoUris.length === 0) {
      throw new Error('未选择图片喵');
    }

    const uri = photoSelectResult.photoUris[0];
    
    // 准备沙箱目标路径 (cache 目录)
    const fileName = `upload_${Date.now()}_${Math.floor(Math.random() * 1000)}.jpg`;
    const destPath = `${context.cacheDir}/${fileName}`;

    // 执行拷贝
    // 注意：uri 需要通过 fs.openSync 打开进行读取
    const file = fs.openSync(uri, fs.OpenMode.READ_ONLY);
    const destFile = fs.openSync(destPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
    fs.copyFileSync(file.fd, destFile.fd);
    fs.closeSync(file.fd);
    fs.closeSync(destFile.fd);

    return destPath;
  }
}