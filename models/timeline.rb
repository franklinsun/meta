# -*- encoding: utf-8 -*-

class Timeline
  include Mongoid::Document
  embedded_in :item
  embeds_one  :increment # 增量
  

  # Fields
  field :outer_id,      type: String
  field :title,         type: String
  field :pic_url,       type: String

  field :prom_type,     type: String

  field :price,         type: Float
  field :prom_price,    type: Float,   default: -> { price }
  field :prom_discount, type: Integer, default: 100

  field :total_num,     type: Integer, default: 0
  field :month_num,     type: Integer, default: 0
  field :quantity,      type: Integer, default: 0

  field :favs_count,    type: Integer, default: 0
  field :skus_count,    type: Integer, default: 0
  field :post_fee,      type: Boolean, default: false
  field :status,        type: String

  field :synced_at,     type: DateTime
  field :_id,           type: Integer, default: -> { synced_at.to_i }

  default_scope desc(:synced_at)

  after_create :increment_create

  def show_status
    case status
    when 'onsale'
      '在售'
    when 'soldout'
      '售罄'
    when 'inventory'
      '下架'
    else
      '未知'
    end
  end

  def increment_create
    current_item  = self.item
    new_increment = {
       timestamp: synced_at.to_i,
      # 价格
           price: ( current_item.price  - price ).round(2),
      # 销售
       total_num: current_item.total_num  - total_num,
       month_num: current_item.month_num  - month_num,
      # 库存
        quantity: current_item.quantity   - quantity,
      skus_count: current_item.skus_count - skus_count,
      # 收藏
      favs_count: current_item.favs_count - favs_count
    }
    # 优惠活动
    if current_item.prom_price > 0 
      prom = { 
           prom_price: (current_item.prom_price - prom_price).round(2), 
        prom_discount: current_item.prom_discount - prom_discount
      }
      new_increment.merge!(prom) 
    end
    self.increment = Increment.new(new_increment)
  end

end