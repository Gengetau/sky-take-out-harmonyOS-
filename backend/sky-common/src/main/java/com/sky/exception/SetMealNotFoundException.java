package com.sky.exception;

/**
 * 新增套餐不存在异常
 */
public class SetMealNotFoundException extends BaseException {
	
	public SetMealNotFoundException() {
	}
	
	public SetMealNotFoundException(String msg) {
		super(msg);
	}
	
}
