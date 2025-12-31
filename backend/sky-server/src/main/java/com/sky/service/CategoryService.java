package com.sky.service;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.IService;
import com.sky.dto.CategoryDTO;
import com.sky.dto.CategoryPageQueryDTO;
import com.sky.entity.Category;
import com.sky.result.Result;
import com.sky.vo.CategoryVO;

import java.util.List;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName CategoryService
 * @Description 菜品分类业务层接口
 * @dateTime 4/12/2025 上午11:03
 */
public interface CategoryService extends IService<Category> {
	// ==================================================
	// =============== client 用户端方法 ===================
	// ==================================================
	
	/**
	 * 查询指定店铺的所有已启用的菜品分类
	 * (不按type过滤,带Redis缓存)
	 *
	 * @param shopId 店铺ID
	 * @return
	 */
	Result<List<CategoryVO>> queryAllEnabledCategories(Long shopId);
	
	// ==================================================
	// =============== admin 管理端方法 ===================
	// ==================================================
	
	/**
	 * 后台分类分页查询
	 */
	Result<Page<CategoryVO>> getCategoryByPage(CategoryPageQueryDTO pageDTO);
	
	/**
	 * 后台分类信息修改
	 */
	Result<CategoryVO> updateCategory(CategoryDTO categoryDTO);
	
	/**
	 * 后台更新分类状态
	 */
	Result<String> updateCategoryStatus(Integer status, Long id);
	
	/**
	 * 后台新增分类
	 */
	Result<String> addCategory(CategoryDTO categoryDTO);
	
	/**
	 * 后台根据id删除分类
	 */
	Result<String> deleteCategoryById(Long id);
	
	/**
	 * 根据类型查询分类
	 */
	Result<List<CategoryVO>> getCategoryByType(Integer type);

	// ==================================================
	// =============== Meow App 商家端方法 =================
	// ==================================================

	/**
	 * 商家端根据类型查询分类 (强制 shopId 隔离)
	 */
	Result<List<CategoryVO>> getShopCategoryByType(Integer type, Long shopId);

	/**
	 * 商家端新增分类 (带 shopId 归属)
	 */
	Result<String> addShopCategory(CategoryDTO categoryDTO, Long shopId);

	/**
	 * 商家端修改分类 (带 shopId 权限检查)
	 */
	Result<String> updateShopCategory(CategoryDTO categoryDTO, Long shopId);

	/**
	 * 商家端删除分类 (带 shopId 权限检查)
	 */
	Result<String> deleteShopCategory(Long id, Long shopId);

	/**
	 * 商家端启用/禁用分类 (带 shopId 权限检查)喵！✨
	 * @param status 1:启用, 0:禁用
	 * @param id 分类ID
	 * @param shopId 店铺ID
	 * @return
	 */
	Result<String> updateShopCategoryStatus(Integer status, Long id, Long shopId);
}
