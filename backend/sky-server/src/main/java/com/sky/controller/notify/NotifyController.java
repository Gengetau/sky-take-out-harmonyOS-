package com.sky.controller.notify;

import com.alipay.api.internal.util.AlipaySignature;
import com.sky.properties.AliPayProperties;
import com.sky.service.OrderService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.servlet.http.HttpServletRequest;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/notify")
@Api(tags = "支付回调相关接口")
@Slf4j
public class NotifyController {

    @Autowired
    private OrderService orderService;

    @Autowired
    private AliPayProperties aliPayProperties;

    /**
     * 支付宝异步回调
     * @param request
     * @return
     */
    @PostMapping("/alipay")
    @ApiOperation("支付宝异步回调")
    public String alipayNotify(HttpServletRequest request) throws Exception {
        log.info("收到支付宝异步回调喵...");
        
        // 1. 获取所有参数
        Map<String, String> params = new HashMap<>();
        Map<String, String[]> requestParams = request.getParameterMap();
        for (String name : requestParams.keySet()) {
            params.put(name, request.getParameter(name));
        }

        // 2. 验签
        boolean verifyResult = AlipaySignature.rsaCheckV1(
                params,
                aliPayProperties.getAlipayPublicKey(),
                "utf-8",
                "RSA2"
        );

        if (verifyResult) {
            // 3. 验签通过，检查交易状态
            String tradeStatus = params.get("trade_status");
            String outTradeNo = params.get("out_trade_no");
            
            log.info("支付宝回调验签成功喵！订单号：{}，状态：{}", outTradeNo, tradeStatus);

            if ("TRADE_SUCCESS".equals(tradeStatus) || "TRADE_FINISHED".equals(tradeStatus)) {
                // 4. 更新订单状态
                orderService.paySuccess(outTradeNo);
            }
            return "success";
        } else {
            log.error("支付宝回调验签失败喵！参数：{}", params);
            return "fail";
        }
    }
}
