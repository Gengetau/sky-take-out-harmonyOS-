package com.sky.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.sky.entity.SetMeal;
import com.sky.mapper.SetMealMapper;
import com.sky.service.SetMealService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName SetMealServiceImpl
 * @Description 套餐业务层接口实现类
 * @dateTime 11/12/2025 上午10:56
 */
@Service
@Slf4j
public class SetMealServiceImpl extends ServiceImpl<SetMealMapper, SetMeal>
		implements SetMealService {
}
