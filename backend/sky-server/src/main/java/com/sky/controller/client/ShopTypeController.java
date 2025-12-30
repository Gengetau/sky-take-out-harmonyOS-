package com.sky.controller.client;

import com.sky.result.Result;
import com.sky.service.ShopTypeService;
import com.sky.vo.ShopTypeVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName ShopTypeController
 * @Description 店铺类型控制器
 * @dateTime 3/12/2025 下午5:14
 */
@RestController
@RequestMapping("/client/type")
public class ShopTypeController {
	@Autowired
	private ShopTypeService shopTypeService;
	
	// 查询店铺类型
	@GetMapping("/list")
	public Result<List<ShopTypeVO>> queryList() {
		return shopTypeService.queryList();
	}
}
