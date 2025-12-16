package com.sky.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.sky.entity.OrderDetail;
import com.sky.mapper.OrderDetailMapper;
import com.sky.service.OrderDetailService;
import org.springframework.stereotype.Service;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName OrderDetailServiceImpl
 * @Description
 * @dateTime 15/12/2025 上午11:25
 */
@Service
public class OrderDetailServiceImpl extends ServiceImpl<OrderDetailMapper, OrderDetail>
		implements OrderDetailService {
}
