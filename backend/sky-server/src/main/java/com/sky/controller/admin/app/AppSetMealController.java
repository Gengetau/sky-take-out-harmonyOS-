package com.sky.controller.admin.app;

import com.sky.context.BaseContext;
import com.sky.dto.SetmealDTO;
import com.sky.result.Result;
import com.sky.service.SetMealService;
import com.sky.vo.SetMealVO;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 商家App端套餐管理
 */
@RestController
@RequestMapping("/admin/app/setmeal")
@Slf4j
@Api(tags = "商家App端-套餐相关接口")
public class AppSetMealController {

    @Autowired
    private SetMealService setMealService;

    /**
     * 根据分类id查询套餐
     */
    @GetMapping("/list")
    @ApiOperation("根据分类id查询套餐")
    public Result<List<SetMealVO>> list(Long categoryId) {
        Long shopId = BaseContext.getCurrentShopId();
        log.info("App端根据分类查询套餐，分类ID: {}，店铺ID: {} 喵", categoryId, shopId);
        return setMealService.getShopSetMealListByCategory(categoryId, shopId);
    }

    /**
     * 根据id查询套餐
     */
    @GetMapping("/{id}")
    @ApiOperation("根据id查询套餐")
    public Result<SetMealVO> getById(@PathVariable Long id) {
        Long shopId = BaseContext.getCurrentShopId();
        log.info("App端查询套餐详情，ID: {}，店铺ID: {} 喵", id, shopId);
        return setMealService.getShopSetMealById(id, shopId);
    }

    /**
     * 套餐起售停售
     */
    @PostMapping("/status/{status}")
    @ApiOperation("套餐起售停售")
    public Result<String> startOrStop(@PathVariable Integer status, Long id) {
        Long shopId = BaseContext.getCurrentShopId();
        log.info("App端修改套餐状态，ID: {}, 状态: {}, 店铺ID: {} 喵", id, status, shopId);
        return setMealService.shopSetMealStatus(status, id, shopId);
    }

    /**
     * 新增套餐
     */
    @PostMapping
    @ApiOperation("新增套餐")
    public Result<String> save(@RequestBody SetmealDTO setmealDTO) {
        Long shopId = BaseContext.getCurrentShopId();
        log.info("App端新增套餐：{}, 店铺ID: {} 喵", setmealDTO, shopId);
        return setMealService.addShopSetMeal(setmealDTO, shopId);
    }

    /**
     * 修改套餐
     */
    @PutMapping
    @ApiOperation("修改套餐")
    public Result<String> update(@RequestBody SetmealDTO setmealDTO) {
        Long shopId = BaseContext.getCurrentShopId();
        log.info("App端修改套餐：{}, 店铺ID: {} 喵", setmealDTO, shopId);
        return setMealService.updateShopSetMeal(setmealDTO, shopId);
    }

    /**
     * 批量删除套餐
     */
    @DeleteMapping
    @ApiOperation("批量删除套餐")
    public Result<String> delete(@RequestParam List<Long> ids) {
        Long shopId = BaseContext.getCurrentShopId();
        log.info("App端批量删除套餐：{}, 店铺ID: {} 喵", ids, shopId);
        return setMealService.deleteShopSetMeals(ids, shopId);
    }
}