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
		Object sidObj = session.getAttributes().get("sid");
		String sid = sidObj != null ? String.valueOf(sidObj) : null;
		
		log.info("【WebSocket连接】SessionID: {}, 远程地址: {}, 携带SID: [{}]", 
				session.getId(), session.getRemoteAddress(), sid);
		
		if (sid != null && !sid.isEmpty()) {
			sessionManager.addSession(sid, session);
		} else {
			log.warn("【WebSocket连接】未找到有效sid，拒绝链接喵");
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
		log.info("【WebSocket断开】SID: [{}], 原因状态: {}", sid, status);
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
		String sid = (String) session.getAttributes().get("sid");
		log.info("【WebSocket上行】收到来自[{}]的消息: {}", sid, payload);
		
		if (sid != null) {
			messageDispatcher.dispatch(payload, sid);
		} else {
			log.warn("【WebSocket上行】无法识别发送者身份，忽略消息喵");
		}
	}
}