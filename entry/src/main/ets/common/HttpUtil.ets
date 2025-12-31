/**
 * HttpUtil,封装RCP工具类
 */

import { rcp } from '@kit.RemoteCommunicationKit';
import { Result } from '../model/ResultModel';
import { promptAction } from '@kit.ArkUI';

// TODO: 如果真机调试，请修改为电脑的局域网IP；模拟器通常可以使用 127.0.0.1 或宿主IP
const BASE_URL = 'http://192.168.0.210:8080'; 
const TIMEOUT = 5000;

/**
 * 拦截器，负责给请求头加上 token
 */
class TokenInterceptor implements rcp.Interceptor {
  async intercept(context: rcp.RequestContext, next: rcp.RequestHandler): Promise<rcp.Response> {
    const token = AppStorage.get<string>('token');
    if (token) {
      if (!context.request.headers) {
        context.request.headers = {};
      }
      context.request.headers['authentication'] = token;
    }
    return next.handle(context);
  }
}

class LogInterceptor implements rcp.Interceptor {
  async intercept(context: rcp.RequestContext, next: rcp.RequestHandler): Promise<rcp.Response> {
    console.info(`喵！[Request] URL: ${context.request.url.href}`);
    console.info(`喵！[Request] Method: ${context.request.method}`);
    const response = await next.handle(context);
    console.info(`喵！[Response] Code: ${response.statusCode}`);
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
    try {
      const resp = await HttpUtil.session!.post(url, data);
      return HttpUtil.handleResponse<T>(resp);
    } catch (err) {
      return HttpUtil.handleError(err);
    }
  }

  static async get<T>(url: string): Promise<T> {
    HttpUtil.init();
    try {
      const resp = await HttpUtil.session!.get(url);
      return HttpUtil.handleResponse<T>(resp);
    } catch (err) {
      return HttpUtil.handleError(err);
    }
  }

  static async put<T>(url: string, data?: object): Promise<T> {
    HttpUtil.init();
    try {
      const resp = await HttpUtil.session!.put(url, data);
      return HttpUtil.handleResponse<T>(resp);
    } catch (err) {
      return HttpUtil.handleError(err);
    }
  }

  static async delete<T>(url: string): Promise<T> {
    HttpUtil.init();
    try {
      const resp = await HttpUtil.session!.delete(url);
      return HttpUtil.handleResponse<T>(resp);
    } catch (err) {
      return HttpUtil.handleError(err);
    }
  }

  private static handleResponse<T>(resp: rcp.Response): Promise<T> {
    if (resp.statusCode !== 200) {
      return Promise.reject(`HTTP Error: ${resp.statusCode}`);
    }
    // 自动推断 JSON
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
    // 使用 promptAction 显示 Toast
    try {
       if (HttpUtil.uiContext) {
         HttpUtil.uiContext.getPromptAction().showToast({ message: msg });
       } else {
         promptAction.showToast({ message: msg });
       }
    } catch (e) {
      console.error('Failed to show toast:', e);
    }
    
    return Promise.reject(msg);
  }
}
