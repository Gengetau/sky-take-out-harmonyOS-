package com.sky.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.sky.entity.Category;
import com.sky.result.Result;
import com.sky.vo.CategoryVO;

import java.util.List;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName CategoryService
 * @Description 菜品分类业务层接口
 * @dateTime 4/12/2025 上午11:03
 */
public interface CategoryService extends IService<Category> {
	Result<List<CategoryVO>> queryAllCategory(Integer type);
}
