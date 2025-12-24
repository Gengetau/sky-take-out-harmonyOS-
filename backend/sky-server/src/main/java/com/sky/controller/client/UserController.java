package com.sky.controller.client;

import com.sky.dto.UserEditDTO;
import com.sky.dto.UserLoginDTO;
import com.sky.entity.User;
import com.sky.result.Result;
import com.sky.service.FileService;
import com.sky.service.UserService;
import com.sky.utils.AliOssUtil;
import com.sky.vo.UserLoginVO;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName UserController
 * @Description 用户前端控制器
 * @dateTime 3/12/2025 上午11:28
 */
@RestController
@RequestMapping("/client/user")
@Api(tags = "C端-用户相关接口")
@Slf4j
public class UserController {
	@Autowired
	private UserService userService;
	
	@Autowired
	private FileService fileService;
	
	// 发送验证码
	@PostMapping("/code")
	@ApiOperation("发送手机验证码")
	public Result<String> sendCode(@RequestBody UserLoginDTO userLoginDTO) {
		return userService.sendCode(userLoginDTO);
	}
	
	// 用户登陆
	@PostMapping("/login")
	@ApiOperation("用户登录")
	public Result<UserLoginVO> login(@RequestBody UserLoginDTO userLoginDTO) {
		return userService.login(userLoginDTO);
	}
	
	// 获取个人信息
	@GetMapping("/info")
	@ApiOperation("获取当前登录用户信息")
	public Result<User> info() {
		log.info("获取当前登录用户信息喵");
		return userService.getUserInfo();
	}
	
	// 修改用户信息
	@PutMapping("/edit")
	@ApiOperation("修改用户信息")
	public Result<String> editUserInfo(@RequestBody UserEditDTO userEditDTO) {
		log.info("用户修改信息：{}", userEditDTO);
		return userService.editUserInfo(userEditDTO);
	}
	
	// 退出登录
	@PostMapping("/logout")
	@ApiOperation("退出登录")
	public Result<String> logout() {
		log.info("用户退出登录喵");
		return userService.logout();
	}
	
	// 上传头像
	@PostMapping("/uploadAvatar")
	@ApiOperation("上传头像")
	public Result<String> uploadAvatar(MultipartFile file, javax.servlet.http.HttpServletRequest request) {
		log.info("用户上传头像喵");
		if (file == null) {
			log.error("文件参数为空喵！请检查前端 FormData 的 key 是否为 'file'");
			return Result.error("文件上传失败，文件为空喵");
		}
		// 1. 上传文件得到签名 URL
		String signedUrl = fileService.upload(file);
		if (signedUrl == null) {
			return Result.error("头像上传失败喵");
		}
		// 2. 提取 Key 用于存库
		String objectKey = AliOssUtil.extractKeyFromUrl(signedUrl);
		// 3. 更新用户头像字段
		userService.updateAvatar(objectKey);
		// 4. 返回前端可用的签名 URL
		return Result.success(signedUrl);
	}
}


