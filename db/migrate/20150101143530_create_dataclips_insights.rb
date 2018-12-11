class CreateDataclipsInsights < ActiveRecord::Migration[5.2]
  def change
    execute "DROP TABLE IF EXISTS dataclips_insights;"
    create_table :dataclips_insights do |t|
      t.string  :hash_id, null: false

      t.string  :clip_id, null: false
      t.json    :params

      t.string  :checksum, null: false
      t.string  :time_zone, null: false
      t.string  :name
      t.string  :connection
      t.integer :per_page
      t.string  :schema
      t.string  :basic_auth_credentials
      t.datetime :last_viewed_at
      t.timestamps
    end

    add_index :dataclips_insights, :clip_id
    add_index :dataclips_insights, :checksum, unique: true
    add_index :dataclips_insights, :hash_id, unique: true
    add_index :dataclips_insights, :schema

    execute <<-SQL
      INSERT INTO "public"."dataclips_insights"("id","clip_id","schema","hash_id","checksum","time_zone","name","basic_auth_credentials","params","last_viewed_at","created_at","updated_at")
      VALUES
      (1,E'sandbox_accounts',NULL,E'TkfQhMV1',E'777436f4f3f00c0f467dddfdf139a18e',E'Europe/Berlin',E'sandbox_accounts',NULL,E'{}',E'2017-12-15 13:31:59.615516',E'2017-09-25 14:16:43.929295',E'2017-12-15 13:31:59.615516'),
      (2,E'production_accounts',NULL,E'kp4ANG73',E'0fd128debc1af873495ad6134af958b5',E'Europe/Berlin',E'production_accounts',NULL,E'{}',E'2017-09-26 11:31:33.780233',E'2017-09-25 15:01:04.790501',E'2017-09-26 11:31:33.780233'),
      (3,E'report_orders',NULL,E'hnYh6jXU',E'521382ba8c9c264f5ce1b8cefdd72cbb',E'Europe/Berlin',E'Germany-2017',NULL,E'{"year":2017, "country_code":["de"]}',E'2018-05-04 11:16:28.077197',E'2017-09-26 09:56:18.818899',E'2018-05-04 11:16:28.077197'),
      (4,E'report_orders',NULL,E'fSy5Taan',E'6981d6e4b3b87863eebd6547df2c1d64',E'Asia/Manila',E'Phillipines-2017',NULL,E'{"year":2017,"country_code":["ph"]}',E'2018-11-27 11:40:23.477572',E'2017-09-26 20:35:39.479502',E'2018-11-27 11:40:23.477572'),
      (5,E'report_orders',NULL,E'wEfxCPvD',E'9ecfe8fa3dd65afe2b8f4a08671ed016',E'Europe/Berlin',E'Austria-2017',NULL,E'{"year":2017,"country_code":["at"]}',E'2017-09-27 08:07:34.215595',E'2017-09-26 20:36:37.697561',E'2017-09-27 08:07:34.215595'),
      (6,E'report_orders',NULL,E'TRvE72uz',E'd3f4461126aa04320533b5b275191ff8',E'Europe/Berlin',E'Sweden-2017',NULL,E'{"year":2017,"country_code":["se"]}',E'2017-09-27 13:02:58.884173',E'2017-09-26 20:37:12.894502',E'2017-09-27 13:02:58.884173'),
      (8,E'report_orders',NULL,E'q8kdpZE1',E'dcdf7d511215427d25b198b2c7015c34',E'Europe/Berlin',E'Germany,Austria,Sweden,France-2017',NULL,E'{"year":2017,"country_code":["de","at","se", "fr"]}',E'2018-06-04 14:12:47.422076',E'2017-09-27 10:50:36.709508',E'2018-06-04 14:12:47.422076'),
      (9,E'report_orders',NULL,E'BK_9FX1e',E'615282b0557a181291935fe6a43426ac',E'Europe/Berlin',E'France-2017',NULL,E'{"year":2017,"country_code":["fr"]}',NULL,E'2017-09-27 11:03:24.089177',E'2017-09-27 11:03:24.089177'),
      (10,E'staff/orders',NULL,E'c28VLj6b',E'79281396f78beec88edcca8120323aeb',E'Europe/Berlin',E'Archive (2017)',NULL,E'{"year":2017}',E'2018-11-20 14:59:08.102996',E'2017-10-31 14:24:20.139652',E'2018-11-20 14:59:08.102996'),
      (11,E'staff/orders',NULL,E'PDxrigiZ',E'f33879642296431febc1568112c72ef0',E'Europe/Berlin',E'Archive (2016)',NULL,E'{"year":2016}',E'2018-10-13 11:29:26.036656',E'2017-10-31 14:24:22.989488',E'2018-10-13 11:29:26.036656'),
      (12,E'staff/orders',NULL,E's31K6Qr5',E'e27c684b085a33bf073ce724101d68bb',E'Europe/Berlin',E'Archive (2015)',NULL,E'{"year":2015}',E'2018-11-22 10:39:26.624536',E'2017-10-31 14:24:25.878536',E'2018-11-22 10:39:26.624536'),
      (13,E'staff/orders',NULL,E'sKhb0Pln',E'95b9e783cd02d39ed43cdd27a4d43222',E'Europe/Berlin',E'Archive (2014)',NULL,E'{"year":2014}',E'2018-08-24 11:33:32.90216',E'2017-10-31 16:35:42.117252',E'2018-08-24 11:33:32.90216'),
      (14,E'staff/orders',NULL,E'U79en7tr',E'04731b96cc68a713a215b31e01727b0d',E'Europe/Berlin',E'Archive (2013)',NULL,E'{"year":2013}',E'2018-02-16 09:44:38.362819',E'2017-10-31 16:35:44.776389',E'2018-02-16 09:44:38.362819'),
      (15,E'staff/orders',NULL,E'ljsh1nC0',E'6d69a8de29e4656dd810f5ef9064b35e',E'Europe/Berlin',E'Archive (2012)',NULL,E'{"year":2012}',E'2018-11-14 15:35:37.428091',E'2017-10-31 16:35:46.633641',E'2018-11-14 15:35:37.428091'),
      (16,E'report_orders',NULL,E'hud7mt21',E'4332815154a8b44bc8cec62cdef9c666',E'Europe/Berlin',E'Germany,Austria,Sweden,France-2018',NULL,E'{"year":2018,"country_code":["de","at","se","fr"]}',E'2018-12-05 09:49:56.302338',E'2018-01-02 13:24:18.098614',E'2018-12-05 09:49:56.302338'),
      (17,E'shell_tours',NULL,E'227OmEj9',E'1fab8d4a999342b2211df1f461ab1db1',E'Asia/Manila',E'shell_tours',NULL,E'{}',E'2018-12-03 04:37:17.241126',E'2018-01-03 11:22:51.536325',E'2018-12-03 04:37:17.241126'),
      (18,E'sales',NULL,E'S5dZkcAh',E'd1bf621a3a2fe3be7dd7ed8c440f6f19',E'Europe/Berlin',E'sales',NULL,E'{}',E'2018-12-10 09:39:47.38774',E'2018-12-07 15:18:42.304318',E'2018-12-10 09:39:47.38774');
      SQL
  end
end
