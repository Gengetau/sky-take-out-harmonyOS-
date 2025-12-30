package com.sky.interceptor;

import lombok.extern.slf4j.Slf4j;
import org.springframework.http.server.ServerHttpRequest;
import org.springframework.http.server.ServerHttpResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.server.HandshakeInterceptor;

import java.util.Map;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName SidHandshakeInterceptor
 * @Description websocket 握手拦截器
 * @dateTime 29/12/2025 下午2:20
 */
@Component
@Slf4j
public class SidHandshakeInterceptor implements HandshakeInterceptor {
	
	@Override
	public boolean beforeHandshake(ServerHttpRequest request, ServerHttpResponse response, WebSocketHandler wsHandler, Map<String, Object> attributes) throws Exception {
		// 1.获取请求路径
		String path = request.getURI().getPath();
		log.info("【WebSocket握手】收到请求，完整URI: {}, Path: {}", request.getURI(), path);
		
		// 2.解析sid
		String sid = path.substring(path.lastIndexOf("/") + 1);
		
		// 3.存入attributes
		attributes.put("sid", sid);
		log.info("【WebSocket握手】解析得到 sid=[{}], 已存入 attributes 喵", sid);
		return true;
	}
	
	@Override
	public void afterHandshake(ServerHttpRequest request, ServerHttpResponse response, WebSocketHandler wsHandler, Exception exception) {
		if (exception != null) {
			log.error("【WebSocket握手】握手后发生异常喵：", exception);
		}
	}
}