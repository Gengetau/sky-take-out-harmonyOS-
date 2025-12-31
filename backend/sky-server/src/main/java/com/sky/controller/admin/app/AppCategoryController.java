package com.sky.controller.admin.app;

import com.sky.context.BaseContext;
import com.sky.result.Result;
import com.sky.service.CategoryService;
import com.sky.vo.CategoryVO;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 商家App端分类管理
 */
@RestController
@RequestMapping("/admin/app/category")
@Slf4j
@Api(tags = "商家App端-分类相关接口")
public class AppCategoryController {

    @Autowired
    private CategoryService categoryService;

    /**
     * 根据类型查询分类
     * @param type 1:菜品分类 2:套餐分类
     * @return
     */
    @GetMapping("/list")
    @ApiOperation("根据类型查询分类")
    public Result<List<CategoryVO>> list(Integer type) {
        Long shopId = BaseContext.getCurrentShopId();
        log.info("App端根据类型查询分类: {}, 店铺ID: {} 喵", type, shopId);
        return categoryService.getShopCategoryByType(type, shopId);
    }
}
