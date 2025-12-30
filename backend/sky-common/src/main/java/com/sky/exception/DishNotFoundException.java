package com.sky.exception;

/**
 * 新增菜品不存在异常
 */
public class DishNotFoundException extends BaseException {
	
	public DishNotFoundException() {
	}
	
	public DishNotFoundException(String msg) {
		super(msg);
	}
	
}
