/**
 * HttpUtil,封装RCP工具类 (全RCP版，上传功能使用Buffer+MultipartForm)
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
    const token = AppStorage.get<string>('token');
    if ( token ) {
      if (!context.request.headers ) {
        context.request.headers = {};
      }
      context.request.headers['authentication'] = token;
    }
    return next.handle(context);
  }
}

class LogInterceptor implements rcp.Interceptor {
  async intercept(context: rcp.RequestContext, next: rcp.RequestHandler): Promise<rcp.Response> {
    console.info(`喵！[Request] URL: ${ context.request.url.href }`);
    console.info(`喵！[Request] Method: ${ context.request.method }`);
    const response = await next.handle(context);
    console.info(`喵！[Response] Code: ${ response.statusCode }`);
    return response;
  }
}

/**
 * 全局Http工具
 */
export class HttpUtil {
  private static session: rcp.Session | null = null;
  private static uiContext: UIContext | null = null;

  static setContext(context: UIContext) {
    HttpUtil.uiContext = context;
  }

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
      const resp = await HttpUtil.session!.post(url, data);
      return HttpUtil.handleResponse<T>(resp);
    } catch ( err ) {
      return HttpUtil.handleError(err);
    }
  }

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
   * 📤 上传文件 (RCP 官方推荐自定义方式)
   * 根据 API 11+ 文档，对于需要指定字段名的 MultipartForm 上传：
   * 1. 使用 rcp.MultipartForm 包装数据。
   * 2. 对于文件字段，contentOrPath 属性可以直接接受文件路径字符串。
   */
  static async upload<T>(url: string, fileUri: string): Promise<T> {
    // ⚠️ 使用临时 Session，避免全局 Session 的 'Content-Type': 'application/json' 干扰 boundary 生成
    const uploadSession = rcp.createSession({
      baseAddress: BASE_URL,
      interceptors: [ new TokenInterceptor(), new LogInterceptor() ]
    });

    try {
      const req = new rcp.Request(BASE_URL + url, 'POST');

      // 构造多部分表单
      // 根据类型定义：FormFieldFileValue 包含 contentOrPath 属性，它接受 string 类型（文件路径）
      const form = new rcp.MultipartForm({
        'file': {
          contentOrPath: fileUri
        }
      });

      req.content = form;

      // RCP 会自动设置 Content-Type 为 multipart/form-data 并生成随机 boundary
      const resp = await uploadSession.fetch(req);

      return HttpUtil.handleResponse<T>(resp);
    } catch ( err ) {
      return HttpUtil.handleError(err);
    } finally {
      uploadSession.close();
    }
  }

  private static handleResponse<T>(resp: rcp.Response): Promise<T> {
    if ( resp.statusCode !== 200 ) {
      return Promise.reject(`HTTP Error: ${ resp.statusCode }`);
    }
    const result = resp.toJSON() as Result<T>;
    if ( result.code === 1 ) {
      return Promise.resolve(result.data);
    } else {
      const errorMsg = result.msg || '未知错误';
      HttpUtil.handleError(errorMsg);
      return Promise.reject(errorMsg);
    }
  }

  private static handleError(err: Object): Promise<never> {
    let msg = '网络开小差了';
    if ( typeof err === 'string' ) {
      msg = err;
    }

    console.error(`[HttpUtil] Error: ${ msg }`);
    if ( HttpUtil.uiContext ) {
      HttpUtil.uiContext.getPromptAction().showToast({ message: msg });
    }
    return Promise.reject(msg);
  }
}
