package com.sky.utils;

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.util.StrUtil;
import cn.hutool.json.JSONObject;
import cn.hutool.json.JSONUtil;
import lombok.extern.slf4j.Slf4j;
import org.redisson.api.RBloomFilter;
import org.redisson.api.RLock;
import org.redisson.api.RedissonClient;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.function.Function;

import static com.sky.constant.RedisConstants.CACHE_NULL_TTL;
import static com.sky.constant.RedisConstants.LOCK_SHOP_KEY;


/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName CacheClient
 * @Description redis缓存工具类
 * @dateTime 6/11/2025 下午1:03
 */
@Component
@Slf4j
public class CacheClient {
	// 缓存重建线程池,最大线程数:10
	private static final ExecutorService CACHE_REBUILD_EXECUTOR = Executors.newFixedThreadPool(10);
	@Autowired
	private StringRedisTemplate stringRedisTemplate;
	
	@Autowired
	private RedissonClient redissonClient;
	// 布隆过滤器
	private RBloomFilter<Long> bloomFilter;
	
	/**
	 * @param keyPrefix 布隆过滤器键名前缀
	 * @param name      布隆过滤器名称
	 * @MethodName: initBloomFilter
	 * @Description: 初始化布隆过滤器
	 */
	@Async// 开启新线程执行
	public void initBloomFilter(
			String keyPrefix,
			String name,
			long l, // 预计元素数量
			double v, // 误判率
			List<Long> ids// 需要加载的id列表
	) {
		log.info("初始化{}布隆过滤器", name);
		// 1.获取布隆过滤器
		String key = keyPrefix + name;
		bloomFilter = redissonClient.getBloomFilter(key);
		// 2.设置(预计 l 个元素，误判率 v)
		bloomFilter.tryInit(l, v);
		// 3.获取所有店铺id
		if (CollUtil.isEmpty(ids)) {
			// 没有元素，跳过预热
			log.warn("没有{}数据，跳过布隆过滤器预热。", name);
			return;
		}
		// 4.将id加入布隆过滤器
		ids.forEach(id -> bloomFilter.add(id));
		log.info("{}布隆过滤器初始化完毕，共加入 {} 个ID。", name, ids.size());
	}
	
	/**
	 * @param key   键名
	 * @param value 值
	 * @param time  过期时间
	 * @param unit  单位
	 * @MethodName: set
	 * @Description: 将任意java对象序列化为JSON并存储在string类型的key中, 可以设置TTL过期时间
	 */
	public <T> void set(String key, T value, Long time, TimeUnit unit) {
		stringRedisTemplate.opsForValue().set(key, JSONUtil.toJsonStr(value), time, unit);
	}
	
	/**
	 * @param key   键名
	 * @param value data数据
	 * @param time  过期时间
	 * @MethodName: setWithLogicalExpire
	 * @Description: 逻辑过期专用方法
	 */
	public <T> void setWithLogicalExpire(String key, T value, Long time, TimeUnit unit) {
		RedisData redisData = new RedisData();
		redisData.setData(value);
		redisData.setExpireTime(LocalDateTime.now().plusSeconds(unit.toSeconds(time)));
		stringRedisTemplate.opsForValue().set(key, JSONUtil.toJsonStr(redisData));
	}
	
	/**
	 * @return R:返回值类型
	 * ID:id类型
	 * @MethodName: redisToBean
	 * @Description: 根据指定的key查询缓存，并反序列化为指定类型，利用缓存空值的的方式解决缓存穿透问题
	 */
	public <R, ID> R queryWithPassThrough(
			String keyPrefix,           // 键名前缀，例："cache:shop:"
			ID id,                      // id,例：1L
			Class<R> type,              // 例：Shop.class
			Function<ID, R> dbFallback, // 函数，查询数据库逻辑
			Long time, TimeUnit unit    // 物理TTL
	) {
		// 1.布隆过滤器判断(如果已初始化)
		if (bloomFilter != null) {
			boolean isContained = bloomFilter.contains((Long) id);
			if (!isContained) {
				return null;
			}
		}
		
		// 2.获取完整key
		String key = keyPrefix + id;
		
		// 3.查询redis
		String jsonStr = stringRedisTemplate.opsForValue().get(key);
		
		// 4.判断缓存是否存在
		if (StrUtil.isNotBlank(jsonStr)) {
			// 4.1存在，直接返回
			return JSONUtil.toBean(jsonStr, type);
		}
		
		// 5.不存在，判断是null还是""
		if (jsonStr != null) {
			// 5.1不为null,命中缓存空值
			return null;
		}
		
		// 6.为null,查询数据库,执行传进来的Lambda函数
		R result = dbFallback.apply(id);
		
		// 7.数据库也为空
		if (result == null) {
			// 向redis写入空值,ttl:2分钟
			stringRedisTemplate.opsForValue().set(key, "", CACHE_NULL_TTL, TimeUnit.MINUTES);
			return null;
		}
		
		// 8.数据库存在数据,向redis写入缓存
		this.set(key, result, time, unit);
		
		// 9.返回数据
		return result;
	}
	
	/**
	 * @return R:返回值类型
	 * ID:id类型
	 * @MethodName: queryListWithPassThrough
	 * @Description: 根据指定的key查询List缓存，并反序列化为指定类型，利用缓存空值的的方式解决缓存穿透问题
	 */
	public <R, ID> List<R> queryListWithPassThrough(
			String keyPrefix,           // 键名前缀，例："cache:shop:"
			ID id,                      // id,例：1L
			Class<R> type,              // List元素的类型，例：DishVO.class
			Function<ID, List<R>> dbFallback, // 函数，查询数据库逻辑
			Long time, TimeUnit unit    // 物理TTL
	) {
		// 1.布隆过滤器判断(如果已初始化)
		if (bloomFilter != null) {
			boolean isContained = bloomFilter.contains((Long) id);
			if (!isContained) {
				return null;
			}
		}
		
		// 2.获取完整key
		String key = keyPrefix + id;
		
		// 3.查询redis
		String jsonStr = stringRedisTemplate.opsForValue().get(key);
		
		// 4.判断缓存是否存在
		if (StrUtil.isNotBlank(jsonStr)) {
			// 4.1存在，直接返回List
			return JSONUtil.toList(jsonStr, type);
		}
		
		// 5.不存在，判断是null还是""
		if (jsonStr != null) {
			// 5.1不为null,命中缓存空值
			return null;
		}
		
		// 6.为null,查询数据库,执行传进来的Lambda函数
		List<R> result = dbFallback.apply(id);
		
		// 7.数据库也为空
		if (CollUtil.isEmpty(result)) {
			// 向redis写入空值,ttl:2分钟
			stringRedisTemplate.opsForValue().set(key, "", CACHE_NULL_TTL, TimeUnit.MINUTES);
			return null;
		}
		
		// 8.数据库存在数据,向redis写入缓存
		this.set(key, result, time, unit);
		
		// 9.返回数据
		return result;
	}
	
	/**
	 * @return R:返回值类型
	 * ID:id类型
	 * @MethodName: queryWithLogicalExpire
	 * @Description: 逻辑过期查询
	 */
	public <R, ID> R queryWithLogicalExpire(
			String keyPrefix,           // 键名前缀，例："cache:shop:"
			ID id,                      // id,例：1L
			Class<R> type,              // 例：Shop.class
			Function<ID, R> dbFallback, // 函数，查询数据库逻辑
			Long time, TimeUnit unit    // 物理TTL
	) {
		// 1.布隆过滤器判断(如果已初始化)
		if (bloomFilter != null) {
			boolean isContained = bloomFilter.contains((Long) id);
			if (!isContained) {
				return null;
			}
		}

		// 2.获取完整键
		String key = keyPrefix + id;
		// 3.查询redis
		String jsonStr = stringRedisTemplate.opsForValue().get(key);
		// 4.未命中
		if (StrUtil.isBlank(jsonStr)) {
			return null;
		}
		// 5.命中
		RedisData redisData = JSONUtil.toBean(jsonStr, RedisData.class);
		R result = JSONUtil.toBean((JSONObject) redisData.getData(), type);
		LocalDateTime expireTime = redisData.getExpireTime();
		// 6.判断逻辑是否过期
		if (expireTime.isAfter(LocalDateTime.now())) {
			// 6.1未过期，直接返回
			return result;
		}
		// 7.过期，缓存重建
		String lockKey = LOCK_SHOP_KEY + id;
		RLock lock = redissonClient.getLock(lockKey);
		boolean isLockAcquired;
		try {
			// 7.1获取互斥锁
			isLockAcquired = lock.tryLock();
			// 7.2判断是否取锁成功
			if (isLockAcquired) {
				// 7.3成功，进行DCL双重检测
				jsonStr = stringRedisTemplate.opsForValue().get(key);
				RedisData newRedisData = JSONUtil.toBean(jsonStr, RedisData.class);
				LocalDateTime newExpireTime = newRedisData.getExpireTime();
				if (newExpireTime.isAfter(LocalDateTime.now())) {
					// 未过期，直接返回店铺信息
					return result;
				}
				// 7.4开启独立线程，实现缓存重建
				CACHE_REBUILD_EXECUTOR.submit(() -> {
					try {
						// 获取数据库数据
						R newResult = dbFallback.apply(id);
						// 向redis写入新数据
						this.setWithLogicalExpire(key, newResult, time, unit);
					} catch (Exception e) {
						throw new RuntimeException(e);
					} finally {
						lock.unlock();
					}
				});
			}
			// 7.5直接返回店铺信息
			return result;
		} catch (Exception e) {
			throw new RuntimeException(e);
		}
	}

	/**
	 * 获取匹配的key集合
	 * @param pattern
	 * @return
	 */
	public java.util.Set<String> keys(String pattern) {
		return stringRedisTemplate.keys(pattern);
	}

	/**
	 * 批量删除key
	 * @param keys
	 */
	public void delete(java.util.Set<String> keys) {
		stringRedisTemplate.delete(keys);
	}
}
