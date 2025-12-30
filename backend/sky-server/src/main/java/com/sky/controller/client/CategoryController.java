package com.sky.controller.client;

import com.sky.result.Result;
import com.sky.service.CategoryService;
import com.sky.vo.CategoryVO;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName CategoryController
 * @Description 菜品分类控制器 (客户端)
 */
@Api(tags = "C端-菜品分类接口")
@RestController
@RequestMapping("/client/category")
public class CategoryController {
	@Autowired
	private CategoryService categoryService;
	
	// 查询指定店铺的所有菜品分类
	@GetMapping("/all/{shopId}")
	@ApiOperation("查询指定店铺所有已启用的菜品分类")
	public Result<List<CategoryVO>> queryAllEnabledCategories(@PathVariable Long shopId) {
		return categoryService.queryAllEnabledCategories(shopId);
	}
}