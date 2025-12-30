package com.sky.vo;

import lombok.Data;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName ShopTypeVO
 * @Description 店铺类型VO
 * @dateTime 3/12/2025 下午5:19
 */
@Data
public class ShopTypeVO {
	private Long id;
	
	private String name;
	
	private String icon;
	
	private Integer sort;
}
