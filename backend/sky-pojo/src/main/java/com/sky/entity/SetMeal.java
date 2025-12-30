package com.sky.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 套餐
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@TableName(value = "set_meal")
public class SetMeal implements Serializable {
	
	private static final long serialVersionUID = 1L;
	
	@TableId(type = IdType.AUTO)
	private Long id;
	
	// 分类id
	private Long categoryId;
	
	// 套餐名称
	private String name;
	
	// 套餐价格
	private BigDecimal price;
	
	// 状态 0:停用 1:启用
	private Integer status;
	
	// 描述信息
	private String description;
	
	// 图片
	private String image;
	
	@TableField(fill = FieldFill.INSERT)
	private LocalDateTime createTime;
	
	@TableField(fill = FieldFill.INSERT_UPDATE)
	private LocalDateTime updateTime;
	
	@TableField(fill = FieldFill.INSERT)
	private Long createUser;
	
	@TableField(fill = FieldFill.INSERT_UPDATE)
	private Long updateUser;

	// 店铺ID
	private Long shopId;
}