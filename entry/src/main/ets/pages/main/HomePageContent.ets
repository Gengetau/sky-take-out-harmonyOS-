/**
 * 首页
 */
import { promptAction } from '@kit.ArkUI';
import { ShopTypeVO } from '../../model/entity/ShopTypeModel';
import { HomeService } from '../../service/HomeService';

// 💡 预览模式：加上这个！
@Component
export struct HomePageContent {
  @Consume('pageStack') pageStack: NavPathStack;
  // 1. 轮播图数据
  private bannerList: Resource[] = [
    $r('app.media.banner1'),
    $r('app.media.banner2'),
    $r('app.media.banner3'),
    $r('app.media.banner4')
  ];
  // 原始数据 (假设有 15 个)
  @State rawGridItems: ShopTypeVO[] = [];
  // ✂️ 切分后的二维数组 (Swiper 的数据源)
  @State pagedGridItems: ShopTypeVO[][] = [];

  async aboutToAppear() {
    this.queryShopTypes();
  }

  async queryShopTypes() {
    // 👇 这里就是报错的地方 (Line 154)
    // 以前可能写了 throw new Error('Function not implemented') 或者调了空的 HttpUtil.get

    // ✅ 现在改成调用 Service
    const data = await HomeService.getShopTypes();

    if ( data.length > 0 ) {
      this.rawGridItems = data;
      // 切割数据！(按每页 10 个切分：2行 x 5列)
      this.pagedGridItems = chunkArray(this.rawGridItems, 10);
    } else {
      // 如果没拿到数据，可以塞点假数据兜底，防止页面空空的
      // this.entryList = [ ... mock data ... ]
    }
  }

  build() {
    Column() {
      // --- 1. 顶部搜索栏 (固定在顶部) ---
      this.TopSearchBar()

      // --- 2. 可滚动区域 ---
      Scroll() {
        Column({ space: 15 }) {

          // (1) 轮播图 Banner
          Swiper() {
            ForEach(this.bannerList, (img: Resource) => {
              Image(img)
                .width('100%')
                .height(160)
                .objectFit(ImageFit.Cover)
                .borderRadius(12)
                .onClick(() => {
                  this.pageStack.pushPath({ name: 'ShopPage' }, true)
                })
            })
          }
          .autoPlay(true)
          .interval(3000)
          .indicator(true) // 显示指示点
          .width('100%')
          .margin({ top: 10 })

          // 轮播翻页容器
          Swiper() {
            // 第一层循环：遍历“页”
            ForEach(this.pagedGridItems, (pageItems: ShopTypeVO[]) => {

              // 每一页是一个 Grid
              Grid() {
                // 第二层循环：遍历“页内的图标”
                ForEach(pageItems, (item: ShopTypeVO) => {
                  GridItem() {
                    Column({ space: 6 }) {
                      Image(item.icon)
                        .width(40).height(40)
                        .objectFit(ImageFit.Contain)
                      Text(item.name)
                        .fontSize(12)
                        .fontColor('#333333')
                    }
                  }
                }, (item: ShopTypeVO) => item.id.toString())
              }
              .columnsTemplate('1fr 1fr 1fr 1fr 1fr') // 5列
              .rowsTemplate('1fr 1fr') // 2行
              .rowsGap(1)
              .width('100%')
              .height('80%') // 占满 Swiper 给的高度

            })
          }
          .height(220) // Swiper 的总高度 (要容纳 Grid + 指示点)
          .autoPlay(false) // 菜单通常不自动轮播
          .loop(false) // 菜单通常不循环，滑到头就停
          .indicator( // 自定义指示点样式
            Indicator.dot()
              .itemWidth(8)
              .itemHeight(4)
              .selectedItemWidth(12)
              .selectedItemHeight(4)
              .color('#CCCCCC')
              .selectedColor('#0D9FFB') // 选中变蓝
          )
          .width('100%')

          // (4) 瀑布流/列表 (占位)
          // 这里以后可以放 List 或者 WaterFlow
          ForEach([ 1, 2, 3, 4, 5 ], (item: number) => {
            this.RecommendItem()
          })
        }
        .padding({ left: 12, right: 12, bottom: 20 }) // 给内容加点边距
      }
      .layoutWeight(1) // 占据剩余高度
      .scrollBar(BarState.Off) // 隐藏滚动条
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F6F6F6') // 浅灰底色，更有层次感
  }

  // 🎨 抽取：顶部搜索栏组件
  @Builder
  TopSearchBar() {
    Row({ space: 10 }) {
      // 定位
      Column() {
        Text('北京')
          .fontSize(14).fontWeight(FontWeight.Bold)
        Text('朝阳区...')
          .fontSize(10).fontColor('#666666')
      }

      // 搜索框 (伪装成输入框的按钮)
      Row() {
        Image($r('sys.symbol.magnifyingglass')) // 系统搜索图标
          .width(16).height(16).fillColor('#999999')
          .margin({ left: 10, right: 5 })
        Text('搜索美食、商家')
          .fontSize(12).fontColor('#999999')
      }
      .layoutWeight(1) // 撑满中间
      .height(36)
      .backgroundColor('#FFFFFF')
      .borderRadius(18)
      .onClick(() => {
        promptAction.showToast({ message: '去搜索页喵！' })
      })

      // 消息图标
      SymbolGlyph($r('sys.symbol.bell'))
        .fontSize(24)
        .fontColor([ '#333333' ])
    }
    .width('100%')
    .padding({
      left: 12,
      right: 12,
      top: 10,
      bottom: 10
    })
    .backgroundColor('#F6F6F6') // 与背景同色，或者白色
  }

  // 🎨 抽取：推荐商品卡片
  @Builder
  RecommendItem() {
    Row() {
      // 这里可以模仿之前写的 IndexListItemUI，左图右文
      Image($r('app.media.fig1'))
        .width(80).height(80).borderRadius(8)
        .margin({ right: 10 })
      Column() {
        Text('美味大汉堡').fontSize(16).fontWeight(FontWeight.Bold)
        Text('月售 1000+').fontSize(12).fontColor('#999999').margin({ top: 5 })
        Text('¥ 19.9').fontSize(16).fontColor('#FF0000').margin({ top: 10 })
      }.alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(10)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ bottom: 10 })
  }
}

/**
 * swiper 数据分组
 * @param source 源数组
 * @param size 每页大小 (比如 10)
 */
function chunkArray<T>(source: T[], size: number): T[][] {
  const result: T[][] = [];
  for ( let i = 0; i < source.length; i += size ) {
    result.push(source.slice(i, i + size));
  }
  return result;
}
