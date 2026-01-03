import { BusinessDataVO } from '../../model/ReportModel';
import { ReportService } from '../../service/ReportService';
import { promptAction } from '@kit.ArkUI';

/**
 * 简易折线图组件 (Pro版 - 字体加强适配)
 */
@Component
struct SimpleLineChart {
  @Prop @Watch('onDataChange') dateList: string[] = [];
  @Prop @Watch('onDataChange') valueList: number[] = [];
  @Prop lineColor: string = '#FFD700'; 
  @Prop title: string = '';

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  onDataChange() {
    this.drawChart();
  }

  build() {
    Column() {
      Text(this.title)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 10 })
        .width('100%')
      
      Canvas(this.context)
        .width('100%')
        .height(220) 
        .backgroundColor('#FAFAFA')
        .onReady(() => {
          this.drawChart();
        })
    }
    .padding(10)
    .backgroundColor(Color.White)
    .borderRadius(8)
    .margin({ top: 10 })
  }

  drawChart() {
    const ctx = this.context;
    const width = ctx.width;
    const height = ctx.height;
    
    // 🐾 增加左侧边距，容纳更大的文字
    const paddingLeft = 50; 
    const paddingRight = 20;
    const paddingTop = 20;
    const paddingBottom = 35;

    ctx.clearRect(0, 0, width, height);

    if (this.dateList.length === 0 || this.valueList.length === 0) return;

    let minData = Math.min(...this.valueList);
    let maxData = Math.max(...this.valueList);
    
    if (minData === maxData) {
      if (minData === 0) {
        maxData = 10;
      } else {
        minData = minData * 0.5;
        maxData = maxData * 1.5;
      }
    } else {
      const diff = maxData - minData;
      minData = Math.max(0, minData - diff * 0.1); 
      maxData = maxData + diff * 0.1;
    }
    
    const range = maxData - minData;

    // 2. 绘制 Y 轴
    const ySteps = 4; 
    ctx.lineWidth = 0.5;
    // 🐾 字体加大到 12px
    ctx.font = '12px sans-serif'; 
    ctx.fillStyle = '#666666'; // 颜色加深一点
    ctx.strokeStyle = '#EEEEEE';
    ctx.textAlign = 'right';
    ctx.textBaseline = 'middle';

    for (let i = 0; i <= ySteps; i++) {
      const value = minData + (range / ySteps) * i;
      const y = height - paddingBottom - (i / ySteps) * (height - paddingTop - paddingBottom);
      
      ctx.beginPath();
      ctx.moveTo(paddingLeft, y);
      ctx.lineTo(width - paddingRight, y);
      ctx.stroke();

      // 只保留整数或1位小数
      ctx.fillText(value.toFixed(value >= 100 ? 0 : 1), paddingLeft - 8, y);
    }

    // 3. 绘制 X 轴
    ctx.strokeStyle = '#CCCCCC';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(paddingLeft, height - paddingBottom);
    ctx.lineTo(width - paddingRight, height - paddingBottom);
    ctx.stroke();

    // 4. 绘制折线
    const stepX = (width - paddingLeft - paddingRight) / (this.dateList.length - 1 || 1);
    
    ctx.beginPath();
    ctx.lineWidth = 2.5; // 线稍微粗一点
    ctx.strokeStyle = this.lineColor;

    this.valueList.forEach((val, index) => {
      const x = paddingLeft + index * stepX;
      const y = height - paddingBottom - ((val - minData) / range) * (height - paddingTop - paddingBottom);
      if (index === 0) ctx.moveTo(x, y);
      else ctx.lineTo(x, y);
    });
    ctx.stroke();

    // 5. 绘制 X 轴标签
    ctx.fillStyle = '#666666';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'top';
    ctx.font = '12px sans-serif'; // 🐾 字体加大到 12px

    const labelWidth = 70; 
    const maxLabels = Math.floor((width - paddingLeft - paddingRight) / labelWidth);
    const interval = Math.ceil(this.dateList.length / maxLabels);

    this.dateList.forEach((date, index) => {
      if (index === 0 || index === this.dateList.length - 1 || index % interval === 0) {
        const x = paddingLeft + index * stepX;
        const shortDate = date.substring(5); 
        ctx.fillText(shortDate, x, height - paddingBottom + 8);
      }
    });

    // 6. 绘制圆点
    this.valueList.forEach((val, index) => {
      const x = paddingLeft + index * stepX;
      const y = height - paddingBottom - ((val - minData) / range) * (height - paddingTop - paddingBottom);
      ctx.beginPath();
      ctx.fillStyle = this.lineColor;
      ctx.arc(x, y, 4, 0, 6.28); 
      ctx.fill();
      ctx.lineWidth = 1.5;
      ctx.strokeStyle = '#FFFFFF';
      ctx.stroke();
    });
  }
}

/**
 * 数据项组件
 */
@Component
struct DataItemCard {
  @Prop title: string = '';
  @Prop value: string = '0';
  @Prop unit: string = '';

  build() {
    Column() {
      Text(this.title)
        .fontSize(12)
        .fontColor('#999999')
        .margin({ bottom: 4 })
      Row() {
        Text(this.value)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
        if (this.unit) {
          Text(this.unit)
            .fontSize(12)
            .fontColor('#333333')
            .margin({ top: 4, left: 2 })
        }
      }
    }
    .width('100%') 
    .height(80)
    .backgroundColor('#F9F9F9')
    .borderRadius(8)
    .justifyContent(FlexAlign.Center)
  }
}

@Component
export struct StatisticsContent {
  @State businessData: BusinessDataVO = {
    turnover: 0,
    validOrderCount: 0,
    orderCompletionRate: 0,
    unitPrice: 0,
    newUsers: 0
  };

  @State chartDates: string[] = [];
  @State chartValues: number[] = [];
  @State chartTitle: string = '营业额趋势';
  @State chartType: number = 0; 
  @State dateRangeIndex: number = 1; 
  @State isRefreshing: boolean = false;

  @StorageProp('RefreshStatistics') @Watch('onRefreshSignal') refreshSignal: number = 0;

  async aboutToAppear() {
    this.refreshAllData();
  }

  onRefreshSignal() {
    this.refreshAllData();
  }

  async refreshAllData() {
    if (this.isRefreshing) return;
    this.isRefreshing = true;
    try {
      await Promise.all([this.loadBusinessData(), this.loadChartData()]);
    } catch (e) {
      console.error('刷新失败', e);
    } finally {
      this.isRefreshing = false;
    }
  }

  async loadBusinessData() {
    try {
      const data = await ReportService.getBusinessData();
      this.businessData = data;
    } catch (e) {
      console.error('加载运营数据失败', e);
    }
  }

  getDateRange(): string[] {
    const end = new Date();
    end.setDate(end.getDate() - 1); 
    const begin = new Date(end);
    if (this.dateRangeIndex === 1) begin.setDate(end.getDate() - 6);
    else if (this.dateRangeIndex === 2) begin.setDate(end.getDate() - 29);

    const formatDate = (d: Date) => {
      return `${d.getFullYear()}-${(d.getMonth() + 1).toString().padStart(2, '0')}-${d.getDate().toString().padStart(2, '0')}`;
    };
    return [formatDate(begin), formatDate(end)];
  }

  async loadChartData() {
    const dates = this.getDateRange();
    try {
      if (this.chartType === 0) {
        this.chartTitle = '营业额趋势 (元)';
        const res = await ReportService.getTurnoverStatistics(dates[0], dates[1]);
        this.chartDates = res.dateList.split(',');
        this.chartValues = res.turnoverList.split(',').map(Number);
      } else {
        this.chartTitle = '有效订单趋势 (单)';
        const res = await ReportService.getOrderStatistics(dates[0], dates[1]);
        this.chartDates = res.dateList.split(',');
        this.chartValues = res.validOrderCountList.split(',').map(Number);
      }
    } catch (e) {
      console.error('加载图表数据失败', e);
    }
  }

  build() {
    Column() {
      // 1. 标题栏
      Row() {
        Text('数据中心').fontSize(20).fontWeight(FontWeight.Bold)
        Blank() 
        if (this.isRefreshing) {
          LoadingProgress().width(24).height(24).color($r('app.color.theme_color'))
        } else {
          Button({ type: ButtonType.Circle, stateEffect: true }) {
            Text('↻').fontSize(20).fontColor('#333333').fontWeight(FontWeight.Bold).textAlign(TextAlign.Center)
          }
          .width(32).height(32).backgroundColor('#F0F0F0')
          .onClick(() => { this.refreshAllData(); })
        }
      }
      .width('100%').padding(16).backgroundColor(Color.White)

      Scroll() {
        Column() {
          Text('今日数据概览').fontSize(16).fontWeight(FontWeight.Bold).width('100%').margin({ top: 10, bottom: 10, left: 16 })
          
          Grid() {
            GridItem() { 
              DataItemCard({ title: '营业额', value: this.businessData.turnover.toString(), unit: '元' }) 
            }
            GridItem() { 
              DataItemCard({ title: '有效订单', value: this.businessData.validOrderCount.toString(), unit: '单' }) 
            }
            GridItem() { 
              DataItemCard({ title: '订单完成率', value: (this.businessData.orderCompletionRate * 100).toFixed(0), unit: '%' }) 
            }
            GridItem() { 
              // 🐾 修复客单价保留两位小数
              DataItemCard({ title: '平均客单价', value: this.businessData.unitPrice.toFixed(2), unit: '元' }) 
            }
          }
          .columnsTemplate('1fr 1fr') 
          .columnsGap(10).rowsGap(10).padding({ left: 16, right: 16 }).height(180) 

          Divider().color('#EEEEEE').strokeWidth(8).margin({ top: 20, bottom: 20 })

          Column() {
            Row() {
              Button('营业额')
                .type(ButtonType.Normal)
                .backgroundColor(this.chartType === 0 ? $r('app.color.theme_color') : '#F0F0F0')
                .fontColor(this.chartType === 0 ? Color.Black : '#666666')
                .borderRadius(16).height(30)
                .onClick(() => { this.chartType = 0; this.loadChartData(); })
              
              Button('订单数')
                .type(ButtonType.Normal)
                .backgroundColor(this.chartType === 1 ? $r('app.color.theme_color') : '#F0F0F0')
                .fontColor(this.chartType === 1 ? Color.Black : '#666666')
                .borderRadius(16).height(30).margin({ left: 10 })
                .onClick(() => { this.chartType = 1; this.loadChartData(); })
            }
            .width('100%').justifyContent(FlexAlign.Start).margin({ bottom: 10 })

            Row() {
              Text('昨日').fontSize(12).fontColor(this.dateRangeIndex === 0 ? $r('app.color.theme_color') : '#999999').onClick(() => { this.dateRangeIndex = 0; this.loadChartData(); }).padding(5)
              Text('近7天').fontSize(12).fontColor(this.dateRangeIndex === 1 ? $r('app.color.theme_color') : '#999999').onClick(() => { this.dateRangeIndex = 1; this.loadChartData(); }).padding(5).margin({ left: 10 })
              Text('近30天').fontSize(12).fontColor(this.dateRangeIndex === 2 ? $r('app.color.theme_color') : '#999999').onClick(() => { this.dateRangeIndex = 2; this.loadChartData(); }).padding(5).margin({ left: 10 })
            }
            .width('100%').justifyContent(FlexAlign.End).margin({ bottom: 10 })

            if (this.chartValues.length > 0) {
              SimpleLineChart({
                dateList: this.chartDates,
                valueList: this.chartValues,
                title: this.chartTitle,
                lineColor: this.chartType === 0 ? '#FFD700' : '#007DFF'
              })
            } else {
              Text('暂无趋势数据喵').fontSize(14).fontColor('#999999').margin({ top: 50 })
            }
          }
          .padding(16).backgroundColor(Color.White)
        }
      }
      .layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor(Color.White)
  }
}