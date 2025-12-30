-- =================================================================================
-- 多商家平台测试数据及索引优化脚本喵！🐱✨
-- =================================================================================

USE `sky_take_out`;

-- 1. 索引优化：解决多商家重名冲突喵！🛠️
# ALTER TABLE `category` DROP INDEX `idx_category_name`;
ALTER TABLE `category` ADD UNIQUE KEY `idx_name_shop` (`name`, `shop_id`);

# ALTER TABLE `dish` DROP INDEX `idx_dish_name`;
ALTER TABLE `dish` ADD UNIQUE KEY `idx_name_shop` (`name`, `shop_id`);

-- 2. 批量插入分类数据喵 (ID 手动指定方便关联)

-- KFC (ID: 2)
INSERT INTO `category` (id, type, name, sort, status, create_time, update_time, create_user, update_user, shop_id) VALUES
(100, 1, '人气汉堡', 1, 1, NOW(), NOW(), 1, 1, 2),
(101, 1, '吮指炸鸡', 2, 1, NOW(), NOW(), 1, 1, 2),
(102, 1, '缤纷小食', 3, 1, NOW(), NOW(), 1, 1, 2),
(103, 1, '冰爽饮料', 4, 1, NOW(), NOW(), 1, 1, 2),
(104, 1, '甜品时间', 5, 1, NOW(), NOW(), 1, 1, 2);

-- 老北京炸酱面 (ID: 3)
INSERT INTO `category` (id, type, name, sort, status, create_time, update_time, create_user, update_user, shop_id) VALUES
(105, 1, '特色面食', 1, 1, NOW(), NOW(), 1, 1, 3),
(106, 1, '京味凉菜', 2, 1, NOW(), NOW(), 1, 1, 3),
(107, 1, '手工水饺', 3, 1, NOW(), NOW(), 1, 1, 3),
(108, 1, '营养汤品', 4, 1, NOW(), NOW(), 1, 1, 3),
(109, 1, '老北京饮品', 5, 1, NOW(), NOW(), 1, 1, 3);

-- 瑞幸咖啡 (ID: 4)
INSERT INTO `category` (id, type, name, sort, status, create_time, update_time, create_user, update_user, shop_id) VALUES
(110, 1, '大师咖啡', 1, 1, NOW(), NOW(), 1, 1, 4),
(111, 1, '瑞纳冰', 2, 1, NOW(), NOW(), 1, 1, 4),
(112, 1, '经典拿铁', 3, 1, NOW(), NOW(), 1, 1, 4),
(113, 1, '幸运烘焙', 4, 1, NOW(), NOW(), 1, 1, 4),
(114, 1, '清爽果茶', 5, 1, NOW(), NOW(), 1, 1, 4);

-- 3. 批量插入菜品数据喵

-- KFC 菜品
INSERT INTO `dish` (id, name, category_id, price, image, description, status, create_time, update_time, create_user, update_user, shop_id) VALUES
(100, '香辣鸡腿堡', 100, 19.50, 'kfc_burger_1.png', '经典香辣，欲罢不能喵', 1, NOW(), NOW(), 1, 1, 2),
(101, '吮指原味鸡', 101, 13.00, 'kfc_chicken_1.png', '经典配方喵', 1, NOW(), NOW(), 1, 1, 2),
(102, '波纹薯条', 102, 11.00, 'kfc_snack_1.png', '外酥里嫩喵', 1, NOW(), NOW(), 1, 1, 2);

-- 炸酱面 菜品
INSERT INTO `dish` (id, name, category_id, price, image, description, status, create_time, update_time, create_user, update_user, shop_id) VALUES
(103, '招牌炸酱面', 105, 28.00, 'bj_noodle_1.png', '地道老北京口味喵', 1, NOW(), NOW(), 1, 1, 3),
(104, '手工水饺', 107, 22.00, 'bj_dumpling_1.png', '手工现包喵', 1, NOW(), NOW(), 1, 1, 3);

-- 瑞幸咖啡 菜品
INSERT INTO `dish` (id, name, category_id, price, image, description, status, create_time, update_time, create_user, update_user, shop_id) VALUES
(105, '生椰拿铁', 110, 18.00, 'luckin_1.png', 'YYDS喵！', 1, NOW(), NOW(), 1, 1, 4),
(106, '抹茶瑞纳冰', 111, 22.00, 'luckin_3.png', '清凉一夏喵', 1, NOW(), NOW(), 1, 1, 4);

-- 4. 批量插入菜品口味数据喵 (关键环节喵！✨)

-- 为瑞幸咖啡 (生椰拿铁) 增加口味
INSERT INTO `dish_flavor` (dish_id, name, value) VALUES
(105, '温度', '["热","去冰","少冰","常温"]'),
(105, '糖度', '["全糖","半糖","微糖","无糖"]');

-- 为瑞幸咖啡 (抹茶瑞纳冰) 增加口味
INSERT INTO `dish_flavor` (dish_id, name, value) VALUES
(106, '糖度', '["全糖","半糖","无糖"]'),
(106, '奶油', '["要奶油","不要奶油"]');

-- 为炸酱面增加口味
INSERT INTO `dish_flavor` (dish_id, name, value) VALUES
(103, '辣度', '["不辣","微辣","中辣","特辣"]'),
(103, '配料', '["不要葱","不要香菜","多放酱"]');

-- 为肯德基汉堡增加口味
INSERT INTO `dish_flavor` (dish_id, name, value) VALUES
(100, '配料', '["去生菜","去蛋黄酱","加芝士"]');

-- 5. 为其他店铺快速补齐基础分类喵
INSERT INTO `category` (type, name, sort, status, create_time, update_time, create_user, update_user, shop_id) VALUES
(1, '当季推荐', 1, 1, NOW(), NOW(), 1, 1, 5),
(1, '热销披萨', 1, 1, NOW(), NOW(), 1, 1, 6),
(1, '皇堡套餐', 1, 1, NOW(), NOW(), 1, 1, 7),
(1, '灵感之茶', 1, 1, NOW(), NOW(), 1, 1, 8),
(1, '霸气系列', 1, 1, NOW(), NOW(), 1, 1, 9),
(1, '超值套餐', 1, 1, NOW(), NOW(), 1, 1, 10),
(1, '招牌牛饭', 1, 1, NOW(), NOW(), 1, 1, 11),
(1, '全能沙拉', 1, 1, NOW(), NOW(), 1, 1, 12),
(1, '浓郁拉面', 1, 1, NOW(), NOW(), 1, 1, 13);