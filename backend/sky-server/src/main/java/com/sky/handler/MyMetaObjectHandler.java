package com.sky.handler;

import com.baomidou.mybatisplus.core.handlers.MetaObjectHandler;
import com.sky.context.BaseContext;
import lombok.extern.slf4j.Slf4j;
import org.apache.ibatis.reflection.MetaObject;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

/**
 * 自定义元数据对象处理器
 */
@Component
@Slf4j
public class MyMetaObjectHandler implements MetaObjectHandler {
	
	/**
	 * 插入操作，自动填充
	 *
	 * @param metaObject
	 */
	@Override
	public void insertFill(MetaObject metaObject) {
		log.info("开始插入填充...");
		// 1. 只有当实体类中有 createTime 且需要填充时，才设值
		if (metaObject.hasSetter("createTime")) {
			// 如果主人希望覆盖已有的值，或者只在值为null时填充，也可以在这里加逻辑
			// 这里妮娅保持主人原本的逻辑，直接设置
			this.setFieldValByName("createTime", LocalDateTime.now(), metaObject);
		}
		
		// 2. 检查 updateTime
		if (metaObject.hasSetter("updateTime")) {
			this.setFieldValByName("updateTime", LocalDateTime.now(), metaObject);
		}
		
		// 3. 检查 createUser
		if (metaObject.hasSetter("createUser")) {
			this.setFieldValByName("createUser", BaseContext.getCurrentId(), metaObject);
		}
		
		// 4. 检查 updateUser
		if (metaObject.hasSetter("updateUser")) {
			this.setFieldValByName("updateUser", BaseContext.getCurrentId(), metaObject);
		}
	}
	
	/**
	 * 更新操作，自动填充
	 *
	 * @param metaObject
	 */
	@Override
	public void updateFill(MetaObject metaObject) {
		log.info("开始更新填充...");
		metaObject.setValue("updateTime", LocalDateTime.now());
		metaObject.setValue("updateUser", BaseContext.getCurrentId());
	}
}
