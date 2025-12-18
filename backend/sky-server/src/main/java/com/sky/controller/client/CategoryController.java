package com.sky.controller.client;

import com.sky.result.Result;
import com.sky.service.CategoryService;
import com.sky.vo.CategoryVO;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName AdminCategoryController
 * @Description 菜品分类控制器
 * @dateTime 4/12/2025 上午11:18
 */
@Api(tags = "客户端菜品分类控制器")
@RestController
@RequestMapping("/client/category")
public class CategoryController {
	@Autowired
	private CategoryService categoryService;
	
	// 查询所有菜品分类
	@GetMapping("/all")
	@ApiOperation("查询所有已启用的菜品分类")
	public Result<List<CategoryVO>> queryAllEnabledCategories() {
		return categoryService.queryAllEnabledCategories();
	}
}
