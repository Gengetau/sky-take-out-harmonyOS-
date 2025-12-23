package com.sky.service.impl;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.bean.copier.CopyOptions;
import cn.hutool.core.lang.UUID;
import cn.hutool.core.util.RandomUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.sky.dto.UserLoginDTO;
import com.sky.entity.User;
import com.sky.mapper.UserMapper;
import com.sky.result.Result;
import com.sky.service.UserService;
import com.aliyun.oss.OSS;
import com.sky.config.OSSConfig;
import com.sky.utils.AliOssUtil;
import com.sky.utils.RegexUtils;
import com.sky.vo.UserHolder;
import com.sky.vo.UserLoginVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

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
		User user = getOne(new LambdaQueryWrapper<User>().eq(User::getPhone, phone));
		// 3.1不存在，创建新用户
		if (user == null) {
			// 3.2创建新用户 (使用清理后的手机号保存)
			User newUser = new User();
			newUser.setName("用户" + RandomUtil.randomNumbers(6));
			newUser.setPhone(phone);
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
}
