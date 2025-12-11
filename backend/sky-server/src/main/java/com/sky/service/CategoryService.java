package com.sky.service;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.IService;
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
	 * 根据类型查询菜品分类
	 *
	 * @param type
	 * @return
	 */
	Result<List<CategoryVO>> queryAllCategory(Integer type);
	
	// ==================================================
	// =============== admin 管理端方法 ===================
	// ==================================================
	
	/**
	 * 后台菜品分页查询
	 *
	 * @param pageDTO
	 * @return
	 */
	Result<Page<CategoryVO>> getCategoryByPage(CategoryPageQueryDTO pageDTO);
}
