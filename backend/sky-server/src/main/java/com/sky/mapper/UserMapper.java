package com.sky.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.sky.entity.User;
import org.apache.ibatis.annotations.Mapper;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName UserMapper
 * @Description 用户持久层接口
 * @dateTime 3/12/2025 上午11:37
 */
@Mapper
public interface UserMapper extends BaseMapper<User> {
}
