package com.sky.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.sky.entity.AddressBook;

import java.util.List;

public interface AddressBookService extends IService<AddressBook> {
	/**
	 * 查询默认地址
	 *
	 * @return
	 */
	AddressBook getDefault();
	
	/**
	 * 查询当前登录用户的所有地址信息
	 *
	 * @return
	 */
	List<AddressBook> listByUser();
	
    /**
     * 新增地址
     * @param addressBook
     */
    void add(AddressBook addressBook);
}
}
