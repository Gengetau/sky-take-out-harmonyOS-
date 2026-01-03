import { promptAction } from '@kit.ArkUI';
import { ShopInfoVO } from '../model/ShopModel';
import { ShopService } from '../service/ShopService';
import { EditFieldParam } from './EditFieldPage';
import { FileUtil } from '../common/FileUtil';
import { common } from '@kit.AbilityKit';
import { HttpUtil } from '../common/HttpUtil';

/**
 * 信息项组件
 */
@Component
struct InfoItemComponent {
  @Prop label: string = '';
  @Prop value: string = '';
  onItemClick: () => void = () => {}; 

  build() {
    ListItem() {
      Row() {
        Text(this.label).fontSize(16).fontColor($r('app.color.text_main'))
        Blank()
        Text(this.value)
          .fontSize(14).fontColor($r('app.color.text_secondary'))
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1).textAlign(TextAlign.End).margin({ left: 20 })
        Image($r('app.media.startIcon')).width(16).height(16).opacity(0.3).margin({ left: 10 })
      }
      .width('100%').height(60).padding({ left: 15, right: 15 }).backgroundColor(Color.White)
      .onClick(() => {
        this.onItemClick();
      })
    }.margin({ bottom: 1 })
  }
}

@Component
export struct ShopInfoPage {
  @Consume('pageStack') pageStack: NavPathStack;
  @StorageLink('shopInfo') shopInfo: ShopInfoVO | null = null;
  @State isLoading: boolean = false;
  @State isUploadingLogo: boolean = false; // 🐾 Logo上传状态

  async aboutToAppear() {
    this.loadShopInfo();
  }

  async loadShopInfo() {
    try {
      if (!this.shopInfo) this.isLoading = true;
      const res = await ShopService.getShopInfo();
      this.shopInfo = res;
      AppStorage.setOrCreate('shopInfo', res);
    } catch (e) {
    } finally {
      this.isLoading = false;
    }
  }

  async toggleStatus(isOn: boolean) {
    if (!this.shopInfo) return;
    const newStatus = isOn ? 1 : 0;
    try {
      await ShopService.setStatus(newStatus);
      this.shopInfo.status = newStatus;
      promptAction.showToast({ message: isOn ? '开门大吉喵！☀️' : '辛苦了，休息时间喵🌙' });
      AppStorage.setOrCreate('shopInfo', this.shopInfo);
    } catch (e) {
      this.loadShopInfo(); 
    }
  }

  /**
   * 修改店铺 Logo 的魔法逻辑喵！📸
   */
  async handleLogoUpload() {
    const context = getContext(this) as common.UIAbilityContext;
    
    try {
      // 1. 选择图片
      const localPath = await FileUtil.pickAndCacheImage(context);
      
      this.isUploadingLogo = true;
      promptAction.showToast({ message: '正在上传图片喵...' });

      // 2. 上传文件到后端 (API 8.1)
      // 注意：这里的 URL 是 '/common/upload'
      const uploadedUrl = await HttpUtil.upload<string>('/common/upload', localPath);
      console.info('喵！图片上传成功，获得 URL:', uploadedUrl);

      // 3. 弹出确认框喵
      AlertDialog.show({
        title: '更换店铺 Logo',
        message: '已经为您准备好美美的图片了，确定要更换吗喵？',
        primaryButton: {
          value: '取消',
          action: () => {
            this.isUploadingLogo = false;
          }
        },
        secondaryButton: {
          value: '确定修改',
          action: async () => {
            try {
              // 4. 修改店铺信息 (API 3.5)
              const updateData: Partial<ShopInfoVO> = { avatar: uploadedUrl };
              await ShopService.updateShopInfo(updateData);
              promptAction.showToast({ message: 'Logo 修改成功喵！✨' });
              this.loadShopInfo(); // 刷新显示
            } catch (e) {
              promptAction.showToast({ message: '保存失败，请重试喵' });
            } finally {
              this.isUploadingLogo = false;
            }
          }
        },
        cancel: () => {
          this.isUploadingLogo = false;
        }
      });

    } catch (e) {
      console.error('喵！Logo 上传过程出错:', e);
      this.isUploadingLogo = false;
      if (e.message !== '未选择图片喵') {
        promptAction.showToast({ message: '图片处理失败喵' });
      }
    }
  }

  build() {
    NavDestination() {
      Column() {
        if (this.isLoading) {
          LoadingProgress().width(50).height(50).color($r('app.color.theme_color'))
        } else if (this.shopInfo) {
          List() {
            // 1. Logo 编辑项
            ListItem() {
              Row() {
                Text('店铺 Logo').fontSize(16).fontColor($r('app.color.text_main'))
                Blank()
                
                Stack() {
                  Image(this.shopInfo.avatar || $r('app.media.startIcon'))
                    .width(60).height(60).borderRadius(30).objectFit(ImageFit.Cover).backgroundColor('#F0F0F0')
                  
                  if (this.isUploadingLogo) {
                    Column() {
                      LoadingProgress().width(24).height(24).color(Color.White)
                    }
                    .width(60).height(60).borderRadius(30)
                    .backgroundColor('#80000000').justifyContent(FlexAlign.Center)
                  }
                }
                
                Image($r('app.media.startIcon')).width(16).height(16).opacity(0.3).margin({ left: 10 })
              }
              .width('100%').height(80).padding({ left: 15, right: 15 }).backgroundColor(Color.White)
              .onClick(() => {
                if (!this.isUploadingLogo) {
                  this.handleLogoUpload();
                }
              })
            }.margin({ bottom: 1 })

            // 2. 营业状态
            ListItem() {
              Row() {
                Text('营业状态').fontSize(16).fontColor($r('app.color.text_main'))
                Blank()
                Text(this.shopInfo.status === 1 ? '正在营业' : '已打烊')
                  .fontSize(14).fontColor(this.shopInfo.status === 1 ? Color.Green : Color.Gray).margin({ right: 10 })
                Toggle({ type: ToggleType.Switch, isOn: this.shopInfo.status === 1 })
                  .selectedColor($r('app.color.theme_color'))
                  .onChange((isOn: boolean) => { this.toggleStatus(isOn); })
              }
              .width('100%').height(60).padding({ left: 15, right: 15 }).backgroundColor(Color.White)
            }.margin({ bottom: 10 })

            // 3. 基础信息编辑
            InfoItemComponent({ label: '店铺名称', value: this.shopInfo.name, onItemClick: () => { this.openInputPrompt('店铺名称', 'name', this.shopInfo!.name) } })
            InfoItemComponent({ label: '联系电话', value: this.shopInfo.phone || '未填写', onItemClick: () => { this.openInputPrompt('联系电话', 'phone', this.shopInfo!.phone) } })
            InfoItemComponent({ label: '店铺地址', value: this.shopInfo.address, onItemClick: () => { this.openInputPrompt('店铺地址', 'address', this.shopInfo!.address) } })
            InfoItemComponent({ label: '店铺简介', value: this.shopInfo.description || '暂无简介', onItemClick: () => { this.openInputPrompt('店铺简介', 'description', this.shopInfo!.description) } })

            ListItem() {
              Divider().color(Color.Transparent).height(10)
            }

            // 4. 价格设置
            InfoItemComponent({ 
              label: '起送价', 
              value: (this.shopInfo.deliveryPrice || 0).toString() + ' 元', 
              onItemClick: () => { this.openInputPrompt('起送价', 'deliveryPrice', (this.shopInfo!.deliveryPrice || 0).toString(), true) } 
            })
            InfoItemComponent({ 
              label: '配送费', 
              value: (this.shopInfo.shippingFee || 0).toString() + ' 元', 
              onItemClick: () => { this.openInputPrompt('配送费', 'shippingFee', (this.shopInfo!.shippingFee || 0).toString(), true) } 
            })

            // 5. 评分 (只读)
            ListItem() {
              Row() {
                Text('店铺评分').fontSize(16).fontColor($r('app.color.text_main'))
                Blank()
                Text(this.shopInfo.score.toFixed(1)).fontSize(16).fontWeight(FontWeight.Bold).fontColor('#FFB000')
                Text(' 分').fontSize(12).fontColor('#999999')
              }
              .width('100%').height(60).padding({ left: 15, right: 15 }).backgroundColor(Color.White)
            }
          }
          .width('100%').layoutWeight(1)
        }
      }
      .width('100%').height('100%').backgroundColor($r('app.color.page_background'))
    }
    .title('店铺设置')
    .onShown(() => {
      this.loadShopInfo();
    })
  }

  openInputPrompt(title: string, field: string, oldVal: string, isNumber: boolean = false) {
    const params = new EditFieldParam(title, field, oldVal, isNumber);
    this.pageStack.pushPath({
      name: 'EditFieldPage',
      param: params
    })
  }
}
