package com.sky.service.impl;

import cn.hutool.core.bean.BeanUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.CollectionUtils;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.sky.entity.Category;
import com.sky.mapper.CategoryMapper;
import com.sky.result.Result;
import com.sky.service.CategoryService;
import com.sky.vo.CategoryVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName CategoryServiceImpl
 * @Description
 * @dateTime 4/12/2025 上午11:04
 */
@Service
@Slf4j
public class CategoryServiceImpl extends ServiceImpl<CategoryMapper, Category>
		implements CategoryService {
	@Override
	public Result<List<CategoryVO>> queryAllCategory(Integer type) {
		List<Category> list = list(new LambdaQueryWrapper<Category>()
				.eq(Category::getType, type));
		if (CollectionUtils.isEmpty(list)) {
			return Result.error("菜品分类查询失败");
		}
		List<CategoryVO> vos = BeanUtil.copyToList(list, CategoryVO.class);
		
		return Result.success(vos);
	}
}
