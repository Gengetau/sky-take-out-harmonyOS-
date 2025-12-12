package com.sky.service.impl;

import com.aliyun.oss.OSS;
import com.sky.config.OSSConfig;
import com.sky.service.FileService;
import com.sky.utils.AliOssUtil;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.util.DigestUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;

@Service
@Slf4j
public class FileServiceImpl implements FileService {
	
	@Autowired
	private OSS ossClient;
	
	@Autowired
	private OSSConfig ossConfig;
	
	/**
	 * 文件上传
	 *
	 * @param file
	 * @return
	 */
	public String upload(MultipartFile file) {
		try {
			// 1. 预处理
			byte[] fileBytes = file.getBytes();
			String fileHash = DigestUtils.md5DigestAsHex(fileBytes);
			String originalFilename = file.getOriginalFilename();
			String extension = originalFilename.substring(originalFilename.lastIndexOf("."));
			
			// 2. 构造唯一 Key
			String objectKey = fileHash + extension;
			
			// 3. 检查是否存在
			boolean exists = ossClient.doesObjectExist(ossConfig.getBucketName(), objectKey);
			
			if (exists) {
				// 【命中缓存】
				log.info("发现重复图片，秒传成功！Key: {}", objectKey);
			} else {
				// 【新上传】
				log.info("发现新图片，正在上传，Key: {}", objectKey);
				// 调用纯粹的上传方法
				AliOssUtil.upload(ossClient, fileBytes, objectKey, ossConfig.getBucketName());
			}
			
			// 4. 【统一出口】无论是否新上传，最后都统一生成签名 URL 返回给前端
			String signedUrl = AliOssUtil.getSignedUrl(ossClient, objectKey, ossConfig.getBucketName());
			
			log.info("返回给前端的签名链接: {}", signedUrl);
			return signedUrl;
			
		} catch (IOException e) {
			log.error("读取文件流失败", e);
			return null; // 或者抛出自定义异常
		} catch (Exception e) {
			log.error("上传流程异常", e);
			return null;
		}
	}
}