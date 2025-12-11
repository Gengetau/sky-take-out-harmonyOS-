package com.sky.vo;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName EmployeeVO
 * @Description 员工信息展示VO
 * @dateTime 10/12/2025 下午1:26
 */
@Data
public class EmployeeVO {
	private Long id;
	
	private String username;
	
	private String name;
	
	private String phone;
	
	private String sex;
	
	private String idNumber;
	
	private Integer status;
	
	private LocalDateTime updateTime;
}
