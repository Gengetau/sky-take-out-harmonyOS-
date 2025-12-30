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
	 *
	 * @param addressBook
	 */
	void add(AddressBook addressBook);

	/**
	 * 设置默认地址
	 *
	 * @param id
	 */
	void setDefault(Long id);

	/**
	 * 根据id查询地址
	 *
	 * @param id
	 * @return
	 */
	AddressBook getById(Long id);

	/**
	 * 根据id修改地址
	 *
	 * @param addressBook
	 */
	void update(AddressBook addressBook);

	/**
	 * 根据id删除地址
	 *
	 * @param id
	 */
	void deleteById(Long id);
}
