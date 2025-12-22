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
      for (let h = startHour; h <= endHour; h++) {
        // 如果是过去的时间，跳过 (保留缓冲期? 比如现在 12:10，那 12:00-12:30 就不显示了，从 12:30-13:00 开始)
        // 简单逻辑：只显示当前时间 + 30分钟 之后的时间段
        
        // 生成两个槽位: xx:00-xx:30 和 xx:30-xx+1:00
        const slot1Start = h * 60; // 分钟数
        const slot1End = h * 60 + 30;
        
        const slot2Start = h * 60 + 30;
        const slot2End = (h + 1) * 60;

        const currentTotalMinutes = currentHour * 60 + currentMinute;

        // 槽位1
        if (slot1Start > currentTotalMinutes) {
           todayTimes.push(`${pad(h)}:00-${pad(h)}:30`);
        }
        // 槽位2 (注意跨天处理，这里简化不跨天)
        if (slot2Start > currentTotalMinutes && h < endHour) { // 23:30-24:00 通常不算营业时间? 假设到23:00关门
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
}

// 补零函数
function pad(n: number): string {
  return n.toString().padStart(2, '0');
}

export interface DateGroup {
  date: string;
  times: string[];
}
