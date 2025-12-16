package com.sky.service;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.IService;
import com.sky.dto.OrdersCancelDTO;
import com.sky.dto.OrdersConfirmDTO;
import com.sky.dto.OrdersPageQueryDTO;
import com.sky.dto.OrdersRejectionDTO;
import com.sky.entity.Orders;
import com.sky.result.Result;
import com.sky.vo.OrderStatisticsVO;
import com.sky.vo.OrderVO;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName OrderService
 * @Description 订单业务层接口
 * @dateTime 9/12/2025 下午1:08
 */
public interface OrderService extends IService<Orders> {
	Result<Page<OrderVO>> getOrdersByPage(OrdersPageQueryDTO dto);
	
	Result<OrderStatisticsVO> getOrderStatistics();
	
	Result<OrderVO> getOrderDetailById(Long id);
	
	Result<String> cancel(OrdersCancelDTO dto);
	
	Result<String> confirm(OrdersConfirmDTO dto);
	
	Result<String> rejection(OrdersRejectionDTO dto);

	Result<String> complete(Long id);

	Result<String> delivery(Long id);
}
