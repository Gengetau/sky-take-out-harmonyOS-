package com.sky.service;

import com.sky.result.Result;
import com.sky.vo.BusinessDataVO;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName WorkSpaceService
 * @Description 仪表盘业务层接口
 * @dateTime 9/12/2025 下午12:51
 */
public interface WorkSpaceService {
	Result<BusinessDataVO> getBusinessData();
}
