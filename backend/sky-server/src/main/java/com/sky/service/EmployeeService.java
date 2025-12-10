package com.sky.service;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.IService;
import com.sky.dto.EmployeeDTO;
import com.sky.dto.EmployeeLoginDTO;
import com.sky.dto.EmployeePageQueryDTO;
import com.sky.entity.Employee;
import com.sky.result.Result;
import com.sky.vo.EmployeeLoginVO;
import com.sky.vo.EmployeeVO;

public interface EmployeeService extends IService<Employee> {
	
	/**
	 * 员工登录
	 *
	 * @param employeeLoginDTO
	 * @return
	 */
	EmployeeLoginVO login(EmployeeLoginDTO employeeLoginDTO);
	
	Result<String> saveEmployee(EmployeeDTO employeeDTO);
	
	Result<Page<EmployeeVO>> getEmployeeByPage(EmployeePageQueryDTO pageQueryDTO);
	
	Result<String> updateEmployee(EmployeeDTO employeeDTO);
	
	Result<String> updateEmployeeStatus(Integer status, Long id);
}
