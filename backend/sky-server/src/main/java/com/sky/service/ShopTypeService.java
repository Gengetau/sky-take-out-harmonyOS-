package com.sky.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.sky.entity.ShopType;
import com.sky.result.Result;
import com.sky.vo.ShopTypeVO;

import java.util.List;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName ShopTypeService
 * @Description 店铺类型业务层接口
 * @dateTime 3/12/2025 下午5:15
 */
public interface ShopTypeService extends IService<ShopType> {
	Result<List<ShopTypeVO>> queryList();
}
