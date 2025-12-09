package com.sky.vo;

public class UserHolder {
	private static final ThreadLocal<UserLoginVO> tl = new ThreadLocal<>();
	
	public static void saveUser(UserLoginVO user) {
		tl.set(user);
	}
	
	public static UserLoginVO getUser() {
		return tl.get();
	}
	
	public static void removeUser() {
		tl.remove();
	}
}
