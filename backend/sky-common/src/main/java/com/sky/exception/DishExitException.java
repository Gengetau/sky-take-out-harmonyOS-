package com.sky.exception;

/**
 * 新增菜品已存在异常
 */
public class DishExitException extends BaseException {
	
	public DishExitException() {
	}
	
	public DishExitException(String msg) {
		super(msg);
	}
	
}
