package com.sky.controller.client;

import com.sky.dto.UserLoginDTO;
import com.sky.result.Result;
import com.sky.service.UserService;
import com.sky.vo.UserLoginVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName UserController
 * @Description 用户前端控制器
 * @dateTime 3/12/2025 上午11:28
 */
@RestController
@RequestMapping("/client/user")
@Slf4j
public class UserController {
	@Autowired
	private UserService userService;
	
	// 发送验证码
	@PostMapping("/code")
	public Result<String> sendCode(@RequestBody UserLoginDTO userLoginDTO) {
		return userService.sendCode(userLoginDTO);
	}
	
	// 用户登陆
	@PostMapping("/login")
	public Result<UserLoginVO> login(@RequestBody UserLoginDTO userLoginDTO) {
		return userService.login(userLoginDTO);
	}
}
