package com.sky.controller.client;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.sky.dto.OrdersPaymentDTO;
import com.sky.dto.OrdersSubmitDTO;
import com.sky.result.Result;
import com.sky.service.OrderService;
import com.sky.vo.OrderPaymentVO;
import com.sky.vo.OrderSubmitVO;
import com.sky.vo.OrderVO;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

/**
 * @author Nia
 * @ClassName OrderController
 * @Description C端-订单相关接口
 */
@RestController
@RequestMapping("/client/order")
@Api(tags = "C端-订单相关接口")
@Slf4j
public class OrderController {
	
	@Autowired
	private OrderService orderService;
	
	/**
	 * 用户下单
	 *
	 * @param ordersSubmitDTO
	 * @return
	 */
	@PostMapping("/submit")
	@ApiOperation("用户下单")
	public Result<OrderSubmitVO> submit(@RequestBody OrdersSubmitDTO ordersSubmitDTO) {
		log.info("用户下单喵，参数为：{}", ordersSubmitDTO);
		return orderService.submit(ordersSubmitDTO);
	}
	
	/**
	 * 订单支付
	 *
	 * @param ordersPaymentDTO
	 * @return
	 */
	@PutMapping("/payment")
	@ApiOperation("订单支付")
	public Result<OrderPaymentVO> payment(@RequestBody OrdersPaymentDTO ordersPaymentDTO) throws Exception {
		log.info("订单支付喵：{}", ordersPaymentDTO);
		OrderPaymentVO orderPaymentVO = orderService.payment(ordersPaymentDTO).getData();
		log.info("生成预支付交易单喵：{}", orderPaymentVO);
		return Result.success(orderPaymentVO);
	}
	
	/**
	 * 历史订单查询
	 *
	 * @param page
	 * @param pageSize
	 * @param status   订单状态 1待付款 2待接单 3已接单 4派送中 5已完成 6已取消
	 * @return
	 */
	@GetMapping("/historyOrders")
	@ApiOperation("历史订单查询")
	public Result<Page<OrderVO>> page(int page, int pageSize, Integer status) {
		log.info("历史订单查询喵，page={}, pageSize={}, status={}", page, pageSize, status);
		return orderService.pageQuery4User(page, pageSize, status);
	}
}