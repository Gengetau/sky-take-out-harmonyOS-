package com.sky.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.sky.entity.AddressBook;

import java.util.List;

public interface AddressBookService extends IService<AddressBook> {
    /**
     * 查询默认地址
     * @return
     */
    AddressBook getDefault();

    /**
     * 条件查询
     * @param addressBook
     * @return
     */
    List<AddressBook> list(AddressBook addressBook);
}
