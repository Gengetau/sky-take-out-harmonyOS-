import { AddressBook } from '../../../model/entity/AddressBook';
import { OrderService } from '../../../service/OrderService';

@Component
export struct AddressListView {
  @State addressList: AddressBook[] = [];
  @State isLoading: boolean = true;
  @Prop selectedId: number = 0;
  onSelect: (addr: AddressBook) => void = () => {};
  onClose: () => void = () => {};
  onNewAddress: () => void = () => {};
  onEditAddress: (id: number) => void = () => {};

  async aboutToAppear() {
    this.loadData();
  }

  async loadData() {
    this.isLoading = true;
    try {
      this.addressList = await OrderService.getAddressList();
    } catch (err) {
      console.error('加载地址列表失败:', err);
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      Text('选择收货地址')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 15, bottom: 15 })
      if (this.isLoading) {
        LoadingProgress().width(30).height(30).color('#999')
      } else if (this.addressList.length === 0) {
        Column() {
          Image($r('app.media.ic_delete'))
            .width(60).height(60).opacity(0.2).margin({ bottom: 10 })
          Text('暂无收货地址').fontSize(14).fontColor('#999')
        }.layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.addressList, (item: AddressBook) => {
            ListItem() {
              Row() {
                Radio({ value: 'addr', group: 'addrGroup' })
                  .checked(item.id === this.selectedId)
                  .hitTestBehavior(HitTestMode.None)
                  .margin({ right: 10 })
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
                      .fontSize(14)
                      .fontColor('#333')
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .layoutWeight(1)
                  }.width('100%').alignItems(VerticalAlign.Top)
                  Row() {
                    Text(item.consignee).fontSize(14).fontColor('#666')
                    Text(item.sex === '1' ? '先生' : '女士').fontSize(14).fontColor('#666').margin({ left: 5 })
                    Text(item.phone).fontSize(14).fontColor('#666').margin({ left: 15 })
                    Blank()
                    Row({ space: 15 }) {
                      if (item.isDefault !== 1) {
                        Text('设为默认')
                          .fontSize(11)
                          .fontColor('#666')
                          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                          .border({ width: 0.5, color: '#CCC' })
                          .borderRadius(12)
                          .backgroundColor('#F5F5F5')
                          .hitTestBehavior(HitTestMode.Block)
                          .onClick(async () => {
                            try {
                              await OrderService.setDefaultAddress(item.id);
                              this.loadData();
                            } catch (err) {
                              console.error('设置默认地址失败:', err);
                            }
                          })
                      }
                      // 编辑按钮
                      SymbolGlyph($r('sys.symbol.square_and_pencil'))
                        .fontSize(20)
                        .fontColor(['#999'])
                        .hitTestBehavior(HitTestMode.Block)
                        .onClick(() => {
                          if (this.onEditAddress) {
                            this.onEditAddress(item.id);
                          }
                        })
                      SymbolGlyph($r('sys.symbol.trash'))
                        .fontSize(20)
                        .fontColor(['#FF4D4F'])
                        .hitTestBehavior(HitTestMode.Block)
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
                                }
                              }
                            }
                          })
                        })
                    }
                  }.width('100%').margin({ top: 4 })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
              .padding({ top: 15, bottom: 15 })
              .border({ width: { bottom: 0.5 }, color: '#EEE' })
              .backgroundColor(Color.White)
              .onClick(() => {
                if (this.onSelect) this.onSelect(item);
                if (this.onClose) this.onClose();
              })
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      Button('+ 新建收货地址')
        .width('90%')
        .height(45)
        .backgroundColor('#FFCC00')
        .fontColor('#333')
        .margin({ top: 10, bottom: 20 })
        .onClick(() => {
          if (this.onNewAddress) this.onNewAddress();
        })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16 })
    .backgroundColor(Color.White)
  }
}