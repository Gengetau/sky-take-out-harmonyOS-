import { common } from '@kit.AbilityKit';
import { relationalStore, ValuesBucket } from '@kit.ArkData';
import { CartItem } from '../../model/entity/ShopModel';

/**
 * 🛒 购物车数据库工具类 (RDB)
 */
export class CartRdb {
  private static readonly DB_NAME = 'SkyDelivery.db';
  private static readonly TABLE_NAME = 'cart_item';
  private static rdbStore: relationalStore.RdbStore | null = null;
  // 建表语句
  private static readonly SQL_CREATE_TABLE = `
    CREATE TABLE IF NOT EXISTS cart_item (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      shop_id INTEGER NOT NULL,
      dish_id INTEGER,
      setmeal_id INTEGER,
      name TEXT NOT NULL,
      image TEXT,
      price REAL NOT NULL,
      count INTEGER NOT NULL,
      flavors TEXT
    )
  `;

  /**
   * 初始化数据库
   */
  static async init(context: common.UIAbilityContext) {
    if ( CartRdb.rdbStore ) {
      return;
    }

    const config: relationalStore.StoreConfig = {
      name: CartRdb.DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    };

    try {
      CartRdb.rdbStore = await relationalStore.getRdbStore(context, config);
      await CartRdb.rdbStore.executeSql(CartRdb.SQL_CREATE_TABLE);
      console.info('喵！RDB数据库初始化成功 🛒');
    } catch ( err ) {
      console.error('RDB初始化失败', err);
    }
  }

  /**
   * 获取指定店铺的购物车
   */
  static async getCartByShopId(shopId: number): Promise<CartItem[]> {
    if (!CartRdb.rdbStore ) {
      return [];
    }

    const predicates = new relationalStore.RdbPredicates(CartRdb.TABLE_NAME);
    predicates.equalTo('shop_id', shopId);

    const resultSet = await CartRdb.rdbStore.query(predicates);
    const items: CartItem[] = [];

    while ( resultSet.goToNextRow() ) {
      const item = new CartItem(
        resultSet.getLong(resultSet.getColumnIndex('dish_id')) || undefined,
        resultSet.getLong(resultSet.getColumnIndex('setmeal_id')) || undefined,
        resultSet.getString(resultSet.getColumnIndex('name')),
        resultSet.getString(resultSet.getColumnIndex('image')),
        resultSet.getDouble(resultSet.getColumnIndex('price')),
        resultSet.getLong(resultSet.getColumnIndex('count')),
        resultSet.getString(resultSet.getColumnIndex('flavors'))
      );
      items.push(item);
    }
    resultSet.close();
    return items;
  }

  /**
   * 获取所有有商品的店铺ID及其商品
   * 用于 CartPage 展示多店列表
   */
  static async getAllCarts(): Promise<Record<number, CartItem[]>> {
    if (!CartRdb.rdbStore ) {
      return {};
    }

    const predicates = new relationalStore.RdbPredicates(CartRdb.TABLE_NAME);
    // 按店铺排序，方便处理
    predicates.orderByAsc('shop_id');

    const resultSet = await CartRdb.rdbStore.query(predicates);
    const result: Record<number, CartItem[]> = {};

    while ( resultSet.goToNextRow() ) {
      const shopId = resultSet.getLong(resultSet.getColumnIndex('shop_id'));

      const item = new CartItem(
        resultSet.getLong(resultSet.getColumnIndex('dish_id')) || undefined,
        resultSet.getLong(resultSet.getColumnIndex('setmeal_id')) || undefined,
        resultSet.getString(resultSet.getColumnIndex('name')),
        resultSet.getString(resultSet.getColumnIndex('image')),
        resultSet.getDouble(resultSet.getColumnIndex('price')),
        resultSet.getLong(resultSet.getColumnIndex('count')),
        resultSet.getString(resultSet.getColumnIndex('flavors'))
      );

      if (!result[shopId] ) {
        result[shopId] = [];
      }
      result[shopId].push(item);
    }
    resultSet.close();
    return result;
  }

  /**
   * 添加或更新商品
   */
  static async saveItem(shopId: number, item: CartItem): Promise<boolean> {
    if (!CartRdb.rdbStore ) {
      return false;
    }

    // 1. 先查询是否存在 (根据 uniqueKey 的逻辑：dishId/setmealId + flavors)
    const predicates = new relationalStore.RdbPredicates(CartRdb.TABLE_NAME);
    predicates.equalTo('shop_id', shopId);

    if ( item.dishId ) {
      predicates.equalTo('dish_id', item.dishId);
    } else {
      predicates.isNull('dish_id');
    }

    if ( item.setmealId ) {
      predicates.equalTo('setmeal_id', item.setmealId);
    } else {
      predicates.isNull('setmeal_id');
    }

    // flavors 为空时也要匹配空字符串或null
    predicates.equalTo('flavors', item.flavors || '');

    const resultSet = await CartRdb.rdbStore.query(predicates);

    const valueBucket: ValuesBucket = {
      'shop_id': shopId,
      'dish_id': item.dishId || null,
      'setmeal_id': item.setmealId || null,
      'name': item.name,
      'image': item.image,
      'price': item.price,
      'count': item.count,
      'flavors': item.flavors || ''
    };

    try {
      if ( resultSet.rowCount > 0 ) {
        // 更新数量
        await CartRdb.rdbStore.update(valueBucket, predicates);
      } else {
        // 插入新记录
        await CartRdb.rdbStore.insert(CartRdb.TABLE_NAME, valueBucket);
      }
      return true;
    } catch ( e ) {
      console.error('保存购物车失败', e);
      return false;
    } finally {
      resultSet.close();
    }
  }

  /**
   * 删除商品
   */
  static async deleteItem(shopId: number, item: CartItem): Promise<boolean> {
    if (!CartRdb.rdbStore ) {
      return false;
    }

    const predicates = new relationalStore.RdbPredicates(CartRdb.TABLE_NAME);
    predicates.equalTo('shop_id', shopId);

    if ( item.dishId ) {
      predicates.equalTo('dish_id', item.dishId);
    } else {
      predicates.isNull('dish_id');
    }

    if ( item.setmealId ) {
      predicates.equalTo('setmeal_id', item.setmealId);
    } else {
      predicates.isNull('setmeal_id');
    }

    predicates.equalTo('flavors', item.flavors || '');

    try {
      await CartRdb.rdbStore.delete(predicates);
      return true;
    } catch ( e ) {
      console.error('删除商品失败', e);
      return false;
    }
  }

  /**
   * 清空指定店铺的购物车
   */
  static async clearShopCart(shopId: number): Promise<boolean> {
    if (!CartRdb.rdbStore ) {
      return false;
    }
    const predicates = new relationalStore.RdbPredicates(CartRdb.TABLE_NAME);
    predicates.equalTo('shop_id', shopId);
    await CartRdb.rdbStore.delete(predicates);
    return true;
  }

  /**
   * 清空所有购物车
   */
  static async clearAll(): Promise<boolean> {
    if (!CartRdb.rdbStore ) {
      return false;
    }
    const predicates = new relationalStore.RdbPredicates(CartRdb.TABLE_NAME);
    await CartRdb.rdbStore.delete(predicates);
    return true;
  }
}
