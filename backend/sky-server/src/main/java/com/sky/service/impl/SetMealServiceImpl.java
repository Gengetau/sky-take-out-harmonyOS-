package com.sky.service.impl;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.collection.CollUtil;
import com.aliyun.oss.OSS;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.sky.config.OSSConfig;
import com.sky.constant.StatusConstant;
import com.sky.dto.SetmealDTO;
import com.sky.dto.SetmealPageQueryDTO;
import com.sky.entity.Category;
import com.sky.entity.Dish;
import com.sky.entity.SetMeal;
import com.sky.entity.SetMealDish;
import com.sky.exception.DeletionNotAllowedException;
import com.sky.exception.SetMealExitException;
import com.sky.exception.SetMealNotFoundException;
import com.sky.exception.SetmealEnableFailedException;
import com.sky.mapper.SetMealMapper;
import com.sky.result.Result;
import com.sky.service.CategoryService;
import com.sky.service.DishService;
import com.sky.service.SetMealDishService;
import com.sky.service.SetMealService;
import com.sky.utils.AliOssUtil;
import com.sky.vo.SetMealVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import static com.sky.constant.MessageConstant.*;
import static com.sky.constant.StatusConstant.DISABLE;
import static com.sky.constant.StatusConstant.ENABLE;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName SetMealServiceImpl
 * @Description 套餐业务层接口实现类
 * @dateTime 11/12/2025 上午10:56
 */
@Service
@Slf4j
public class SetMealServiceImpl extends ServiceImpl<SetMealMapper, SetMeal>
		implements SetMealService {
	@Autowired
	private CategoryService categoryService;
	@Autowired
	private SetMealDishService setMealDishService;
	@Autowired
	private OSS ossClient;
	@Autowired
	private OSSConfig ossConfig;
	@Autowired
	private DishService dishService;
	
	@Override
	public Result<Page<SetMealVO>> getSetMealByPage(SetmealPageQueryDTO dto) {
		int currentPage = dto.getPage();
		int pageSize = dto.getPageSize();
		// 1.创建分页模型
		Page<SetMeal> page = new Page<>(currentPage, pageSize);
		// 2.创建查询模型
		LambdaQueryWrapper<SetMeal> qw = new LambdaQueryWrapper<>();
		// 名称模糊查询
		qw.like(dto.getName() != null, SetMeal::getName, dto.getName());
		// 分类id查询
		qw.eq(dto.getCategoryId() != null, SetMeal::getCategoryId, dto.getCategoryId());
		// 状态查询
		qw.eq(dto.getStatus() != null, SetMeal::getStatus, dto.getStatus());
		// 3.查询
		Page<SetMeal> setMealPage = page(page, qw);
		// 4.校验
		if (CollUtil.isEmpty(setMealPage.getRecords())) {
			throw new SetMealNotFoundException(SET_MEAL_NOT_FOUND);
		}
		// 5.复制属性
		List<SetMealVO> vos = BeanUtil.copyToList(setMealPage.getRecords(), SetMealVO.class);
		List<Long> ids = vos.stream().map(SetMealVO::getCategoryId).collect(Collectors.toList());
		// 6.查询分类名称
		List<Category> categories = categoryService.listByIds(ids);
		// 7.转化为map集合
		Map<Long, String> cateMap = categories.stream()
				.collect(Collectors.toMap(Category::getId, Category::getName));
		// 8.遍历vos,进行分类名称赋值并对Image签名
		vos.forEach(vo -> {
			vo.setCategoryName(cateMap.get(vo.getCategoryId()));
			String keyFromUrl = AliOssUtil.getSignedUrl(ossClient, vo.getImage(), ossConfig.getBucketName());
			vo.setImage(keyFromUrl);
		});
		// 9.创建vo分页模型
		Page<SetMealVO> setMealVOPage = new Page<>(currentPage, pageSize);
		setMealVOPage.setRecords(vos);
		setMealVOPage.setTotal(setMealPage.getTotal());
		// 10.返回
		return Result.success(setMealVOPage);
	}
	
	@Override
	@Transactional(rollbackFor = Exception.class)
	public Result<String> setMealStatus(Integer status, Long setmealId) {
		// 1.查询套餐是否存在
		long count = count(new LambdaQueryWrapper<SetMeal>().eq(SetMeal::getId, setmealId));
		if (count <= 0) {
			throw new SetMealNotFoundException(SET_MEAL_NOT_FOUND);
		}
		// 2.查询套餐内所有菜品是否全部启售
		if (status == StatusConstant.ENABLE) {
			// 2.1获取相关菜品id
			List<Long> ids = setMealDishService.list(new LambdaQueryWrapper<SetMealDish>()
							.eq(SetMealDish::getSetMealId, setmealId))
					.stream()
					.map(SetMealDish::getDishId)
					.collect(Collectors.toList());
			// 2.2查询
			long dishCount = dishService.count(new LambdaQueryWrapper<Dish>()
					.in(Dish::getId, ids)
					.eq(Dish::getStatus, DISABLE));
			if (dishCount > 0) {
				throw new SetmealEnableFailedException(SET_MEAL_ENABLE_FAILED);
			}
		}
		// 2.修改
		SetMeal setMeal = SetMeal.builder()
				.status(status)
				.id(setmealId)
				.build();
		updateById(setMeal);
		return Result.success();
	}
	
	@Override
	@Transactional(rollbackFor = Exception.class)
	public Result<String> saveSetMeal(SetmealDTO dto) {
		// 1.校验套餐名称是否存在
		long count = count(new LambdaQueryWrapper<SetMeal>().eq(SetMeal::getName, dto.getName()));
		if (count > 0) {
			throw new SetMealExitException(SET_MEAL_EXIT);
		}
		// 2.复制属性
		SetMeal setMeal = BeanUtil.copyProperties(dto, SetMeal.class);
		// 3.处理 image 地址
		String keyFromUrl = AliOssUtil.extractKeyFromUrl(dto.getImage());
		setMeal.setImage(keyFromUrl);
		// 3.新增 set_meal 表
		save(setMeal);
		// 4.获取新增id 和套餐菜品
		Long id = setMeal.getId();
		List<SetMealDish> setMealDishes = dto.getSetmealDishes();
		setMealDishes.forEach(setMealDish -> {
			setMealDish.setSetMealId(id);
		});
		// 5.根据 id 批量新增 set_meal_dish 表
		setMealDishService.saveBatch(setMealDishes);
		// 6.返回
		return Result.success();
	}
	
	@Override
	public Result<SetMealVO> getSetMealById(Long id) {
		// 1.查询 set_meal 表
		SetMeal setMeal = getById(id);
		if (setMeal == null) {
			throw new SetMealNotFoundException(SET_MEAL_NOT_FOUND);
		}
		// 2.复制属性
		SetMealVO setMealVO = BeanUtil.copyProperties(setMeal, SetMealVO.class);
		// 3.查询 set_meal_dish 表，获取关联的菜品信息
		List<SetMealDish> list = setMealDishService.list(new LambdaQueryWrapper<SetMealDish>()
				.eq(SetMealDish::getSetMealId, setMeal.getId()));
		// 4.查询所属分类名称
		Category category = categoryService.getById(setMeal.getCategoryId());
		setMealVO.setCategoryName(category.getName());
		// 5.对image进行签名处理
		String signedUrl = AliOssUtil.getSignedUrl(ossClient, setMealVO.getImage(), ossConfig.getBucketName());
		setMealVO.setImage(signedUrl);
		// 6.组装
		setMealVO.setSetmealDishes(list);
		// 7.返回
		return Result.success(setMealVO);
	}
	
	@Override
	@Transactional(rollbackFor = Exception.class)
	public Result<String> updateSetMeal(SetmealDTO dto) {
		// 1.根据id 查询
		SetMeal setMeal = getById(dto.getId());
		if (setMeal == null) {
			throw new SetMealNotFoundException(SET_MEAL_NOT_FOUND);
		}
		if (!dto.getName().equals(setMeal.getName())) {
			// 校验新套餐名称是否存在
			long count = count(new LambdaQueryWrapper<SetMeal>().eq(SetMeal::getName, dto.getName()));
			if (count > 0) {
				throw new SetMealExitException(SET_MEAL_EXIT);
			}
		}
		// 2.复制属性
		BeanUtil.copyProperties(dto, setMeal);
		// 3.处理 image 地址
		String keyFromUrl = AliOssUtil.extractKeyFromUrl(dto.getImage());
		setMeal.setImage(keyFromUrl);
		// 4.修改 set_meal 表
		updateById(setMeal);
		// 5.获取套餐id
		Long setMealId = dto.getId();
		// 6.获取套餐菜品
		List<SetMealDish> setMealDishes = dto.getSetmealDishes();
		// 7.判断套餐菜品是否为空
		if (CollUtil.isNotEmpty(setMealDishes)) {
			// 不为空则遍历赋值
			setMealDishes.forEach(setMealDish -> {
				setMealDish.setSetMealId(setMealId);
			});
			updateSetMealDish(setMealDishes);
		} else {
			// 为空则删除该套餐关联的菜品
			setMealDishService.remove(new LambdaQueryWrapper<SetMealDish>().eq(SetMealDish::getSetMealId, setMealId));
		}
		// 8.返回
		return Result.success();
	}
	
	@Override
	@Transactional(rollbackFor = Exception.class)
	public Result<String> deleteBatch(List<Long> ids) {
		// 1.校验是否有启售中的套餐
		long count = count(new LambdaQueryWrapper<SetMeal>()
				.in(SetMeal::getId, ids)
				.eq(SetMeal::getStatus, ENABLE));
		if (count > 0) {
			throw new DeletionNotAllowedException(SET_MEAL_ON_SALE);
		}
		// 2.批量移除套餐相关菜品
		setMealDishService.remove(new LambdaQueryWrapper<SetMealDish>()
				.in(SetMealDish::getSetMealId, ids));
		// 3.批量移除套餐
		removeBatchByIds(ids);
		return Result.success();
	}
	
	/**
	 * 修改 set_meal_dish 表
	 *
	 * @param setMealDishes
	 */
	@Transactional(rollbackFor = Exception.class)
	public void updateSetMealDish(List<SetMealDish> setMealDishes) {
		// 1.获取套餐id
		Long setMealId = setMealDishes.get(0).getSetMealId();
		// 2.删除原套餐id对应的菜品
		setMealDishService.remove(new LambdaQueryWrapper<SetMealDish>().eq(SetMealDish::getSetMealId, setMealId));
		// 3.新增套餐对应的菜品
		setMealDishService.saveBatch(setMealDishes);
	}
}
