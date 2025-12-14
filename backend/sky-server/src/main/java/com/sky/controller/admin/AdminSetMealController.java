package com.sky.controller.admin;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.sky.dto.SetmealDTO;
import com.sky.dto.SetmealPageQueryDTO;
import com.sky.result.Result;
import com.sky.service.SetMealService;
import com.sky.vo.SetMealVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName AdminSetMealController
 * @Description 后台套餐管理控制器
 * @dateTime 12/12/2025 上午9:04
 */
@RestController
@RequestMapping("/admin/setmeal")
public class AdminSetMealController {
	@Autowired
	private SetMealService setMealService;
	
	/**
	 * 套餐分页查询
	 *
	 * @param dto
	 * @return
	 */
	@GetMapping("/page")
	public Result<Page<SetMealVO>> getSetMealByPage(SetmealPageQueryDTO dto) {
		return setMealService.getSetMealByPage(dto);
	}
	
	/**
	 * 套餐启售停售
	 *
	 * @param status
	 * @return
	 */
	@PostMapping("/status/{status}")
	public Result<String> setMealStatus(@PathVariable("status") Integer status, Long id) {
		return setMealService.setMealStatus(status, id);
	}
	
	/**
	 * 新增套餐
	 *
	 * @param dto
	 * @return
	 */
	@PostMapping
	public Result<String> saveSetMeal(@RequestBody SetmealDTO dto) {
		return setMealService.saveSetMeal(dto);
	}
	
	/**
	 * 根据 id 查询套餐
	 *
	 * @param id
	 * @return
	 */
	@GetMapping("/{id}")
	public Result<SetMealVO> getSetMealById(@PathVariable("id") Long id) {
		return setMealService.getSetMealById(id);
	}
}
