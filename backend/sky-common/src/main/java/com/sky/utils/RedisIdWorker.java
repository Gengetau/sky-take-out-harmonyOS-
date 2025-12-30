package com.sky.utils;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName RedisIdWorker
 * @Description redis全局唯一id生成器
 * @dateTime 6/11/2025 下午4:54
 */
@Component
public class RedisIdWorker {
	
	// 定义初始时间
	private static final long BEGIN_TIMESTAMP = 1640995200L;
	// 序列号长度
	private static final int COUNT_BITS = 32;
	
	@Autowired
	private StringRedisTemplate stringRedisTemplate;
	
	/**
	 * @param keyPrefix key前缀
	 * @return 返回id
	 * @MethodName: nextId
	 * @Description: 生成自增的唯一id
	 */
	public long nextId(String keyPrefix) {
		// 1.生成时间戳
		LocalDateTime now = LocalDateTime.now();
		// 统一UTC时区
		long nowEpochSecond = now.toEpochSecond(ZoneOffset.UTC);
		long timeStamp = nowEpochSecond - BEGIN_TIMESTAMP;
		// 2.生成序列号
		// 获取当天日期
		String date = now.format(DateTimeFormatter.ofPattern("yyyy:MM:dd"));
		// 自增长
		Long count = stringRedisTemplate.opsForValue().increment("icr:" + keyPrefix + ":" + date);
		
		// 3.拼接并返回
		return timeStamp << COUNT_BITS | count;
	}
	
}
