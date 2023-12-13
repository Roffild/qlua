--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- https://github.com/Roffild/qlua
--

---@class roffild
---@field SCRIPT_PATH string Абсолютный путь к запущенному скрипту
---@field ISTRADINGALLOWED_SECONDS number Секунд в ожидании обезличиной сделки (по умолчанию = 3)
local roffild = {
    SCRIPT_PATH = "",
    ISTRADINGALLOWED_SECONDS = 3,
}

---Для внутренних глобальных переменных.
local roffild_vars = {
    win1251 = require("roffildqlua.win1251")
}

---Функция должна вызываться в `OnInit()`, когда она переопределена.
function roffild.OnInit(script_path)
    roffild.SCRIPT_PATH = script_path
end

function OnInit(script_path)
    roffild.OnInit(script_path)
end

---`isConnected() == 1` ещё ДО ввода PIN при Двухфакторной аутентификации.
---Обход бага через `getInfoParam("LASTRECORDTIME")`.
---@param seconds? number Секунд для ожидания (по умолчанию = 3 = `ISTRADINGALLOWED_SECONDS`)
---@return boolean
function roffild.isTradingAllowed(seconds)
    if isConnected() == 1 then
        local lastrecordtime = getInfoParam("LASTRECORDTIME")
        local servertime = getInfoParam("SERVERTIME") -- время с часовым поясом сервера (секунды локальные)
        if
            not (lastrecordtime == nil or lastrecordtime == "")
            and not (servertime == nil or servertime == "")
        then
            -- convertDateOrTimeToUnix из-за ":" не работает
            local fixlastrecordtime = os.sysdate()
            fixlastrecordtime.hour = tonumber(string.sub(lastrecordtime, 0, -7))
            fixlastrecordtime.min = tonumber(string.sub(lastrecordtime, -5, -4))
            fixlastrecordtime.sec = tonumber(string.sub(lastrecordtime, -2))
            if -- clearing
                fixlastrecordtime.hour < 7
                or (fixlastrecordtime.hour == 14 and fixlastrecordtime.min < 5)
                or (fixlastrecordtime.hour == 18 and fixlastrecordtime.min >= 45)
                or (fixlastrecordtime.hour == 19 and fixlastrecordtime.min < 5)
                or (fixlastrecordtime.hour == 23 and fixlastrecordtime.min >= 50)
            then
                return false
            end
            local fixservertime = os.sysdate()
            fixservertime.hour = tonumber(string.sub(servertime, 0, -7))
            fixservertime.min = tonumber(string.sub(servertime, -5, -4))
            fixservertime.sec = tonumber(string.sub(servertime, -2))
            return (math.abs(os.time(fixservertime) - os.time(fixlastrecordtime)) <=
                (seconds or roffild.ISTRADINGALLOWED_SECONDS))
        end
    end
    return false
end

---Конвертация ГГГГММДД(с поясом) или ЧЧММСС в UnixTime.
---@param date_or_time number|string
---@return number
function roffild.convertDateOrTimeToUnix(date_or_time)
    date_or_time = tonumber(date_or_time)
    if date_or_time == nil then
        return 0
    end
    if date_or_time > 1000000 then
        return os.time({
            year = math.floor(date_or_time / 10000),
            month = math.floor((date_or_time % 10000) / 100),
            day = math.floor(date_or_time % 100),
            hour = 0,
            min = 0,
            sec = 0
        })
    else
        return (math.floor(date_or_time / 10000) * 3600 +
                math.floor((date_or_time % 10000) / 100) * 60 +
                (date_or_time % 100))
    end
end

---Попадает `time` в отрезок времени?
---@param hourstart number Начальный час
---@param minstart number Начальная минута
---@param time qluaDateTime Время
---@param hourend number Конечный час
---@param minend number Конечная минута
---@return boolean
function roffild.isBetweenTimes(hourstart, minstart, time, hourend, minend)
    if time.hour < hourstart or time.hour > hourend then
        return false
    elseif time.hour == hourstart and time.min < minstart then
        return false
    elseif time.hour == hourend and time.min >= minend then
        return false
    end
    return true
end

---Функция заказывает получение параметров Таблицы текущих торгов с `ParamRequest()`.
---@param codes table Формат `{sec_code=class_code,...}`
---@param params? table Список параметров (по умолчанию = ценовые)
---@param reinit boolean Перезапросить?
function roffild.initParamRequest(codes, params, reinit)
    local ipr, prms
    if _INIT_PARAM_REQUEST_ == nil then
        _INIT_PARAM_REQUEST_ = {}
    end
    if params == nil then
        params = {}
    end
    prms = {
        BID=0, OFFER=0, LAST=0,
        HIGH=0, LOW=0,
        PRICEMIN=0, PRICEMAX=0,
        BUYDEPO=0, SELLDEPO=0, -- Garant
    }
    for k, v in pairs(params) do
        prms[v] = 0
    end
    for sec_code, class_code in pairs(codes) do
        ipr = _INIT_PARAM_REQUEST_[sec_code .. class_code]
        if ipr == nil or reinit then
            _INIT_PARAM_REQUEST_[sec_code .. class_code] = prms
            for p, n in pairs(prms) do
                if ParamRequest(class_code, sec_code, p) ~= true then
                    message("initParamRequest: p=" .. p .. " sec=" .. sec_code .. " class=" .. class_code, 2)
                end
            end
        end
    end
end

---Получает таблицу QUIK.
---@param table_name string Имена таблиц в справке "Таблицы, используемые в функциях getItem, getNumberOf и SearchItems"
---@param last? number Максимум последних заявок (по умолчанию = 100)
---@return table
function roffild.getTable(table_name, last)
    local i, count, result
    count = getNumberOf(table_name)
    result = {}
    if count ~= nil and count ~= 0 then
        if last == nil then
            last = 100
        end
        last = count - last
        if last < 0 then
            last = 0
        end
        for x = count-1, last, -1 do
            i = getItem(table_name, x)
            if i ~= nil then
                table.insert(result, i)
            end
        end
    end
    return result
end

---Возвращает таблицу значений для `getParamEx2()`, скопированную из справки.
---@return table
function roffild.getParamExAll()
    return roffild_vars.win1251.getParamExAll()
end

---@class roffildgetFuturesHoldingPriceReturn : qluaClientAccountPositionsFutures
---@field class_code string "SPBFUT"
---@field issell boolean На продажу?
---@field lastprice number Цена последней сделки
---@field lasttrade_num number Номер последней сделки

---Синхронизирует `futures_client_holding` с `trades` (обход бага).
---@param timeout? number Ожидание в секундах (по умолчанию = 3)
---@return roffildgetFuturesHoldingPriceReturn[] #Возвращает `futures_client_holding` с ценой и номером последней сделки.
function roffild.getFuturesHoldingPrice(timeout)
    local count = getNumberOf("trades")
    if count == nil then
        return {}
    end

    ---@type roffildgetFuturesHoldingPriceReturn
    local result = {}
    local price = 0.0
    for k, v in pairs(roffild.getTable("futures_client_holding")) do
        if v.totalnet ~= nil and v.totalnet ~= 0 then
            v.class_code = "SPBFUT"
            v.issell = v.totalnet < 0
            v.lastprice = v.avrposnprice
            v.lasttrade_num = 0
            result[v.trdaccid .. v.sec_code] = v
            price = price + v.avrposnprice
        end
    end

    if
        roffild_vars.GETFUTURESHOLDINGPRICE_TABLE ~= nil
        and roffild_vars.GETFUTURESHOLDINGPRICE_COUNT == count
        and math.abs(roffild_vars.GETFUTURESHOLDINGPRICE_PRICE - price) < 1.0e-8
    then -- изменений нет
        return roffild_vars.GETFUTURESHOLDINGPRICE_TABLE
    end

    timeout = os.clock() + (timeout or 3.0)
    while roffild_vars.GETFUTURESHOLDINGPRICE_COUNT == count do -- синхрон
        sleep(10)
        if os.clock() > timeout then
            break
        elseif roffild.isTradingAllowed() ~= true then
            return {}
        end
        count = getNumberOf("trades")
    end

    ---@type qltrades
    local trade = {}
    for k, v in pairs(result) do
        for x = count-1, 0, -1 do
            if trade[x] == nil then -- cache
                trade[x] = getItem("trades", x)
            end
            if
                trade[x] ~= nil
                and trade[x].sec_code == v.sec_code
                and trade[x].account == v.trdaccid
            then
                v.lastprice = trade[x].price
                v.lasttrade_num = trade[x].trade_num
                break
            end
        end
    end

    roffild_vars.GETFUTURESHOLDINGPRICE_TABLE = result
    roffild_vars.GETFUTURESHOLDINGPRICE_PRICE = price
    roffild_vars.GETFUTURESHOLDINGPRICE_COUNT = count
    return roffild_vars.GETFUTURESHOLDINGPRICE_TABLE
end

---@class roffildgetOrdersReturn : qluaOrders
---@field issell boolean На продажу?

---@class roffildgetOrdersReturnStop : qluaStopOrders
---@field issell boolean На продажу?

---Получить последнии записи по обычным заявкам или стоп-заявкам.
---@param stops boolean Стоп-заявки?
---@param last? number Максимум последних заявок (по умолчанию = ВСЕ)
---@param all boolean С исполнеными заявками?
---@param trans_id? string|number Номер транзакции
---@param sec_code? string Код инструмента
---@param class_code? string Код класса
---@param account? string Код клиента
---@return roffildgetOrdersReturn[]|roffildgetOrdersReturnStop[] #Тип `roffildgetOrdersReturn[]` или `roffildgetOrdersReturnStop[]`
function roffild.getOrders(stops, last, all, trans_id, sec_code, class_code, account)
    local tname, i, count, result
    if stops then
        tname = "stop_orders"
    else
        tname = "orders"
    end
    count = getNumberOf(tname)
    result = {}
    if count ~= nil and count ~= 0 then
        if last == nil or last < 1 then
            last = count
        end
        if trans_id ~= nil then
            trans_id = tonumber(trans_id)
        end
        for x = count-1, 0, -1 do
            i = getItem(tname, x)
            if
                i ~= nil
                and (all or (i.flags & 0x1) ~= 0)
                and (trans_id == nil or i.trans_id == trans_id)
                and (sec_code == nil or i.sec_code == sec_code)
                and (class_code == nil or i.class_code == class_code)
                and (account == nil or i.account == account)
            then
                i["issell"] = (i.flags & 0x4) > 0
                table.insert(result, i)
                last = last - 1
                if last < 1 then
                    break
                end
            end
        end
    end
    return result
end

---@class roffildgetDealsReturn : qluaTradesDeals
---@field issell boolean На продажу?

---Получить последние записи по сделкам.
---@param last? number Максимум последних заявок (по умолчанию = ВСЕ)
---@param order_num? number Номер заявки
---@param trans_id? string|number Номер транзакции
---@param sec_code? string Код инструмента
---@param class_code? string Код класса
---@param account? string Код клиента
---@return roffildgetDealsReturn[]
function roffild.getDeals(last, order_num, trans_id, sec_code, class_code, account)
    local i, count, result
    count = getNumberOf("trades")
    result = {}
    if count ~= nil and count ~= 0 then
        if last == nil or last < 1 then
            last = count
        end
        if trans_id ~= nil then
            trans_id = tonumber(trans_id)
        end
        for x = count-1, 0, -1 do
            i = getItem("trades", x)
            if
                i ~= nil
                and (order_num == nil or i.order_num == order_num)
                and (trans_id == nil or i.trans_id == trans_id)
                and (sec_code == nil or i.sec_code == sec_code)
                and (class_code == nil or i.class_code == class_code)
                and (account == nil or i.account == account)
            then
                if (i.flags & 0x4) ~= 0 then
                    i["issell"] = true
                else
                    i["issell"] = false
                end
                table.insert(result, i)
                last = last - 1
                if last < 1 then
                    break
                end
            end
        end
    end
    return result
end

---Генерацая TRANS_ID для `sendTransaction()`. \
---Для `roffild.sendStatus` уникальность ВАЖНА! \
---В самом QUIK это число не проверяется на уникальность и не используется.
---@return string #Строка
function roffild.genTransId()
    return tostring(math.ceil(os.clock() * 1000) % 0x7FFFFFFF)
end

---Определяет примерное количество цифр, которое должно стоять после символа десятичной точки.
---@param num number Число
---@param precision? number Количество цифр после точки
---@return number #Число
function roffild.round(num, precision)
    local mult = 10^(precision or 0)
    if num < 0 then
        return math.ceil(num * mult - 0.5) / mult
    end
    return math.floor(num * mult + 0.5) / mult
end

---Определяет точное количество цифр, которое должно стоять после символа десятичной точки.
---@param price string|number Цена
---@param precision? string|number Количество цифр после точки
---@return string #Строка
function roffild.roundPrice(price, precision)
    return string.format("%." .. tostring(precision or "0") .. "f", tonumber(price))
end

---@class roffildcreateOrderReturn
---@field trans_id string
---@field class_code string
---@field sec_code string
---@field account string
---@field price number
---@field qty number
---@field condition_price number
---@field offset number
---@field spread number
---@field condition_price2 number
---@field expiry number
---@field active_from_time number
---@field active_to_time number
---@field flags number
---@field stopflags number

---Создание заявки для последующей передачи в
---`sendOrder()`, `sendCancel()`, `sendStopOrder()`, `sendStopCancel()`.
---@param class_code string Код класса
---@param sec_code string Код инструмента
---@param account string Код клиента
---@param trans_id? number|string Номер транзакции (по умолчанию = `genTransId()`)
---@param sell boolean Продать?
---@param price? number Цена
---@param qty? number Количество лотов
---@param stoplimit? number Цена Stop-Limit
---@param takeprofit? number Цена Take-Profit
---@param offset? number|string Отступ от min (10 или "10%")
---@param spread? number|string Защитный спред (10 или "10%")
---@param active_from_time? number Время действия стоп-заявки С ЧЧММСС
---@param active_to_time? number Время действия стоп-заявки ДО ЧЧММСС
---@param expiry? number Срок действия стоп-заявки ГГГГММДД
---@return roffildcreateOrderReturn
function roffild.createOrder(class_code, sec_code, account, trans_id,
        sell, price, qty, stoplimit, takeprofit, offset, spread,
        active_from_time, active_to_time, expiry)
    local order
    order = {
        trans_id = tostring(trans_id or roffild.genTransId()),
        class_code = class_code,
        sec_code = sec_code,
        account = account,
        ---------------------
        price = tonumber(price),
        qty = tonumber(qty),
        condition_price = tonumber(takeprofit) or 0.0,
        offset = tonumber(offset) or 0,
        spread = tonumber(spread) or 0,
        condition_price2 = tonumber(stoplimit) or 0.0,
        expiry = tonumber(expiry) or 0,
        active_from_time = tonumber(active_from_time) or 0,
        active_to_time = tonumber(active_to_time) or 235959,
        flags = 0,
        stopflags = 0
    }
    if sell then
        order.flags = order.flags | 0x4
    end
    if type(offset) == "string" and string.sub(offset, -1) == "%" then
        order.offset = tonumber(string.sub(offset, 1, string.len(offset) - 1))
        order.stopflags = order.stopflags | 0x8
    end
    if type(spread) == "string" and string.sub(spread, -1) == "%" then
        order.spread = tonumber(string.sub(spread, 1, string.len(spread) - 1))
        order.stopflags = order.stopflags | 0x10
    end
    if order.expiry == 0 then
        order.stopflags = order.stopflags | 0x20 -- EXPIRY_DATE = "TODAY"
    end
    if order.active_from_time > 0 or order.active_to_time < 235959 then
       order.stopflags = order.stopflags | 0x40 -- IS_ACTIVE_IN_TIME
    end
    if order.spread == nil or tonumber(order.spread) == 0.0 then
        order.stopflags = order.stopflags | 0x80 -- MARKET_TAKE_PROFIT
    end
    if order.price == nil or tonumber(order.price) == 0.0 then
        order.stopflags = order.stopflags | 0x100 -- MARKET_STOP_LIMIT
    end
    return order
end

---Обычная заявка. Для открытия по рынку нужно задрать цену.
---@param order roffildcreateOrderReturn Возврат из `createOrder()`
---@param exec_cond? string "PUT_IN_QUEUE" – поставить в очередь, "FILL_OR_KILL" – немедленно или отклонить (по умолчанию), "KILL_BALANCE" – снять остаток
---@return table #Таблица отправленной транзакции
function roffild.sendOrder(order, exec_cond)
    local scale, trans, err
    scale = getSecurityInfo(order.class_code, order.sec_code).scale
    trans = {
        TRANS_ID = tostring(order.trans_id),
        CLASSCODE = tostring(order.class_code),
        SECCODE = tostring(order.sec_code),
        ACCOUNT = tostring(order.account),
        ---------------------
        ACTION = "NEW_ORDER",
        TYPE = "L",
        OPERATION = "B",
        PRICE = roffild.roundPrice(order.price, scale),
        QUANTITY = roffild.roundPrice(order.qty, 0),
        EXECUTION_CONDITION = exec_cond or "FILL_OR_KILL"
    }
    if (order.flags & 0x4) ~= 0 then
        trans.OPERATION = "S"
    end
    err = sendTransaction(trans)
    if err ~= "" then
        message("sendOrder: " .. err)
        return nil
    end
    return trans
end

---Стоп-заявка.
---@param stop_order roffildcreateOrderReturn Возврат из `createOrder()`
---@return table #Таблица отправленной транзакции
function roffild.sendStopOrder(stop_order)
    local scale, trans, err
    scale = getSecurityInfo(stop_order.class_code, stop_order.sec_code).scale
    trans = {
        TRANS_ID = tostring(stop_order.trans_id),
        CLASSCODE = tostring(stop_order.class_code),
        SECCODE = tostring(stop_order.sec_code),
        ACCOUNT = tostring(stop_order.account),
        ---------------------
        ACTION = "NEW_STOP_ORDER",
        STOP_ORDER_KIND = "TAKE_PROFIT_AND_STOP_LIMIT_ORDER",
        OPERATION = "B",
        QUANTITY = roffild.roundPrice(stop_order.qty, 0),
        STOPPRICE = roffild.roundPrice(stop_order.condition_price, scale), -- takeprofit
        OFFSET = roffild.roundPrice(stop_order.offset, scale),
        OFFSET_UNITS = "PRICE_UNITS",
        SPREAD = roffild.roundPrice(stop_order.spread, scale),
        SPREAD_UNITS = "PRICE_UNITS",
        MARKET_TAKE_PROFIT = "NO",
        STOPPRICE2 = roffild.roundPrice(stop_order.condition_price2, scale), -- stoplimit
        PRICE = roffild.roundPrice(stop_order.price, scale), -- stopprice
        MARKET_STOP_LIMIT = "NO",
        EXPIRY_DATE = tostring(stop_order.expiry),
        IS_ACTIVE_IN_TIME = "NO",
        ACTIVE_FROM_TIME = string.format("%.6d", tonumber(stop_order.active_from_time)),
        ACTIVE_TO_TIME = string.format("%.6d", tonumber(stop_order.active_to_time)),
    }
    if (stop_order.flags & 0x4) ~= 0 then
        trans.OPERATION = "S"
    end
    if (stop_order.stopflags & 0x8) ~= 0 then
        trans.OFFSET_UNITS = "PERCENTS"
        trans.OFFSET = tostring(stop_order.offset)
    end
    if (stop_order.stopflags & 0x10) ~= 0 then
        trans.SPREAD_UNITS = "PERCENTS"
        trans.SPREAD = tostring(stop_order.spread)
    end
    if tonumber(stop_order.expiry) <= tonumber(os.date("%Y%m%d")) then
        trans.EXPIRY_DATE = "TODAY"
    end
    if (stop_order.stopflags & 0x40) ~= 0 or tonumber(stop_order.active_from_time) > 0.0 then
        trans.IS_ACTIVE_IN_TIME = "YES"
        if tonumber(stop_order.active_to_time) == 0 then
            trans.ACTIVE_TO_TIME = "235959"
        end
    end
    if (stop_order.stopflags & 0x80) ~= 0 or tonumber(stop_order.spread) == 0.0 then
        trans.MARKET_TAKE_PROFIT = "YES"
    end
    if (stop_order.stopflags & 0x100) ~= 0 or tonumber(stop_order.price) == 0.0 then
        trans.MARKET_STOP_LIMIT = "YES"
    end
    err = sendTransaction(trans)
    if err ~= "" then
        message("sendStopOrder: " .. err)
        return nil
    end
    return trans
end

---Снятие обычной заявки.
---@param order roffildgetOrdersReturn Обычная заявка из `getOrders()`
---@return table #Таблица отправленной транзакции
function roffild.sendCancel(order)
    local trans, err
    trans = {
        TRANS_ID = tostring(order.trans_id),
        CLASSCODE = tostring(order.class_code),
        SECCODE = tostring(order.sec_code),
        ACCOUNT = tostring(order.account),
        ---------------------
        ACTION = "KILL_ORDER",
        ORDER_KEY = tostring(order.order_num)
    }
    err = sendTransaction(trans)
    if err ~= "" then
        message("sendCancel: " .. err)
        return nil
    end
    return trans
end

---Снятие стоп-заявки.
---@param stop_order roffildgetOrdersReturnStop Стоп-заявка из `getOrders()`
---@return table #Таблица отправленной транзакции
function roffild.sendStopCancel(stop_order)
    local trans, err
    trans = {
        TRANS_ID = tostring(stop_order.trans_id),
        CLASSCODE = tostring(stop_order.class_code),
        SECCODE = tostring(stop_order.sec_code),
        ACCOUNT = tostring(stop_order.account),
        ---------------------
        ACTION = "KILL_STOP_ORDER",
        STOP_ORDER_KEY = tostring(stop_order.order_num)
    }
    err = sendTransaction(trans)
    if err ~= "" then
        message("sendStopCancel: " .. err)
        return nil
    end
    return trans
end

---@class roffildsendStatusReturn
---@field order roffildgetOrdersReturn|roffildgetOrdersReturnStop
---@field deal roffildgetDealsReturn
---@field issell boolean На продажу?
---@field status number -1=nil | 0=исполнена | 1=активна

---Получает статус транзакции из заявки и/или сделки. \
---status = -1=nil | 0=исполнена | 1=активна \
---ВАЖНА УНИКАЛЬНОСТЬ `TRANS_ID`, чтоб не получить информацию по старой заявке!
---@param trans table Возврат из функций `send*()`
---@param stops? boolean Стоп-заявка?
---@return roffildsendStatusReturn #Здесь `status`
function roffild.sendStatus(trans, stops)
    local k, v, result
    result = {
        order = nil,
        deal = nil,
        issell = false,
        status = -1
    }
    if trans == nil then
        return result
    end
    result.order = roffild.getOrders(stops, 1, true, trans.TRANS_ID, trans.SECCODE, trans.CLASSCODE, trans.ACCOUNT)
    k, v = next(result.order)
    if v then
        if stops ~= true then
            result.deal = roffild.getDeals(1, v.order_num)
        end
        result.status = v.flags & 0x1
        result.issell = (v.flags & 0x4) > 0
    elseif stops ~= true then
        result.deal = roffild.getDeals(1, nil, trans.TRANS_ID, trans.SECCODE, trans.CLASSCODE, trans.ACCOUNT)
        k, v = next(result.deal)
        if v then
            result.status = 0
            result.issell = (v.flags & 0x4) > 0
        end
    end
    return result
end

---Дамп обычную таблицу Lua в строку. Или вернет `tostring(value)`.
---@param value any
---@param depth? number Максимальная глубина таблиц (по умолчанию = 1)
---@return string
function roffild.dumpToString(value, depth)
    if type(value) ~= "table" then
        return tostring(value)
    end
    if depth == nil then
        depth = 1
    elseif depth < 0 then
        return "{...}"
    end
    local result = "{"
    for k, v in pairs(value) do
        result = result .. tostring(k) .. "=" .. roffild.dumpToString(v, depth-1) .. ","
    end
    result = result .. "}"
    return result
end

---Дамп таблицу QUIK в строку.
---@param table_name string Имена таблиц в справке "Таблицы, используемые в функциях getItem, getNumberOf и SearchItems"
---@param last? number Максимум последних заявок (по умолчанию = 100)
---@return string
function roffild.dumpTableToString(table_name, last)
    local i, count, result
    count = getNumberOf(table_name)
    result = ""
    if count ~= nil and count ~= 0 then
        if last == nil then
            last = 100
        end
        last = count - last
        if last < 0 then
            last = 0
        end
        for x = count-1, last, -1 do
            result = result .. tostring(x) .. "\n"
            i = getItem(table_name, x)
            if i ~= nil then
                if type(i) == "table" then
                    for key, value in pairs(i) do
                        result = result .. "\t" .. tostring(key) .. " = "
                        if type(value) == "table" then
                            result = result .. roffild.dumpToString(value) .. "\n"
                        else
                            result = result .. tostring(value) .. "\t|" .. type(value) .. "|\n"
                        end
                    end
                else
                    result = result .. "\t" .. tostring(i) .. "\t|" .. type(i) .. "|\n"
                    break
                end
            end
        end
    end
    return result
end


---Дамп таблиц QUIK в папку.
---@param path? string Путь к папке (по умолчанию = `getWorkingFolder() .. "\\DumpTables\\"`)
---@param table_names? string[] Список таблиц QUIK (по умолчанию = ВСЕ)
---@param last? number Максимум последних заявок (по умолчанию = 100)
function roffild.dumpTablesToFolder(path, table_names, last)
    local fdump
    if path == nil then
        path = getWorkingFolder() .. "\\DumpTables\\"
    end
    if table_names == nil then
        table_names = {
            "firms", "classes", "securities", "trade_accounts", "client_codes", "all_trades",
            "account_positions", "orders", "futures_client_holding", "futures_client_limits",
            "money_limits", "depo_limits", "trades", "stop_orders", "neg_deals", "neg_trades",
            "neg_deal_reports", "firm_holding", "account_balance", "ccp_holdings", "rm_holdings"
        }
    end
    os.execute("mkdir " .. path)
    for key, value in pairs(table_names) do
        fdump = io.open(path .. "\\" .. value, "w")
        fdump:write(roffild.dumpTableToString(value, last))
        fdump:close()
    end
end

--#region Indicators

---DataSource for Indicator
---@return fnCreateDataSourceReturn
function roffild.indicToDataSource()
    return {
        ["O"] = function (self, index) return O(index) end,
        ["H"] = function (self, index) return H(index) end,
        ["L"] = function (self, index) return L(index) end,
        ["C"] = function (self, index) return C(index) end,
        ["V"] = function (self, index) return V(index) end,
        ["T"] = function (self, index) return T(index) end,
        ["Size"] = function (self) return Size() end,
        ["Close"] = function (self) return true end,
        ["SetEmptyCallback"] = function (self) return true end,
        ["SetUpdateCallback"] = function (self, callback_function) return true end,
    }
end

---Возвращает цену.
---@param datasource fnCreateDataSourceReturn DataSource
---@param index number Индексы свечек начинаются с 1
---@param pricetype string Тип цены: "O", "H", "L", "C", "V", "M"(edian), "T"(ypical), "W"(eighted)
---@return number?
function roffild.indicPrice(datasource, index, pricetype)
    if pricetype == nil or #pricetype == 0 then
        return nil
    end
    local t = string.upper(string.sub(pricetype, 1, 1))
    if t == "O" then
        return datasource:O(index)
    elseif t == "H" then
        return datasource:H(index)
    elseif t == "L" then
        return datasource:L(index)
    elseif t == "C" then
        return datasource:C(index)
    elseif t == "V" then
        return datasource:V(index)
    elseif t == "M" then
        return (datasource:H(index) + datasource:L(index)) / 2.0
    elseif t == "T" then
        return (datasource:H(index) + datasource:L(index) + datasource:C(index)) / 3.0
    elseif t == "W" then
        return (datasource:H(index) + datasource:L(index) + (datasource:C(index) * 2.0)) / 4.0
    end
    return nil
end

---Moving Average
---@param datasource fnCreateDataSourceReturn DataSource
---@param period number Период
---@param shift number Сдвиг в барах
---@param pricetype string Тип цены: "O", "H", "L", "C", "V", "M"(edian), "T"(ypical), "W"(eighted)
---@return number?
function roffild.indicMovingAverage(datasource, period, shift, pricetype)
    if shift == nil then
        shift = 0
    end
    local stop = datasource:Size() - shift
    local start = stop - (period - 1)
    local result = 0.0
    local ip = roffild.indicPrice
    if start < 1 or stop < 1 then
        return nil
    end
    for x = start, stop, 1 do
        result = result + ip(datasource, x, pricetype)
    end
    return result / period
end

---Money Flow Index
---@param datasource fnCreateDataSourceReturn DataSource
---@param period number Период
---@param shift number Сдвиг в барах
---@return number?
function roffild.indicMoneyFlowIndex(datasource, period, shift)
    if shift == nil then
        shift = 0
    end
    local stop = datasource:Size() - shift
    local start = stop - period
    if start < 1 or stop < 1 then
        return nil
    end
    local pos = 0.0
    local neg = 0.0
    local last = (datasource:H(start) + datasource:L(start) + datasource:C(start)) / 3.0
    for x = start+1, stop, 1 do
        local tp = (datasource:H(x) + datasource:L(x) + datasource:C(x)) / 3.0
        if tp >= last then
            pos = pos + (tp * datasource:V(x))
        else
            neg = neg + (tp * datasource:V(x))
        end
        last = tp
    end
    if neg ~= 0.0 then
        return 100.0 - (100.0 / (1.0 + (pos / neg)))
    else
        return 100.0
    end
end

--#endregion

--#region Logger

---@class roffildLogger
---@field LOG_PATH string Абсолютный путь к лог-файлу
---@field LOG_FILE file* Открытый на добавление лог-файл
roffild.logger = {}

---Записать в лог JSON
---@param level number
---@param ... any
function roffild.logger.log(level, ...)
    local sd = os.sysdate()
    local result = ""
    local rdts = roffild.dumpToString
    local flog = roffild.logger.LOG_FILE
    local json_escape_char_map = {
        ["\\"] = "\\",
        ["/"] = "\\/",
        ["\""] = "\"",
        ["\b"] = "b",
        ["\f"] = "f",
        ["\n"] = "n",
        ["\r"] = "r",
        ["\t"] = "t",
    }
    local function json_escape_char(c)
        return "\\" .. (json_escape_char_map[c] or string.format("u%04x", c:byte()))
    end
    local dbinfo = debug.getinfo(3, "Snl")
    if dbinfo ~= nil then
        dbinfo = ',"f":"' .. (dbinfo.name or "") ..
                 '","ln":' .. tostring(dbinfo.currentline) ..
                 ',"p":"' .. dbinfo.source:gsub("\\", "\\\\") .. '"'
    else
        dbinfo = ',"f":"","ln":-1,"p":""'
    end
    for k, v in pairs({...}) do
        result = result .. rdts(v)
    end
    if flog == nil then
        roffild.logger.LOG_PATH = roffild.SCRIPT_PATH .. ".jlog"
        roffild.logger.LOG_FILE = io.open(roffild.logger.LOG_PATH, "a")
        flog = roffild.logger.LOG_FILE
    end
    flog:write('{"l":', level, ',"d":[', sd.year, ',', sd.month, ',', sd.day, ',',
        sd.hour, ',', sd.min, ',', sd.sec, ',', sd.mcs, '],"m":"',
        result:gsub('[%z\1-\31\\"]', json_escape_char), '"', dbinfo, '}\n')
    flog:flush()
end

---Trace level
---@param ... any
function roffild.logger.trace(...)
    roffild.logger.log(1, ...)
end

---Debug level
---@param ... any
function roffild.logger.debug(...)
    roffild.logger.log(2, ...)
end

---Info level
---@param ... any
function roffild.logger.info(...)
    roffild.logger.log(3, ...)
end

---Warning level
---@param ... any
function roffild.logger.warn(...)
    roffild.logger.log(4, ...)
end

---Error level
---@param ... any
function roffild.logger.error(...)
    roffild.logger.log(5, ...)
end

--#endregion

return roffild
