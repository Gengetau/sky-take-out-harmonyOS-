package com.sky.websocket;

import cn.hutool.core.util.IdUtil;
import cn.hutool.core.util.StrUtil;
import cn.hutool.json.JSONUtil;
import com.aliyun.oss.OSS;
import com.sky.config.OSSConfig;
import com.sky.constant.WebSocketConstant;
import com.sky.dto.MessageDTO;
import com.sky.entity.Shop;
import com.sky.entity.User;
import com.sky.mapper.ShopMapper;
import com.sky.mapper.UserMapper;
import com.sky.utils.AliOssUtil;
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

    @Autowired
    private OSS ossClient;

    @Autowired
    private OSSConfig ossConfig;
    
    @Autowired
    private UserMapper userMapper;
    
    @Autowired
    private ShopMapper shopMapper;

    /**
     * 处理来自客户端的上行消息
     *
     * @param jsonPayload JSON消息体
     * @param fromSid     发送者的Session ID
     */
    public void dispatch(String jsonPayload, String fromSid) {
        try {
            // 1. 解析消息
            MessageDTO messageDTO = JSONUtil.toBean(jsonPayload, MessageDTO.class);
            
            // 2. 补全基础信息（身份识别、头像填充）
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
        Integer receiverRole = messageDTO.getReceiverRole();

        if (receiverId == null) {
            log.warn("私聊消息缺少接收者ID: {}", JSONUtil.toJsonStr(messageDTO));
            return;
        }

        // 构建目标 Session ID
        // 约定：商家连接时使用 "S_" 前缀，用户使用纯数字
        String targetSid;
        if (WebSocketConstant.ROLE_SHOP.equals(receiverRole)) {
            targetSid = "S_" + receiverId;
        } else {
            // 默认为用户 (或者明确指定为 ROLE_USER)
            targetSid = String.valueOf(receiverId);
        }

        // 发送消息
        boolean sent = sessionManager.sendMessageIfExist(targetSid, messageDTO);
        if (!sent) {
            log.info("用户/商家 {} 不在线，消息未实时送达 (可扩展离线存储)", targetSid);
            // TODO: 这里可以调用 ChatService 保存离线消息
        }
    }

    /**
     * 发送系统通知（服务端主动发起）
     */
    public void sendSystemNotification(Long toUserId, String content, Long orderId) {
        MessageDTO message = MessageDTO.builder()
                .type(WebSocketConstant.SYSTEM_NOTIFICATION)
                .msgId(IdUtil.simpleUUID())
                .senderId(Long.valueOf(WebSocketConstant.SYSTEM_SID))
                .senderRole(WebSocketConstant.ROLE_SYSTEM)
                .senderName(WebSocketConstant.SYSTEM_NAME)
                .senderAvatar(getSignedSystemAvatar())
                .content(content)
                .timestamp(System.currentTimeMillis())
                .orderId(orderId)
                .receiverId(toUserId)
                .receiverRole(WebSocketConstant.ROLE_USER) // 系统通知通常发给用户
                .build();

        sessionManager.sendMessageToUser(String.valueOf(toUserId), message);
    }
    
    /**
     * 发送订单状态通知（服务端主动发起）
     */
    public void sendOrderNotification(Long toUserId, String content, Long orderId) {
        MessageDTO message = MessageDTO.builder()
                .type(WebSocketConstant.ORDER_NOTIFICATION)
                .msgId(IdUtil.simpleUUID())
                .senderId(Long.valueOf(WebSocketConstant.SYSTEM_SID))
                .senderRole(WebSocketConstant.ROLE_SYSTEM)
                .senderName(WebSocketConstant.SYSTEM_NAME)
                .senderAvatar(getSignedSystemAvatar())
                .content(content)
                .timestamp(System.currentTimeMillis())
                .orderId(orderId)
                .receiverId(toUserId)
                .receiverRole(WebSocketConstant.ROLE_USER)
                .build();
                
        sessionManager.sendMessageToUser(String.valueOf(toUserId), message);
    }

    /**
     * 获取系统头像的签名URL
     */
    private String getSignedSystemAvatar() {
        try {
            return AliOssUtil.getSignedUrl(ossClient, WebSocketConstant.SYSTEM_AVATAR, ossConfig.getBucketName());
        } catch (Exception e) {
            log.error("获取系统头像签名URL失败", e);
            return null;
        }
    }

    /**
     * 补全消息元数据
     */
    private void fillMessageInfo(MessageDTO message, String fromSid) {
        // 1. 推断或确认发送者身份
        boolean isShopSession = fromSid.startsWith("S_");
        long actualSenderId;
        
        try {
            if (isShopSession) {
                actualSenderId = Long.parseLong(fromSid.substring(2));
                // 如果DTO没传，强制修正为Shop
                if (message.getSenderRole() == null) {
                    message.setSenderRole(WebSocketConstant.ROLE_SHOP);
                }
            } else {
                actualSenderId = Long.parseLong(fromSid);
                if (message.getSenderRole() == null) {
                    message.setSenderRole(WebSocketConstant.ROLE_USER);
                }
            }
        } catch (NumberFormatException e) {
            log.warn("SID解析失败: {}", fromSid);
            return;
        }

        // 2. 补全 SenderId (以 Session 为准，防止伪造)
        message.setSenderId(actualSenderId);

        // 3. 补全 SenderName 和 Avatar
        String avatarKey = null;
        String name = null;
        Integer role = message.getSenderRole();

        if (WebSocketConstant.ROLE_SHOP.equals(role)) {
            // 查询商家信息
            Shop shop = shopMapper.selectById(actualSenderId);
            if (shop != null) {
                avatarKey = shop.getAvatar();
                name = shop.getName();
            }
        } else {
            // 查询用户信息
            User user = userMapper.selectById(actualSenderId);
            if (user != null) {
                avatarKey = user.getAvatar();
                name = user.getName();
            }
        }
        
        // 设置头像 (带签名)
        if (StrUtil.isNotBlank(avatarKey)) {
            try {
                 // 自动去除可能存在的URL前缀，只保留Key
                 String cleanKey = AliOssUtil.extractKeyFromUrl(avatarKey);
                 String signedUrl = AliOssUtil.getSignedUrl(ossClient, cleanKey, ossConfig.getBucketName());
                 message.setSenderAvatar(signedUrl);
            } catch (Exception e) {
                log.error("头像签名失败", e);
            }
        }
        
        // 设置名称 (如果前端没传)
        if (StrUtil.isBlank(message.getSenderName()) && StrUtil.isNotBlank(name)) {
            message.setSenderName(name);
        }

        // 4. 补全消息ID
        if (StrUtil.isBlank(message.getMsgId())) {
            message.setMsgId(IdUtil.simpleUUID());
        }

        // 5. 补全时间戳
        if (message.getTimestamp() == null) {
            message.setTimestamp(System.currentTimeMillis());
        }
    }
}