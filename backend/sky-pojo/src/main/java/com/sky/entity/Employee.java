package com.sky.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@TableName(value = "employee")
public class Employee implements Serializable {
	
	private static final long serialVersionUID = 1L;
	
	@TableId(type = IdType.AUTO)
	private Long id;
	
	private String username;
	
	private String name;
	
	private String password;
	
	private String salt;
	
	private String phone;
	
	private String sex;
	
	private String idNumber;
	
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
