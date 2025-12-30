package com.sky.utils;

import cn.hutool.core.codec.Base64;

import java.security.SecureRandom;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName PasswordUtil
 * @Description 密码工具类
 * @dateTime 9/12/2025 上午11:15
 */
public class PasswordUtil {
	
	private final static int SALT_LENGTH_BYTES = 16;// 盐的长度
	
	/**
	 * 随机生成哈希加密盐
	 *
	 * @return Base64 编码的盐字符串，方便存储和传输
	 */
	public static String generateSecureSalt() {
		SecureRandom secureRandom = new SecureRandom();
		byte[] salt = new byte[SALT_LENGTH_BYTES];
		secureRandom.nextBytes(salt); // 用随机字节填充盐数组
		return Base64.encode(salt); // 将字节数组编码成 Base64 字符串
	}
}
