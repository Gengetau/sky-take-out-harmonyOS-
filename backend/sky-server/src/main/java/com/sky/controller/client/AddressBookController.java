package com.sky.controller.client;

import com.sky.entity.AddressBook;
import com.sky.result.Result;
import com.sky.service.AddressBookService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.sky.vo.UserHolder;
import java.util.List;

@RestController
@RequestMapping("/client/addressBook")
@Api(tags = "C端-地址簿相关接口")
@Slf4j
public class AddressBookController {

    @Autowired
    private AddressBookService addressBookService;

    /**
     * 查询当前登录用户的所有地址信息
     * @return
     */
    @GetMapping("/list")
    @ApiOperation("查询当前登录用户的所有地址信息")
    public Result<List<AddressBook>> list() {
        AddressBook addressBook = new AddressBook();
        addressBook.setUserId(UserHolder.getUser().getId());
        return Result.success(addressBookService.list(addressBook));
    }

    /**
     * 查询默认地址
     * @return
     */
    @GetMapping("/default")
    @ApiOperation("查询默认地址")
    public Result<AddressBook> getDefault() {
        log.info("查询当前用户的默认地址喵");
        AddressBook addressBook = addressBookService.getDefault();
        if (addressBook != null) {
            return Result.success(addressBook);
        }
        return Result.error("没有找到默认地址喵");
    }
}
