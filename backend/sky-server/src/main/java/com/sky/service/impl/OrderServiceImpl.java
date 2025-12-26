package com.sky.service.impl;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.collection.CollUtil;
import cn.hutool.json.JSONUtil;
import com.alipay.api.AlipayClient;
import com.alipay.api.domain.AlipayTradePrecreateModel;
import com.alipay.api.request.AlipayTradePrecreateRequest;
import com.alipay.api.response.AlipayTradePrecreateResponse;
import com.aliyun.oss.OSS;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.sky.config.OSSConfig;
import com.sky.dto.*;
import com.sky.entity.*;
import com.sky.exception.AddressBookBusinessException;
import com.sky.exception.OrderBusinessException;
import com.sky.mapper.AddressBookMapper;
import com.sky.mapper.OrderMapper;
import com.sky.mapper.ShopMapper;
import com.sky.properties.AliPayProperties;
import com.sky.result.Result;
import com.sky.service.OrderDetailService;
import com.sky.service.OrderService;
import com.sky.service.UserService;
import com.sky.utils.AliOssUtil;
import com.sky.utils.AliPayUtil;
import com.sky.vo.*;
import com.sky.websocket.WebSocketServer;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import static com.sky.constant.MessageConstant.*;
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
	
	@Autowired
	private AddressBookMapper addressBookMapper;
	
	@Autowired
	private ShopMapper shopMapper;
	
	@Autowired
	private UserService userService;
	
	@Autowired
	private AlipayClient alipayClient;
	
	@Autowired
	private AliPayProperties aliPayProperties;
	
	@Autowired
	private AliPayUtil aliPayUtil;
	
	@Autowired
	private WebSocketServer webSocketServer;
	
	@Autowired
	private OSS ossClient;
	
	@Autowired
	private OSSConfig ossConfig;
	
	@Override
	public Result<Page<OrderVO>> getOrdersByPage(OrdersPageQueryDTO dto) {        // 1.获取分页数据
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
	public Result<OrderVO> userOrderDetail(Long id) {
		// 1.根据订单id 查询订单
		Orders order = getById(id);
		// 2.查询相关菜品
		List<OrderDetail> orderDetails = orderDetailService.list(new LambdaQueryWrapper<OrderDetail>()
				.eq(OrderDetail::getOrderId, id));
		List<String> strings = new ArrayList<>();

		// 处理图片签名
		if (CollUtil.isNotEmpty(orderDetails)) {
			orderDetails.forEach(orderDetail -> {
				strings.add(orderDetail.getName());
				String signedUrl = AliOssUtil.getSignedUrl(ossClient, orderDetail.getImage(), ossConfig.getBucketName());
				orderDetail.setImage(signedUrl);
			});
		}

		// 3.复制属性
		OrderVO orderVO = BeanUtil.copyProperties(order, OrderVO.class);
		orderVO.setOrderDishes(strings.toString());
		orderVO.setOrderDetailList(orderDetails);

		// 4. 查询并设置店铺名称
		Shop shop = shopMapper.getById(order.getShopId());
		if (shop != null) {
			orderVO.setShopName(shop.getName());
		}

		return Result.success(orderVO);
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
			// TODO 用户已付款,需要退款
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
	
	@Override
	@Transactional(rollbackFor = Exception.class)
	public Result<OrderSubmitVO> submit(OrdersSubmitDTO ordersSubmitDTO) {
		// 1. 业务异常处理（地址簿为空、购物车为空）
		AddressBook addressBook = addressBookMapper.selectById(ordersSubmitDTO.getAddressBookId());
		if (addressBook == null) {
			throw new AddressBookBusinessException(ADDRESS_BOOK_IS_NULL);
		}
		
		List<OrdersSubmitDTO.CartItem> cartItems = ordersSubmitDTO.getCartItems();
		if (cartItems == null || cartItems.isEmpty()) {
			throw new OrderBusinessException(SHOPPING_CART_IS_NULL);
		}
		
		Long userId = UserHolder.getUser().getId();
		User user = userService.getById(userId);
		
		// 2. 向订单表插入1条数据
		Orders orders = new Orders();
		BeanUtil.copyProperties(ordersSubmitDTO, orders);
		orders.setOrderTime(LocalDateTime.now());
		orders.setPayStatus(Orders.UN_PAID);
		orders.setStatus(Orders.PENDING_PAYMENT);
		orders.setNumber(String.valueOf(System.currentTimeMillis()) + userId);
		orders.setPhone(addressBook.getPhone());
		orders.setConsignee(addressBook.getConsignee());
		orders.setUserId(userId);
		orders.setUserName(user.getName());
		orders.setAddress(addressBook.getProvinceName() + addressBook.getCityName() + addressBook.getDistrictName() + addressBook.getDetail());
		
		this.save(orders);
		
		// 3. 向订单明细表插入n条数据
		List<OrderDetail> orderDetailList = new ArrayList<>();
		for (OrdersSubmitDTO.CartItem cartItem : cartItems) {
			OrderDetail orderDetail = new OrderDetail();
			BeanUtil.copyProperties(cartItem, orderDetail);
			orderDetail.setOrderId(orders.getId());
			// 处理图像链接
			String keyFromUrl = AliOssUtil.extractKeyFromUrl(orderDetail.getImage());
			orderDetail.setImage(keyFromUrl);
			orderDetailList.add(orderDetail);
		}
		
		orderDetailService.saveBatch(orderDetailList);
		
		// 4. 封装VO返回结果
		OrderSubmitVO orderSubmitVO = OrderSubmitVO.builder()
				.id(orders.getId())
				.orderTime(orders.getOrderTime())
				.orderNumber(orders.getNumber())
				.orderAmount(orders.getAmount())
				.build();
		
		return Result.success(orderSubmitVO);
	}
	
	@Override
	public Result<OrderPaymentVO> payment(OrdersPaymentDTO ordersPaymentDTO) throws Exception {
		// 1. 获取订单信息
		Orders order = this.getOne(new LambdaQueryWrapper<Orders>()
				.eq(Orders::getNumber, ordersPaymentDTO.getOrderNumber()));
		
		if (order == null) {
			throw new OrderBusinessException(ORDER_NOT_FOUND);
		}
		
		// 2. 调用支付宝预下单接口（当面付）
		AlipayTradePrecreateRequest request = new AlipayTradePrecreateRequest();
		AlipayTradePrecreateModel model = new AlipayTradePrecreateModel();
		model.setOutTradeNo(order.getNumber());
		model.setTotalAmount(order.getAmount().toString());
		model.setSubject("Meow外卖订单-" + order.getNumber());
		model.setProductCode("FACE_TO_FACE_PAYMENT");
		
		request.setBizModel(model);
		request.setNotifyUrl(aliPayProperties.getNotifyUrl());
		
		AlipayTradePrecreateResponse response = alipayClient.execute(request);
		
		if (response.isSuccess()) {
			log.info("支付宝预下单成功喵！二维码内容：{}", response.getQrCode());
			OrderPaymentVO vo = OrderPaymentVO.builder()
					.qrCode(response.getQrCode())
					.build();
			return Result.success(vo);
		} else {
			log.error("支付宝预下单失败喵！原因：{}", response.getSubMsg());
			throw new OrderBusinessException("支付宝预下单失败喵: " + response.getSubMsg());
		}
	}
	
	@Override
	public void paySuccess(String outTradeNo) {
		// 1. 根据订单号查询订单
		Orders order = this.getOne(new LambdaQueryWrapper<Orders>()
				.eq(Orders::getNumber, outTradeNo));
		
		// 2. 只有待付款的订单才需要更新状态喵
		if (order != null && order.getStatus().equals(Orders.PENDING_PAYMENT)) {
			order.setStatus(Orders.TO_BE_CONFIRMED);
			order.setPayStatus(Orders.PAID);
			order.setCheckoutTime(LocalDateTime.now());
			this.updateById(order);
			log.info("订单 {} 支付成功，状态已更新喵！", outTradeNo);
			
			// 通过WebSocket推送消息给客户端
			Map<String, Object> map = new HashMap<>();
			map.put("type", 1); // 1表示支付成功，2表示商家接单/拒单等（将来扩展用）
			map.put("orderId", order.getId());
			map.put("content", "订单支付成功");
			
			String json = JSONUtil.toJsonStr(map);
			webSocketServer.sendToClient(order.getUserId().toString(), json);
		}
	}
	
	@Override
	public Result<Page<OrderVO>> pageQuery4User(int page, int pageSize, Integer status) {
		// 1. 设置分页
		Page<Orders> pageInfo = new Page<>(page, pageSize);
		
		// 2. 构建查询条件
		LambdaQueryWrapper<Orders> queryWrapper = new LambdaQueryWrapper<>();
		queryWrapper.eq(Orders::getUserId, UserHolder.getUser().getId()); // 查询当前用户
		
		if (status != null) {
			queryWrapper.eq(Orders::getStatus, status);
		}
		
		// 按下单时间倒序
		queryWrapper.orderByDesc(Orders::getOrderTime);
		
		// 3. 执行查询
		this.page(pageInfo, queryWrapper);
		
		// 4. 查询订单明细并封装VO
		List<Orders> records = pageInfo.getRecords();
		List<OrderVO> orderVOList = new ArrayList<>();
		
		if (CollUtil.isNotEmpty(records)) {
			for (Orders orders : records) {
				OrderVO orderVO = new OrderVO();
				BeanUtil.copyProperties(orders, orderVO);
				
				// 查询订单明细
				List<OrderDetail> orderDetailList = orderDetailService.list(new LambdaQueryWrapper<OrderDetail>()
						.eq(OrderDetail::getOrderId, orders.getId()));
				
				// 处理每个订单明细的图片链接 (生成签名 URL)
				if (CollUtil.isNotEmpty(orderDetailList)) {
					for (OrderDetail orderDetail : orderDetailList) {
						String signedUrl = AliOssUtil.getSignedUrl(ossClient, orderDetail.getImage(), ossConfig.getBucketName());
						orderDetail.setImage(signedUrl); // 这里会替换原始 key 为签名 URL，仅用于 VO 展示，不会保存回库
					}
				}
				
				orderVO.setOrderDetailList(orderDetailList);
				
				// 查询店铺名称
				Shop shop = shopMapper.getById(orders.getShopId());
				if (shop != null) {
					orderVO.setShopName(shop.getName());
				}
				
				orderVOList.add(orderVO);
			}
		}
		
		// 5. 封装 Page<OrderVO> 返回
		Page<OrderVO> voPage = new Page<>(page, pageSize);
		voPage.setTotal(pageInfo.getTotal());
		voPage.setRecords(orderVOList);
		voPage.setPages(pageInfo.getPages());
		
		return Result.success(voPage);
	}
	
	@Override
	public Result<String> checkPayStatus(String orderNumber) throws Exception {
		// 1. 调用支付宝工具类查询状态
		String tradeStatus = aliPayUtil.queryOrder(orderNumber);
		
		// 2. 如果支付成功，且本地状态未更新，则更新
		if ("TRADE_SUCCESS".equals(tradeStatus) || "TRADE_FINISHED".equals(tradeStatus)) {
			log.info("主动查询发现订单 {} 已支付，开始修正状态... 喵", orderNumber);
			paySuccess(orderNumber);
		}
		
		return Result.success(tradeStatus);
	}
}