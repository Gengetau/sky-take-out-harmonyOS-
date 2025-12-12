package com.sky.service.impl;

import cn.hutool.core.bean.BeanUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.core.toolkit.CollectionUtils;
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
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

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
	
	// ==================================================
	// =============== client 用户端方法 ===================
	// ==================================================
	@Override
	public Result<List<CategoryVO>> queryAllCategory(Integer type) {
		List<Category> list = list(new LambdaQueryWrapper<Category>()
				.eq(Category::getType, type));
		if (CollectionUtils.isEmpty(list)) {
			return Result.error("菜品分类查询失败");
		}
		List<CategoryVO> vos = BeanUtil.copyToList(list, CategoryVO.class);
		
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
