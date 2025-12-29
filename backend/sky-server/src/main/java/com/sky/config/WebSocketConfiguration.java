package com.sky.config;

import com.sky.handler.MyWebSocketHandle;
import com.sky.interceptor.SidHandshakeInterceptor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;

/**
 * WebSocket配置类，用于注册WebSocket的Bean
 */
@Configuration
public class WebSocketConfiguration implements WebSocketConfigurer {
	private final MyWebSocketHandle myWebSocketHandle;
	private final SidHandshakeInterceptor sidHandshakeInterceptor;
	
	public WebSocketConfiguration(MyWebSocketHandle myWebSocketHandle, SidHandshakeInterceptor sidHandshakeInterceptor) {
		this.myWebSocketHandle = myWebSocketHandle;
		this.sidHandshakeInterceptor = sidHandshakeInterceptor;
	}
	
	@Override
	public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
		registry.addHandler(myWebSocketHandle, "/ws/*")
				.addInterceptors(sidHandshakeInterceptor)
				.setAllowedOrigins("*");
	}
	
	/*@Bean
    public ServerEndpointExporter serverEndpointExporter() {
        return new ServerEndpointExporter();
    }*/
}
