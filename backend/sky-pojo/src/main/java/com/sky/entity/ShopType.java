package com.sky.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName ShopType
 * @Description shop_type
 * @dateTime 3/12/2025 下午5:11
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@TableName(value = "shop_type")
public class ShopType {
	@TableId(type = IdType.AUTO)
	private Long id;
	
	private String name;
	
	private String icon;
	
	private Integer sort;
	
	private LocalDateTime createTime;
	
	private LocalDateTime updateTime;
}
