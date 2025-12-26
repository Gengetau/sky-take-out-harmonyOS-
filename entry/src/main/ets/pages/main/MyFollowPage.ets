import { FollowItem } from '../../common/utils/FollowRdb';
import { ShopService } from '../../service/ShopService';

@Component
export struct MyFollowPage {
  @Consume('pageStack') pageStack: NavPathStack;
  @State followList: FollowItem[] = [];
  @State isLoading: boolean = true;

  async aboutToAppear() {
    this.loadData();
  }

  async loadData() {
    this.isLoading = true;
    try {
      this.followList = await ShopService.getFollowList();
    } catch (err) {
      console.error('加载关注列表失败喵', err);
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    NavDestination() {
      Column() {
        if (this.isLoading) {
          LoadingProgress().width(50).height(50).margin({ top: 50 })
        } else if (this.followList.length === 0) {
          Column({ space: 10 }) {
            SymbolGlyph($r('sys.symbol.heart_slash'))
              .fontSize(60)
              .fontColor(['#DDD'])
            Text('还没有关注任何店铺喵~')
              .fontSize(14)
              .fontColor('#999')
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        } else {
          List({ space: 12 }) {
            ForEach(this.followList, (item: FollowItem) => {
              ListItem() {
                Row() {
                  Image(item.avatar || $r('app.media.shop_logo'))
                    .width(60)
                    .height(60)
                    .borderRadius(8)
                    .objectFit(ImageFit.Cover)
                    .backgroundColor('#f0f0f0')
                    .margin({ right: 12 })

                  Column() {
                    Text(item.name)
                      .fontSize(16)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#333')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    
                    Text('已关注')
                      .fontSize(12)
                      .fontColor('#FF3B30')
                      .backgroundColor('#FFF0F0')
                      .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                      .borderRadius(4)
                      .margin({ top: 6 })
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)

                  SymbolGlyph($r('sys.symbol.chevron_right'))
                    .fontSize(20)
                    .fontColor(['#CCC'])
                }
                .width('100%')
                .padding(12)
                .backgroundColor(Color.White)
                .borderRadius(12)
                .onClick(() => {
                  // 跳转到店铺详情
                  if (item.shopId) {
                    this.pageStack.pushPath({ name: 'ShopPage', param: item.shopId });
                  }
                })
              }
            })
          }
          .width('100%')
          .height('100%')
          .padding(12)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')
    }
    .title('我的关注')
    .hideTitleBar(false)
  }
}