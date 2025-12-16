package com.sky.service.impl;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.collection.CollUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.sky.dto.OrdersCancelDTO;
import com.sky.dto.OrdersConfirmDTO;
import com.sky.dto.OrdersPageQueryDTO;
import com.sky.dto.OrdersRejectionDTO;
import com.sky.entity.OrderDetail;
import com.sky.entity.Orders;
import com.sky.exception.OrderBusinessException;
import com.sky.mapper.OrderMapper;
import com.sky.result.Result;
import com.sky.service.OrderDetailService;
import com.sky.service.OrderService;
import com.sky.vo.OrderStatisticsVO;
import com.sky.vo.OrderVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import static com.sky.constant.MessageConstant.ORDER_NOT_FOUND;
import static com.sky.constant.MessageConstant.ORDER_STATUS_ERROR;
import static com.sky.entity.Orders.*;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName OrderServiceImpl
 * @Description
 * @dateTime 9/12/2025 下午1:09
 */
@Service
@Slf4j
public class OrderServiceImpl extends ServiceImpl<OrderMapper, Orders> implements OrderService {
	@Autowired
	private OrderDetailService orderDetailService;
	
	@Override
	public Result<Page<OrderVO>> getOrdersByPage(OrdersPageQueryDTO dto) {
		// 1.获取分页数据
		int currentPage = dto.getPage();
		int pageSize = dto.getPageSize();
		// 2.构建分页模型
		Page<Orders> page = new Page<>(currentPage, pageSize);
		// 3.构建查询模型
		LambdaQueryWrapper<Orders> qw = new LambdaQueryWrapper<>();
		// 订单号查询
		qw.eq(dto.getNumber() != null, Orders::getNumber, dto.getNumber());
		// 手机号查询
		qw.eq(dto.getPhone() != null, Orders::getPhone, dto.getPhone());
		// 日期范围查询
		qw.ge(dto.getBeginTime() != null, Orders::getOrderTime, dto.getBeginTime());
		qw.le(dto.getEndTime() != null, Orders::getOrderTime, dto.getEndTime());
		// 状态查询
		qw.eq(dto.getStatus() != null, Orders::getStatus, dto.getStatus());
		// 4.查询
		Page<Orders> ordersPage = page(page, qw);
		// 校验
		if (CollUtil.isEmpty(ordersPage.getRecords())) {
			throw new OrderBusinessException(ORDER_NOT_FOUND);
		}
		// 5.查询订单菜品
		List<Long> orderIds = ordersPage.getRecords().stream()
				.map(Orders::getId)
				.collect(Collectors.toList());
		// 转化为map集合
		Map<Long, List<String>> orderDetailMap = orderDetailService.list(new LambdaQueryWrapper<OrderDetail>()
						.in(OrderDetail::getOrderId, orderIds))
				.stream()
				.collect(Collectors.groupingBy(OrderDetail::getOrderId,
						Collectors.mapping(OrderDetail::getName, Collectors.toList())));
		// 复制属性
		List<OrderVO> orderVOS = BeanUtil.copyToList(ordersPage.getRecords(), OrderVO.class);
		// 遍历设置属性
		orderVOS.forEach(orderVO -> {
			List<String> strings = orderDetailMap.get(orderVO.getId());
			orderVO.setOrderDishes(strings.toString());
		});
		// 构建VO分页模型
		Page<OrderVO> orderVOPage = new Page<>(currentPage, pageSize);
		orderVOPage.setRecords(orderVOS);
		orderVOPage.setTotal(page.getTotal());
		// 返回
		return Result.success(orderVOPage);
	}
	
	@Override
	public Result<OrderStatisticsVO> getOrderStatistics() {
		// 1.待接单数量
		long toBeConfirmed = count(new LambdaQueryWrapper<Orders>()
				.eq(Orders::getStatus, TO_BE_CONFIRMED));
		// 2.待派送数量
		long confirmed = count(new LambdaQueryWrapper<Orders>()
				.eq(Orders::getStatus, CONFIRMED));
		// 3.派送中数量
		long deliveryInProgress = count(new LambdaQueryWrapper<Orders>()
				.eq(Orders::getStatus, DELIVERY_IN_PROGRESS));
		OrderStatisticsVO vo = OrderStatisticsVO.builder()
				.toBeConfirmed(toBeConfirmed)
				.confirmed(confirmed)
				.deliveryInProgress(deliveryInProgress)
				.build();
		return Result.success(vo);
	}
	
	@Override
	public Result<OrderVO> getOrderDetailById(Long id) {
		// 1.根据订单id 查询订单
		Orders order = getById(id);
		// 2.查询相关菜品
		List<OrderDetail> orderDetails = orderDetailService.list(new LambdaQueryWrapper<OrderDetail>()
				.eq(OrderDetail::getOrderId, id));
		List<String> strings = new ArrayList<>();
		orderDetails.forEach(orderDetail -> {
			strings.add(orderDetail.getName());
		});
		// 3.复制属性
		OrderVO orderVO = BeanUtil.copyProperties(order, OrderVO.class);
		orderVO.setOrderDishes(strings.toString());
		orderVO.setOrderDetailList(orderDetails);
		return Result.success(orderVO);
	}

	@Override
	public Result<String> cancel(OrdersCancelDTO dto) {
		// 1.根据id查询订单
		Orders orders = getById(dto.getId());
		// 2.判断订单状态
		if (orders.getStatus() > 2) {
			throw new OrderBusinessException(ORDER_STATUS_ERROR);
		}
		// 3.已接单,但已付款,需要退款
		if (orders.getPayStatus().equals(PAID)) {
			// TODO 退款操作
		}
		// 4.更新订单状态
		orders.setStatus(CANCELLED);
		orders.setCancelReason(dto.getCancelReason());
		orders.setCancelTime(LocalDateTime.now());
		updateById(orders);
		return Result.success();
	}

	@Override
	public Result<String> confirm(OrdersConfirmDTO dto) {
		Orders orders = getById(dto.getId());
		if (!orders.getStatus().equals(TO_BE_CONFIRMED)) {
			throw new OrderBusinessException(ORDER_STATUS_ERROR);
		}
		orders.setStatus(CONFIRMED);
		updateById(orders);
		return Result.success();
	}

	@Override
	public Result<String> rejection(OrdersRejectionDTO dto) {
		Orders orders = getById(dto.getId());
		if (!orders.getStatus().equals(TO_BE_CONFIRMED)) {
			throw new OrderBusinessException(ORDER_STATUS_ERROR);
		}
		if (orders.getPayStatus().equals(PAID)) {
			//TODO 用户已付款,需要退款
		}
		orders.setStatus(CANCELLED);
		orders.setRejectionReason(dto.getRejectionReason());
		orders.setCancelTime(LocalDateTime.now());
		updateById(orders);
		return Result.success();
	}

	@Override
	public Result<String> complete(Long id) {
		Orders orders = getById(id);
		if (!orders.getStatus().equals(DELIVERY_IN_PROGRESS)) {
			throw new OrderBusinessException(ORDER_STATUS_ERROR);
		}
		orders.setStatus(COMPLETED);
		updateById(orders);
		return Result.success();
	}

	@Override
	public Result<String> delivery(Long id) {
		Orders orders = getById(id);
		if (!orders.getStatus().equals(CONFIRMED)) {
			throw new OrderBusinessException(ORDER_STATUS_ERROR);
		}
		orders.setStatus(DELIVERY_IN_PROGRESS);
		updateById(orders);
		return Result.success();
	}
}
