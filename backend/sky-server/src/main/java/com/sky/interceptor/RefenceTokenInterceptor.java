package com.sky.interceptor;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.util.StrUtil;
import com.sky.vo.UserHolder;
import com.sky.vo.UserLoginVO;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.web.servlet.HandlerInterceptor;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.util.Map;
import java.util.concurrent.TimeUnit;

import static com.sky.constant.RedisConstants.LOGIN_USER_KEY;
import static com.sky.constant.RedisConstants.LOGIN_USER_TTL;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName LoginInterceptor
 * @Description 令牌拦截器
 * @dateTime 5/11/2025 上午9:44
 */
public class RefenceTokenInterceptor implements HandlerInterceptor {
	private StringRedisTemplate stringRedisTemplate;
	
	public RefenceTokenInterceptor(StringRedisTemplate stringRedisTemplate) {
		this.stringRedisTemplate = stringRedisTemplate;
	}
	
	// 前置拦截器
	@Override
	public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
		// 1.获取请求头中的token
		// String token = request.getHeader("authorization"); // web端
		String token = request.getHeader("authentication");// 鸿蒙
		if (StrUtil.isBlank(token)) {
			return true;
		}
		// 2.获取redis中的用户
		String key = LOGIN_USER_KEY + token;
		Map<Object, Object> userMap = stringRedisTemplate.opsForHash().entries(key);
		// 3.判断用户是否存在
		if (userMap.isEmpty()) {
			return true;
		}
		// 4.将查询到的Hash数据转为UserVO对象
		UserLoginVO userVO = BeanUtil.fillBeanWithMap(userMap, new UserLoginVO(), false);
		
		// 5.保存用户信息到ThreadLocal
		if (userMap.isEmpty()) {
			return true;
		}
		UserHolder.saveUser(userVO);
		
		// 6.刷新token有效期
		stringRedisTemplate.expire(key, LOGIN_USER_TTL, TimeUnit.MINUTES);
		
		// 7.放行
		return true;
	}
	
	// 后置拦截器
	@Override
	public void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) throws Exception {
		// 移除用户
		UserHolder.removeUser();
	}
}
