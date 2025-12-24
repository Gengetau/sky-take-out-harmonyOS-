import { AddressEditPage } from './AddressEditPage';

/**
 * 地址编辑路由页面
 * 接收路由参数 editId，并显示 AddressEditPage 组件
 */
@Component
export struct AddressEditRoutePage {
  @Consume('pageStack') pageStack: NavPathStack;
  @State editId: number = 0;

  aboutToAppear() {
    // 获取路由参数
    // NavPathStack 传递的参数通常在 pushPath 时指定
    // 这里需要一种方式获取当前页面的参数，但在 NavDestination 内部获取参数比较trick
    // 通常是在 build 中获取，或者通过 @Prop 传递？
    // 在 NavPathStack 模式下，参数并不直接注入到组件属性。
    // 我们需要通过栈顶元素获取？或者通过 LocalStorage?
    // 简单起见，我们假设外部调用时已经把参数传进来了（但这在 NavDestination 路由表中不适用）
    
    // 更稳妥的方式：
    // 使用 onReady 回调获取 NavDestinationContext，从中拿 pathInfo
    // 但 ArkTS API 比较新，我们尝试用标准做法：
    // 在 build 里的 NavDestination.onReady((context) => { ... })
  }

  build() {
    NavDestination() {
      AddressEditPage({
        editId: this.editId,
        onClose: () => {
          this.pageStack.pop();
        },
        onSaveSuccess: () => {
          // 保存成功，这里不需要 pop，因为 AddressEditPage 会在 onSaveSuccess 后调用 onClose
          // 列表页会在 onPageShow 时自动刷新
        }
      })
    }
    .hideTitleBar(true)
    .onReady((context: NavDestinationContext) => {
       // 获取参数
       const param = context.pathInfo.param as number;
       if (param !== undefined) {
         this.editId = param;
       }
    })
  }
}