package com.sky.service.impl;

import cn.hutool.core.util.StrUtil;
import cn.hutool.json.JSONUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.sky.constant.RedisConstants;
import com.sky.entity.AddressBook;
import com.sky.mapper.AddressBookMapper;
import com.sky.service.AddressBookService;
import com.sky.vo.UserHolder;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Slf4j
public class AddressBookServiceImpl extends ServiceImpl<AddressBookMapper, AddressBook> implements AddressBookService {
	
	@Autowired
	private StringRedisTemplate stringRedisTemplate;
	
	/**
	 * 查询默认地址
	 *
	 * @return
	 */
	@Override
	public AddressBook getDefault() {
		Long userId = UserHolder.getUser().getId();
		log.info("查询用户 {} 的默认地址喵", userId);
		
		// 1. 查询 Redis
		String key = RedisConstants.USER_DEFAULT_ADDRESS_KEY + userId;
		String addressJson = stringRedisTemplate.opsForValue().get(key);
		
		if (StrUtil.isNotBlank(addressJson)) {
			log.info("从 Redis 缓存中命中默认地址喵");
			return JSONUtil.toBean(addressJson, AddressBook.class);
		}
		
		// 2. 查询数据库
		LambdaQueryWrapper<AddressBook> queryWrapper = new LambdaQueryWrapper<>();
		queryWrapper.eq(AddressBook::getUserId, userId);
		queryWrapper.eq(AddressBook::getIsDefault, 1);
		AddressBook addressBook = getOne(queryWrapper);
		
		// 3. 存入 Redis
		if (addressBook != null) {
			stringRedisTemplate.opsForValue().set(key, JSONUtil.toJsonStr(addressBook));
		}
		
		return addressBook;
	}
	
	/**
	 * 查询当前登录用户的所有地址信息
	 *
	 * @return
	 */
	@Override
	public List<AddressBook> listByUser() {
		Long userId = UserHolder.getUser().getId();
		LambdaQueryWrapper<AddressBook> queryWrapper = new LambdaQueryWrapper<>();
		queryWrapper.eq(AddressBook::getUserId, userId);
		return list(queryWrapper);
	}
	
	/**
	 * 新增地址
	 *
	 * @param addressBook
	 */
	@Override
	@Transactional(rollbackFor = Exception.class)
	public void add(AddressBook addressBook) {
		addressBook.setUserId(UserHolder.getUser().getId());
		addressBook.setIsDefault(0); // 新增地址强制设为非默认，由专门接口控制默认设置
		save(addressBook);
	}
}
