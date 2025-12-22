/**
 * HttpUtil,封装RCP工具类
 */

import { rcp } from '@kit.RemoteCommunicationKit';
import { Result } from '../../model/api/ResultModel';

const BASE_URL = 'http://192.168.0.210:8080'; // 后端springBoot地址
const TIMEOUT = 5000; // 超时时间

/**
 * 拦截器，负责给请求头加上 token
 */
class TokenInterceptor implements rcp.Interceptor {
  async intercept(context: rcp.RequestContext, next: rcp.RequestHandler): Promise<rcp.Response> {
    // 从 AppStorage 获取 token
    const token = AppStorage.get<string>('token');

    if ( token ) {
      if (!context.request.headers ) {
        context.request.headers = {}; // 如果没有，就初始化一个空对象
      }
      context.request.headers['authentication'] = token;
    }

    // 放行，继续请求
    return next.handle(context);
  }
}

class LogInterceptor implements rcp.Interceptor {
  async intercept(context: rcp.RequestContext, next: rcp.RequestHandler): Promise<rcp.Response> {
    // 🟢 1. 打印请求信息
    console.info(`喵！[Request] URL: ${ context.request.url.href }`);
    console.info(`喵！[Request] Method: ${ context.request.method }`);

    // 📦 2. 偷看请求体 (Body)
    const content = context.request.content;
    if ( content ) {
      // 如果是字符串或对象，尝试转 JSON 打印
      try {
        console.info(`喵！[Request Body]: ${ JSON.stringify(content) }`);
      } catch ( e ) {
        // 如果是二进制流 (ArrayBuffer) 或者其他复杂类型，可能无法直接 stringify
        console.info(`喵！[Request Body]: (Binary or Complex Data) ${ content }`);
      }
    } else {
      console.info(`喵！[Request Body]: (Empty)`);
    }

    // 👉 3. 放行，让请求继续
    const response = await next.handle(context);

    // 🔵 4. 顺便打印一下响应状态
    console.info(`喵！[Response] Code: ${ response.statusCode }`);

    // 如果想看响应内容，也可以在这里打印 response.toString()
    // 但要注意：如果在这里读取了响应流，可能会导致后面业务层读不到，RCP 处理这个比较智能，通常没问题。

    return response;
  }
}

/**
 * 全局Http工具
 */
export class HttpUtil {
  // 单例 session
  private static session: rcp.Session | null = null;
  private static uiContext: UIContext | null = null;

  // 2. 新增：提供一个方法让外部把 Context 传进来
  static setContext(context: UIContext) {
    HttpUtil.uiContext = context;
  }

  // 初始化session
  private static init() {
    if ( HttpUtil.session === null ) {
      HttpUtil.session = rcp.createSession({
        baseAddress: BASE_URL,
        headers: {
          'Content-Type': 'application/json'
        },
        interceptors: [ new TokenInterceptor(), new LogInterceptor() ]
      });
    }
  }

  static async post<T>(url: string, data?: object): Promise<T> {
    HttpUtil.init();

    try {
      // 发起请求
      const resp = await HttpUtil.session!.post(url, data);

      // 处理响应
      return HttpUtil.handleResponse<T>(resp);
    } catch ( err ) {
      return HttpUtil.handleError(err);
    }
  }

  /**
   *  通用 GET 请求
   */
  static async get<T>(url: string): Promise<T> {
    HttpUtil.init();
    try {
      const resp = await HttpUtil.session!.get(url);
      return HttpUtil.handleResponse<T>(resp);
    } catch ( err ) {
      return HttpUtil.handleError(err);
    }
  }

  static async put<T>(url: string, data?: object): Promise<T> {
    HttpUtil.init();
    try {
      const resp = await HttpUtil.session!.put(url, data);
      return HttpUtil.handleResponse<T>(resp);
    } catch ( err ) {
      return HttpUtil.handleError(err);
    }
  }

  static async delete<T>(url: string): Promise<T> {
    HttpUtil.init();
    try {
      const resp = await HttpUtil.session!.delete(url);
      return HttpUtil.handleResponse<T>(resp);
    } catch ( err ) {
      return HttpUtil.handleError(err);
    }
  }

  /**
   *  核心逻辑：统一处理后端返回的结果
   */
  private static handleResponse<T>(resp: rcp.Response): Promise<T> {
    // 1. 检查 HTTP 状态码 (200 OK)
    if ( resp.statusCode !== 200 ) {
      return Promise.reject(`HTTP Error: ${ resp.statusCode }`);
    }

    // 2. 解析 JSON 数据
    // 苍穹外卖的结构: { code: 1, msg: "...", data: ... }
    const result = resp.toJSON() as Result<T>;

    // 3. 业务逻辑判断
    if ( result.code === 1 ) {
      //  成功！直接把 data 剥离出来返回给 UI，方便！
      return Promise.resolve(result.data);
    } else {
      //  业务失败 (比如密码错误)
      const errorMsg = result.msg || '未知错误';

      // 全局弹窗报错 (省得每个页面都写)
      HttpUtil.handleError(errorMsg);

      // 如果是 Token 过期 (比如 code === 0 && msg === 'NOT_LOGIN')
      if ( errorMsg === 'NOT_LOGIN' ) {
        // TODO: 这里可以加跳转回登录页的逻辑
      }

      return Promise.reject(errorMsg);
    }
  }

  /**
   * 🛡️ 统一处理网络层面的异常
   */
  private static handleError(err: Object): Promise<never> {
    let msg = '网络开小差了';
    let error = err as BusinessError;
    // 然后判断它是不是真的有 code 属性
    if ( error && error.code !== undefined ) {
      // 说明它确实是 BusinessError (比如 RCP 抛出的 404, 500 等)
      msg = `请求异常: ${ error.message } (Code: ${ error.code })`;
    } else if ( err instanceof Error ) {
      // 普通的 JS Error
      msg = err.message;
    } else {
      // 其他奇怪的错误 (比如直接抛出一个字符串)
      msg = String(err);
    }

    console.error(`[HttpUtil] Error: ${ msg }`);

    // 使用注入的 Context 弹窗
    if ( HttpUtil.uiContext ) {
      HttpUtil.uiContext.getPromptAction().showToast({
        message: msg
      });
    }

    // 返回一个失败的 Promise
    return Promise.reject(msg);
  }
}

