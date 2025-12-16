package com.sky.config;

import com.fasterxml.jackson.annotation.JsonAutoDetect;
import com.fasterxml.jackson.annotation.PropertyAccessor;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.serializer.Jackson2JsonRedisSerializer;
import org.springframework.data.redis.serializer.StringRedisSerializer;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName RedisConfig
 * @Description redis配置类
 * @dateTime 16/12/2025 上午10:55
 */
@Configuration
public class RedisConfig {
	@Bean
	@SuppressWarnings("all")
	public RedisTemplate<String, Object> redisTemplate(RedisConnectionFactory factory) {
		// 1. 创建 RedisTemplate 对象
		RedisTemplate<String, Object> template = new RedisTemplate<>();
		template.setConnectionFactory(factory);
		
		// 2. 定义 Jackson2JsonRedisSerializer 序列化器
		Jackson2JsonRedisSerializer<Object> jackson2JsonRedisSerializer = new Jackson2JsonRedisSerializer<>(Object.class);
		ObjectMapper om = new ObjectMapper();
		om.setVisibility(PropertyAccessor.ALL, JsonAutoDetect.Visibility.ANY);
		// 开启类型白名单，这一步是为了能在反序列化时拿到具体的类信息（JDK 1.8/Spring 2.x常用）
		om.enableDefaultTyping(ObjectMapper.DefaultTyping.NON_FINAL);
		jackson2JsonRedisSerializer.setObjectMapper(om);
		
		// 3. 定义 String 序列化器
		StringRedisSerializer stringRedisSerializer = new StringRedisSerializer();
		
		// 4. 设置 Key 和 Value 的序列化规则
		// Key 采用 String 的序列化方式
		template.setKeySerializer(stringRedisSerializer);
		// Hash 的 Key 也采用 String 的序列化方式
		template.setHashKeySerializer(stringRedisSerializer);
		
		// Value 采用 Jackson (JSON) 的序列化方式
		template.setValueSerializer(jackson2JsonRedisSerializer);
		// Hash 的 Value 也采用 Jackson 的序列化方式
		template.setHashValueSerializer(jackson2JsonRedisSerializer);
		
		template.afterPropertiesSet();
		return template;
	}
}
