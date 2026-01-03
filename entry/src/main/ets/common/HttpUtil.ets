/**
 * HttpUtil,封装RCP工具类
 */

import { rcp } from '@kit.RemoteCommunicationKit';
import { Result } from '../model/ResultModel';
import { promptAction } from '@kit.ArkUI';

// TODO: 如果真机调试，请修改为电脑的局域网IP
const BASE_URL = 'http://192.168.0.210:8080/admin/app/'; 
const TIMEOUT = 10000;

/**
 * 拦截器，负责给请求头加上 token
 */
class TokenInterceptor implements rcp.Interceptor {
  async intercept(context: rcp.RequestContext, next: rcp.RequestHandler): Promise<rcp.Response> {
    const token = AppStorage.get<string>('token');
    
    // 🐾 调试日志：检查拦截器是否拿到了 Token
    if (token) {
      console.info('喵！[TokenInterceptor] 发现 Token，准备注入 Header');
      if (!context.request.headers) {
        context.request.headers = {};
      }
      // 强制转型以确保能设置属性
      (context.request.headers as Record<string, string | string[]> )['token'] = token;
    } else {
      console.warn('喵！[TokenInterceptor] 未发现 Token，本次请求可能报错 401');
    }
    
    return next.handle(context);
  }
}

class LogInterceptor implements rcp.Interceptor {
  async intercept(context: rcp.RequestContext, next: rcp.RequestHandler): Promise<rcp.Response> {
    console.info(`喵！[Request] URL: ${context.request.url.href}`);
    const response = await next.handle(context);
    console.info(`喵！[Response] Code: ${response.statusCode} URL: ${context.request.url.href}`);
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
    if (HttpUtil.session === null) {
      HttpUtil.session = rcp.createSession({
        baseAddress: BASE_URL,
        headers: {
          'Content-Type': 'application/json'
        },
        interceptors: [new TokenInterceptor(), new LogInterceptor()],
        requestConfiguration: {
          transfer: {
            timeout: {
              connectMs: TIMEOUT,
              transferMs: TIMEOUT
            }
          }
        }
      });
    }
  }

  static async post<T>(url: string, data?: object): Promise<T> {
    HttpUtil.init();
    if (url.startsWith('/')) {
      url = url.substring(1);
    }
    try {
      const resp = await HttpUtil.session!.post(url, data);
      return HttpUtil.handleResponse<T>(resp);
    } catch (err) {
      return HttpUtil.handleError(err);
    }
  }

  static async get<T>(url: string): Promise<T> {
    HttpUtil.init();
    if (url.startsWith('/')) {
      url = url.substring(1);
    }
    try {
      const resp = await HttpUtil.session!.get(url);
      return HttpUtil.handleResponse<T>(resp);
    } catch (err) {
      return HttpUtil.handleError(err);
    }
  }

  static async put<T>(url: string, data?: object): Promise<T> {
    HttpUtil.init();
    if (url.startsWith('/')) {
      url = url.substring(1);
    }
    try {
      const resp = await HttpUtil.session!.put(url, data);
      return HttpUtil.handleResponse<T>(resp);
    } catch (err) {
      return HttpUtil.handleError(err);
    }
  }

  static async delete<T>(url: string): Promise<T> {
    HttpUtil.init();
    if (url.startsWith('/')) {
      url = url.substring(1);
    }
    try {
      const resp = await HttpUtil.session!.delete(url);
      return HttpUtil.handleResponse<T>(resp);
    } catch (err) {
      return HttpUtil.handleError(err);
    }
  }

  /**
   * 📤 上传文件 (已经补回来啦喵！)
   * @param url 相对路径，例如 '/common/upload'
   * @param fileUri 文件本地路径
   */
  static async upload<T>(url: string, fileUri: string): Promise<T> {
    const uploadSession = rcp.createSession({
      baseAddress: BASE_URL,
      interceptors: [new TokenInterceptor(), new LogInterceptor()]
    });

    try {
      if (url.startsWith('/')) {
        url = url.substring(1);
      }
      
      const req = new rcp.Request(BASE_URL + url, 'POST');
      const form = new rcp.MultipartForm({
        'file': {
          contentOrPath: fileUri
        }
      });

      req.content = form;
      const resp = await uploadSession.fetch(req);
      return HttpUtil.handleResponse<T>(resp);
    } catch (err) {
      return HttpUtil.handleError(err);
    } finally {
      uploadSession.close();
    }
  }

  private static handleResponse<T>(resp: rcp.Response): Promise<T> {
    if (resp.statusCode !== 200) {
      try {
        const errBody = resp.toString();
        console.error(`喵！[HttpUtil] 非200响应详情: ${errBody}`);
      } catch (e) {}
      return Promise.reject(`HTTP Error: ${resp.statusCode}`);
    }
    
    const result = resp.toJSON() as Result<T>;
    if (result.code === 1) {
      return Promise.resolve(result.data);
    } else {
      const errorMsg = result.msg || '未知错误';
      HttpUtil.handleError(errorMsg);
      return Promise.reject(errorMsg);
    }
  }

  private static handleError(err: Object): Promise<never> {
    let msg = '网络开小差了喵';
    if (typeof err === 'string') {
      msg = err;
    } else if (err instanceof Error) {
      msg = err.message;
    }

    console.error(`[HttpUtil] Error: ${msg}`);
    try {
       if (HttpUtil.uiContext) {
         HttpUtil.uiContext.getPromptAction().showToast({ message: msg });
       } else {
         promptAction.showToast({ message: msg });
       }
    } catch (e) {}
    
    return Promise.reject(msg);
  }
}
