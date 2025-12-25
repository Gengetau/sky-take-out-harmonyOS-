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
	
	// ==================================================
	// =============== client 用户端方法 ===================
	// ==================================================
	@Override
	public Result<List<CategoryVO>> queryAllEnabledCategories(Long shopId) {
		// 1.从redis获取数据 (按 shopId 隔离缓存喵)
		String key = CACHE_CATEGORY_SHOP_KEY + shopId;
		String categoryJson = stringRedisTemplate.opsForValue().get(key);
		
		// 2.存在，返回
		if (categoryJson != null) {
			List<CategoryVO> categoryVOList = JSONUtil.toList(categoryJson, CategoryVO.class);
			return Result.success(categoryVOList);
		}
		
		// 3.不存在，查询数据库（查询指定店铺且已启用的分类，并按sort排序）
		List<Category> list = list(new LambdaQueryWrapper<Category>()
				.eq(Category::getShopId, shopId) // 增加 shopId 过滤喵！
				.eq(Category::getStatus, StatusConstant.ENABLE)
				.orderByAsc(Category::getSort));
		
		if (CollUtil.isEmpty(list)) {
			// 如果该店铺没有任何分类，直接返回空列表而不是报错
			return Result.success(CollUtil.newArrayList());
		}
		
		// 4.复制属性
		List<CategoryVO> vos = BeanUtil.copyToList(list, CategoryVO.class);
		
		// 5.存入redis
		stringRedisTemplate.opsForValue().set(key, JSONUtil.toJsonStr(vos), CACHE_CATEGORY_TTL, TimeUnit.HOURS);
		
		// 6.返回
		return Result.success(vos);
	}
	
	// ==================================================
	// =============== admin 管理端方法 ===================
	// ==================================================
	@Override
	public Result<Page<CategoryVO>> getCategoryByPage(CategoryPageQueryDTO pageDTO) {
		// 0.获取数据
		int currentPage = pageDTO.getPage();
		int pageSize = pageDTO.getPageSize();
		// 1.创建分页模型
		Page<Category> page = new Page<>(currentPage, pageSize);
		// 2.创建查询 Lambda 模型
		LambdaQueryWrapper<Category> qw = new LambdaQueryWrapper<>();
		// 类型查询
		qw.eq(pageDTO.getType() != null, Category::getType, pageDTO.getType());
		// 名称查询
		qw.like(pageDTO.getName() != null, Category::getName, pageDTO.getName());
		// 按 sort 排序
		qw.orderByAsc(Category::getSort);
		// 3.查询数据
		Page<Category> page1 = page(page, qw);
		// 4.复制属性
		List<CategoryVO> vos = BeanUtil.copyToList(page1.getRecords(), CategoryVO.class);
		// 5.创建新的分页模型
		Page<CategoryVO> pageVO = new Page<>(currentPage, pageSize);
		pageVO.setRecords(vos);
		pageVO.setTotal(page1.getTotal());
		// 6.返回数据
		return Result.success(pageVO);
	}
	
	@Override
	@Transactional(rollbackFor = Exception.class)
	public Result<CategoryVO> updateCategory(CategoryDTO categoryDTO) {
		// 1.查询
		Category category = getById(categoryDTO.getId());
		// 2.验证
		if (category == null) {
			throw new CategoryNotFoundException(MessageConstant.CATEGORY_NOT_FOUND);
		}
		// 3.复制属性
		BeanUtil.copyProperties(categoryDTO, category);
		// 4.修改
		updateById(category);
		// 5.返回
		return Result.success();
	}
	
	@Override
	@Transactional(rollbackFor = Exception.class)
	public Result<String> updateCategoryStatus(Integer status, Long id) {
		// 1.查询
		Category category = getById(id);
		// 2.验证
		if (category == null) {
			throw new CategoryNotFoundException(MessageConstant.CATEGORY_NOT_FOUND);
		}
		// 3.修改
		LambdaUpdateWrapper<Category> updateWrapper = new LambdaUpdateWrapper<>();
		updateWrapper.eq(Category::getId, id);
		updateWrapper.set(Category::getStatus, status);
		update(updateWrapper);
		// 4.返回
		return Result.success();
	}
	
	@Override
	@Transactional(rollbackFor = Exception.class)
	public Result<String> addCategory(CategoryDTO categoryDTO) {
		// 1.校验
		long count = count(new LambdaQueryWrapper<Category>()
				.eq(Category::getName, categoryDTO.getName())
				.or().eq(Category::getSort, categoryDTO.getSort()));
		if (count > 0) {
			throw new CategoryExitException(MessageConstant.CATEGORY_EXIT);
		}
		// 2.复制属性
		Category newCategory = BeanUtil.copyProperties(categoryDTO, Category.class);
		newCategory.setStatus(StatusConstant.ENABLE);// 默认启用
		// 3.新增
		save(newCategory);
		// 4.返回
		return Result.success();
	}
	
	@Override
	@Transactional(rollbackFor = Exception.class)
	public Result<String> deleteCategoryById(Long id) {
		// 1.校验是否存在
		Category category = getById(id);
		if (category == null) {
			throw new CategoryNotFoundException(MessageConstant.CATEGORY_NOT_FOUND);
		}
		// 2.校验分类是否关连菜品或套餐
		if (category.getType() == 1) {
			long dishCount = dishService.count(new LambdaQueryWrapper<Dish>()
					.eq(Dish::getCategoryId, id));
			if (dishCount > 0) {
				throw new DeletionNotAllowedException(MessageConstant.CATEGORY_BE_RELATED_BY_DISH);
			}
		} else {
			long mealCount = setMealService.count(new LambdaQueryWrapper<SetMeal>()
					.eq(SetMeal::getCategoryId, id));
			if (mealCount > 0) {
				throw new DeletionNotAllowedException(MessageConstant.CATEGORY_BE_RELATED_BY_SET_MEAL);
			}
		}
		// 3.删除
		removeById(id);
		// 4.返回
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
}