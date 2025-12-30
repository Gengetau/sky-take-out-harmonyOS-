package com.sky.controller.admin;

import com.sky.result.Result;
import com.sky.service.FileService;
import com.sky.utils.AliOssUtil;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.util.ArrayList;
import java.util.List;

@RestController
@RequestMapping("/admin/common")
@Api(tags = "管理端-通用接口")
@Slf4j
public class FileController {
	
	@Autowired
	private FileService fileService;
	
	/**
	 * 单文件上传
	 *
	 * @param file
	 * @return
	 */
	@PostMapping("/upload")
	@ApiOperation("单个文件上传")
	public Result<String> upload(MultipartFile file) {
		log.info("文件上传：{}", file.getOriginalFilename());
		String url = fileService.upload(file);
		if (url != null) {
			return Result.success(url);
		}
		return Result.error("文件上传失败喵");
	}
	
	/**
	 * 批量文件上传 (测试工具喵)
	 *
	 * @param files
	 * @return 带签名的 URL 列表
	 */
	@PostMapping("/batchUpload")
	@ApiOperation("批量文件上传 (测试用)")
	public Result<List<String>> batchUpload(MultipartFile[] files) {
		if (files == null || files.length == 0) {
			return Result.error("请选择要上传的文件喵");
		}
		log.info("开始批量上传 {} 个文件喵", files.length);
		List<String> urls = new ArrayList<>();
		for (MultipartFile file : files) {
			String url = fileService.upload(file);
			String keyFromUrl = AliOssUtil.extractKeyFromUrl(url);
			if (url != null) {
				urls.add(keyFromUrl);
			}
		}
		log.info("批量上传完成，成功 {} 个喵", urls.size());
		return Result.success(urls);
	}
}
