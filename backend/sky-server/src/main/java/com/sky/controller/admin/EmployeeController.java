package com.sky.controller.admin;

import cn.hutool.core.bean.BeanUtil;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.sky.constant.JwtClaimsConstant;
import com.sky.context.BaseContext;
import com.sky.dto.EmployeeDTO;
import com.sky.dto.EmployeeLoginDTO;
import com.sky.dto.EmployeePageQueryDTO;
import com.sky.properties.JwtProperties;
import com.sky.result.Result;
import com.sky.service.EmployeeService;
import com.sky.utils.JwtUtil;
import com.sky.vo.EmployeeLoginVO;
import com.sky.vo.EmployeeVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

/**
 * 员工管理
 */
@RestController
@RequestMapping("/admin/employee")
@Slf4j
public class EmployeeController {
	
	@Autowired
	private EmployeeService employeeService;
	@Autowired
	private JwtProperties jwtProperties;
	
	/**
	 * 登录
	 *
	 * @param employeeLoginDTO 员工登录表单
	 * @return EmployeeLoginVO
	 */
	@PostMapping("/login")
	public Result<EmployeeLoginVO> login(@RequestBody EmployeeLoginDTO employeeLoginDTO) {
		log.info("员工登录：{}", employeeLoginDTO);
		
		EmployeeLoginVO employeeVO = employeeService.login(employeeLoginDTO);
		
		// 登录成功后，生成jwt令牌
		Map<String, Object> claims = new HashMap<>();
		claims.put(JwtClaimsConstant.EMP_ID, employeeVO.getId());
		String token = JwtUtil.createJWT(
				jwtProperties.getAdminSecretKey(),
				jwtProperties.getAdminTtl(),
				claims);
		employeeVO.setToken(token);
		return Result.success(employeeVO);
	}
	
	/**
	 * 新增员工
	 *
	 * @param employeeDTO
	 * @return
	 */
	@PostMapping
	public Result<String> saveEmployee(@RequestBody EmployeeDTO employeeDTO) {
		return employeeService.saveEmployee(employeeDTO);
	}
	
	/**
	 * @param pageQueryDTO 查询表单
	 * @return Result<Page<Employee>>
	 * @MethodName: getEmployeeByPage
	 * @Description: 员工分页查询
	 */
	@GetMapping("/page")
	public Result<Page<EmployeeVO>> getEmployeeByPage(EmployeePageQueryDTO pageQueryDTO) {
		return employeeService.getEmployeeByPage(pageQueryDTO);
	}
	
	/**
	 * @param id 员工id
	 * @return Result<Employee>
	 * @MethodName: getEmployeeById
	 * @Description: 根据id查询员工信息
	 */
	@GetMapping("/{id}")
	public Result<EmployeeVO> getEmployeeById(@PathVariable Long id) {
		EmployeeVO vo = BeanUtil.copyProperties(employeeService.getById(id), EmployeeVO.class);
		return Result.success(vo);
	}
	
	/**
	 * @param employeeDTO 信息修改表单
	 * @return Result<String>
	 * @MethodName: updateEmployee
	 * @Description: 修改员工信息
	 */
	@PutMapping
	public Result<String> updateEmployee(@RequestBody EmployeeDTO employeeDTO) {
		return employeeService.updateEmployee(employeeDTO);
	}
	
	/**
	 * @param status 状态
	 * @param id     员工id
	 * @return Result<String>
	 * @MethodName: updateEmployeeStatus
	 * @Description: 修改员工状态
	 */
	@PostMapping("/status/{status}")
	public Result<String> updateEmployeeStatus(@PathVariable Integer status, Long id) {
		return employeeService.updateEmployeeStatus(status, id);
	}
	
	/**
	 * 退出
	 *
	 */
	@PostMapping("/logout")
	public Result<String> logout() {
		BaseContext.removeCurrentId();
		return Result.success();
	}
	
}
