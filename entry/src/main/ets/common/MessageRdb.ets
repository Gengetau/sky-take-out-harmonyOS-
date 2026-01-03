import { common } from '@kit.AbilityKit';
import { relationalStore, ValuesBucket } from '@kit.ArkData';
import { SessionModel } from '../model/MessageModel';

/**
 * 消息实体 (对应 RDB 存储结构)
 */
export interface MessageEntity {
  id?: number;         
  shopId: number;      // 🐾 关键字段：所属店铺ID
  sessionId: string;   
  msgId: string;       
  senderId: number;    
  role: number;        
  content: string;     
  type: number;        
  createTime: number;  
  orderId?: number;    
}

/**
 * 📨 消息中心数据库工具类 (RDB)
 * 增加店铺隔离逻辑喵！✨
 */
export class MessageRdb {
  private static readonly DB_NAME = 'SkyDelivery_Merchant_Msg_V2.db'; // 🐾 升级数据库名
  private static readonly TABLE_SESSION = 'tb_session';
  private static readonly TABLE_MESSAGE = 'tb_message';
  private static rdbStore: relationalStore.RdbStore | null = null;
  
  private static readonly SQL_CREATE_SESSION = `
    CREATE TABLE IF NOT EXISTS tb_session (
      shop_id INTEGER,
      session_id TEXT,
      title TEXT,
      avatar TEXT,
      last_msg TEXT,
      last_time INTEGER,
      unread_count INTEGER,
      PRIMARY KEY (shop_id, session_id)
    )
  `;
  
  private static readonly SQL_CREATE_MESSAGE = `
    CREATE TABLE IF NOT EXISTS tb_message (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      shop_id INTEGER,
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

  static async init(context: common.UIAbilityContext) {
    if (MessageRdb.rdbStore) return;
    const config: relationalStore.StoreConfig = {
      name: MessageRdb.DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    };
    try {
      MessageRdb.rdbStore = await relationalStore.getRdbStore(context, config);
      await MessageRdb.rdbStore.executeSql(MessageRdb.SQL_CREATE_SESSION);
      await MessageRdb.rdbStore.executeSql(MessageRdb.SQL_CREATE_MESSAGE);
      console.info('喵！隔离版消息数据库初始化成功 📨');
    } catch (err) {
      console.error('消息数据库初始化失败', err);
    }
  }

  // ==================== 会话管理 ====================

  static async saveSession(shopId: number, session: SessionModel): Promise<boolean> {
    if (!MessageRdb.rdbStore) return false;

    const predicates = new relationalStore.RdbPredicates(MessageRdb.TABLE_SESSION);
    predicates.equalTo('shop_id', shopId).and().equalTo('session_id', session.sessionId);
    const resultSet = await MessageRdb.rdbStore.query(predicates);

    const values: ValuesBucket = {
      'shop_id': shopId,
      'session_id': session.sessionId,
      'title': session.title,
      'avatar': typeof session.avatar === 'string' ? session.avatar : '',
      'last_msg': session.lastMsg,
      'last_time': session.lastTime
    };

    try {
      if (resultSet.rowCount > 0) {
        resultSet.goToFirstRow();
        const currentUnread = resultSet.getLong(resultSet.getColumnIndex('unread_count'));
        values['unread_count'] = session.unreadCount === 0 ? 0 : currentUnread + session.unreadCount;
        await MessageRdb.rdbStore.update(values, predicates);
      } else {
        values['unread_count'] = session.unreadCount;
        await MessageRdb.rdbStore.insert(MessageRdb.TABLE_SESSION, values);
      }
      return true;
    } catch (e) {
      console.error('保存会话失败', e);
      return false;
    } finally {
      resultSet.close();
    }
  }

  static async getSessionList(shopId: number): Promise<SessionModel[]> {
    if (!MessageRdb.rdbStore) return [];
    const predicates = new relationalStore.RdbPredicates(MessageRdb.TABLE_SESSION);
    predicates.equalTo('shop_id', shopId).orderByDesc('last_time');

    const resultSet = await MessageRdb.rdbStore.query(predicates);
    const list: SessionModel[] = [];
    while (resultSet.goToNextRow()) {
      list.push(new SessionModel(
        resultSet.getString(resultSet.getColumnIndex('session_id')),
        resultSet.getString(resultSet.getColumnIndex('title')),
        resultSet.getString(resultSet.getColumnIndex('avatar')),
        resultSet.getString(resultSet.getColumnIndex('last_msg')),
        resultSet.getLong(resultSet.getColumnIndex('last_time')),
        resultSet.getLong(resultSet.getColumnIndex('unread_count'))
      ));
    }
    resultSet.close();
    return list;
  }
  
  static async deleteSession(shopId: number, sessionId: string): Promise<boolean> {
    if (!MessageRdb.rdbStore) return false;
    try {
      const sessPred = new relationalStore.RdbPredicates(MessageRdb.TABLE_SESSION);
      sessPred.equalTo('shop_id', shopId).and().equalTo('session_id', sessionId);
      await MessageRdb.rdbStore.delete(sessPred);

      const msgPred = new relationalStore.RdbPredicates(MessageRdb.TABLE_MESSAGE);
      msgPred.equalTo('shop_id', shopId).and().equalTo('session_id', sessionId);
      await MessageRdb.rdbStore.delete(msgPred);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ==================== 消息管理 ====================

  static async saveMessage(msg: MessageEntity): Promise<boolean> {
    if (!MessageRdb.rdbStore) return false;
    const values: ValuesBucket = {
      'shop_id': msg.shopId,
      'session_id': msg.sessionId,
      'msg_id': msg.msgId,
      'sender_id': msg.senderId,
      'role': msg.role,
      'content': msg.content,
      'type': msg.type,
      'create_time': msg.createTime,
      'order_id': msg.orderId || null
    };
    try {
      await MessageRdb.rdbStore.insert(MessageRdb.TABLE_MESSAGE, values);
      return true;
    } catch (e) {
      console.error('保存消息失败', e);
      return false;
    }
  }

  static async getMessages(shopId: number, sessionId: string): Promise<MessageEntity[]> {
    if (!MessageRdb.rdbStore) return [];
    const predicates = new relationalStore.RdbPredicates(MessageRdb.TABLE_MESSAGE);
    predicates.equalTo('shop_id', shopId).and().equalTo('session_id', sessionId).orderByAsc('create_time');

    const resultSet = await MessageRdb.rdbStore.query(predicates);
    const list: MessageEntity[] = [];
    while (resultSet.goToNextRow()) {
      list.push({
        shopId: resultSet.getLong(resultSet.getColumnIndex('shop_id')),
        sessionId: resultSet.getString(resultSet.getColumnIndex('session_id')),
        msgId: resultSet.getString(resultSet.getColumnIndex('msg_id')),
        senderId: resultSet.getLong(resultSet.getColumnIndex('sender_id')),
        role: resultSet.getLong(resultSet.getColumnIndex('role')),
        content: resultSet.getString(resultSet.getColumnIndex('content')),
        type: resultSet.getLong(resultSet.getColumnIndex('type')),
        createTime: resultSet.getLong(resultSet.getColumnIndex('create_time')),
        orderId: resultSet.getLong(resultSet.getColumnIndex('order_id'))
      });
    }
    resultSet.close();
    return list;
  }
}
