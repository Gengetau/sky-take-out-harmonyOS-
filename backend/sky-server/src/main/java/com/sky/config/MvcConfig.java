package com.sky.config;


import com.sky.interceptor.JwtTokenAdminInterceptor;
import com.sky.interceptor.JwtTokenAppInterceptor;
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

	@Resource
	private JwtTokenAppInterceptor jwtTokenAppInterceptor;
	
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
		// 添加jwt令牌拦截器 (Web管理后台)
		registry.addInterceptor(jwtTokenAdminInterceptor)
				.addPathPatterns("/admin/**")
				.excludePathPatterns("/admin/employee/login",
						"/admin/shop/preheat",
						"/admin/common/batchUpload",
						"/admin/app/**"); // 关键：排除App端路径

		// 添加商家App端jwt令牌拦截器
		registry.addInterceptor(jwtTokenAppInterceptor)
				.addPathPatterns("/admin/app/**")
				.excludePathPatterns("/admin/app/employee/login"); // 排除登录接口
	}
}