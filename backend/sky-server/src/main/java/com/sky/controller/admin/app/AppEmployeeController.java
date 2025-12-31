package com.sky.controller.admin.app;

import com.sky.constant.JwtClaimsConstant;
import com.sky.context.BaseContext;
import com.sky.dto.EmployeeLoginDTO;
import com.sky.properties.JwtProperties;
import com.sky.result.Result;
import com.sky.service.EmployeeService;
import com.sky.utils.JwtUtil;
import com.sky.vo.EmployeeLoginVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

/**
 * 商家App端员工管理
 */
@RestController
@RequestMapping("/admin/app/employee")
@Slf4j
public class AppEmployeeController {

    @Autowired
    private EmployeeService employeeService;
    @Autowired
    private JwtProperties jwtProperties;

    /**
     * App端登录
     *
     * @param employeeLoginDTO 员工登录表单
     * @return EmployeeLoginVO
     */
    @PostMapping("/login")
    public Result<EmployeeLoginVO> login(@RequestBody EmployeeLoginDTO employeeLoginDTO) {
        log.info("商家App员工登录：{}", employeeLoginDTO);

        EmployeeLoginVO employeeVO = employeeService.login(employeeLoginDTO);

        // 登录成功后，生成jwt令牌，特别加入shopId
        Map<String, Object> claims = new HashMap<>();
        claims.put(JwtClaimsConstant.EMP_ID, employeeVO.getId());
        claims.put(JwtClaimsConstant.SHOP_ID, employeeVO.getShopId()); // 关键：在Token中存入店铺ID

        String token = JwtUtil.createJWT(
                jwtProperties.getAdminSecretKey(),
                jwtProperties.getAdminTtl(),
                claims);

        employeeVO.setToken(token);
        return Result.success(employeeVO);
    }

    /**
     * App端退出
     */
    @PostMapping("/logout")
    public Result<String> logout() {
        BaseContext.removeCurrentId();
        BaseContext.removeCurrentShopId();
        return Result.success();
    }
}
