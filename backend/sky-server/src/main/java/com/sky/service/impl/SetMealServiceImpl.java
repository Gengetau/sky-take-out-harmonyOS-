package com.sky.service.impl;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.collection.CollUtil;
import com.aliyun.oss.OSS;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.sky.config.OSSConfig;
import com.sky.dto.SetmealPageQueryDTO;
import com.sky.entity.Category;
import com.sky.entity.SetMeal;
import com.sky.exception.SetMealNotFoundException;
import com.sky.mapper.SetMealMapper;
import com.sky.result.Result;
import com.sky.service.CategoryService;
import com.sky.service.SetMealService;
import com.sky.utils.AliOssUtil;
import com.sky.vo.SetMealVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import static com.sky.constant.MessageConstant.SET_MEAL_NOT_FOUND;

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
	@Autowired
	private CategoryService categoryService;
	@Autowired
	private OSS ossClient;
	@Autowired
	private OSSConfig ossConfig;
	
	@Override
	public Result<Page<SetMealVO>> getSetMealByPage(SetmealPageQueryDTO dto) {
		int currentPage = dto.getPage();
		int pageSize = dto.getPageSize();
		// 1.创建分页模型
		Page<SetMeal> page = new Page<>(currentPage, pageSize);
		// 2.创建查询模型
		LambdaQueryWrapper<SetMeal> qw = new LambdaQueryWrapper<>();
		// 名称模糊查询
		qw.like(dto.getName() != null, SetMeal::getName, dto.getName());
		// 分类id查询
		qw.eq(dto.getCategoryId() != null, SetMeal::getCategoryId, dto.getCategoryId());
		// 状态查询
		qw.eq(dto.getStatus() != null, SetMeal::getStatus, dto.getStatus());
		// 3.查询
		Page<SetMeal> setMealPage = page(page, qw);
		// 4.校验
		if (CollUtil.isEmpty(setMealPage.getRecords())) {
			throw new SetMealNotFoundException(SET_MEAL_NOT_FOUND);
		}
		// 5.复制属性
		List<SetMealVO> vos = BeanUtil.copyToList(setMealPage.getRecords(), SetMealVO.class);
		List<Long> ids = vos.stream().map(SetMealVO::getCategoryId).collect(Collectors.toList());
		// 6.查询分类名称
		List<Category> categories = categoryService.listByIds(ids);
		// 7.转化为map集合
		Map<Long, String> cateMap = categories.stream()
				.collect(Collectors.toMap(Category::getId, Category::getName));
		// 8.遍历vos,进行分类名称赋值并对Image签名
		vos.forEach(vo -> {
			vo.setCategoryName(cateMap.get(vo.getCategoryId()));
			String keyFromUrl = AliOssUtil.getSignedUrl(ossClient, vo.getImage(), ossConfig.getBucketName());
			vo.setImage(keyFromUrl);
		});
		// 9.创建vo分页模型
		Page<SetMealVO> setMealVOPage = new Page<>(currentPage, pageSize);
		setMealVOPage.setRecords(vos);
		setMealVOPage.setTotal(setMealPage.getTotal());
		// 10.返回
		return Result.success(setMealVOPage);
	}
}
