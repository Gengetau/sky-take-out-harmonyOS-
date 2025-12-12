package com.sky.controller.admin;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.sky.dto.CategoryDTO;
import com.sky.dto.CategoryPageQueryDTO;
import com.sky.result.Result;
import com.sky.service.CategoryService;
import com.sky.vo.CategoryVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

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
	
	/**
	 * 修改分类信息
	 *
	 * @param categoryDTO
	 * @return
	 */
	@PutMapping
	public Result<CategoryVO> updateCategory(@RequestBody CategoryDTO categoryDTO) {
		return categoryService.updateCategory(categoryDTO);
	}
	
	/**
	 * 更新分类状态
	 *
	 * @param status
	 * @param id
	 * @return
	 */
	@PostMapping("/status/{status}")
	public Result<String> updateCategoryStatus(@PathVariable Integer status, @RequestParam Long id) {
		return categoryService.updateCategoryStatus(status, id);
	}
	
	/**
	 * 新增分类
	 *
	 * @param categoryDTO
	 * @return
	 */
	@PostMapping
	public Result<String> addCategory(@RequestBody CategoryDTO categoryDTO) {
		return categoryService.addCategory(categoryDTO);
	}
	
	/**
	 * 根据id删除分类
	 *
	 * @param id
	 * @return
	 */
	@DeleteMapping
	public Result<String> deleteCategoryById(Long id) {
		return categoryService.deleteCategoryById(id);
	}
	
	/**
	 * 根据类型查询分类
	 *
	 * @param type
	 * @return
	 */
	@GetMapping("/list")
	public Result<List<CategoryVO>> getCategoryByType(@RequestParam Integer type) {
		return categoryService.getCategoryByType(type);
	}
}
