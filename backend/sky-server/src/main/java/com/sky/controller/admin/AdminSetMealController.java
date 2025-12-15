package com.sky.controller.admin;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.sky.dto.SetmealDTO;
import com.sky.dto.SetmealPageQueryDTO;
import com.sky.result.Result;
import com.sky.service.SetMealService;
import com.sky.vo.SetMealVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

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
	
	/**
	 * 修改套餐信息
	 *
	 * @param dto
	 * @return
	 */
	@PutMapping
	public Result<String> updateSetMeal(@RequestBody SetmealDTO dto) {
		return setMealService.updateSetMeal(dto);
	}
	
	/**
	 * 批量删除套餐
	 *
	 * @param idsString
	 * @return
	 */
	@DeleteMapping
	public Result<String> deleteBatch(@RequestParam("ids") String idsString) {
		// 将字符串转化为列表
		List<Long> ids = Arrays.stream(idsString.split(","))
				.map(Long::valueOf)
				.collect(Collectors.toList());
		return setMealService.deleteBatch(ids);
	}
}
