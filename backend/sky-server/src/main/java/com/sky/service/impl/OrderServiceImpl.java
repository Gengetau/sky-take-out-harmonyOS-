package com.sky.service.impl;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.collection.CollUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.sky.dto.OrdersPageQueryDTO;
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

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import static com.sky.constant.MessageConstant.ORDER_NOT_FOUND;
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
}
