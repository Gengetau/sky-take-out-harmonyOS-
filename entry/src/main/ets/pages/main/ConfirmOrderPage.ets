import { OrderSubmitDTO } from '../../model/api/OrderModel';
import { AddressBook } from '../../model/entity/AddressBook';
import { CartItem } from '../../model/entity/ShopModel';
import { CartService } from '../../service/CartService';
import { OrderService } from '../../service/OrderService';
import { AddressEditPage } from '../address/AddressEditPage';
import { AddressListView } from '../address/components/AddressListView';
import { DateGroup, TimeGenerator } from '../../common/utils/TimeGenerator';

/**
 * 确认订单弹窗组件
 */
@Component
export struct ConfirmOrderView {
  pageStack: NavPathStack = new NavPathStack();
  onClose: () => void = () => {};
  @State cartService: CartService = CartService.getInstance();
  @StorageProp('CartUpdateSignal') @Watch('onCartUpdate') cartSignal: number = 0;
  @State currentTotalPrice: number = 0;
  @State subTotalAmount: number = 0;
  @State defaultAddress: AddressBook | null = null;
  @State remark: string = '';
  @State isLoading: boolean = false;
  
  // ✨ 弹窗控制
  @State showAddressList: boolean = false;
  @State isEditingAddress: boolean = false;
  @State editingAddressId: number = 0;
  
  // ✨ 时间选择相关
  @State showTimeSheet: boolean = false;
  @State timeGroups: DateGroup[] = [];
  @State selectedDateIndex: number = 0;
  @State deliveryTimeText: string = '立即送出 (约12:30送达)';

  private packAmount: number = 2; // 模拟打包费
  private deliveryPrice: number = 6; // 模拟配送费

  async aboutToAppear() {
    this.onCartUpdate();
    this.defaultAddress = await OrderService.getDefaultAddress();
    this.timeGroups = TimeGenerator.getDeliveryTimes();
  }

  onCartUpdate() {
    this.currentTotalPrice = this.cartService.totalPrice;
    const price = this.currentTotalPrice || 0;
    const pack = this.packAmount || 0;
    const delivery = this.deliveryPrice || 0;
    const total = price + pack + delivery;
    this.subTotalAmount = isNaN(total) ? 0 : total;
  }

  formatPrice(price: number | undefined | null): string {
    if (price === undefined || price === null || Number.isNaN(price)) {
      return '0.00';
    }
    try {
      return price.toFixed(2);
    } catch (e) {
      return '0.00';
    }
  }

  async onSubmitOrder() {
    if (!this.defaultAddress) {
      console.warn('喵！请选择地址！');
      return;
    }
    this.isLoading = true;
    try {
      const submitDTO: OrderSubmitDTO = {
        addressBookId: this.defaultAddress.id,
        payMethod: 1, // 默认微信
        remark: this.remark,
        estimatedDeliveryTime: this.deliveryTimeText === '立即送出 (约12:30送达)' ? '立即送出' : this.deliveryTimeText,
        deliveryStatus: 1,
        packAmount: this.packAmount,
        tablewareNumber: 2, // Mock
        tablewareStatus: 1,
        amount: this.subTotalAmount
      };
      const result = await OrderService.submitOrder(submitDTO);
      this.showPaymentDialog(result.orderAmount);
    } catch (err) {
      console.error('下单失败喵', err);
    } finally {
      this.isLoading = false;
    }
  }

  showPaymentDialog(amount: number) {
    AlertDialog.show({
      title: '正在支付...',
      message: `需支付 ¥${amount.toFixed(2)}
(模拟支付环境)`,
      autoCancel: false,
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: '放弃支付',
        action: () => { console.info('放弃支付喵'); }
      },
      secondaryButton: {
        value: '支付成功',
        action: () => {
          this.cartService.clearCart();
          if (this.onClose) { this.onClose(); }
          console.info('支付成功喵！');
        }
      }
    });
  }

  @Builder
  TimeSheetBuilder() {
    Column() {
      // 标题
      Text('选择送达时间')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ top: 15, bottom: 15 })
        .backgroundColor('#F9F9F9')

      Row() {
        // --- 左侧：日期列表 ---
        List() {
          ForEach(this.timeGroups, (group: DateGroup, index: number) => {
            ListItem() {
              Text(group.date)
                .fontSize(14)
                .fontColor(this.selectedDateIndex === index ? '#333' : '#666')
                .fontWeight(this.selectedDateIndex === index ? FontWeight.Bold : FontWeight.Normal)
                .width('100%')
                .height(50)
                .textAlign(TextAlign.Center)
                .backgroundColor(this.selectedDateIndex === index ? Color.White : '#F5F5F5')
                .onClick(() => {
                  this.selectedDateIndex = index;
                })
            }
          })
        }
        .width('30%')
        .height('100%')
        .backgroundColor('#F5F5F5')

        // --- 右侧：时间段列表 ---
        List() {
          if (this.timeGroups.length > 0 && this.timeGroups[this.selectedDateIndex]) {
             ForEach(this.timeGroups[this.selectedDateIndex].times, (timeStr: string) => {
              ListItem() {
                Row() {
                  Text(timeStr)
                    .fontSize(14)
                    .fontColor('#333')
                    .layoutWeight(1)
                  
                  if (this.deliveryTimeText.includes(timeStr)) {
                    SymbolGlyph($r('sys.symbol.checkmark'))
                      .fontSize(16)
                      .fontColor(['#FFCC00'])
                  }
                }
                .width('100%')
                .height(50)
                .padding({ left: 20, right: 20 })
                .backgroundColor(Color.White)
                .onClick(() => {
                  const dateStr = this.timeGroups[this.selectedDateIndex].date;
                  if (timeStr === '立即送出') {
                    this.deliveryTimeText = '立即送出 (约12:30送达)';
                  } else {
                    this.deliveryTimeText = `${dateStr} ${timeStr}`;
                  }
                  this.showTimeSheet = false;
                })
              }
            })
          }
        }
        .width('70%')
        .height('100%')
        .backgroundColor(Color.White)
      }
      .layoutWeight(1)
    }
    .height(400)
    .backgroundColor(Color.White)
  }

  @Builder
  AddressListBuilder() {
    AddressListView({
      selectedId: this.defaultAddress?.id || 0,
      onSelect: (addr: AddressBook) => {
        this.defaultAddress = addr;
        this.showAddressList = false;
      },
      onClose: () => {
        this.showAddressList = false;
      },
      onNewAddress: () => {
        this.editingAddressId = 0;
        this.showAddressList = false;
        this.isEditingAddress = true;
      },
      onEditAddress: (id: number) => {
        this.editingAddressId = id;
        this.showAddressList = false;
        this.isEditingAddress = true;
      }
    })
  }

  build() {
    Stack() {
      if (this.isEditingAddress) {
        AddressEditPage({
          editId: this.editingAddressId,
          onClose: () => {
            this.isEditingAddress = false;
            this.showAddressList = true;
          },
          onSaveSuccess: () => {
            this.isEditingAddress = false;
            this.showAddressList = true;
          }
        })
      } else {
        Column() {
          Row() {
            Text('确认订单')
              .fontSize(18).fontWeight(FontWeight.Bold)
              .layoutWeight(1).textAlign(TextAlign.Center)
          }
          .width('100%').height(50).padding({ left: 16, right: 16 }).backgroundColor('#F1F3F5')

          Scroll() {
            Column({ space: 12 }) {
              this.AddressSection()
              this.DeliveryTimeSection()
              this.OrderDetailSection()
              this.RemarkSection()
              Blank().height(80)
            }
            .padding(12).width('100%')
          }
          .layoutWeight(1).backgroundColor('#F1F3F5')

          this.BottomBar()
        }
        .width('100%').height('100%').backgroundColor('#F1F3F5')
        .bindSheet(this.showAddressList, this.AddressListBuilder(), {
          height: SheetSize.MEDIUM, 
          dragBar: true,
          backgroundColor: '#F1F3F5',
          onDisappear: () => { this.showAddressList = false; }
        })
        .bindSheet(this.showTimeSheet, this.TimeSheetBuilder(), {
          height: 400,
          dragBar: true,
          backgroundColor: Color.White,
          onDisappear: () => { this.showTimeSheet = false; }
        })
      }
    }
    .width('100%').height('100%')
  }

  @Builder
  AddressSection() {
    Column() {
      if (this.defaultAddress) {
        Text(`${this.defaultAddress.provinceName} ${this.defaultAddress.cityName} ${this.defaultAddress.districtName}`)
          .fontSize(12).fontColor('#666666')
        Text(this.defaultAddress.detail)
          .fontSize(18).fontWeight(FontWeight.Bold).margin({ top: 4, bottom: 4 })
        Row() {
          Text(this.defaultAddress.consignee).fontSize(14).fontColor('#333333')
          Text(this.defaultAddress.phone).fontSize(14).fontColor('#999999').margin({ left: 10 })
        }
      } else {
        Text('请选择收货地址 +').fontSize(16).fontWeight(FontWeight.Bold).fontColor('#FFCC00')
      }
    }
    .width('100%').padding(16).backgroundColor(Color.White).borderRadius(8).alignItems(HorizontalAlign.Start)
    .onClick(() => {
      this.showAddressList = true;
    })
  }

  @Builder
  DeliveryTimeSection() {
    Row() {
      Text('预计送达时间').fontSize(14).fontWeight(FontWeight.Bold)
      Blank()
      Row() {
        Text(this.deliveryTimeText).fontSize(14).fontColor('#0099FF').margin({ right: 5 })
        SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(16).fontColor(['#999'])
      }
    }
    .width('100%').padding(16).backgroundColor(Color.White).borderRadius(8)
    .onClick(() => {
      this.showTimeSheet = true;
    })
  }

  @Builder
  OrderDetailSection() {
    Column() {
      Text('苍穹外卖').fontSize(14).fontWeight(FontWeight.Bold).margin({ bottom: 10 })
      ForEach(this.cartService.cartItems, (item: CartItem) => {
        Row() {
          Image(item.image).width(50).height(50).borderRadius(4).objectFit(ImageFit.Cover).backgroundColor('#f0f0f0')
          Column() {
            Text(item.name).fontSize(14).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(item.flavors ? item.flavors : '').fontSize(10).fontColor('#999').margin({ top: 2 })
          }.layoutWeight(1).padding({ left: 10 }).alignItems(HorizontalAlign.Start)
          Column() {
            Text(`¥${item.price}`).fontSize(14).fontWeight(FontWeight.Bold)
            Text(`x${item.count}`).fontSize(12).fontColor('#999')
          }.alignItems(HorizontalAlign.End)
        }.width('100%').margin({ bottom: 12 })
      })
      Divider().color('#f5f5f5').margin({ top: 5, bottom: 5 })
      Row() { Text('打包费').fontSize(14); Blank(); Text(`¥${this.packAmount}`).fontSize(14).fontWeight(FontWeight.Bold) }.width('100%').margin({ top: 8 })
      Row() { Text('配送费').fontSize(14); Blank(); Text(`¥${this.deliveryPrice}`).fontSize(14).fontWeight(FontWeight.Bold) }.width('100%').margin({ top: 8 })
      Divider().color('#f5f5f5').margin({ top: 10, bottom: 10 })
      Row() { Text('小计').fontSize(12).fontColor('#666'); Blank(); Text(`¥${this.formatPrice(this.subTotalAmount)}`).fontSize(18).fontWeight(FontWeight.Bold) }.width('100%')
    }.width('100%').padding(16).backgroundColor(Color.White).borderRadius(8).alignItems(HorizontalAlign.Start)
  }

  @Builder
  RemarkSection() {
    Row() {
      Text('备注').fontSize(14).fontWeight(FontWeight.Bold)
      Blank()
      TextInput({ placeholder: '口味、偏好等要求', text: this.remark })
        .textAlign(TextAlign.End).backgroundColor(Color.Transparent)
        .onChange((val) => { this.remark = val; }).width('60%')
    }.width('100%').padding({ left: 16, right: 16, top: 10, bottom: 10 }).backgroundColor(Color.White).borderRadius(8)
  }

  @Builder
  BottomBar() {
    Row() {
      Column() {
        Text(`¥${this.formatPrice(this.subTotalAmount)}`).fontSize(20).fontWeight(FontWeight.Bold).fontColor(Color.White)
        Text('已优惠 ¥0').fontSize(10).fontColor('#cccccc')
      }.alignItems(HorizontalAlign.Start)
      Blank()
      Button(this.isLoading ? '提交中...' : '去支付').backgroundColor('#FFCC00').fontColor('#333333').height(40).width(100).enabled(!this.isLoading)
        .onClick(() => this.onSubmitOrder())
    }.width('100%').height(60).backgroundColor('#222222').padding({ left: 20, right: 20 })
  }
}