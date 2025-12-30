package com.sky.config;


import com.sky.interceptor.JwtTokenAdminInterceptor;
import com.sky.interceptor.LoginInterceptor;
import com.sky.interceptor.RefenceTokenInterceptor;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import javax.annotation.Resource;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName MvcConfig
 * @Description mvc配置
 * @dateTime 5/11/2025 上午9:54
 */
@Configuration
public class MvcConfig implements WebMvcConfigurer {
	@Resource
	private StringRedisTemplate stringRedisTemplate;
	
	@Resource
	private JwtTokenAdminInterceptor jwtTokenAdminInterceptor;
	
	// 添加拦截器
	@Override
	public void addInterceptors(InterceptorRegistry registry) {
		// 拦截所有请求
		// order控制拦截器顺序
		registry.addInterceptor(new RefenceTokenInterceptor(stringRedisTemplate)).order(0);
		// 拦截部分请求
		registry.addInterceptor(new LoginInterceptor())
				.excludePathPatterns(
						"/client/user/**",
						"/admin/**",
						"/notify/**",
						"/ws/**").order(1);
		// 添加jwt令牌拦截器
		registry.addInterceptor(jwtTokenAdminInterceptor)
				.addPathPatterns("/admin/**")
				.excludePathPatterns("/admin/employee/login");
	}
}
