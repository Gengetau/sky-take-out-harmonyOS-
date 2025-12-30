package com.sky.service.impl;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.bean.copier.CopyOptions;
import cn.hutool.core.lang.UUID;
import cn.hutool.core.util.RandomUtil;
import com.aliyun.oss.OSS;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.sky.config.OSSConfig;
import com.sky.dto.UserEditDTO;
import com.sky.dto.UserLoginDTO;
import com.sky.entity.AddressBook;
import com.sky.entity.User;
import com.sky.mapper.AddressBookMapper;
import com.sky.mapper.UserMapper;
import com.sky.result.Result;
import com.sky.service.UserService;
import com.sky.utils.AliOssUtil;
import com.sky.utils.RegexUtils;
import com.sky.vo.UserHolder;
import com.sky.vo.UserLoginVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;

import static com.sky.constant.RedisConstants.*;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName UserServiceImpl
 * @Description
 * @dateTime 3/12/2025 上午11:40
 */
@Service
@Slf4j
public class UserServiceImpl extends ServiceImpl<UserMapper, User>
		implements UserService {
	@Autowired
	private StringRedisTemplate stringRedisTemplate;
	
	@Autowired
	private OSS ossClient;
	
	@Autowired
	private OSSConfig ossConfig;
	
	@Autowired
	private AddressBookMapper addressBookMapper;
	
	@Override
	public Result<String> sendCode(UserLoginDTO userLoginDTO) {
		// 1.验证手机号
		String phone = userLoginDTO.getPhone();
		if (RegexUtils.isPhoneInvalid(phone)) {
			return Result.error("手机号格式错误!");
		}
		// 2.生成验证码
		String code = RandomUtil.randomNumbers(6);
		// 3.保存验证码到redis (使用清理后的手机号作为key)
		stringRedisTemplate.opsForValue().set(LOGIN_CODE_KEY + phone, code, LOGIN_CODE_TTL, TimeUnit.MINUTES);
		// 5.发送验证码
		// 真实业务替换为第三方平台接口进行发送
		log.debug("发送短信验证码成功，验证码，{}", code);
		// 6.返回发送结果
		return Result.success(code);
	}
	
	@Override
	@Transactional(rollbackFor = Exception.class)
	public Result<UserLoginVO> login(UserLoginDTO userLoginDTO) {
		String phone = userLoginDTO.getPhone();
		String dtoCode = userLoginDTO.getCode();
		// 1.校验手机号
		if (RegexUtils.isPhoneInvalid(phone)) {
			return Result.error("手机号格式错误!");
		}
		// 2.校验验证码 (使用清理后的手机号作为key)
		String cashCode = stringRedisTemplate.opsForValue().get(LOGIN_CODE_KEY + phone);
		if (cashCode == null || !cashCode.equals(dtoCode)) {
			// 2.1不符合，返回错误信息
			return Result.error("验证码错误!");
		}
		// 3.根据手机号查询用户 (使用清理后的手机号查询)
		// 且必须是未注销的用户
		User user = getOne(new LambdaQueryWrapper<User>()
				.eq(User::getPhone, phone)
				.eq(User::getIsDeleted, 0)); // 只能查到没注销的
		
		// 3.1不存在，创建新用户
		if (user == null) {
			// 3.2创建新用户 (使用清理后的手机号保存)
			User newUser = new User();
			newUser.setName("用户" + RandomUtil.randomNumbers(6));
			newUser.setPhone(phone);
			newUser.setMeowId("meow" + System.currentTimeMillis());
			newUser.setIsDeleted(0); // 明确设置
			save(newUser);
			user = newUser;
		}
		// 4.保存用户到Redis
		// 4.1 随机生成UUID作为redis的key
		String token = UUID.randomUUID().toString(true);
		String tokenKey = LOGIN_USER_KEY + token;
		// 4.2 复制属性
		UserLoginVO userVO = BeanUtil.copyProperties(user, UserLoginVO.class);
		userVO.setToken(token);
		Map<String, Object> userMap = BeanUtil.beanToMap(userVO, new HashMap<>(),
				CopyOptions.create()
						.setIgnoreNullValue(true)
						.setFieldValueEditor((fieldName, fieldValue) -> fieldValue != null ? fieldValue.toString() : null));
		stringRedisTemplate.opsForHash().putAll(tokenKey, userMap);
		// 4.3 设置有效期
		stringRedisTemplate.expire(tokenKey, LOGIN_USER_TTL, TimeUnit.MINUTES);
		// 5.返回结果
		return Result.success(userVO);
	}
	
	@Override
	public Result<User> getUserInfo() {
		UserLoginVO userVO = UserHolder.getUser();
		if (userVO == null) {
			return Result.error("用户未登录喵！");
		}
		User user = getById(userVO.getId());
		
		// 校验用户是否已注销
		if (user == null || (user.getIsDeleted() != null && user.getIsDeleted() == 1)) {
			// 清理 Redis 缓存，强制退出
			stringRedisTemplate.delete(LOGIN_USER_KEY + userVO.getToken());
			UserHolder.removeUser();
			return Result.error("账号已注销喵！");
		}
		
		// 处理头像签名
		if (user.getAvatar() != null && !user.getAvatar().isEmpty()) {
			// 只有当头像是OSS路径时才签名（简单的判断，或者默认全是OSS）
			try {
				String signedUrl = AliOssUtil.getSignedUrl(ossClient, user.getAvatar(), ossConfig.getBucketName());
				user.setAvatar(signedUrl);
			} catch (Exception e) {
				log.error("头像签名失败喵", e);
				// 签名失败可以保留原链接或者设为空，这里暂时保留原链接
			}
		}
		
		return Result.success(user);
	}
	
	@Override
	public Result<String> logout() {
		UserLoginVO user = UserHolder.getUser();
		if (user != null) {
			stringRedisTemplate.delete(LOGIN_USER_KEY + user.getToken());
			UserHolder.removeUser();
			return Result.success("退出成功喵！");
		}
		return Result.error("用户未登录喵！");
	}
	
	@Override
	@Transactional(rollbackFor = Exception.class)
	public Result<String> updateAvatar(String avatar) {
		UserLoginVO user = UserHolder.getUser();
		if (user == null) {
			return Result.error("用户未登录喵！");
		}
		
		boolean success = lambdaUpdate()
				.eq(User::getId, user.getId())
				.set(User::getAvatar, avatar)
				.update();
		
		if (success) {
			return Result.success("头像更新成功喵！");
		} else {
			return Result.error("头像更新失败喵！");
		}
	}
	
	@Override
	@Transactional(rollbackFor = Exception.class)
	public Result<String> editUserInfo(UserEditDTO userEditDTO) {
		UserLoginVO user = UserHolder.getUser();
		if (user == null) {
			return Result.error("用户未登录喵！");
		}
		
		String code = userEditDTO.getCode();
		String value = userEditDTO.getValue();
		
		if (code == null || code.trim().isEmpty()) {
			return Result.error("参数错误：字段名不能为空喵！");
		}
		
		LambdaUpdateWrapper<User> updateWrapper = new LambdaUpdateWrapper<>();
		updateWrapper.eq(User::getId, user.getId());
		
		boolean validField = true;
		
		switch (code) {
			case "name": // 昵称
				updateWrapper.set(User::getName, value);
				break;
			case "sex": // 性别
				if (!"0".equals(value) && !"1".equals(value)) {
					return Result.error("性别参数错误，只能是 0(女) 或 1(男) 喵！");
				}
				updateWrapper.set(User::getSex, value);
				break;
			case "profile": // 简介
				updateWrapper.set(User::getProfile, value);
				break;
			case "idNumber": // 身份证号
				updateWrapper.set(User::getIdNumber, value);
				break;
			case "phone": // 手机号
				if (RegexUtils.isPhoneInvalid(value)) {
					return Result.error("手机号格式错误喵！");
				}
				updateWrapper.set(User::getPhone, value);
				break;
			default:
				validField = false;
				break;
		}
		
		if (!validField) {
			return Result.error("不支持修改该字段：" + code);
		}
		
		boolean success = update(updateWrapper);
		if (success) {
			return Result.success("信息修改成功！");
		} else {
			return Result.error("信息修改失败，请稍后重试！");
		}
	}
	
	@Override
	@Transactional(rollbackFor = Exception.class)
	public Result<String> cancelAccount() {
		UserLoginVO userVO = UserHolder.getUser();
		if (userVO == null) {
			return Result.error("用户未登录喵！");
		}
		
		Long userId = userVO.getId();
		
		// 1. 用户信息脱敏与注销标记
		// 生成随机后缀确保唯一性约束不冲突（如 phone/openid）
		String suffix = "_del_" + System.currentTimeMillis();
		
		boolean userUpdateSuccess = lambdaUpdate()
				.eq(User::getId, userId)
				.set(User::getIsDeleted, 1) // 标记注销
				.set(User::getCancelTime, LocalDateTime.now()) // 记录注销时间
				.set(User::getName, "已注销用户")
				.set(User::getPhone, "已注销" + RandomUtil.randomNumbers(4)) // 脱敏
				.set(User::getOpenid, (userVO.getOpenid() != null ? userVO.getOpenid() : "") + suffix) // 避免唯一索引冲突
				.set(User::getAvatar, null) // 清空头像
				.set(User::getIdNumber, null) // 清空身份证
				.update();
		
		if (!userUpdateSuccess) {
			return Result.error("注销失败，请稍后重试喵！");
		}
		
		// 2. 关联地址簿信息脱敏
		LambdaUpdateWrapper<AddressBook> addressWrapper = new LambdaUpdateWrapper<>();
		addressWrapper.eq(AddressBook::getUserId, userId)
				.set(AddressBook::getConsignee, "已注销")
				.set(AddressBook::getPhone, "******")
				.set(AddressBook::getDetail, "******");
		
		addressBookMapper.update(null, addressWrapper);
		
		// 3. 清理 Redis 登录状态
		stringRedisTemplate.delete(LOGIN_USER_KEY + userVO.getToken());
		UserHolder.removeUser();
		
		return Result.success("账号已注销，江湖再见喵！");
	}
}