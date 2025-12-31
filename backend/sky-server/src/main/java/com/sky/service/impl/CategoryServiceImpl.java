package com.sky.service.impl;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.collection.CollUtil;
import cn.hutool.json.JSONUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.sky.constant.MessageConstant;
import com.sky.constant.StatusConstant;
import com.sky.dto.CategoryDTO;
import com.sky.dto.CategoryPageQueryDTO;
import com.sky.entity.Category;
import com.sky.entity.Dish;
import com.sky.entity.SetMeal;
import com.sky.exception.CategoryExitException;
import com.sky.exception.CategoryNotFoundException;
import com.sky.exception.DeletionNotAllowedException;
import com.sky.mapper.CategoryMapper;
import com.sky.result.Result;
import com.sky.service.CategoryService;
import com.sky.service.DishService;
import com.sky.service.SetMealService;
import com.sky.vo.CategoryVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.concurrent.TimeUnit;

import static com.sky.constant.RedisConstants.CACHE_CATEGORY_TTL;
import static com.sky.constant.RedisConstants.CACHE_CATEGORY_SHOP_KEY;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName CategoryServiceImpl
 * @Description
 * @dateTime 4/12/2025 上午11:04
 */
@Service
@Slf4j
public class CategoryServiceImpl extends ServiceImpl<CategoryMapper, Category>
		implements CategoryService {
	@Autowired
	private DishService dishService;
	@Autowired
	private SetMealService setMealService;
	@Autowired
	private StringRedisTemplate stringRedisTemplate;
	
	@Override
	public Result<List<CategoryVO>> queryAllEnabledCategories(Long shopId) {
		String key = CACHE_CATEGORY_SHOP_KEY + shopId;
		String categoryJson = stringRedisTemplate.opsForValue().get(key);
		if (categoryJson != null) {
			List<CategoryVO> categoryVOList = JSONUtil.toList(categoryJson, CategoryVO.class);
			return Result.success(categoryVOList);
		}
		List<Category> list = list(new LambdaQueryWrapper<Category>()
				.eq(Category::getShopId, shopId)
				.eq(Category::getStatus, StatusConstant.ENABLE)
				.orderByAsc(Category::getSort));
		if (CollUtil.isEmpty(list)) {
			return Result.success(CollUtil.newArrayList());
		}
		List<CategoryVO> vos = BeanUtil.copyToList(list, CategoryVO.class);
		stringRedisTemplate.opsForValue().set(key, JSONUtil.toJsonStr(vos), CACHE_CATEGORY_TTL, TimeUnit.HOURS);
		return Result.success(vos);
	}
	
	@Override
	public Result<Page<CategoryVO>> getCategoryByPage(CategoryPageQueryDTO pageDTO) {
		int currentPage = pageDTO.getPage();
		int pageSize = pageDTO.getPageSize();
		Page<Category> page = new Page<>(currentPage, pageSize);
		LambdaQueryWrapper<Category> qw = new LambdaQueryWrapper<>();
		qw.eq(pageDTO.getType() != null, Category::getType, pageDTO.getType());
		qw.like(pageDTO.getName() != null, Category::getName, pageDTO.getName());
		qw.orderByAsc(Category::getSort);
		Page<Category> page1 = page(page, qw);
		List<CategoryVO> vos = BeanUtil.copyToList(page1.getRecords(), CategoryVO.class);
		Page<CategoryVO> pageVO = new Page<>(currentPage, pageSize);
		pageVO.setRecords(vos);
		pageVO.setTotal(page1.getTotal());
		return Result.success(pageVO);
	}
	
	@Override
	@Transactional(rollbackFor = Exception.class)
	public Result<CategoryVO> updateCategory(CategoryDTO categoryDTO) {
		Category category = getById(categoryDTO.getId());
		if (category == null) {
			throw new CategoryNotFoundException(MessageConstant.CATEGORY_NOT_FOUND);
		}
		BeanUtil.copyProperties(categoryDTO, category);
		updateById(category);
		return Result.success();
	}
	
	@Override
	@Transactional(rollbackFor = Exception.class)
	public Result<String> updateCategoryStatus(Integer status, Long id) {
		Category category = getById(id);
		if (category == null) {
			throw new CategoryNotFoundException(MessageConstant.CATEGORY_NOT_FOUND);
		}
		LambdaUpdateWrapper<Category> updateWrapper = new LambdaUpdateWrapper<>();
		updateWrapper.eq(Category::getId, id);
		updateWrapper.set(Category::getStatus, status);
		update(updateWrapper);
		return Result.success();
	}
	
	@Override
	@Transactional(rollbackFor = Exception.class)
	public Result<String> addCategory(CategoryDTO categoryDTO) {
		long count = count(new LambdaQueryWrapper<Category>()
				.eq(Category::getName, categoryDTO.getName())
				.or().eq(Category::getSort, categoryDTO.getSort()));
		if (count > 0) {
			throw new CategoryExitException(MessageConstant.CATEGORY_EXIT);
		}
		Category newCategory = BeanUtil.copyProperties(categoryDTO, Category.class);
		newCategory.setStatus(StatusConstant.ENABLE);
		save(newCategory);
		return Result.success();
	}
	
	@Override
	@Transactional(rollbackFor = Exception.class)
	public Result<String> deleteCategoryById(Long id) {
		Category category = getById(id);
		if (category == null) {
			throw new CategoryNotFoundException(MessageConstant.CATEGORY_NOT_FOUND);
		}
		if (category.getType() == 1) {
			long dishCount = dishService.count(new LambdaQueryWrapper<Dish>().eq(Dish::getCategoryId, id));
			if (dishCount > 0) throw new DeletionNotAllowedException(MessageConstant.CATEGORY_BE_RELATED_BY_DISH);
		} else {
			long mealCount = setMealService.count(new LambdaQueryWrapper<SetMeal>().eq(SetMeal::getCategoryId, id));
			if (mealCount > 0) throw new DeletionNotAllowedException(MessageConstant.CATEGORY_BE_RELATED_BY_SET_MEAL);
		}
		removeById(id);
		return Result.success();
	}
	
	@Override
	public Result<List<CategoryVO>> getCategoryByType(Integer type) {
		List<Category> list = list(new LambdaQueryWrapper<Category>().eq(Category::getType, type)
				.eq(Category::getStatus, StatusConstant.ENABLE)
				.orderByAsc(Category::getSort));
		List<CategoryVO> vos = BeanUtil.copyToList(list, CategoryVO.class);
		return Result.success(vos);
	}

	// ==================================================
	// =============== Meow App 商家端方法实现 =============
	// ==================================================

	/**
	 * 商家端根据类型查询分类 (带 shopId 过滤)
	 */
	@Override
	public Result<List<CategoryVO>> getShopCategoryByType(Integer type, Long shopId) {
		log.info("App端查询分类列表，类型: {}, 店铺ID: {} 喵", type, shopId);
		List<Category> list = list(new LambdaQueryWrapper<Category>()
				.eq(Category::getShopId, shopId)
				.eq(type != null, Category::getType, type)
				.orderByAsc(Category::getSort));
		List<CategoryVO> vos = BeanUtil.copyToList(list, CategoryVO.class);
		return Result.success(vos);
	}

	/**
	 * 商家端新增分类 (带归属)
	 */
	@Override
	@Transactional(rollbackFor = Exception.class)
	public Result<String> addShopCategory(CategoryDTO categoryDTO, Long shopId) {
		long count = count(new LambdaQueryWrapper<Category>()
				.eq(Category::getShopId, shopId)
				.and(wrapper -> wrapper.eq(Category::getName, categoryDTO.getName())
						.or().eq(Category::getSort, categoryDTO.getSort())));
		if (count > 0) throw new CategoryExitException(MessageConstant.CATEGORY_EXIT);
		
		Category newCategory = BeanUtil.copyProperties(categoryDTO, Category.class);
		newCategory.setShopId(shopId); 
		newCategory.setStatus(StatusConstant.ENABLE); 
		save(newCategory);
		
		cleanShopCache(shopId);
		return Result.success();
	}

	/**
	 * 商家端修改分类 (带越权检查)
	 */
	@Override
	@Transactional(rollbackFor = Exception.class)
	public Result<String> updateShopCategory(CategoryDTO categoryDTO, Long shopId) {
		Category category = getById(categoryDTO.getId());
		if (category == null || !category.getShopId().equals(shopId)) {
			throw new CategoryNotFoundException(MessageConstant.CATEGORY_NOT_FOUND);
		}
		BeanUtil.copyProperties(categoryDTO, category);
		updateById(category);
		cleanShopCache(shopId);
		return Result.success();
	}

	/**
	 * 商家端删除分类 (带关联检查)
	 */
	@Override
	@Transactional(rollbackFor = Exception.class)
	public Result<String> deleteShopCategory(Long id, Long shopId) {
		Category category = getById(id);
		if (category == null || !category.getShopId().equals(shopId)) {
			throw new CategoryNotFoundException(MessageConstant.CATEGORY_NOT_FOUND);
		}
		if (category.getType() == 1) {
			long dishCount = dishService.count(new LambdaQueryWrapper<Dish>().eq(Dish::getCategoryId, id));
			if (dishCount > 0) throw new DeletionNotAllowedException(MessageConstant.CATEGORY_BE_RELATED_BY_DISH);
		} else {
			long mealCount = setMealService.count(new LambdaQueryWrapper<SetMeal>().eq(SetMeal::getCategoryId, id));
			if (mealCount > 0) throw new DeletionNotAllowedException(MessageConstant.CATEGORY_BE_RELATED_BY_SET_MEAL);
		}
		removeById(id);
		cleanShopCache(shopId);
		return Result.success();
	}

	/**
	 * 商家端启用/禁用分类 (补齐逻辑喵！✨)
	 */
	@Override
	@Transactional(rollbackFor = Exception.class)
	public Result<String> updateShopCategoryStatus(Integer status, Long id, Long shopId) {
		log.info("App端修改分类状态，ID: {}, 状态: {}, 店铺ID: {} 喵", id, status, shopId);
		Category category = getById(id);
		if (category == null || !category.getShopId().equals(shopId)) {
			throw new CategoryNotFoundException(MessageConstant.CATEGORY_NOT_FOUND);
		}
		
		category.setStatus(status);
		updateById(category);
		
		cleanShopCache(shopId);
		return Result.success();
	}

	private void cleanShopCache(Long shopId) {
		String key = CACHE_CATEGORY_SHOP_KEY + shopId;
		stringRedisTemplate.delete(key);
	}
}
