package com.sky.vo;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName CategoryVO
 * @Description 菜品分类VO
 * @dateTime 4/12/2025 上午11:21
 */
@Data
public class CategoryVO {
	// 主键
	private Long id;
	
	// 类型 1 菜品分类 2 套餐分类
	private Integer type;
	
	// 分类名称
	private String name;
	
	// 排序
	private Integer sort;
	
	private Integer status;
	
	private LocalDateTime updateTime;
}
