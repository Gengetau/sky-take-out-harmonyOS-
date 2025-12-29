package com.sky.websocket;

import cn.hutool.core.util.IdUtil;
import cn.hutool.core.util.StrUtil;
import cn.hutool.json.JSONUtil;
import com.sky.constant.WebSocketConstant;
import com.sky.dto.MessageDTO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

/**
 * @author Gengetsu
 * @version v1.0
 * @ClassName MessageDispatcher
 * @Description 消息分发器，负责解析消息、构建消息并路由到 SessionManager
 * @dateTime 29/12/2025 下午2:45
 */
@Component
@Slf4j
public class MessageDispatcher {

    @Autowired
    private SessionManager sessionManager;

    /**
     * 处理来自客户端的上行消息
     *
     * @param jsonPayload JSON消息体
     * @param fromSid     发送者的Session ID (通常是UserId)
     */
    public void dispatch(String jsonPayload, String fromSid) {
        try {
            // 1. 解析消息
            MessageDTO messageDTO = JSONUtil.toBean(jsonPayload, MessageDTO.class);
            
            // 2. 补全基础信息
            fillMessageInfo(messageDTO, fromSid);

            // 3. 根据类型分发
            Integer type = messageDTO.getType();
            if (type == null) {
                log.warn("收到未知类型的消息，忽略: {}", jsonPayload);
                return;
            }

            if (WebSocketConstant.PRIVATE_MESSAGE.equals(type)) {
                handlePrivateMessage(messageDTO);
            } else {
                log.info("收到非私聊消息(Type={})，暂不处理或仅作记录: {}", type, jsonPayload);
                // 可以在这里扩展处理其他类型，比如客户端发送的心跳或状态确认
            }

        } catch (Exception e) {
            log.error("消息分发异常", e);
        }
    }

    /**
     * 处理私聊消息
     */
    private void handlePrivateMessage(MessageDTO messageDTO) {
        Long receiverId = messageDTO.getReceiverId();
        if (receiverId == null) {
            log.warn("私聊消息缺少接收者ID: {}", JSONUtil.toJsonStr(messageDTO));
            return;
        }

        // 转发给目标用户
        // 注意：SessionManager 的 key 是 String 类型的 userId
        sessionManager.sendMessageToUser(String.valueOf(receiverId), messageDTO);
        
        // TODO: 如果需要存储聊天记录，可以在这里调用 ChatService.save(messageDTO)
    }

    /**
     * 发送系统通知（服务端主动发起）
     *
     * @param toUserId 接收者ID
     * @param content  通知内容
     * @param orderId  关联订单ID (可选)
     */
    public void sendSystemNotification(Long toUserId, String content, Long orderId) {
        MessageDTO message = MessageDTO.builder()
                .type(WebSocketConstant.SYSTEM_NOTIFICATION)
                .msgId(IdUtil.simpleUUID())
                .senderId(Long.valueOf(WebSocketConstant.SYSTEM_SID))
                .senderName(WebSocketConstant.SYSTEM_NAME)
                .content(content)
                .timestamp(System.currentTimeMillis())
                .orderId(orderId)
                .receiverId(toUserId)
                .build();

        sessionManager.sendMessageToUser(String.valueOf(toUserId), message);
    }
    
    /**
     * 发送订单状态通知（服务端主动发起）
     * 
     * @param toUserId 接收者ID
     * @param content 内容
     * @param orderId 订单ID
     */
    public void sendOrderNotification(Long toUserId, String content, Long orderId) {
        MessageDTO message = MessageDTO.builder()
                .type(WebSocketConstant.ORDER_NOTIFICATION)
                .msgId(IdUtil.simpleUUID())
                .senderId(Long.valueOf(WebSocketConstant.SYSTEM_SID))
                .senderName(WebSocketConstant.SYSTEM_NAME)
                .content(content)
                .timestamp(System.currentTimeMillis())
                .orderId(orderId)
                .receiverId(toUserId)
                .build();
                
        sessionManager.sendMessageToUser(String.valueOf(toUserId), message);
    }

    /**
     * 补全消息元数据
     */
    private void fillMessageInfo(MessageDTO message, String fromSid) {
        // 补全发送者ID
        if (message.getSenderId() == null) {
            // 尝试将 sid 转为 Long，如果 sid 不是纯数字可能抛异常，这里做个保护
            try {
                message.setSenderId(Long.valueOf(fromSid));
            } catch (NumberFormatException e) {
                log.warn("SID转Long失败，使用默认值0或保留原值: {}", fromSid);
            }
        }

        // 补全消息ID
        if (StrUtil.isBlank(message.getMsgId())) {
            message.setMsgId(IdUtil.simpleUUID());
        }

        // 补全时间戳
        if (message.getTimestamp() == null) {
            message.setTimestamp(System.currentTimeMillis());
        }
    }
}
