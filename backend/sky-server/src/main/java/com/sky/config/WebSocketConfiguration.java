package com.sky.config;

import com.sky.handler.MyWebSocketHandle;
import com.sky.interceptor.SidHandshakeInterceptor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;

/**
 * WebSocket配置类，用于注册WebSocket的Bean
 */
@Configuration
@EnableWebSocket
public class WebSocketConfiguration implements WebSocketConfigurer {
	private final MyWebSocketHandle myWebSocketHandle;
	private final SidHandshakeInterceptor sidHandshakeInterceptor;
	
	public WebSocketConfiguration(MyWebSocketHandle myWebSocketHandle, SidHandshakeInterceptor sidHandshakeInterceptor) {
		this.myWebSocketHandle = myWebSocketHandle;
		this.sidHandshakeInterceptor = sidHandshakeInterceptor;
		System.out.println("【WebSocket配置】WebSocketConfiguration 正在初始化... 喵！");
	}
	
	@Override
	public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
		// 使用 /ws/{sid} 这种路径变量风格，看是否能更好地匹配
		// 同时也保留通配符风格以防万一，但要注意顺序
		registry.addHandler(myWebSocketHandle, "/ws/{sid}")
				.addInterceptors(sidHandshakeInterceptor)
				.setAllowedOrigins("*");
				
		System.out.println("【WebSocket配置】已注册Handler，路径为 /ws/{sid} 喵！");
	}
	
	/*@Bean
    public ServerEndpointExporter serverEndpointExporter() {
        return new ServerEndpointExporter();
    }*/
}
