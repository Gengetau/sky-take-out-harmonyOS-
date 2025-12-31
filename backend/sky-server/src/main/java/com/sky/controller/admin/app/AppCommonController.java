package com.sky.controller.admin.app;

import com.sky.result.Result;
import com.sky.service.FileService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

/**
 * 商家App端公共接口
 */
@RestController
@RequestMapping("/admin/app/common")
@Api(tags = "商家App端-公共接口")
@Slf4j
public class AppCommonController {
	
	@Autowired
	private FileService fileService;
	
	/**
	 * 文件上传
	 *
	 * @param file
	 * @return
	 */
	@PostMapping("/upload")
	@ApiOperation("文件上传")
	public Result<String> upload(MultipartFile file) {
		log.info("App端文件上传：{}", file);
		
		String keyFromUrl = fileService.upload(file);
		
		return Result.success(keyFromUrl);
	}
}
