import { DateGroup, TimeGenerator } from '../../common/utils/TimeGenerator';
import { CartItemDTO, OrderSubmitDTO } from '../../model/api/OrderModel';
import { AddressBook } from '../../model/entity/AddressBook';
import { CartItem } from '../../model/entity/ShopModel';
import { CartService } from '../../service/CartService';
import { OrderService } from '../../service/OrderService';
import { AddressEditPage } from '../address/AddressEditPage';
import { AddressListView } from '../address/components/AddressListView';
import { RemarkPage } from './RemarkPage';
import { PaymentPageParams } from './PaymentPage';
import { promptAction } from '@kit.ArkUI';

/**
 * 确认订单弹窗组件
 */
@Component
export struct ConfirmOrderView {
  @Consume('pageStack') pageStack: NavPathStack;
  // 外部传入的关闭回调，用于关闭 bindSheet
  onClose: () => void = () => {
  };
  @State cartService: CartService = CartService.getInstance();
  @StorageProp('CartUpdateSignal') @Watch('onCartUpdate') cartSignal: number = 0;
  @State currentTotalPrice: number = 0;
  @State subTotalAmount: number = 0;
  @State defaultAddress: AddressBook | null = null;
  @State remark: string = '';
  @State isLoading: boolean = false;
  // ✨ 新增状态
  @State payMethod: number = 2; // ✨ 默认改为 2 (支付宝)，因为微信暂时不可用
  @State tablewareNumber: number = 0; // 餐具数量
  @State tablewareStatus: number = 1; // 1:按餐量提供, 0:具体数量
  // ✨ 弹窗控制
  @State showAddressList: boolean = false;
  @State isEditingAddress: boolean = false;
  @State isAddingRemark: boolean = false; // ✨ 新增备注页控制
  @State editingAddressId: number = 0;
  // ✨ 时间选择相关
  @State showTimeSheet: boolean = false;
  @State timeGroups: DateGroup[] = [];
  @State selectedDateIndex: number = 0;
  @State deliveryTimeText: string = TimeGenerator.getImmediateDeliveryTime();
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
    if ( price === undefined || price === null || Number.isNaN(price) ) {
      return '0.00';
    }
    try {
      return price.toFixed(2);
    } catch ( e ) {
      return '0.00';
    }
  }

  async onSubmitOrder() {
    console.info('喵！开始提交订单...');
    if (!this.defaultAddress ) {
      console.warn('喵！未选择地址，终止提交');
      promptAction.showToast({ message: '请选择收货地址喵' });
      return;
    }
    this.isLoading = true;
    try {
      // 1. 解析时间
      const isImmediate = this.deliveryTimeText.startsWith('立即送出');
      const estimatedTime = this.parseEstimatedTime(this.deliveryTimeText);
      console.info(`喵！解析预计时间: ${estimatedTime}, 是否立即: ${isImmediate}`);

      // 2. 转换购物车数据
      const cartItemsDTO: CartItemDTO[] = this.cartService.cartItems.map((item: CartItem): CartItemDTO => {
        return {
          dishId: item.dishId,
          setmealId: item.setmealId,
          dishFlavor: item.flavors,
          number: item.count,
          amount: item.price,
          name: item.name,
          image: item.image
        } as CartItemDTO;
      });
      console.info(`喵！购物车项数: ${cartItemsDTO.length}`);

      const submitDTO: OrderSubmitDTO = {
        addressBookId: this.defaultAddress.id,
        payMethod: this.payMethod,
        remark: this.remark,
        estimatedDeliveryTime: estimatedTime,
        deliveryStatus: isImmediate ? 1 : 0,
        packAmount: this.packAmount,
        tablewareNumber: this.tablewareNumber,
        tablewareStatus: this.tablewareStatus,
        amount: this.subTotalAmount,
        cartItems: cartItemsDTO
      };

      console.info('喵！正在调用 OrderService.submitOrder...');
      const result = await OrderService.submitOrder(submitDTO);
      console.info('喵！订单提交成功！返回结果:', JSON.stringify(result));

      // ✨ 跳转到支付页面
      const params: PaymentPageParams = {
        orderNumber: result.orderNumber,
        payMethod: this.payMethod,
        totalAmount: result.orderAmount
      };

      // 🚀 关键修改：先跳转，然后立刻关闭当前的 bindSheet 弹窗！
      this.pageStack.pushPath({ name: 'PaymentPage', param: params });

      if (this.onClose) {
        this.onClose(); // 这行代码会让 ShopPage 里的 showConfirmOrder = false，从而关闭弹窗
      }

      // 清空购物车
      this.cartService.clearCart();

    } catch ( err ) {
      console.error('喵！！！下单失败，错误信息:', err);
      promptAction.showToast({ message: '下单失败，请检查网络喵' });
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 解析配送时间文本为 yyyy-MM-dd HH:mm:ss 格式
   */
  parseEstimatedTime(text: string): string {
    const now = new Date();
    let targetTime = new Date();

    if ( text.startsWith('立即送出') ) {
      targetTime.setHours(now.getHours() + 1);
    } else {
      const parts = text.split(' ');
      if ( parts.length >= 2 ) {
        const dayStr = parts[0];
        const timeRange = parts[1];
        const startTime = timeRange.split('-')[0];
        const timeParts = startTime.split(':');
        const hour = Number(timeParts[0]);
        const minute = Number(timeParts[1]);

        if ( dayStr === '明天' ) {
          targetTime.setDate(targetTime.getDate() + 1);
        }
        targetTime.setHours(hour, minute, 0, 0);
      }
    }
    const y = targetTime.getFullYear();
    const m = (targetTime.getMonth() + 1).toString().padStart(2, '0');
    const d = targetTime.getDate().toString().padStart(2, '0');
    const h = targetTime.getHours().toString().padStart(2, '0');
    const min = targetTime.getMinutes().toString().padStart(2, '0');
    const s = targetTime.getSeconds().toString().padStart(2, '0');
    return `${ y }-${ m }-${ d } ${ h }:${ min }:${ s }`;
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
          if ( this.timeGroups.length > 0 && this.timeGroups[this.selectedDateIndex] ) {
            ForEach(this.timeGroups[this.selectedDateIndex].times, (timeStr: string) => {
              ListItem() {
                Row() {
                  Text(timeStr)
                    .fontSize(14)
                    .fontColor('#333')
                    .layoutWeight(1)

                  if ( this.deliveryTimeText.includes(timeStr) ) {
                    SymbolGlyph($r('sys.symbol.checkmark'))
                      .fontSize(16)
                      .fontColor([ '#FFCC00' ])
                  }
                }
                .width('100%')
                .height(50)
                .padding({ left: 20, right: 20 })
                .backgroundColor(Color.White)
                .onClick(() => {
                  const dateStr = this.timeGroups[this.selectedDateIndex].date;
                  if ( timeStr === '立即送出' ) {
                    this.deliveryTimeText = TimeGenerator.getImmediateDeliveryTime();
                  } else {
                    this.deliveryTimeText = `${ dateStr } ${ timeStr }`;
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
    NavDestination() {
      Stack() {
        if ( this.isEditingAddress ) {
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
        } else if ( this.isAddingRemark ) {
          RemarkPage({
            remarkText: this.remark,
            onSave: (val: string) => {
              this.remark = val;
            },
            onClose: () => {
              this.isAddingRemark = false;
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
                this.PayMethodSection()
                this.OrderDetailSection()
                this.TablewareSection()
                this.RemarkSection()
                Blank().height(80)
              }
              .padding(12).width('100%')
            }
            .layoutWeight(1).backgroundColor('#F1F3F5')

            this.BottomBar()
          }
          .width('100%')
          .height('100%')
          .backgroundColor('#F1F3F5')
          .bindSheet(this.showAddressList, this.AddressListBuilder(), {
            height: SheetSize.MEDIUM,
            dragBar: true,
            backgroundColor: '#F1F3F5',
            onDisappear: () => {
              this.showAddressList = false;
            }
          })
          .bindSheet(this.showTimeSheet, this.TimeSheetBuilder(), {
            height: 400,
            dragBar: true,
            backgroundColor: Color.White,
            onDisappear: () => {
              this.showTimeSheet = false;
            }
          })
        }
      }
      .width('100%').height('100%')
    }.hideTitleBar(true)
  }

  @Builder
  AddressSection() {
    Column() {
      if ( this.defaultAddress ) {
        Text(`${ this.defaultAddress.provinceName } ${ this.defaultAddress.cityName } ${ this.defaultAddress.districtName }`)
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
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(8)
    .alignItems(HorizontalAlign.Start)
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
        SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(16).fontColor([ '#999' ])
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(8)
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
          Image(item.image)
            .width(50)
            .height(50)
            .borderRadius(4)
            .objectFit(ImageFit.Cover)
            .backgroundColor('#f0f0f0')
          Column() {
            Text(item.name).fontSize(14).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(item.flavors ? item.flavors : '').fontSize(10).fontColor('#999').margin({ top: 2 })
          }.layoutWeight(1).padding({ left: 10 }).alignItems(HorizontalAlign.Start)

          Column() {
            Text(`¥${ item.price }`).fontSize(14).fontWeight(FontWeight.Bold)
            Text(`x${ item.count }`).fontSize(12).fontColor('#999')
          }.alignItems(HorizontalAlign.End)
        }.width('100%').margin({ bottom: 12 })
      })
      Divider().color('#f5f5f5').margin({ top: 5, bottom: 5 })
      Row() {
        Text('打包费').fontSize(14);
        Blank();
        Text(`¥${ this.packAmount }`).fontSize(14).fontWeight(FontWeight.Bold)
      }.width('100%').margin({ top: 8 })

      Row() {
        Text('配送费').fontSize(14);
        Blank();
        Text(`¥${ this.deliveryPrice }`).fontSize(14).fontWeight(FontWeight.Bold)
      }.width('100%').margin({ top: 8 })

      Divider().color('#f5f5f5').margin({ top: 10, bottom: 10 })
      Row() {
        Text('小计').fontSize(12).fontColor('#666');
        Blank();
        Text(`¥${ this.formatPrice(this.subTotalAmount) }`).fontSize(18).fontWeight(FontWeight.Bold)
      }.width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(8)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  PayMethodSection() {
    Column() {
      Row() {
        Text('支付方式').fontSize(14).fontWeight(FontWeight.Bold)
      }.width('100%').margin({ bottom: 10 })

      // ✨ 微信支付 - 禁用状态
      Row() {
        Image($r('app.media.wechat'))
          .width(24)
          .height(24)
          .margin({ right: 10 })
          .grayscale(1) // 变灰
          .opacity(0.5) // 半透明

        Text('微信支付')
          .fontSize(14)
          .layoutWeight(1)
          .fontColor('#999') // 文字变灰

        Text('(维护中)')
          .fontSize(12)
          .fontColor('#999')
          .margin({ right: 10 })

        Radio({ value: '1', group: 'pay' })
          .checked(this.payMethod === 1)
          .enabled(false) // 禁用单选框
      }
      .width('100%')
      .padding({ top: 10, bottom: 10 })
      .onClick(() => {
        promptAction.showToast({ message: '微信支付暂不可用，请使用支付宝喵' });
      })

      // ✨ 支付宝 - 正常状态 (默认选中)
      Row() {
        Image($r('app.media.alipay')).width(24).height(24).margin({ right: 10 })
        Text('支付宝').fontSize(14).layoutWeight(1)
        Radio({ value: '2', group: 'pay' })
          .checked(this.payMethod === 2)
          .onChange((isChecked: boolean) => {
            if ( isChecked ) {
              this.payMethod = 2;
            }
          })
      }.width('100%').padding({ top: 10, bottom: 10 })
      .onClick(() => {
        this.payMethod = 2
      })

    }.width('100%').padding(16).backgroundColor(Color.White).borderRadius(8)
  }

  @Builder
  TablewareSection() {
    Row() {
      Text('餐具数量').fontSize(14).fontWeight(FontWeight.Bold)
      Blank()
      Row() {
        Text(this.tablewareStatus === 1 ? '依据餐量提供' : `${ this.tablewareNumber } 份`)
          .fontSize(14)
          .fontColor('#333')
          .margin({ right: 5 })

        SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(16).fontColor([ '#999' ])
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(8)

    .onClick(() => {
      const ranges = [ '依据餐量提供', '1份', '2份', '3份', '4份', '5份', '6份', '7份', '8份', '9份', '10份' ];
      TextPickerDialog.show({
        range: ranges,
        selected: this.tablewareStatus === 1 ? 0 : this.tablewareNumber,
        onAccept: (value: TextPickerResult) => {
          if ( value.index === 0 ) {
            this.tablewareStatus = 1;
            this.tablewareNumber = 0;
          } else {
            this.tablewareStatus = 0;
            this.tablewareNumber = Number(value.index);
          }
        }
      })
    })
  }

  @Builder
  RemarkSection() {
    Row() {
      Text('备注').fontSize(14).fontWeight(FontWeight.Bold)
      Blank()
      Row() {
        Text(this.remark ? this.remark : '口味、偏好等要求')
          .fontSize(14)
          .fontColor(this.remark ? '#333' : '#999')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('60%')
          .textAlign(TextAlign.End)
          .margin({ right: 5 })
        SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(16).fontColor([ '#999' ])
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(8)
    .onClick(() => {
      this.isAddingRemark = true;
    })
  }

  @Builder
  BottomBar() {
    Row() {
      Column() {
        Text(`¥${ this.formatPrice(this.subTotalAmount) }`)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
        Text('已优惠 ¥0').fontSize(10).fontColor('#cccccc')
      }.alignItems(HorizontalAlign.Start)

      Blank()
      Button(this.isLoading ? '提交中...' : '去支付')
        .backgroundColor('#FFCC00')
        .fontColor('#333333')
        .height(40)
        .width(100)
        .enabled(!this.isLoading)
        .onClick(() => this.onSubmitOrder())
    }.width('100%').height(60).backgroundColor('#222222').padding({ left: 20, right: 20 })
  }
}