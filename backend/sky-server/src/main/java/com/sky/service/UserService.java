package com.sky.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.sky.dto.UserLoginDTO;
import com.sky.entity.User;
import com.sky.result.Result;
import com.sky.vo.UserLoginVO;

import com.sky.dto.UserEditDTO;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName UserService
 * @Description 用户业务层接口
 * @dateTime 3/12/2025 上午11:31
 */
public interface UserService extends IService<User> {
	Result<String> sendCode(UserLoginDTO userLoginDTO);
	
	Result<UserLoginVO> login(UserLoginDTO userLoginDTO);
	
	Result<User> getUserInfo();
	
	Result<String> logout();
	
	Result<String> updateAvatar(String avatar);

	Result<String> editUserInfo(UserEditDTO userEditDTO);
}