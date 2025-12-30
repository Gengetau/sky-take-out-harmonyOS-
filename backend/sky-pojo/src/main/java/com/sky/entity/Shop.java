package com.sky.entity;

import com.baomidou.mybatisplus.annotation.FieldFill;
import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 店铺信息
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@TableName(value = "shop")
public class Shop implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId(type = IdType.AUTO)
    private Long id;

    // 店铺类型ID (对应 shop_type 表)
    private Long shopTypeId;

    // 店铺名称
    private String name;

    // 店铺Logo
    private String avatar;

    // 联系电话
    private String phone;

    // 详细地址
    private String address;

    // 省
    private String provinceName;

    // 市
    private String cityName;

    // 区/县
    private String districtName;

    // 经度
    private BigDecimal longitude;

    // 纬度
    private BigDecimal latitude;

    // 店铺简介
    private String description;

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

    // 营业时间
    private String openingHours;

    // 状态 0:打烊 1:营业
    private Integer status;

    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createTime;

    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updateTime;

    @TableField(fill = FieldFill.INSERT)
    private Long createUser;

    @TableField(fill = FieldFill.INSERT_UPDATE)
    private Long updateUser;
}
