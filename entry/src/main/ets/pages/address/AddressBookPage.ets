import { promptAction } from '@kit.ArkUI';
import { AddressBook } from '../../model/entity/AddressBook';
import { OrderService } from '../../service/OrderService';

/**
 * 地址管理页面 (我的地址)
 */
@Component
export struct AddressBookPage {
  @Consume('pageStack') pageStack: NavPathStack;
  @State addressList: AddressBook[] = [];
  @State isLoading: boolean = true;

  async aboutToAppear() {
    this.loadData();
  }

  async loadData() {
    this.isLoading = true;
    try {
      this.addressList = await OrderService.getAddressList();

      // 贴心小功能：如果只有一个地址且没设为默认，自动设为默认
      if (this.addressList.length === 1 && this.addressList[0].isDefault !== 1) {
        const onlyOne = this.addressList[0];
        console.info('喵！检测到唯一地址且非默认，正在自动设为默认:', onlyOne.id);
        await OrderService.setDefaultAddress(onlyOne.id);
        // 设完后刷新列表以显示“默认”标签
        this.addressList = await OrderService.getAddressList();
      }
    } catch (err) {
      console.error('加载地址列表失败:', err);
      // promptAction.showToast({ message: '加载失败，请重试' });
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    NavDestination() {
      Column() {
        // 自定义标题栏 (NavDestination 默认有，但为了统一风格可以自定义，这里先用默认的)
        
        if (this.isLoading) {
          Column() {
            LoadingProgress().width(40).height(40).color('#FFCC00')
            Text('加载中...').fontSize(14).fontColor('#999').margin({ top: 10 })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else if (this.addressList.length === 0) {
          Column() {
            Image($r('app.media.ic_delete')) // 暂时借用个图标
              .width(80).height(80).opacity(0.1).margin({ bottom: 10 })
            Text('暂无收货地址').fontSize(14).fontColor('#999')
          }.layoutWeight(1).justifyContent(FlexAlign.Center)
        } else {
          List() {
            ForEach(this.addressList, (item: AddressBook) => {
              ListItem() {
                this.AddressItem(item)
              }
              .swipeAction({
                end: {
                  builder: () => { this.SwipeDeleteButton(item) },
                  onAction: () => {
                    // 可以在这里处理删除，或者点击按钮处理
                  },
                  actionAreaDistance: 80,
                }
              })
            })
          }
          .width('100%')
          .layoutWeight(1)
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
        }

        // 底部新增按钮
        Button('新增收货地址')
          .width('90%')
          .height(45)
          .backgroundColor('#FFCC00')
          .fontColor('#333')
          .margin({ top: 10, bottom: 20 })
          .onClick(() => {
             this.pageStack.pushPath({ name: 'AddressEditRoutePage', param: 0 }); // 0 表示新增
          })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F7F8FA')
    }
    .title('我的地址')
    .hideTitleBar(false)
    .onShown(() => {
      this.loadData();
    })
  }

  @Builder
  AddressItem(item: AddressBook) {
    Column() {
      Row() {
        Column() {
          Row() {
            if (item.isDefault === 1) {
              Text('默认')
                .fontSize(10)
                .fontColor('#FFCC00')
                .backgroundColor('#FFF8D1')
                .border({ width: 0.5, color: '#FFCC00' })
                .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                .borderRadius(2)
                .margin({ right: 6 })
            }
            Text(item.label)
              .fontSize(10)
              .fontColor(Color.White)
              .backgroundColor(item.label === '公司' ? '#0099FF' : (item.label === '家' ? '#FF6600' : '#00CC66'))
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
              .borderRadius(2)
              .margin({ right: 6 })
              .visibility(item.label ? Visibility.Visible : Visibility.None)
            Text(`${item.provinceName}${item.cityName}${item.districtName}${item.detail}`)
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333')
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
          }.width('100%').alignItems(VerticalAlign.Top)

          Row() {
            Text(item.consignee).fontSize(14).fontColor('#666')
            Text(item.sex === '1' ? '先生' : '女士').fontSize(14).fontColor('#666').margin({ left: 5 })
            Text(item.phone).fontSize(14).fontColor('#666').margin({ left: 15 })
          }.width('100%').margin({ top: 8 })

          // 操作栏
          Row() {
            // 设为默认按钮
            Row() {
               Radio({ value: 'default', group: 'defaultGroup' })
                 .checked(item.isDefault === 1)
                 .width(16)
                 .height(16)
                 .hitTestBehavior(HitTestMode.None) // 点击由父容器处理
               Text(item.isDefault === 1 ? '已设为默认' : '设为默认')
                 .fontSize(12)
                 .fontColor(item.isDefault === 1 ? '#FFCC00' : '#666')
                 .margin({ left: 6 })
            }
            .onClick(async () => {
               if (item.isDefault !== 1) {
                 try {
                   await OrderService.setDefaultAddress(item.id);
                   this.loadData();
                 } catch (err) {
                   console.error('设置默认地址失败:', err);
                 }
               }
            })

            Blank()

            // 编辑按钮
            Row() {
              SymbolGlyph($r('sys.symbol.square_and_pencil'))
                .fontSize(16)
                .fontColor(['#666'])
              Text('编辑')
                .fontSize(12)
                .fontColor('#666')
                .margin({ left: 4 })
            }
            .onClick(() => {
               this.pageStack.pushPath({ name: 'AddressEditRoutePage', param: item.id });
            })
            .margin({ right: 20 })

            // 删除按钮
            Row() {
              SymbolGlyph($r('sys.symbol.trash'))
                .fontSize(16)
                .fontColor(['#666'])
              Text('删除')
                .fontSize(12)
                .fontColor('#666')
                .margin({ left: 4 })
            }
            .onClick(() => {
              AlertDialog.show({
                title: '删除地址',
                message: '确定要删除这个收货地址吗？',
                autoCancel: true,
                alignment: DialogAlignment.Center,
                primaryButton: { value: '取消', action: () => {} },
                secondaryButton: {
                  value: '删除',
                  fontColor: '#FF4D4F',
                  action: async () => {
                    try {
                      await OrderService.deleteAddress(item.id);
                      this.loadData();
                    } catch (err) {
                      console.error('删除失败:', err);
                      promptAction.showToast({ message: '删除失败' });
                    }
                  }
                }
              })
            })
          }
          .width('100%')
          .padding({ top: 15 })
          .margin({ top: 10 })
          .border({ width: { top: 0.5 }, color: '#F0F0F0' })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 12 })
      .backgroundColor(Color.White)
      .borderRadius(12)
    }
    .padding({ left: 12, right: 12, top: 10 })
  }

  @Builder
  SwipeDeleteButton(item: AddressBook) {
    Button() {
      SymbolGlyph($r('sys.symbol.trash'))
        .fontSize(24)
        .fontColor([Color.White])
    }
    .width(80)
    .height('100%') // 会撑满 ListItem 高度
    .backgroundColor('#FF4D4F')
    .type(ButtonType.Normal)
    .borderRadius({ topRight: 12, bottomRight: 12 }) // 匹配 Item 圆角
    .margin({ top: 10, right: 12 }) // 匹配 Item 外边距
    .onClick(() => {
      AlertDialog.show({
        title: '删除地址',
        message: '确定要删除这个收货地址吗？',
        autoCancel: true,
        alignment: DialogAlignment.Center,
        primaryButton: { value: '取消', action: () => {} },
        secondaryButton: {
          value: '删除',
          fontColor: '#FF4D4F',
          action: async () => {
            try {
              await OrderService.deleteAddress(item.id);
              this.loadData(); // 刷新列表
            } catch (err) {
              console.error('删除失败:', err);
              promptAction.showToast({ message: '删除失败' });
            }
          }
        }
      })
    })
  }
}