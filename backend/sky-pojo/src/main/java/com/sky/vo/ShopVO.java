package com.sky.vo;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.math.BigDecimal;

/**
 * 店铺VO (C端展示)
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ShopVO implements Serializable {

    private Long id;

    // 店铺名称
    private String name;

    // 店铺Logo
    private String avatar;

    // 评分
    private BigDecimal score;

    // 月售单量
    private Integer monthlySales;

    // 起送价
    private BigDecimal deliveryPrice;

    // 配送费
    private BigDecimal shippingFee;

    // 平均配送时间 (分钟)
    private Integer averageDeliveryTime;

    // 店铺简介
    private String description;
    
    // 地址
    private String address;
    
    // 距离 (单位: km/m，预留)
    private String distance;
    
    // 营业状态 0:打烊 1:营业
    private Integer status;
}
