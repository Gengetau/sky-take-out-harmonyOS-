package com.sky.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.sky.entity.User;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.time.LocalDateTime;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName UserMapper
 * @Description 用户持久层接口
 * @dateTime 3/12/2025 上午11:37
 */
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@Mapper
public interface UserMapper extends BaseMapper<User> {
	Long getNewUserCountByTimeRange(LocalDateTime beginTime, LocalDateTime endTime);

	/**
	 * 根据时间范围统计用户数量
	 * @param beginTime
	 * @param endTime
	 * @return
	 */
	List<Map> getUserCount(LocalDateTime beginTime, LocalDateTime endTime);
}
