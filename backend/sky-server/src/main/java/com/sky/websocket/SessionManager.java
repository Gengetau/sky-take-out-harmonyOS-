package com.sky.websocket;

import cn.hutool.json.JSONUtil;
import com.sky.dto.MessageDTO;
import lombok.Getter;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;

import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName SessionManager
 * @Description WebSocket 会话管理器
 * @dateTime 29/12/2025 下午1:45
 */
@Getter
@Component
@Slf4j
public class SessionManager {
	/**
	 * 使用ConcurrentHashMap 确保线程安全
	 * -- GETTER --
	 * 获取所有在线用户的Id
	 */
	private final Map<String, WebSocketSession> sessionPool = new ConcurrentHashMap<>();
	
	/**
	 * 增加会话
	 *
	 * @param userId
	 * @param session
	 */
	public void addSession(String userId, WebSocketSession session) {
		sessionPool.put(userId, session);
		log.info("用户上线:{},当前在线人数:{}", userId, sessionPool.size());
	}
	
	/**
	 * 移除会话
	 *
	 * @param userId
	 */
	public WebSocketSession removeSession(String userId) {
		WebSocketSession removedSession = sessionPool.remove(userId);
		if (removedSession != null) {
			log.info("用户：{}下线，当前在线人数：{}", userId, sessionPool.size());
		}
		return removedSession;
	}
	
	/**
	 * 单点推送
	 */
	public void sendMessageToUser(String userId, MessageDTO messageDTO) {
		WebSocketSession webSocketSession = sessionPool.get(userId);
		String jsonStr = JSONUtil.toJsonStr(messageDTO);
		TextMessage textMessage = new TextMessage(jsonStr);
		if (webSocketSession != null && webSocketSession.isOpen()) {
			try {
				// 加锁发送，防止并发写入异常
				synchronized (webSocketSession) {
					webSocketSession.sendMessage(textMessage);
				}
			} catch (IOException e) {
				log.error("给用户{}发送消息失败:{}", userId, e.getMessage());
			}
		} else {
			log.warn("用户{}不在线或会话已关闭，消息发送失败", userId);
		}
	}
	
	/**
	 * 广播消息
	 */
	public void broadcast(MessageDTO messageDTO) {
		String jsonStr = JSONUtil.toJsonStr(messageDTO);
		TextMessage textMessage = new TextMessage(jsonStr);
		sessionPool.forEach((userId, session) -> {
			if (session.isOpen()) {
				try {
					synchronized (session) {
						session.sendMessage(textMessage);
					}
				} catch (IOException e) {
					log.error("广播消息给{}失败：{}", userId, e.getMessage());
				}
			}
		});
	}
}
