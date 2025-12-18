package com.sky.service.impl;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.collection.CollUtil;
import cn.hutool.json.JSONUtil;
import com.aliyun.oss.OSS;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.sky.config.OSSConfig;
import com.sky.constant.MessageConstant;
import com.sky.constant.StatusConstant;
import com.sky.dto.DishDTO;
import com.sky.dto.DishPageQueryDTO;
import com.sky.entity.Category;
import com.sky.entity.Dish;
import com.sky.entity.DishFlavor;
import com.sky.entity.SetMealDish;
import com.sky.exception.CategoryNotFoundException;
import com.sky.exception.DeletionNotAllowedException;
import com.sky.exception.DishExitException;
import com.sky.exception.DishNotFoundException;
import com.sky.mapper.DishFlavorMapper;
import com.sky.mapper.DishMapper;
import com.sky.result.Result;
import com.sky.service.CategoryService;
import com.sky.service.DishService;
import com.sky.service.SetMealDishService;
import com.sky.utils.AliOssUtil;
import com.sky.vo.DishVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;

import static com.sky.constant.MessageConstant.*;
import static com.sky.constant.RedisConstants.CACHE_DISH_TTL;
import static com.sky.constant.RedisConstants.DISH_CACHE_KEY;
import static com.sky.constant.StatusConstant.ENABLE;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName DishServiceImpl
 * @description
 * @dateTime 4/12/2025 上午11:02
 */
@Service
@Slf4j
public class DishServiceImpl extends ServiceImpl<DishMapper, Dish> implements DishService {
	@Autowired
	private DishFlavorMapper dishFlavorMapper;
	@Autowired
	private SetMealDishService setMealDishService;
	@Autowired
	private CategoryService categoryService;
	@Autowired
	private OSS ossClient;
	@Autowired
	private OSSConfig ossConfig;
	@Autowired
	private StringRedisTemplate stringRedisTemplate;
	
	@Override
	public Result<List<DishVO>> queryDishList(Integer categoryId) {
		// 0.构造redis的key
		String key = DISH_CACHE_KEY + categoryId;
		// 1.从redis获取数据
		String dishVOJson = stringRedisTemplate.opsForValue().get(key);
		if (dishVOJson != null) {
			// 2.存在，返回
			List<DishVO> dishVOList = JSONUtil.toList(dishVOJson, DishVO.class);
			return Result.success(dishVOList);
		}
		
		// 3.不存在，查询数据库
		List<Dish> list = list(new LambdaQueryWrapper<Dish>()
				.eq(Dish::getCategoryId, categoryId)
				.eq(Dish::getStatus, 1));
		if (list.isEmpty()) {
			return Result.error("获取菜品失败");
		}
		// 4.复制属性
		List<DishVO> dishVOS = BeanUtil.copyToList(list, DishVO.class);
		// 5.设置菜品口味和签名
		dishVOS.forEach(vo -> {
			// 设置菜品口味
			List<DishFlavor> dishFlavors = dishFlavorMapper
					.selectList(new LambdaQueryWrapper<DishFlavor>()
							.eq(DishFlavor::getDishId, vo.getId()));
			vo.setFlavors(dishFlavors);
			
			// 对图片进行签名
			String signedUrl = AliOssUtil.getSignedUrl(ossClient, vo.getImage(), ossConfig.getBucketName());
			vo.setImage(signedUrl);
		});
		
		// 6.存入redis
		stringRedisTemplate.opsForValue().set(key, JSONUtil.toJsonStr(dishVOS), CACHE_DISH_TTL, TimeUnit.MINUTES);
		// 7.返回数据
		return Result.success(dishVOS);
	}
	
	@Override
	public Result<Page<DishVO>> getDishByPage(DishPageQueryDTO dto) {
		// 0.获取数据
		int currentPage = dto.getPage();
		int pageSize = dto.getPageSize();
		// 1.创建分页模型
		Page<Dish> page = new Page<>(currentPage, pageSize);
		// 2.创建查询模型
		LambdaQueryWrapper<Dish> qw = new LambdaQueryWrapper<>();
		// 菜名模糊查询
		qw.like(dto.getName() != null, Dish::getName, dto.getName());
		// 分类查询
		qw.eq(dto.getCategoryId() != null, Dish::getCategoryId, dto.getCategoryId());
		// 状态查询
		qw.eq(dto.getStatus() != null, Dish::getStatus, dto.getStatus());
		// 3.查询
		Page<Dish> dishPage = page(page, qw);
		if (CollUtil.isEmpty(dishPage.getRecords())) {
			throw new DishNotFoundException(ELIGIBLE_DISHES_DO_NOT_EXIST);
		}
		// 4.复制属性
		List<DishVO> dishVOS = BeanUtil.copyToList(dishPage.getRecords(), DishVO.class);
		List<Long> ids = dishVOS.stream().map(DishVO::getCategoryId)
				.collect(Collectors.toList());
		// 5.查询所属分类
		List<Category> categories = categoryService.listByIds(ids);
		Map<Long, String> categoryMap = categories.stream()
				.collect(Collectors.toMap(Category::getId, Category::getName));
		// 6.组装属性并对image进行签名
		dishVOS.forEach(vo -> {
			vo.setCategoryName(categoryMap.get(vo.getCategoryId()));
			String signedUrl = AliOssUtil.getSignedUrl(ossClient, vo.getImage(), ossConfig.getBucketName());
			vo.setImage(signedUrl);
		});
		// 7.创建新的分页模型
		Page<DishVO> voPage = new Page<>(currentPage, pageSize);
		voPage.setRecords(dishVOS);
		voPage.setTotal(dishPage.getTotal());
		// 8.返回
		return Result.success(voPage);
	}
	
	@Override
	@Transactional(rollbackFor = Exception.class)
	public Result<String> saveDish(DishDTO dishDTO) {
		Dish saveDish = getDish(dishDTO);
		// 4.存储
		save(saveDish);
		// 5.返回
		return Result.success();
	}
	
	private Dish getDish(DishDTO dishDTO) {
		// 1.校验
		// 1.1校验所属分类是否存在及是否启用
		long count = categoryService.count(new LambdaQueryWrapper<Category>()
				.eq(Category::getId, dishDTO.getCategoryId())
				.eq(Category::getStatus, ENABLE));
		if (count <= 0) {
			throw new CategoryNotFoundException(THE_CURRENT_CLASSIFICATION_DOES_NOT_EXIST_OR_IS_DISABLE);
		}
		// 1.2校验菜品名称是否存在
		long count1 = count(new LambdaQueryWrapper<Dish>()
				.eq(Dish::getName, dishDTO.getName()));
		if (count1 > 0) {
			throw new DishExitException(DISH_EXIT);
		}
		// 2.复制属性
		Dish saveDish = BeanUtil.copyProperties(dishDTO, Dish.class);
		// 3.处理图片路径
		String keyFromUrl = AliOssUtil.extractKeyFromUrl(dishDTO.getImage());
		saveDish.setImage(keyFromUrl);
		return saveDish;
	}
	
	@Override
	public Result<List<DishVO>> getDishListByCategory(Long categoryId) {
		// 1.校验所属分类是否存在及是否启用
		long count = categoryService.count(new LambdaQueryWrapper<Category>()
				.eq(Category::getId, categoryId)
				.eq(Category::getStatus, ENABLE));
		if (count <= 0) {
			throw new CategoryNotFoundException(THE_CURRENT_CLASSIFICATION_DOES_NOT_EXIST_OR_IS_DISABLE);
		}
		// 2.查询
		List<Dish> list = list(new LambdaQueryWrapper<Dish>()
				.eq(Dish::getCategoryId, categoryId));
		String name = categoryService.getObj(new LambdaQueryWrapper<Category>()
				.eq(Category::getId, categoryId)
				.select(Category::getName), Object::toString);
		// 3.组装
		List<DishVO> dishVOS = list.stream().map(dish -> {
			DishVO dishVO = BeanUtil.copyProperties(dish, DishVO.class);
			dishVO.setCategoryName(name);
			String signedUrl = AliOssUtil.getSignedUrl(ossClient, dishVO.getImage(), ossConfig.getBucketName());
			dishVO.setImage(signedUrl);
			return dishVO;
		}).collect(Collectors.toList());
		// 4.返回
		return Result.success(dishVOS);
	}
	
	@Override
	public Result<DishVO> getDishById(Long id) {
		// 1.根据id查询菜品
		Dish dish = getById(id);
		if (dish == null) {
			throw new DishNotFoundException(ELIGIBLE_DISHES_DO_NOT_EXIST);
		}
		DishVO vo = BeanUtil.copyProperties(dish, DishVO.class);
		log.info(vo.toString());
		// 2.查询对应分类
		String name = categoryService.getObj(new LambdaQueryWrapper<Category>()
				.eq(Category::getId, dish.getCategoryId())
				.select(Category::getName), Object::toString);
		// 3.查询对应口味
		List<DishFlavor> dishFlavors = dishFlavorMapper
				.selectList(new LambdaQueryWrapper<DishFlavor>()
						.eq(DishFlavor::getDishId, vo.getId()));
		// 4.组装
		vo.setCategoryName(name);
		vo.setFlavors(dishFlavors);
		String signedUrl = AliOssUtil.getSignedUrl(ossClient, vo.getImage(), ossConfig.getBucketName());
		vo.setImage(signedUrl);
		// 5.返回
		return Result.success(vo);
	}
	
	@Override
	@Transactional(rollbackFor = Exception.class)
	public Result<String> updateDish(DishDTO dishDTO) {
		// 1.校验并转化
		Dish dish = getDish(dishDTO);
		// 2.保存
		updateById(dish);
		return Result.success();
	}
	
	@Override
	@Transactional(rollbackFor = Exception.class)
	public Result<String> deleteBatch(List<Long> ids) {
		// 1. 校验是否存在启售菜品
		long count = count(new LambdaQueryWrapper<Dish>()
				.in(Dish::getId, ids)
				.eq(Dish::getStatus, ENABLE));
		if (count > 0) {
			throw new DeletionNotAllowedException(DISH_ON_SALE);
		}
		// 2.校验菜品是否关联套餐
		long count1 = setMealDishService.count(new LambdaQueryWrapper<SetMealDish>()
				.in(SetMealDish::getId, ids));
		if (count1 > 0) {
			throw new DeletionNotAllowedException(DISH_BE_RELATED_BY_SET_MEAL);
		}
		removeBatchByIds(ids);
		return Result.success();
	}
	
	@Override
	@Transactional(rollbackFor = Exception.class)
	public Result<String> startOrStop(Integer status, Long id) {
		// 停售
		if (status.equals(StatusConstant.DISABLE)) {
			// 判断当前菜品是否在套餐中
			List<SetMealDish> setMealDishes = setMealDishService.list(new LambdaQueryWrapper<SetMealDish>()
					.eq(SetMealDish::getDishId, id));
			if (setMealDishes != null && !setMealDishes.isEmpty()) {
				// 菜品在套餐中，不能停售
				throw new DeletionNotAllowedException(MessageConstant.DISH_IS_RELATED_TO_SETMEAL);
			}
		}
		
		Dish dish = Dish.builder()
				.id(id)
				.status(status)
				.build();
		updateById(dish);
		
		return Result.success();
	}
}

