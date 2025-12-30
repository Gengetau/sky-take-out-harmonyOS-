import { common } from '@kit.AbilityKit';
import { relationalStore, ValuesBucket } from '@kit.ArkData';

/**
 * 会话实体
 */
export interface SessionModel {
  sessionId: string; // 会话ID (如 "user_101", "shop_1")
  title: string; // 标题 (对方昵称/店铺名)
  avatar: string; // 头像
  lastMsg: string; // 最后一条消息内容
  lastTime: number; // 最后一条消息时间
  unreadCount: number; // 未读数
}

/**
 * 消息实体 (对应 RDB 存储结构)
 */
export interface MessageEntity {
  id?: number; // 自增主键
  sessionId: string; // 关联会话ID
  msgId: string; // 消息UUID
  senderId: number; // 发送者ID
  role: number; // 发送者角色 (0:我, 1:对方) - 用于UI判断左右
  content: string; // 内容
  type: number; // 消息类型
  createTime: number; // 时间戳
  orderId?: number; // 关联订单ID (可选)
}

/**
 * 📨 消息中心数据库工具类 (RDB)
 * 管理会话列表 (tb_session) 和 消息明细 (tb_message)
 */
export class MessageRdb {
  private static readonly DB_NAME = 'SkyDelivery_Msg.db';
  private static readonly TABLE_SESSION = 'tb_session';
  private static readonly TABLE_MESSAGE = 'tb_message';
  private static rdbStore: relationalStore.RdbStore | null = null;
  // 定义数据库版本，用于升级
  private static readonly DB_VERSION = 2;
  // 建表语句 - 会话表
  private static readonly SQL_CREATE_SESSION = `
    CREATE TABLE IF NOT EXISTS tb_session (
      session_id TEXT PRIMARY KEY,
      title TEXT,
      avatar TEXT,
      last_msg TEXT,
      last_time INTEGER,
      unread_count INTEGER
    )
  `;
  // 建表语句 - 消息表
  // 注意：SQLite 不支持 IF NOT EXISTS 里带 ADD COLUMN，所以这里只定义初始结构
  // 如果是旧版本升级上来，需要 ALTER TABLE
  private static readonly SQL_CREATE_MESSAGE = `
    CREATE TABLE IF NOT EXISTS tb_message (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      session_id TEXT NOT NULL,
      msg_id TEXT,
      sender_id INTEGER,
      role INTEGER,
      content TEXT,
      type INTEGER,
      create_time INTEGER,
      order_id INTEGER
    )
  `;

  /**
   * 初始化数据库
   */
  static async init(context: common.UIAbilityContext) {
    if ( MessageRdb.rdbStore ) {
      return;
    }

    const config: relationalStore.StoreConfig = {
      name: MessageRdb.DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    };

    try {
      MessageRdb.rdbStore = await relationalStore.getRdbStore(context, config);

      // 创建表 (如果不存在)
      await MessageRdb.rdbStore.executeSql(MessageRdb.SQL_CREATE_SESSION);

      // 检查 tb_message 是否存在以及是否有 order_id 字段
      // 暴力尝试添加字段，忽略 "duplicate column name" 错误
      try {
        await MessageRdb.rdbStore.executeSql('ALTER TABLE tb_message ADD COLUMN order_id INTEGER');
        console.info('喵！成功为 tb_message 添加 order_id 字段 🎉');
      } catch ( e ) {
        // 错误码 1 或包含 "duplicate" 通常表示字段已存在
        console.warn('尝试添加 order_id 字段时提示:', JSON.stringify(e));
      }

      console.info('喵！消息数据库初始化成功 📨');
    } catch ( err ) {
      console.error('消息数据库初始化失败', err);
    }
  }

  // ==================== 会话管理 ====================

  /**
   * 保存或更新会话
   */
  static async saveSession(session: SessionModel): Promise<boolean> {
    if (!MessageRdb.rdbStore ) {
      return false;
    }

    const predicates = new relationalStore.RdbPredicates(MessageRdb.TABLE_SESSION);
    predicates.equalTo('session_id', session.sessionId);
    const resultSet = await MessageRdb.rdbStore.query(predicates);

    const values: ValuesBucket = {
      'session_id': session.sessionId,
      'title': session.title,
      'avatar': session.avatar,
      'last_msg': session.lastMsg,
      'last_time': session.lastTime
    };

    try {
      if ( resultSet.rowCount > 0 ) {
        resultSet.goToFirstRow();
        const currentUnread = resultSet.getLong(resultSet.getColumnIndex('unread_count'));
        let newUnread = 0;
        if ( session.unreadCount === 0 ) {
          newUnread = 0;
        } else {
          newUnread = currentUnread + session.unreadCount;
        }
        values['unread_count'] = newUnread;
        await MessageRdb.rdbStore.update(values, predicates);
      } else {
        values['unread_count'] = session.unreadCount;
        await MessageRdb.rdbStore.insert(MessageRdb.TABLE_SESSION, values);
      }
      return true;
    } catch ( e ) {
      console.error('保存会话失败', e);
      return false;
    } finally {
      resultSet.close();
    }
  }

  static async clearUnread(sessionId: string): Promise<boolean> {
    if (!MessageRdb.rdbStore ) {
      return false;
    }
    const predicates = new relationalStore.RdbPredicates(MessageRdb.TABLE_SESSION);
    predicates.equalTo('session_id', sessionId);

    const values: ValuesBucket = {
      'unread_count': 0
    };

    try {
      await MessageRdb.rdbStore.update(values, predicates);
      return true;
    } catch ( e ) {
      return false;
    }
  }

  static async getSessionList(): Promise<SessionModel[]> {
    if (!MessageRdb.rdbStore ) {
      return [];
    }

    const predicates = new relationalStore.RdbPredicates(MessageRdb.TABLE_SESSION);
    predicates.orderByDesc('last_time');

    const resultSet = await MessageRdb.rdbStore.query(predicates);
    const list: SessionModel[] = [];

        while (resultSet.goToNextRow()) {

          list.push({

            sessionId: resultSet.getString(resultSet.getColumnIndex('session_id')),

            title: resultSet.getString(resultSet.getColumnIndex('title')),

            avatar: resultSet.getString(resultSet.getColumnIndex('avatar')),

            lastMsg: resultSet.getString(resultSet.getColumnIndex('last_msg')),

            lastTime: resultSet.getLong(resultSet.getColumnIndex('last_time')),

            unreadCount: resultSet.getLong(resultSet.getColumnIndex('unread_count'))

          });

        }

        resultSet.close();

    

        // ✨ 置顶逻辑：把 'system_notify' (Meow外卖) 移动到最前面

        const systemIndex = list.findIndex(s => s.sessionId === 'system_notify');

        if (systemIndex > -1) {

          const systemSession = list.splice(systemIndex, 1)[0];

          list.unshift(systemSession);

        }

    

        return list;

      }

  static async deleteSession(sessionId: string): Promise<boolean> {
    if (!MessageRdb.rdbStore ) {
      return false;
    }

    try {
      const sessPred = new relationalStore.RdbPredicates(MessageRdb.TABLE_SESSION);
      sessPred.equalTo('session_id', sessionId);
      await MessageRdb.rdbStore.delete(sessPred);

      const msgPred = new relationalStore.RdbPredicates(MessageRdb.TABLE_MESSAGE);
      msgPred.equalTo('session_id', sessionId);
      await MessageRdb.rdbStore.delete(msgPred);

      return true;
    } catch ( e ) {
      return false;
    }
  }

  // ==================== 消息管理 ====================

  static async saveMessage(msg: MessageEntity): Promise<boolean> {
    if (!MessageRdb.rdbStore ) {
      return false;
    }

    const values: ValuesBucket = {
      'session_id': msg.sessionId,
      'msg_id': msg.msgId,
      'sender_id': msg.senderId,
      'role': msg.role,
      'content': msg.content,
      'type': msg.type,
      'create_time': msg.createTime,
      'order_id': msg.orderId || null // 存入 orderId
    };

    try {
      await MessageRdb.rdbStore.insert(MessageRdb.TABLE_MESSAGE, values);
      return true;
    } catch ( e ) {
      console.error('保存消息失败', e);
      return false;
    }
  }

  static async getMessages(sessionId: string, limit: number = 50, offset: number = 0): Promise<MessageEntity[]> {
    if (!MessageRdb.rdbStore ) {
      return [];
    }

    const predicates = new relationalStore.RdbPredicates(MessageRdb.TABLE_MESSAGE);
    predicates.equalTo('session_id', sessionId);
    predicates.orderByAsc('create_time');

    const resultSet = await MessageRdb.rdbStore.query(predicates);
    const list: MessageEntity[] = [];

    while ( resultSet.goToNextRow() ) {
      list.push({
        id: resultSet.getLong(resultSet.getColumnIndex('id')),
        sessionId: resultSet.getString(resultSet.getColumnIndex('session_id')),
        msgId: resultSet.getString(resultSet.getColumnIndex('msg_id')),
        senderId: resultSet.getLong(resultSet.getColumnIndex('sender_id')),
        role: resultSet.getLong(resultSet.getColumnIndex('role')),
        content: resultSet.getString(resultSet.getColumnIndex('content')),
        type: resultSet.getLong(resultSet.getColumnIndex('type')),
        createTime: resultSet.getLong(resultSet.getColumnIndex('create_time')),
        orderId: resultSet.getLong(resultSet.getColumnIndex('order_id')) // 读取 orderId
      });
    }
    resultSet.close();
    return list;
  }

  /**
   * 删除指定订单的所有消息
   */
  static async deleteMessagesByOrderId(orderId: number): Promise<boolean> {
    if (!MessageRdb.rdbStore ) {
      return false;
    }
    const predicates = new relationalStore.RdbPredicates(MessageRdb.TABLE_MESSAGE);
    predicates.equalTo('order_id', orderId);
    try {
      await MessageRdb.rdbStore.delete(predicates);
      return true;
    } catch ( e ) {
      return false;
    }
  }

  /**
   * 删除指定单条消息
   */
  static async deleteMessageById(id: number): Promise<boolean> {
    if (!MessageRdb.rdbStore) return false;
    const predicates = new relationalStore.RdbPredicates(MessageRdb.TABLE_MESSAGE);
    predicates.equalTo('id', id);
    try {
      await MessageRdb.rdbStore.delete(predicates);
      return true;
    } catch (e) {
      return false;
    }
  }

  /**
   * 批量删除消息
   * @param ids 消息ID列表
   */
  static async deleteBatch(ids: number[]): Promise<boolean> {
    if (!MessageRdb.rdbStore || ids.length === 0) return false;
    const predicates = new relationalStore.RdbPredicates(MessageRdb.TABLE_MESSAGE);
    predicates.in('id', ids);
    try {
      await MessageRdb.rdbStore.delete(predicates);
      return true;
    } catch (e) {
      console.error('批量删除失败', e);
      return false;
    }
  }
}