package com.sky.utils;

import com.aliyun.oss.OSS;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.ByteArrayInputStream;
import java.net.URI;
import java.net.URISyntaxException;
import java.net.URL;
import java.util.Date;
import java.util.concurrent.TimeUnit;

public class AliOssUtil {
	
	private static final Logger log = LoggerFactory.getLogger(AliOssUtil.class);
	
	/**
	 * 纯粹的上传方法，只负责把字节流扔上去
	 * 返回 void 或者 boolean 即可，不需要返回 URL
	 */
	public static void upload(OSS ossClient, byte[] bytes, String objectName, String bucketName) {
		try {
			ossClient.putObject(bucketName, objectName, new ByteArrayInputStream(bytes));
			// 记录日志即可
		} catch (Exception e) {
			// 这里建议抛出异常让 Service 层捕获，或者记录 Error
			throw new RuntimeException("OSS上传失败", e);
		}
	}
	
	/**
	 * 独立的获取签名 URL 方法
	 */
	public static String getSignedUrl(OSS ossClient, String objectName, String bucketName) {
		// 设置2小时过期
		Date expiration = new Date(new Date().getTime() + 2 * 3600 * 1000);
		URL url = ossClient.generatePresignedUrl(bucketName, objectName, expiration);
		return url.toString();
	}
	
	/**
	 * 独立的获取签名 URL 方法（可自定义过期时间）
	 */
	public static String getSignedUrl(OSS ossClient, String objectName, String bucketName, long duration, TimeUnit unit) {
		Date expiration = new Date(new Date().getTime() + unit.toMillis(duration));
		URL url = ossClient.generatePresignedUrl(bucketName, objectName, expiration);
		return url.toString();
	}
	
	/**
	 * 从完整 OSS URL 中提取 Object Key (存库用)
	 * 适用于：https://bucket.endpoint/path/to/file.jpg?Args...
	 */
	public static String extractKeyFromUrl(String fullUrl) {
		try {
			URI uri = new URI(fullUrl);
			String path = uri.getPath();
			// 去掉开头的斜杠 "/"
			if (path.startsWith("/")) {
				return path.substring(1);
			}
			return path;
		} catch (URISyntaxException e) {
			// 如果 URL 格式不对，就原样返回或者报错，看主人业务需求
			return fullUrl;
		}
	}
}
