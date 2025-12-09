package com.sky.interceptor;

import com.sky.vo.UserHolder;
import org.springframework.web.servlet.HandlerInterceptor;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName LoginInterceptor
 * @Description 登录拦截器
 * @dateTime 5/11/2025 上午9:44
 */
public class LoginInterceptor implements HandlerInterceptor {
	
	// 前置拦截器
	@Override
	public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
		// 1.判断是否需要拦截
		if (UserHolder.getUser() == null) {
			// 没有，需要拦截，
			response.setStatus(401);
			return false;
		}
		// 2.有用户，则放行
		return true;
	}
	
	// 后置拦截器
	@Override
	public void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) throws Exception {
		// 移除用户
		UserHolder.removeUser();
	}
}
