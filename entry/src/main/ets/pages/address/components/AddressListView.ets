import { AddressBook } from '../../../model/entity/AddressBook';
import { OrderService } from '../../../service/OrderService';

@Component

export struct AddressListView {

  

  @State addressList: AddressBook[] = [];
    @State isLoading: boolean = true;
    @Prop selectedId: number = 0;
    onSelect: (addr: AddressBook) => void = () => {};
    onClose: () => void = () => {};
    // ✨ 新增地址回调
    onNewAddress: () => void = () => {};
  
    async aboutToAppear() {
    this.loadData();
  }

  async loadData() {
    this.isLoading = true;
    try {
      this.addressList = await OrderService.getAddressList();
    } catch ( err ) {
      console.error('加载地址列表失败:', err);
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      // 标题
      Text('选择收货地址')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 15, bottom: 15 })

      // 列表
      if ( this.isLoading ) {
        LoadingProgress().width(30).height(30).color('#999')
      } else if ( this.addressList.length === 0 ) {
        Column() {
          Image($r('app.media.ic_delete')) // 暂时用个图
            .width(60).height(60).opacity(0.2).margin({ bottom: 10 })
          Text('暂无收货地址').fontSize(14).fontColor('#999')
        }.layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.addressList, (item: AddressBook) => {
            ListItem() {
              Row() {
                // 选中状态图标
                Radio({ value: 'addr', group: 'addrGroup' })
                  .checked(item.id === this.selectedId)
                  .hitTestBehavior(HitTestMode.None) // 让点击穿透给 Row
                  .margin({ right: 10 })

                Column() {
                  Row() {
                    Text(item.label)
                      .fontSize(10)
                      .fontColor(Color.White)
                      .backgroundColor(item.label === '公司' ? '#0099FF' :
                        ( item.label === '家' ? '#FF6600' : '#00CC66' ))
                      .padding({
                        left: 4,
                        right: 4,
                        top: 1,
                        bottom: 1
                      })
                      .borderRadius(2)
                      .margin({ right: 6 })
                      .visibility(item.label ? Visibility.Visible : Visibility.None)

                    Text(`${ item.provinceName }${ item.cityName }${ item.districtName }${ item.detail }`)
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
                  }.margin({ top: 4 })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)

                // 编辑图标
                Image($r('app.media.ic_increase')) // 暂时用个图标代替编辑
                  .width(16).height(16)
                  .fillColor('#CCC')
                  .margin({ left: 10 })
                // .onClick((e) => {
                //   e.stopPropagation(); // 阻止冒泡
                //   // TODO: 跳转编辑页
                // })

              }
              .width('100%')
              .padding({ top: 15, bottom: 15 })
              .border({ width: { bottom: 0.5 }, color: '#EEE' })
              .backgroundColor(Color.White)
              .onClick(() => {
                if ( this.onSelect ) {
                  this.onSelect(item);
                }
                if ( this.onClose ) {
                  this.onClose();
                }
              })
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }

      // 底部新建按钮
      Button('+ 新建收货地址')
        .width('90%')
        .height(45)
        .backgroundColor('#FFCC00')
        .fontColor('#333')
        .margin({ top: 10, bottom: 20 })
        .onClick(() => {
          console.info(`喵！点击新建收货地址...`);
          if (this.onNewAddress) {
            this.onNewAddress();
          }
        })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16 })
    .backgroundColor(Color.White)
  }
}
