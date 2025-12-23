/**
 * 送达时间生成器
 * 负责生成 "今天"、"明天" 以及对应的时间段 喵！
 */
export class TimeGenerator {

  /**
   * 获取送达时间列表
   * @param startHour 营业开始时间 (默认9点)
   * @param endHour 营业结束时间 (默认23点)
   */
  static getDeliveryTimes(startHour: number = 9, endHour: number = 23): DateGroup[] {
    const groups: DateGroup[] = [];
    const now = new Date();
    const currentHour = now.getHours();
    const currentMinute = now.getMinutes();

    // --- 1. 生成 "今天" 的时间段 ---
    const todayTimes: string[] = [];
    
    // 如果还没过营业时间
    if (currentHour < endHour) {
      // 如果当前时间在营业时间内，先加一个 "立即送出"
      if (currentHour >= startHour) {
        todayTimes.push('立即送出');
      }

      // 从当前时间往后推，生成每30分钟的时间段
      // 逻辑：从 startHour 开始遍历到 endHour
      const currentTotalMinutes = currentHour * 60 + currentMinute;
      // 预约起始时间：立即送达结束(60m) + 30m = 90m
      // 取整时：向上取整到下一小时
      const thresholdRaw = currentTotalMinutes + 90;
      const thresholdRounded = Math.ceil(thresholdRaw / 60) * 60;

      for (let h = startHour; h <= endHour; h++) {
        // 生成两个槽位: xx:00-xx:30 和 xx:30-xx+1:00
        const slot1Start = h * 60; // 分钟数
        const slot1End = h * 60 + 30;
        
        const slot2Start = h * 60 + 30;
        const slot2End = (h + 1) * 60;

        // 槽位1
        if (slot1Start >= thresholdRounded) {
           todayTimes.push(`${pad(h)}:00-${pad(h)}:30`);
        }
        // 槽位2 (注意跨天处理，这里简化不跨天)
        if (slot2Start >= thresholdRounded && h < endHour) { // 23:30-24:00 通常不算营业时间? 假设到23:00关门
           todayTimes.push(`${pad(h)}:30-${pad(h+1)}:00`);
        }
      }
    }

    if (todayTimes.length > 0) {
      groups.push({ date: '今天', times: todayTimes });
    }

    // --- 2. 生成 "明天" 的时间段 ---
    const tomorrowTimes: string[] = [];
    for (let h = startHour; h < endHour; h++) {
      tomorrowTimes.push(`${pad(h)}:00-${pad(h)}:30`);
      tomorrowTimes.push(`${pad(h)}:30-${pad(h+1)}:00`);
    }
    groups.push({ date: '明天', times: tomorrowTimes });

    return groups;
  }

  /**
   * 获取“立即送出”的动态时间范围（下单后45分钟-1小时）喵
   */
  static getImmediateDeliveryTime(): string {
    const now = new Date();
    const start = new Date(now.getTime() + 45 * 60 * 1000);
    const end = new Date(now.getTime() + 60 * 60 * 1000);

    const startTimeStr = `${pad(start.getHours())}:${pad(start.getMinutes())}`;
    const endTimeStr = `${pad(end.getHours())}:${pad(end.getMinutes())}`;

    return `立即送出 (约${startTimeStr}-${endTimeStr}送达)`;
  }
}

// 补零函数
function pad(n: number): string {
  return n.toString().padStart(2, '0');
}

export interface DateGroup {
  date: string;
  times: string[];
}
