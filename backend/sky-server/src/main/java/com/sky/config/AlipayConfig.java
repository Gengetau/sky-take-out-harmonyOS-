package com.sky.config;

import com.alipay.api.AlipayClient;
import com.alipay.api.DefaultAlipayClient;
import com.sky.properties.AliPayProperties;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
@Slf4j
public class AlipayConfig {

    @Bean
    public AlipayClient alipayClient(AliPayProperties aliPayProperties) {
        log.info("开始创建支付宝客户端喵...");
        return new DefaultAlipayClient(
                aliPayProperties.getGatewayUrl(),
                aliPayProperties.getAppId(),
                aliPayProperties.getAppPrivateKey(),
                "json",
                "utf-8",
                aliPayProperties.getAlipayPublicKey(),
                "RSA2"
        );
    }
}
