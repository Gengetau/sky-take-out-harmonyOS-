package com.sky.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.sky.entity.AddressBook;
import com.sky.mapper.AddressBookMapper;
import com.sky.service.AddressBookService;
import com.sky.vo.UserHolder;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@Slf4j
public class AddressBookServiceImpl extends ServiceImpl<AddressBookMapper, AddressBook> implements AddressBookService {

    /**
     * 查询默认地址
     * @return
     */
    @Override
    public AddressBook getDefault() {
        Long userId = UserHolder.getUser().getId();
        log.info("查询用户 {} 的默认地址喵", userId);
        
        LambdaQueryWrapper<AddressBook> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.eq(AddressBook::getUserId, userId);
        queryWrapper.eq(AddressBook::getIsDefault, 1);
        
        return getOne(queryWrapper);
    }

    /**
     * 条件查询
     * @param addressBook
     * @return
     */
    @Override
    public List<AddressBook> list(AddressBook addressBook) {
        LambdaQueryWrapper<AddressBook> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.eq(null != addressBook.getUserId(), AddressBook::getUserId, addressBook.getUserId());
        queryWrapper.eq(null != addressBook.getPhone(), AddressBook::getPhone, addressBook.getPhone());
        queryWrapper.eq(null != addressBook.getIsDefault(), AddressBook::getIsDefault, addressBook.getIsDefault());

        return list(queryWrapper);
    }
}
