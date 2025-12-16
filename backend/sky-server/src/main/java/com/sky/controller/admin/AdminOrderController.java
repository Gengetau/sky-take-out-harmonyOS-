package com.sky.controller.admin;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.sky.dto.OrdersPageQueryDTO;
import com.sky.result.Result;
import com.sky.service.OrderService;
import com.sky.vo.OrderStatisticsVO;
import com.sky.vo.OrderVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName AdminOrderController
 * @Description 后台订单控制器
 * @dateTime 15/12/2025 上午10:22
 */
@RestController
@RequestMapping("/admin/order")
public class AdminOrderController {
	@Autowired
	private OrderService orderService;
	
	/**
	 * 后台分页查询订单
	 *
	 * @param dto
	 * @return
	 */
	@GetMapping("/conditionSearch")
	public Result<Page<OrderVO>> getOrdersByPage(OrdersPageQueryDTO dto) {
		return orderService.getOrdersByPage(dto);
	}
	
	/**
	 * 各个状态的订单数量统计
	 *
	 * @return
	 */
	@GetMapping("/statistics")
	public Result<OrderStatisticsVO> getOrderStatistics() {
		return orderService.getOrderStatistics();
	}
	
	/**
	 * 查询订单详情
	 *
	 * @param id
	 * @return
	 */
	@GetMapping("/details/{id}")
	public Result<OrderVO> getOrderDetailById(@PathVariable Long id) {
		return orderService.getOrderDetailById(id);
	}
}
