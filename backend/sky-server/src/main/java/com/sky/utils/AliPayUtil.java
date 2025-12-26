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
     * @param outTradeNo 商户订单号
     * @return 交易状态 (WAIT_BUYER_PAY, TRADE_CLOSED, TRADE_SUCCESS, TRADE_FINISHED)
     *         如果查询失败或发生异常，返回 null
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
}
