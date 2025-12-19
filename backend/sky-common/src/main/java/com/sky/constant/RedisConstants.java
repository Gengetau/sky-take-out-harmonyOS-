package com.sky.constant;

public class RedisConstants {
	public static final String LOGIN_CODE_KEY = "login:code:";
	public static final Long LOGIN_CODE_TTL = 2L;
	public static final String LOGIN_USER_KEY = "login:token:";
	public static final Long LOGIN_USER_TTL = 60 * 7L;
	
	public static final String SHOP_STATUS_KEY = "shop:status";
	
	public static final String SHOP_TYPE_KEY = "cache:type";
	
	public static final Long CACHE_TYPE_TTL = 24L;
	
	public static final String BLOOM_FILTER_KEY = "bloom:filter:";
	
	public static final Long CACHE_NULL_TTL = 2L;
	
	public static final String CACHE_SHOP_KEY = "cache:shop:";
	
	public static final String LOCK_ORDER_KEY = "lock:order:";
	
	public static final String LOCK_SHOP_KEY = "lock:shop:";
	
	public static final String ORDER_KEY = "order";
	
	public static final String SECKILL_STOCK_KEY = "seckill:stock:{";
	
	public static final String SECKILL_ORDER_KEY = "seckill:order:{";
	
	public static final String BLOG_LIKED_KEY = "blog:liked:";
	
	public static final String FOLLOW_KEY = "follow:";
	
	public static final String FEED_KEY = "feed:";
	
	public static final String SHOP_GEO_KEY = "shop:geo:";
	
	public static final String USER_SIGN_KEY = "sign:";
	
	public static final String DISH_CACHE_KEY = "cache:dish:";
	
	// 单位：分钟
	public static final Long CACHE_DISH_TTL = 60L;
	
	public static final String CATEGORY_ALL_KEY = "cache:category:all";
	
	// 单位：小时
	public static final Long CACHE_CATEGORY_TTL = 24L;
	
	public static final String SETMEAL_CACHE_KEY = "cache:setmeal:";
	
	// 单位：分钟
	public static final Long CACHE_SETMEAL_TTL = 60L;

    public static final String USER_DEFAULT_ADDRESS_KEY = "cache:user:default_address:";
	
	/*// 生成随机TTL
	public static Long randomTTL() {
		long ttl = 30L;
		long l = RandomUtil.randomLong(0, 10);
		return ttl + l;
	}*/
}
