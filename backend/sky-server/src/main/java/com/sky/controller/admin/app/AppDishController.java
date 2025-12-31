package com.sky.controller.admin.app;

import com.sky.context.BaseContext;
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
     * @param categoryId
     * @return
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
     * @param id
     * @return
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
     * @param status
     * @param id
     * @return
     */
    @PostMapping("/status/{status}")
    @ApiOperation("菜品起售停售")
    public Result<String> startOrStop(@PathVariable Integer status, Long id) {
        Long shopId = BaseContext.getCurrentShopId();
        log.info("App端修改菜品状态，ID: {}, 状态: {}, 店铺ID: {} 喵", id, status, shopId);
        return dishService.shopStartOrStop(status, id, shopId);
    }
}
