package com.sky.controller.admin;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.sky.dto.DishDTO;
import com.sky.dto.DishPageQueryDTO;
import com.sky.result.Result;
import com.sky.service.DishService;
import com.sky.vo.DishVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName AdminDishController
 * @Description 后台菜品管理控制器
 * @dateTime 12/12/2025 上午9:06
 */
@RestController
@RequestMapping("/admin/dish")
public class AdminDishController {
	@Autowired
	private DishService dishService;
	
	/**
	 * 分页查询菜品
	 *
	 * @param dto
	 * @return
	 */
	@GetMapping("/page")
	public Result<Page<DishVO>> getDishByPage(DishPageQueryDTO dto) {
		return dishService.getDishByPage(dto);
	}
	
	/**
	 * 新增菜品
	 *
	 * @param dishDTO
	 * @return
	 */
	@PostMapping
	public Result<String> saveDish(@RequestBody DishDTO dishDTO) {
		return dishService.saveDish(dishDTO);
	}
	
	/**
	 * 根据分类id 查询菜品
	 *
	 * @param categoryId
	 * @return
	 */
	@GetMapping("/list")
	public Result<List<DishVO>> getDishListByCategory(@RequestParam("categoryId") Long categoryId) {
		return dishService.getDishListByCategory(categoryId);
	}
	
	/**
	 * 根据id查询菜品信息
	 *
	 * @param id
	 * @return
	 */
	@GetMapping("/{id}")
	public Result<DishVO> getDishById(@PathVariable Long id) {
		return dishService.getDishById(id);
	}
	
	/**
	 * 修改菜品信息
	 *
	 * @param dishDTO
	 * @return
	 */
	@PutMapping
	public Result<String> updateDish(@RequestBody DishDTO dishDTO) {
		return dishService.updateDish(dishDTO);
	}
	
	/**
	 * 批量删除菜品
	 *
	 * @param idsString
	 * @return
	 */
	@DeleteMapping
	@Transactional(rollbackFor = Exception.class)
	public Result<String> deleteBatch(@RequestParam("ids") String idsString) {
		// 将字符串转化为列表
		List<Long> ids = Arrays.stream(idsString.split(","))
				.map(Long::valueOf)
				.collect(Collectors.toList());
		return dishService.deleteBatch(ids);
	}
}
