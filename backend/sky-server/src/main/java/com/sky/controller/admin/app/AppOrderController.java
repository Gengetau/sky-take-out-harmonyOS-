package com.sky.controller.admin.app;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.sky.context.BaseContext;
import com.sky.dto.OrdersCancelDTO;
import com.sky.dto.OrdersConfirmDTO;
import com.sky.dto.OrdersPageQueryDTO;
import com.sky.dto.OrdersRejectionDTO;
import com.sky.exception.OrderBusinessException;
import com.sky.result.Result;
import com.sky.service.OrderService;
import com.sky.vo.OrderStatisticsVO;
import com.sky.vo.OrderVO;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

/**
 * 商家App端订单管理
 */
@RestController
@RequestMapping("/admin/app/order")
@Slf4j
@Api(tags = "商家App端-订单相关接口")
public class AppOrderController {

    @Autowired
    private OrderService orderService;

    /**
     * 商家端分页查询订单
     */
    @GetMapping("/conditionSearch")
    @ApiOperation("商家端分页查询订单")
    public Result<Page<OrderVO>> getOrdersByPage(OrdersPageQueryDTO dto) {
        Long shopId = BaseContext.getCurrentShopId();
        log.info("商家App查询订单，店铺ID: {} 喵", shopId);
        return orderService.getShopOrdersByPage(dto, shopId);
    }

    /**
     * 各个状态的订单数量统计
     */
    @GetMapping("/statistics")
    @ApiOperation("商家端订单数量统计")
    public Result<OrderStatisticsVO> getOrderStatistics() {
        Long shopId = BaseContext.getCurrentShopId();
        log.info("商家App统计订单，店铺ID: {} 喵", shopId);
        return orderService.getShopOrderStatistics(shopId);
    }

    /**
     * 查询订单详情
     */
    @GetMapping("/details/{id}")
    @ApiOperation("商家端查询订单详情")
    public Result<OrderVO> getOrderDetailById(@PathVariable Long id) {
        log.info("商家App查询订单详情，ID: {} 喵", id);
        Result<OrderVO> result = orderService.getOrderDetailById(id);
        
        // 数据安全校验：确保商家只能看自家的订单
        if (result.getData() != null && !result.getData().getShopId().equals(BaseContext.getCurrentShopId())) {
            throw new OrderBusinessException("越权访问：您无权查看该订单喵！");
        }
        return result;
    }

    /**
     * 接单
     */
    @PutMapping("/confirm")
    @ApiOperation("商家端接单")
    public Result<String> confirm(@RequestBody OrdersConfirmDTO dto) {
        checkOrderOwnership(dto.getId());
        return orderService.confirm(dto);
    }

    /**
     * 拒单
     */
    @PutMapping("/rejection")
    @ApiOperation("商家端拒单")
    public Result<String> rejection(@RequestBody OrdersRejectionDTO dto) {
        checkOrderOwnership(dto.getId());
        return orderService.rejection(dto);
    }

    /**
     * 取消订单
     */
    @PutMapping("/cancel")
    @ApiOperation("商家端取消订单")
    public Result<String> cancel(@RequestBody OrdersCancelDTO dto) {
        checkOrderOwnership(dto.getId());
        return orderService.cancel(dto);
    }

    /**
     * 派送订单
     */
    @PutMapping("/delivery/{id}")
    @ApiOperation("商家端派送订单")
    public Result<String> delivery(@PathVariable Long id) {
        checkOrderOwnership(id);
        return orderService.delivery(id);
    }

    /**
     * 完成订单
     */
    @PutMapping("/complete/{id}")
    @ApiOperation("商家端完成订单")
    public Result<String> complete(@PathVariable Long id) {
        checkOrderOwnership(id);
        return orderService.complete(id);
    }

    /**
     * 私有辅助方法：校验订单是否属于当前登录商家
     */
    private void checkOrderOwnership(Long orderId) {
        OrderVO order = orderService.getOrderDetailById(orderId).getData();
        if (order == null || !order.getShopId().equals(BaseContext.getCurrentShopId())) {
            log.warn("商家 {} 尝试越权操作订单 {} 喵！", BaseContext.getCurrentShopId(), orderId);
            throw new OrderBusinessException("操作失败：该订单不属于您的店铺喵！");
        }
    }
}
