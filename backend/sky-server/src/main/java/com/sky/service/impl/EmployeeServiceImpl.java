package com.sky.service.impl;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.crypto.digest.DigestAlgorithm;
import cn.hutool.crypto.digest.Digester;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.sky.constant.MessageConstant;
import com.sky.constant.StatusConstant;
import com.sky.dto.EmployeeLoginDTO;
import com.sky.entity.Employee;
import com.sky.exception.AccountLockedException;
import com.sky.exception.AccountNotFoundException;
import com.sky.mapper.EmployeeMapper;
import com.sky.service.EmployeeService;
import com.sky.vo.EmployeeLoginVO;
import jodd.util.Base64;
import org.springframework.stereotype.Service;

@Service
public class EmployeeServiceImpl extends ServiceImpl<EmployeeMapper, Employee>
		implements EmployeeService {
	
	/**
	 * 员工登录
	 *
	 * @param employeeLoginDTO
	 * @return
	 */
	public EmployeeLoginVO login(EmployeeLoginDTO employeeLoginDTO) {
		String username = employeeLoginDTO.getUsername();
		String password = employeeLoginDTO.getPassword();
		
		// 1、根据用户名查询数据库中的数据
		Employee employee = getOne(new LambdaQueryWrapper<Employee>()
				.eq(Employee::getUsername, username));
		
		// 2、处理各种异常情况（用户名不存在、密码不对、账号被锁定）
		if (employee == null) {
			// 账号不存在
			throw new AccountNotFoundException(MessageConstant.ACCOUNT_NOT_FOUND);
		}
		
		// 密码比对
		// 3.0解析盐字符串为字节数组
		byte[] saltBytes = Base64.decode(employee.getSalt());
		// 3.1构建Digester算法对象,使用sha256
		Digester sha256 = new Digester(DigestAlgorithm.SHA256);
		// 3.2设置盐,数据库中存储的salt
		sha256.setSalt(saltBytes);
		// 3.3对输入密码进行加盐处理
		String inputPasswordHashed = sha256.digestHex(password);
		// 3.4进行校验
		boolean isPasswordCorrect = inputPasswordHashed.equals(employee.getPassword());
		if (!isPasswordCorrect) {
			// 3.4.1校验失败
			throw new AccountLockedException(MessageConstant.PASSWORD_ERROR);
		}
		
		// 4.账号状态校验
		if (employee.getStatus() == StatusConstant.DISABLE) {
			// 账号被锁定
			throw new AccountLockedException(MessageConstant.ACCOUNT_LOCKED);
		}
		
		// 3、返回VO对象
		return BeanUtil.copyProperties(employee, EmployeeLoginVO.class);
	}
	
}
