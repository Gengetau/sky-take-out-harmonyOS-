package com.sky.config;

import com.aliyun.oss.OSS;
import com.aliyun.oss.OSSClientBuilder;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName OSSConfig
 * @Description 阿里云OSS配置类
 * @dateTime 12/12/2025 上午11:27
 */
@Configuration
@ConfigurationProperties(prefix = "aliyun.oss")
@Data
@Slf4j
public class OSSConfig {
	private String endpoint;
	private String accessKeyId;
	private String accessKeySecret;
	private String bucketName;
	
	@Bean
	public OSS ossClient() {
		// 创建 OSSClient 实例
		// 妮娅备注：OSSClient 是线程安全的，单例模式完全没问题喵
		log.info("开始创建阿里云文件上传客户端对象...");
		return new OSSClientBuilder().build(endpoint, accessKeyId, accessKeySecret);
	}
}
