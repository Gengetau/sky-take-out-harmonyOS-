import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { ShopVO } from '../../model/entity/ShopModel';

/**
 * 💖 关注项接口
 */
export interface FollowItem {
  shopId: number;
  name: string;
  avatar: string;
  createTime: number;
}

/**
 * 💖 用户关注数据库工具类
 * 使用本地 RDB 存储关注的店铺信息，保护隐私喵！
 */
export class FollowRdb {
  private static readonly STORE_CONFIG: relationalStore.StoreConfig = {
    name: 'FollowStore.db',
    securityLevel: relationalStore.SecurityLevel.S1
  };
  
  private static readonly TABLE_NAME = 'user_follow';
  
  // SQL 建表语句
  private static readonly SQL_CREATE_TABLE = `
    CREATE TABLE IF NOT EXISTS ${FollowRdb.TABLE_NAME} (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      shopId INTEGER NOT NULL,
      name TEXT,
      avatar TEXT,
      createTime INTEGER
    )
  `;

  private rdbStore: relationalStore.RdbStore | null = null;
  private static instance: FollowRdb;

  private constructor() {}

  public static getInstance(): FollowRdb {
    if (!FollowRdb.instance) {
      FollowRdb.instance = new FollowRdb();
    }
    return FollowRdb.instance;
  }

  /**
   * 初始化数据库
   */
  async initRdb(context: common.Context): Promise<void> {
    try {
      this.rdbStore = await relationalStore.getRdbStore(context, FollowRdb.STORE_CONFIG);
      if (this.rdbStore) {
        await this.rdbStore.executeSql(FollowRdb.SQL_CREATE_TABLE);
        console.info('喵！关注数据库初始化成功！');
      }
    } catch (err) {
      console.error('喵！关注数据库初始化失败:', err);
    }
  }

  /**
   * 关注店铺
   */
  async followShop(shop: ShopVO): Promise<boolean> {
    if (!this.rdbStore) return false;
    
    // 先检查是否已关注
    const isFollowed = await this.isFollowed(shop.id);
    if (isFollowed) return true;

    try {
      const valueBucket: relationalStore.ValuesBucket = {
        'shopId': shop.id,
        'name': shop.name,
        'avatar': shop.avatar || '',
        'createTime': new Date().getTime()
      };
      await this.rdbStore.insert(FollowRdb.TABLE_NAME, valueBucket);
      return true;
    } catch (err) {
      console.error('关注失败喵:', err);
      return false;
    }
  }

  /**
   * 取消关注
   */
  async unfollowShop(shopId: number): Promise<boolean> {
    if (!this.rdbStore) return false;
    
    try {
      const predicates = new relationalStore.RdbPredicates(FollowRdb.TABLE_NAME);
      predicates.equalTo('shopId', shopId);
      await this.rdbStore.delete(predicates);
      return true;
    } catch (err) {
      console.error('取消关注失败喵:', err);
      return false;
    }
  }

  /**
   * 检查是否已关注
   */
  async isFollowed(shopId: number): Promise<boolean> {
    if (!this.rdbStore) return false;

    try {
      const predicates = new relationalStore.RdbPredicates(FollowRdb.TABLE_NAME);
      predicates.equalTo('shopId', shopId);
      const resultSet = await this.rdbStore.query(predicates);
      const count = resultSet.rowCount;
      resultSet.close();
      return count > 0;
    } catch (err) {
      console.error('查询关注状态失败喵:', err);
      return false;
    }
  }

  /**
   * 获取所有关注的店铺列表
   */
  async getFollowList(): Promise<FollowItem[]> {
    if (!this.rdbStore) return [];

    try {
      const predicates = new relationalStore.RdbPredicates(FollowRdb.TABLE_NAME);
      predicates.orderByDesc('createTime'); // 按关注时间倒序
      const resultSet = await this.rdbStore.query(predicates);
      
      const list: FollowItem[] = [];
      while (resultSet.goToNextRow()) {
        const item: FollowItem = {
          shopId: resultSet.getLong(resultSet.getColumnIndex('shopId')),
          name: resultSet.getString(resultSet.getColumnIndex('name')),
          avatar: resultSet.getString(resultSet.getColumnIndex('avatar')),
          createTime: resultSet.getLong(resultSet.getColumnIndex('createTime'))
        };
        list.push(item);
      }
      resultSet.close();
      return list;
    } catch (err) {
      console.error('获取关注列表失败喵:', err);
      return [];
    }
  }
}