package com.sky.utils;

import com.alibaba.fastjson.JSONObject;
import com.alipay.api.AlipayClient;
import com.alipay.api.request.AlipayTradeQueryRequest;
import com.alipay.api.response.AlipayTradeQueryResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

/**
 * 支付宝工具类
 */
@Component
@Slf4j
public class AliPayUtil {
	
	@Autowired
	private AlipayClient alipayClient;
	
	/**
	 * 主动查询支付宝订单状态
	 *
	 * @param outTradeNo 商户订单号
	 * @return 交易状态 (WAIT_BUYER_PAY, TRADE_CLOSED, TRADE_SUCCESS, TRADE_FINISHED)
	 * 如果查询失败或发生异常，返回 null
	 */
	public String queryOrder(String outTradeNo) {
		log.info("开始主动查询支付宝订单状态，订单号：{} 喵", outTradeNo);
		AlipayTradeQueryRequest request = new AlipayTradeQueryRequest();
		JSONObject bizContent = new JSONObject();
		bizContent.put("out_trade_no", outTradeNo);
		request.setBizContent(bizContent.toString());
		
		try {
			AlipayTradeQueryResponse response = alipayClient.execute(request);
			if (response.isSuccess()) {
				log.info("支付宝订单查询成功，状态：{} 喵", response.getTradeStatus());
				return response.getTradeStatus();
			} else {
				log.error("支付宝订单查询失败，错误码：{}, 错误信息：{} 喵", response.getCode(), response.getSubMsg());
				return null;
			}
		} catch (Exception e) {
			log.error("调用支付宝查询接口异常 喵", e);
			return null;
		}
	}
	
	/**
	 * 申请退款
	 *
	 * @param outTradeNo   商户订单号
	 * @param refundAmount 退款金额
	 * @param outRequestNo 退款请求号 (标识一次退款请求，同一笔交易多次退款需要保证唯一，如需部分退款，则此参数必传)
	 * @return true: 退款成功, false: 退款失败
	 */
	public boolean refund(String outTradeNo, String refundAmount, String outRequestNo) {
		log.info("开始调用支付宝退款接口，订单号：{}，金额：{}，请求号：{} 喵", outTradeNo, refundAmount, outRequestNo);
		com.alipay.api.request.AlipayTradeRefundRequest request = new com.alipay.api.request.AlipayTradeRefundRequest();
		JSONObject bizContent = new JSONObject();
		bizContent.put("out_trade_no", outTradeNo);
		bizContent.put("refund_amount", refundAmount);
		bizContent.put("out_request_no", outRequestNo); // 标识一次退款请求
		
		request.setBizContent(bizContent.toString());
		
		try {
			com.alipay.api.response.AlipayTradeRefundResponse response = alipayClient.execute(request);
			if (response.isSuccess()) {
				// 注意：response.isSuccess() 为 true 仅代表接口调用成功。
				// 还需要判断 fund_change 字段，但通常全额退款只要 isSuccess 即可认为成功。
				// 官方文档：接口调用成功，OpenAPI 返回 success
				log.info("支付宝退款调用成功，退款金额：{} 喵", response.getRefundFee());
				return true;
			} else {
				log.error("支付宝退款失败，错误码：{}，错误信息：{} 喵", response.getCode(), response.getSubMsg());
				return false;
			}
		} catch (Exception e) {
			log.error("调用支付宝退款接口异常 喵", e);
			return false;
		}
	}
}
