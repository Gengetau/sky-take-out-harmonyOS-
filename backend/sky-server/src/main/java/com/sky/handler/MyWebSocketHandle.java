package com.sky.handler;

import com.sky.websocket.SessionManager;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName MyWebSocketHandle
 * @Description websocket 处理器
 * @dateTime 29/12/2025 下午2:10
 */
@Component
@Slf4j
public class MyWebSocketHandle extends TextWebSocketHandler {
	// 导入session管理器
	@Autowired
	private SessionManager sessionManager;
	
	@Autowired
	private com.sky.websocket.MessageDispatcher messageDispatcher;
	
	/**
	 * 建立链接调用的方法（对应onOpen类）
	 *
	 * @param session
	 * @throws Exception
	 */
	@Override
	public void afterConnectionEstablished(WebSocketSession session) throws Exception {
		// 1.从attributes取出sid
		String sid = (String) session.getAttributes().get("sid");
		if (sid != null && !sid.isEmpty()) {
			log.info("Handle获取到用户:{}", sid);
			sessionManager.addSession(sid, session);
		} else {
			log.warn("未找到sid，拒绝链接");
			session.close(CloseStatus.BAD_DATA);
		}
	}
	
	/**
	 * 关闭链接方法
	 *
	 * @param session
	 * @param status
	 * @throws Exception
	 */
	@Override
	public void afterConnectionClosed(WebSocketSession session, CloseStatus status) throws Exception {
		String sid = (String) session.getAttributes().get("sid");
		if (sid != null && !sid.isEmpty()) {
			sessionManager.removeSession(sid);
		}
	}
	
	/**
	 * 收到客户端消息后调用的方法
	 *
	 * @param session
	 * @param message
	 * @throws Exception
	 */
	@Override
	protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
		String payload = message.getPayload();
		log.info("收到消息:{}", payload);
		
		// 获取发送者SID
		String sid = (String) session.getAttributes().get("sid");
		if (sid != null) {
			// 分发消息
			messageDispatcher.dispatch(payload, sid);
		} else {
			log.warn("无法识别发送者身份，忽略消息");
		}
	}
	
	
}
