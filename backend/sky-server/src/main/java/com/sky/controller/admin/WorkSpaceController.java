package com.sky.controller.admin;

import com.sky.result.Result;
import com.sky.service.WorkSpaceService;
import com.sky.vo.BusinessDataVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName WorkSpaceController
 * @Description 仪表盘控制器
 * @dateTime 9/12/2025 下午12:43
 */
@RestController
@RequestMapping("/admin/workspace")
public class WorkSpaceController {
	@Autowired
	private WorkSpaceService workSpaceService;
	
	/**
	 * 查询今日运营数据
	 *
	 * @return BusinessDataVO
	 */
	@GetMapping("/businessData")
	public Result<BusinessDataVO> getBusinessData() {
		return workSpaceService.getBusinessData();
	}
}
