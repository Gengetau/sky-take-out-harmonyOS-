package com.sky.exception;

/**
 * 分类不存在异常
 */
public class CategoryNotFoundException extends BaseException {
	
	public CategoryNotFoundException() {
	}
	
	public CategoryNotFoundException(String msg) {
		super(msg);
	}
	
}
