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
		log.info("【WebSocket会话】用户上线: [{}], 当前在线人数: {}, 全部在线用户: {}", 
				userId, sessionPool.size(), sessionPool.keySet());
	}
	
	/**
	 * 移除会话
	 *
	 * @param userId
	 */
	public WebSocketSession removeSession(String userId) {
		WebSocketSession removedSession = sessionPool.remove(userId);
		if (removedSession != null) {
			log.info("【WebSocket会话】用户下线: [{}], 当前在线人数: {}", userId, sessionPool.size());
		}
		return removedSession;
	}
	
	/**
	 * 尝试发送单点消息 (如果不在线则返回false，不打印WARN日志)
	 * @param userId 接收者ID
	 * @param messageDTO 消息对象
	 * @return true if sent, false if not found
	 */
	public boolean sendMessageIfExist(String userId, MessageDTO messageDTO) {
		WebSocketSession webSocketSession = sessionPool.get(userId);
		if (webSocketSession != null && webSocketSession.isOpen()) {
			String jsonStr = JSONUtil.toJsonStr(messageDTO);
			TextMessage textMessage = new TextMessage(jsonStr);
			try {
				synchronized (webSocketSession) {
					webSocketSession.sendMessage(textMessage);
				}
				log.info("【WebSocket下行】消息成功送达给 [{}]: {}", userId, jsonStr);
				return true;
			} catch (IOException e) {
				log.error("【WebSocket下行】给用户[{}]发送消息失败喵: {}", userId, e.getMessage());
				return false;
			}
		}
		return false;
	}

	/**
	 * 单点推送
	 */
	public void sendMessageToUser(String userId, MessageDTO messageDTO) {
		boolean sent = sendMessageIfExist(userId, messageDTO);
		if (!sent) {
			log.warn("【WebSocket下行】推送失败！目标用户 [{}] 不在线。当前池中用户: {}", 
					userId, sessionPool.keySet());
		}
	}
	
	/**
	 * 广播消息
	 */
	public void broadcast(MessageDTO messageDTO) {
		String jsonStr = JSONUtil.toJsonStr(messageDTO);
		TextMessage textMessage = new TextMessage(jsonStr);
		log.info("【WebSocket广播】开始广播消息: {}", jsonStr);
		sessionPool.forEach((userId, session) -> {
			if (session.isOpen()) {
				try {
					synchronized (session) {
						session.sendMessage(textMessage);
					}
				} catch (IOException e) {
					log.error("【WebSocket广播】发送给[{}]失败喵：{}", userId, e.getMessage());
				}
			}
		});
	}
}