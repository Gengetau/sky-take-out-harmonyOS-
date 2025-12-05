/**
 * 资源映射工具
 */
export const LocalImageMap: Record<string, Resource> = {
  'fig1': $r('app.media.fig1'),
  'fig2': $r('app.media.fig2'),
  'fig3': $r('app.media.fig3'),
  'fig4': $r('app.media.fig4'),
  'fig5': $r('app.media.fig5'),
  'fig6': $r('app.media.fig6'),
  'fig7': $r('app.media.fig7'),
  'fig8': $r('app.media.fig8'),
  'fig9': $r('app.media.fig9'),
  'fig10': $r('app.media.fig10'),
  'fig11': $r('app.media.fig11'),
  'fig12': $r('app.media.fig12'),
  'fig13': $r('app.media.fig13'),
  'fig14': $r('app.media.fig14'),
  'fig15': $r('app.media.fig15'),

  'dish_1': $r('app.media.dish_1'),
  'dish_2': $r('app.media.dish_2'),
  'dish_3': $r('app.media.dish_3'),
  'dish_4': $r('app.media.dish_4'),
  'dish_5': $r('app.media.dish_5'),
  'dish_6': $r('app.media.dish_6'),
  'dish_7': $r('app.media.dish_7'),
  'dish_8': $r('app.media.dish_8'),
  'dish_9': $r('app.media.dish_9'),
  'dish_10': $r('app.media.dish_10'),
  'dish_11': $r('app.media.dish_11'),
  'dish_12': $r('app.media.dish_12'),
  'dish_13': $r('app.media.dish_13'),
  'dish_14': $r('app.media.dish_14'),
  'dish_15': $r('app.media.dish_15'),
  'dish_16': $r('app.media.dish_16'),
  'dish_17': $r('app.media.dish_17'),
  'dish_18': $r('app.media.dish_18'),
  'dish_19': $r('app.media.dish_19'),
  'dish_20': $r('app.media.dish_20'),
  'dish_21': $r('app.media.dish_21'),
  'dish_22': $r('app.media.dish_22'),
  'dish_23': $r('app.media.dish_23'),
  'dish_24': $r('app.media.dish_24'),
  'dish_25': $r('app.media.dish_25'),
  'dish_26': $r('app.media.dish_26'),
  'dish_27': $r('app.media.dish_27'),

  // ... 把所有可能会用到的图都登记在这里
  'default': $r('app.media.logo') // 兜底图
};

/**
 * 翻译函数：给它字符串，它还你资源对象
 */
export function getLocalImage(name: string): Resource {
  if (LocalImageMap[name]) {
    return LocalImageMap[name];
  }
  return LocalImageMap['default']; // 找不到就返回默认图
}