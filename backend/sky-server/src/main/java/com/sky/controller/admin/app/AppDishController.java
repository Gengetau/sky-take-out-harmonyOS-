package com.sky.controller.admin.app;

import com.sky.context.BaseContext;
import com.sky.dto.DishDTO;
import com.sky.result.Result;
import com.sky.service.DishService;
import com.sky.vo.DishVO;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 商家App端菜品管理
 */
@RestController
@RequestMapping("/admin/app/dish")
@Slf4j
@Api(tags = "商家App端-菜品相关接口")
public class AppDishController {

    @Autowired
    private DishService dishService;

    /**
     * 根据分类id查询菜品
     */
    @GetMapping("/list")
    @ApiOperation("根据分类id查询菜品")
    public Result<List<DishVO>> list(Long categoryId) {
        Long shopId = BaseContext.getCurrentShopId();
        log.info("App端根据分类查询菜品，分类ID: {}，店铺ID: {} 喵", categoryId, shopId);
        return dishService.getShopDishListByCategory(categoryId, shopId);
    }

    /**
     * 根据id查询菜品
     */
    @GetMapping("/{id}")
    @ApiOperation("根据id查询菜品")
    public Result<DishVO> getById(@PathVariable Long id) {
        Long shopId = BaseContext.getCurrentShopId();
        log.info("App端查询菜品详情，ID: {}，店铺ID: {} 喵", id, shopId);
        return dishService.getShopDishById(id, shopId);
    }

    /**
     * 菜品起售停售
     */
    @PostMapping("/status/{status}")
    @ApiOperation("菜品起售停售")
    public Result<String> startOrStop(@PathVariable Integer status, Long id) {
        Long shopId = BaseContext.getCurrentShopId();
        log.info("App端修改菜品状态，ID: {}, 状态: {}, 店铺ID: {} 喵", id, status, shopId);
        return dishService.shopStartOrStop(status, id, shopId);
    }

    /**
     * 新增菜品
     */
    @PostMapping
    @ApiOperation("新增菜品")
    public Result<String> save(@RequestBody DishDTO dishDTO) {
        Long shopId = BaseContext.getCurrentShopId();
        log.info("App端新增菜品：{}, 店铺ID: {} 喵", dishDTO, shopId);
        return dishService.addShopDish(dishDTO, shopId);
    }

    /**
     * 修改菜品
     */
    @PutMapping
    @ApiOperation("修改菜品")
    public Result<String> update(@RequestBody DishDTO dishDTO) {
        Long shopId = BaseContext.getCurrentShopId();
        log.info("App端修改菜品：{}, 店铺ID: {} 喵", dishDTO, shopId);
        return dishService.updateShopDish(dishDTO, shopId);
    }

    /**
     * 批量删除菜品
     */
    @DeleteMapping
    @ApiOperation("批量删除菜品")
    public Result<String> delete(@RequestParam List<Long> ids) {
        Long shopId = BaseContext.getCurrentShopId();
        log.info("App端批量删除菜品：{}, 店铺ID: {} 喵", ids, shopId);
        return dishService.deleteShopDishes(ids, shopId);
    }
}