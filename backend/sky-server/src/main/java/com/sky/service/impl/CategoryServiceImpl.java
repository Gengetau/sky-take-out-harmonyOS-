package com.sky.service.impl;

import cn.hutool.core.bean.BeanUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.CollectionUtils;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.sky.constant.MessageConstant;
import com.sky.dto.CategoryDTO;
import com.sky.dto.CategoryPageQueryDTO;
import com.sky.entity.Category;
import com.sky.exception.CategoryNotFoundException;
import com.sky.mapper.CategoryMapper;
import com.sky.result.Result;
import com.sky.service.CategoryService;
import com.sky.vo.CategoryVO;
import lombok.extern.slf4j.Slf4j;
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
}
