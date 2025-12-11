package com.sky.controller.admin;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.sky.dto.CategoryPageQueryDTO;
import com.sky.result.Result;
import com.sky.service.CategoryService;
import com.sky.vo.CategoryVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName AdminCategoryController
 * @Description 菜品分类控制器
 * @dateTime 4/12/2025 上午11:18
 */
@RestController
@RequestMapping("/admin/category")
public class AdminCategoryController {
	@Autowired
	private CategoryService categoryService;
	
	/**
	 * 分页查询所有菜品分类
	 *
	 * @param pageDTO
	 * @return
	 */
	@GetMapping("/page")
	public Result<Page<CategoryVO>> getCategoryByPage(CategoryPageQueryDTO pageDTO) {
		return categoryService.getCategoryByPage(pageDTO);
	}
}
