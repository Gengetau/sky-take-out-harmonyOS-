package com.sky.controller.admin.app;

import com.sky.context.BaseContext;
import com.sky.result.Result;
import com.sky.service.ShopService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

/**
 * 商家App端店铺管理
 */
@Slf4j
@RestController
@RequestMapping("/admin/app/shop")
@Api(tags = "商家App端-店铺相关接口")
public class AppShopController {

    @Autowired
    private ShopService shopService;

    /**
     * 获取店铺营业状态
     */
    @GetMapping("/status")
    @ApiOperation("获取店铺营业状态")
    public Result<Integer> getStatus() {
        Long shopId = BaseContext.getCurrentShopId();
        log.info("App端获取店铺 {} 营业状态", shopId);
        
        // 也可以直接查数据库，这里通过服务层获取
        return Result.success(shopService.getById(shopId).getStatus());
    }

    /**
     * 设置店铺营业状态
     *
     * @param status 1:营业 0:打烊
     */
    @PutMapping("/{status}")
    @ApiOperation("设置店铺营业状态")
    public Result<String> setStatus(@PathVariable Integer status) {
        Long shopId = BaseContext.getCurrentShopId();
        log.info("App端设置店铺 {} 状态为: {}", shopId, status);
        
        shopService.updateStatus(shopId, status);
        return Result.success();
    }
}
