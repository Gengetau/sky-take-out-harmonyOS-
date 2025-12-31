package com.sky.interceptor;

import com.sky.constant.JwtClaimsConstant;
import com.sky.context.BaseContext;
import com.sky.properties.JwtProperties;
import com.sky.utils.JwtUtil;
import io.jsonwebtoken.Claims;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.web.method.HandlerMethod;
import org.springframework.web.servlet.HandlerInterceptor;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * 商家App端jwt令牌校验的拦截器
 */
@Component
@Slf4j
public class JwtTokenAppInterceptor implements HandlerInterceptor {

    @Autowired
    private JwtProperties jwtProperties;

    /**
     * 校验jwt并解析shopId
     */
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
        // 判断当前拦截到的是Controller的方法还是其他资源
        if (!(handler instanceof HandlerMethod)) {
            return true;
        }

        // 1、从请求头中获取令牌
        String token = request.getHeader(jwtProperties.getAdminTokenName());

        // 2、校验令牌
        try {
            log.info("App端jwt校验:{}", token);
            Claims claims = JwtUtil.parseJWT(jwtProperties.getAdminSecretKey(), token);
            
            // 解析员工ID
            Long empId = Long.valueOf(claims.get(JwtClaimsConstant.EMP_ID).toString());
            BaseContext.setCurrentId(empId);
            
            // 解析店铺ID
            Object shopIdObj = claims.get(JwtClaimsConstant.SHOP_ID);
            if (shopIdObj != null) {
                Long shopId = Long.valueOf(shopIdObj.toString());
                BaseContext.setCurrentShopId(shopId);
                log.info("当前App员工id：{}, 店铺id：{}", empId, shopId);
            } else {
                log.warn("Token中未发现shopId，可能影响多商家隔离逻辑喵！");
            }
            
            return true;
        } catch (Exception ex) {
            log.error("App端jwt校验失败：{}", ex.getMessage());
            response.setStatus(401);
            return false;
        }
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) throws Exception {
        // 请求结束后清理ThreadLocal，防止内存泄漏喵
        BaseContext.removeCurrentId();
        BaseContext.removeCurrentShopId();
    }
}
