# Mixin to query and write data to mysql.
#
# Please note that you don't need this mixin when you only want to read data from mysql. Use the
# `.stream()` method of connection query.
#
# Usage:
#  * Load the mixin:
#    ```coffee
#    { MysqlMixin } = require('datapumps/mixins')
#    ```
#
#  * Add the mixin and set the mysql connection:
#    ```coffee
#    pump
#      .mixin MysqlMixin myMysqlConnection
#    ```
#
#  * Use the `.query()` method of the pump in `.process()`
#    ```coffee
#    pump
#      .process (data) ->
#        @query 'INSERT INTO customer (name, address) VALUES (?)', [ data.name, data.address ]
#    ```
#    Please note that the `.query()` method returns a promise (it is the promisified version of
#    `connection.query()`).
#
# Complete example: Copy data from one table to another
# ```coffee
# { Pump, mixin: { MysqlMixin } } = require('datapumps')
# mysqlConnection = require('mysql').createConnection <your-connection-string>
#
# mysqlCopy = new Pump
#   .from mysqlConnection.query('SELECT id,last_name,first_name FROM customer').stream()
#   .mixin MysqlMixin mysqlConnection
#   .process (customer) ->
#     @query 'SELECT id FROM new_customer_table WHERE id = ? ', p.id
#       .then ([ result, fields ]) =>
#         if result.length == 0
#           @query 'INSERT INTO new_customer_table
#             (id,last_name,first_name) VALUES (?)',
#             [ customer.id, customer.last_name, customer.first_name ]
#         else
#           @query 'UPDATE new_customer_table
#             SET last_name=?, first_name = ?
#             WHERE id=?',
#             customer.last_name, customer.first_name, customer.id
# ```
#
Promise = require('bluebird')

mysqlMixin = (connection) ->
  if !connection? or typeof(connection?.query) != 'function'
    throw new Error 'Mysql mixin requires connection to be given'
  (target) ->
    target._mysql =
      connection: connection
      query: Promise.promisify connection.query, connection

    target.query = (query, args...) ->
      if args?
        @_mysql.query(query, args)
      else
        @_mysql.query(query)

    target.selectOne = (query, args...) ->
      target.query(query, args)
        .then (results) ->
          if results.length == 1
            Promise.resolve(results[0])
          else if results.length == 0
            Promise.reject('Query returned no result')
          else
            Promise.reject('Query returned more than one result')

module.exports = mysqlMixin
