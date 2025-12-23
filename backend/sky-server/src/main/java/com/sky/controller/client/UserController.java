package com.sky.controller.client;

import com.sky.dto.UserLoginDTO;
import com.sky.entity.User;
import com.sky.result.Result;
import com.sky.service.UserService;
import com.sky.vo.UserLoginVO;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

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

	// 退出登录
	@PostMapping("/logout")
	@ApiOperation("退出登录")
	public Result<String> logout() {
		log.info("用户退出登录喵");
		return userService.logout();
	}
}
