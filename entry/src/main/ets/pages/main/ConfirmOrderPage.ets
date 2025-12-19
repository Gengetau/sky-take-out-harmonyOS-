import { OrderSubmitDTO } from '../../model/api/OrderModel';
import { AddressBook } from '../../model/entity/AddressBook';
import { CartItem } from '../../model/entity/ShopModel';
import { CartService } from '../../service/CartService';
import { OrderService } from '../../service/OrderService';
import { AddressEditPage } from '../address/AddressEditPage';
import { AddressListView } from '../address/components/AddressListView';

/**
 * 确认订单弹窗组件
 * 喵！现在我是一个可以嵌入 bindSheet 的普通组件啦！
 */
@Component
export struct ConfirmOrderView {
  // ✨ 妮娅修正：手动接收 pageStack，确保万无一失
  pageStack: NavPathStack = new NavPathStack();
  // 接受一个关闭回调，用于关闭弹窗
  onClose: () => void = () => {
  };
  @State cartService: CartService = CartService.getInstance();
  // 监听购物车更新信号，并触发手动同步
  @StorageProp('CartUpdateSignal') @Watch('onCartUpdate') cartSignal: number = 0;
  // 本地状态，确保UI刷新
  @State currentTotalPrice: number = 0;
  // ✨ 妮娅改动：直接用 State 存储小计金额，不再用 getter
  @State subTotalAmount: number = 0;
  @State defaultAddress: AddressBook | null = null;
  @State remark: string = '';
  @State isLoading: boolean = false;
  // ✨ 控制地址列表弹窗
  @State showAddressList: boolean = false;
  // ✨ 控制是否正在“新增地址”模式 (内容替换)
  @State isEditingAddress: boolean = false;
  
  // 费用配置 (模拟)
  private packAmount: number = 2; // 模拟打包费
  private deliveryPrice: number = 6; // 模拟配送费

  async aboutToAppear() {
    // 初始化时同步一次购物车数据
    this.onCartUpdate();
    // 加载默认地址
    this.defaultAddress = await OrderService.getDefaultAddress();
  }

  // 购物车数据同步方法
  onCartUpdate() {
    this.currentTotalPrice = this.cartService.totalPrice;

    // 手动计算小计并赋值给 State
    const price = this.currentTotalPrice || 0;
    const pack = this.packAmount || 0;
    const delivery = this.deliveryPrice || 0;
    const total = price + pack + delivery;
    this.subTotalAmount = isNaN(total) ? 0 : total;
  }

  // 安全格式化金额
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

  // 提交订单处理
  async onSubmitOrder() {
    if (!this.defaultAddress ) {
      // 提示选择地址 (简单 Toast 模拟)
      console.warn('喵！请选择地址！');
      return;
    }

    this.isLoading = true;

    try {
      const submitDTO: OrderSubmitDTO = {
        addressBookId: this.defaultAddress.id,
        payMethod: 1, // 默认微信
        remark: this.remark,
        estimatedDeliveryTime: '12:30', // Mock
        deliveryStatus: 1,
        packAmount: this.packAmount,
        tablewareNumber: 2, // Mock
        tablewareStatus: 1,
        amount: this.subTotalAmount
      };

      const result = await OrderService.submitOrder(submitDTO);

      // 模拟支付弹窗
      this.showPaymentDialog(result.orderAmount);

    } catch ( err ) {
      console.error('下单失败喵', err);
    } finally {
      this.isLoading = false;
    }
  }

  showPaymentDialog(amount: number) {
    AlertDialog.show({
      title: '正在支付...',message: `需支付 ¥${ amount.toFixed(2) }
(模拟支付环境)`,
      autoCancel: false,
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: '放弃支付',
        action: () => {
          console.info('放弃支付喵');
        }
      },
      secondaryButton: {
        value: '支付成功',
        action: () => {
          // 清空购物车
          this.cartService.clearCart();

          // 关闭弹窗
          if ( this.onClose ) {
            this.onClose();
          }
          console.info('支付成功喵！');
        }
      }
    });
  }

  @Builder
  AddressListBuilder() {
    AddressListView({
      selectedId: this.defaultAddress?.id || 0,
      onSelect: (addr: AddressBook) => {
        this.defaultAddress = addr;
        // 记得关闭弹窗
        this.showAddressList = false;
      },
      onClose: () => {
        this.showAddressList = false;
      },
      onNewAddress: () => {
        console.info('喵！切换到新增地址模式');
        this.showAddressList = false;
        this.isEditingAddress = true;
      }
    })
  }

  build() {
    Stack() {
      if (this.isEditingAddress) {
        // --- 新增地址模式 ---
        AddressEditPage({
          onClose: () => {
            this.isEditingAddress = false;
            // 回来时重新打开地址选择，方便用户选刚才新建的（如果逻辑需要）
            this.showAddressList = true;
          },
          onSaveSuccess: () => {
            this.isEditingAddress = false;
            this.showAddressList = true;
          }
        })
      } else {
        // --- 确认订单详情模式 ---
        Column() {
          // --- 顶部标题栏 (自定义) ---
          Row() {
            Text('确认订单')
              .fontSize(18).fontWeight(FontWeight.Bold)
              .layoutWeight(1).textAlign(TextAlign.Center)
          }
          .width('100%')
          .height(50)
          .padding({ left: 16, right: 16 })
          .backgroundColor('#F1F3F5')

          // --- 内容区域 ---
          Scroll() {
            Column({ space: 12 }) {

              // 1. 地址卡片
              this.AddressSection()

              // 2. 预计送达时间
              this.DeliveryTimeSection()

              // 3. 订单详情卡片
              this.OrderDetailSection()

              // 4. 备注卡片
              this.RemarkSection()

              // 底部留白，防止被 BottomBar 遮挡
              Blank().height(80)
            }
            .padding(12)
            .width('100%')
          }
          .layoutWeight(1)
          .backgroundColor('#F1F3F5')

          // --- 底部支付栏 ---
          this.BottomBar()

        }
        .width('100%')
        .height('100%')
        .backgroundColor('#F1F3F5')
        // ✨ 嵌套弹窗：选择地址
        .bindSheet(this.showAddressList, this.AddressListBuilder(), {
          height: SheetSize.MEDIUM, 
          dragBar: true,
          backgroundColor: '#F1F3F5',
          onDisappear: () => {
            this.showAddressList = false;
          }
        })
      }
    }
    .width('100%')
    .height('100%')
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
        Text('请选择收货地址 +')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFCC00')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(8)
    .alignItems(HorizontalAlign.Start)
    .onClick(() => {
      console.info('喵！点击了选择收货地址，准备打开列表弹窗...');
      // 打开地址列表弹窗
      this.showAddressList = true;
    })
  }

  @Builder
  DeliveryTimeSection() {
    Row() {
      Text('预计送达时间').fontSize(14).fontWeight(FontWeight.Bold)
      Blank()
      Text('立即送出 (约12:30送达)').fontSize(14).fontColor('#0099FF')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(8)
  }

  @Builder
  OrderDetailSection() {
    Column() {
      Text('苍穹外卖').fontSize(14).fontWeight(FontWeight.Bold).margin({ bottom: 10 })

      // 商品列表 (只显示前3个，多了折叠？暂不折叠)
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
          }
          .layoutWeight(1)
          .padding({ left: 10 })
          .alignItems(HorizontalAlign.Start)

          Column() {
            Text(`¥${ item.price }`).fontSize(14).fontWeight(FontWeight.Bold)
            Text(`x${ item.count }`).fontSize(12).fontColor('#999')
          }
          .alignItems(HorizontalAlign.End)
        }
        .width('100%')
        .margin({ bottom: 12 })
      })

      Divider().color('#f5f5f5').margin({ top: 5, bottom: 5 })

      // 费用明细
      Row() {
        Text('打包费').fontSize(14)
        Blank()
        Text(`¥${ this.packAmount }`).fontSize(14).fontWeight(FontWeight.Bold)
      }.width('100%').margin({ top: 8 })

      Row() {
        Text('配送费').fontSize(14)
        Blank()
        Text(`¥${ this.deliveryPrice }`).fontSize(14).fontWeight(FontWeight.Bold)
      }.width('100%').margin({ top: 8 })

      Divider().color('#f5f5f5').margin({ top: 10, bottom: 10 })

      Row() {
        Text('小计').fontSize(12).fontColor('#666')
        Blank()
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
  RemarkSection() {
    Row() {
      Text('备注').fontSize(14).fontWeight(FontWeight.Bold)
      Blank()
      TextInput({ placeholder: '口味、偏好等要求', text: this.remark })
        .textAlign(TextAlign.End)
        .backgroundColor(Color.Transparent)
        .onChange((val) => {
          this.remark = val;
        })
        .width('60%')
    }
    .width('100%')
    .padding({
      left: 16,
      right: 16,
      top: 10,
      bottom: 10
    })
    .backgroundColor(Color.White)
    .borderRadius(8)
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
      }
      .alignItems(HorizontalAlign.Start)

      Blank()

      Button(this.isLoading ? '提交中...' : '去支付')
        .backgroundColor('#FFCC00')
        .fontColor('#333333')
        .height(40)
        .width(100)
        .enabled(!this.isLoading)
        .onClick(() => this.onSubmitOrder())

    }
    .width('100%')
    .height(60)
    .backgroundColor('#222222')
    .padding({ left: 20, right: 20 })

    // .position({ x: 0, y: '100%' }) // 不用 position，直接放在 Column 最下面
  }
}
