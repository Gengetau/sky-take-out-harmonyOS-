package com.sky.interceptor;

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
		// 2.解析sid
		String sid = path.substring(path.lastIndexOf("/") + 1);
		// 3.存入attributes
		attributes.put("sid", sid);
		log.info("检测到握手请求，sid={}", sid);
		return true;
	}
	
	@Override
	public void afterHandshake(ServerHttpRequest request, ServerHttpResponse response, WebSocketHandler wsHandler, Exception exception) {
	
	}
}
