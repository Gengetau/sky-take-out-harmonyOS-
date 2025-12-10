package com.sky.service.impl;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.crypto.digest.DigestAlgorithm;
import cn.hutool.crypto.digest.Digester;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.sky.constant.MessageConstant;
import com.sky.constant.StatusConstant;
import com.sky.dto.EmployeeDTO;
import com.sky.dto.EmployeeLoginDTO;
import com.sky.dto.EmployeePageQueryDTO;
import com.sky.entity.Employee;
import com.sky.exception.AccountLockedException;
import com.sky.exception.AccountNotFoundException;
import com.sky.mapper.EmployeeMapper;
import com.sky.result.Result;
import com.sky.service.EmployeeService;
import com.sky.utils.PasswordUtil;
import com.sky.vo.EmployeeLoginVO;
import com.sky.vo.EmployeeVO;
import jodd.util.Base64;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class EmployeeServiceImpl extends ServiceImpl<EmployeeMapper, Employee>
		implements EmployeeService {
	@Autowired
	private EmployeeMapper employeeMapper;
	
	/**
	 * 员工登录
	 *
	 * @param employeeLoginDTO
	 * @return
	 */
	@Override
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
	
	@Override
	@Transactional(rollbackFor = Exception.class)
	public Result<String> saveEmployee(EmployeeDTO employeeDTO) {
		// 0.验证账号是否已存在
		Employee employee = getOne(new LambdaQueryWrapper<Employee>()
				.eq(Employee::getUsername, employeeDTO.getUsername()));
		if (employee != null) {
			throw new AccountLockedException(MessageConstant.ACCOUNT_EXIT);
		}
		// 1.复制属性
		Employee newEmployee = BeanUtil.copyProperties(employeeDTO, Employee.class);
		// 2. 初始密码统一为123456
		// 2.1 创建随机盐
		String salt = PasswordUtil.generateSecureSalt();
		// 2.2 解码盐字符串为字节数组，以供 Digester 使用
		byte[] saltBytes = cn.hutool.core.codec
				.Base64.decode(salt);
		// 2.3 创建一个摘要算法对象，这里用 SHA-256
		Digester sha256 = new Digester(DigestAlgorithm.SHA256);
		sha256.setSalt(saltBytes); // 设置盐
		// 2.4 执行哈希计算,获得加密密码
		String saltedHash = sha256.digestHex("123456");
		// 2.5将盐和加密密码存储进对象
		newEmployee.setPassword(saltedHash);
		newEmployee.setSalt(salt);
		// 3. 设置账号状态
		newEmployee.setStatus(StatusConstant.ENABLE);
		// 4. 调用save()保存
		save(newEmployee);
		// 5. 返回结果
		return Result.success();
	}
	
	@Override
	public Result<Page<EmployeeVO>> getEmployeeByPage(EmployeePageQueryDTO pageQueryDTO) {
		// 1.获取数据
		int currentPage = pageQueryDTO.getPage();
		int pageSize = pageQueryDTO.getPageSize();
		// 2.创建分页对象
		Page<Employee> page = new Page<>(currentPage, pageSize);
		LambdaQueryWrapper<Employee> queryWrapper = new LambdaQueryWrapper<>();
		// 3.判断是否根据名字查询
		queryWrapper.eq(pageQueryDTO.getName() != null,
				Employee::getName, pageQueryDTO.getName());
		// 4.查询结果
		Page<Employee> employeePage = employeeMapper.selectPage(page, queryWrapper);
		// 5.封装vo对象
		Page<EmployeeVO> voPage = new Page<>(currentPage, pageSize);
		List<EmployeeVO> vos = BeanUtil.copyToList(employeePage.getRecords(), EmployeeVO.class);
		voPage.setRecords(vos);
		voPage.setTotal(page.getTotal());
		// 6.返回结果
		return Result.success(voPage);
	}
	
	@Override
	@Transactional(rollbackFor = Exception.class)
	public Result<String> updateEmployee(EmployeeDTO employeeDTO) {
		// 1.查询
		Employee employee = getById(employeeDTO.getId());
		// 2.校验
		if (employee == null) {
			throw new AccountNotFoundException(MessageConstant.ACCOUNT_NOT_FOUND);
		}
		// 3.复制
		BeanUtil.copyProperties(employeeDTO, employee);
		// 4.修改
		updateById(employee);
		// 5.返回
		return Result.success();
	}
	
	@Override
	@Transactional(rollbackFor = Exception.class)
	public Result<String> updateEmployeeStatus(Integer status, Long id) {
		// 1.查询
		Employee employee = getById(id);
		// 2.校验
		if (employee == null) {
			throw new AccountNotFoundException(MessageConstant.ACCOUNT_NOT_FOUND);
		}
		// 3.改变状态
		employee.setStatus(status);
		// 4.修改
		updateById(employee);
		// 5.返回
		return Result.success();
	}
	
}
