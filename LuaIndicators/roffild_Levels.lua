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

Settings = {
    Name = "Levels_Roffild",
    Step = 0,
    line = {}
}

LINES = 10

for x = 1, LINES, 1 do
    Settings.line[x] = {
        Name = "Line" .. tostring(x),
        Type = TYPE_POINT,
        Color = RGB(55, 55, 55),
        Width = 2
    }
end

local rd = require("roffild")

function Init()
    LINES = #Settings.line
    return LINES
end

function OnCalculate(index)
    local start = O(index)
    if start == nil then
        return nil
    end
    if MINSTEP == nil then
        local info = getDataSourceInfo()
        local secinfo = getSecurityInfo(info.class_code, info.sec_code)
        MINSTEP = secinfo.min_price_step
        STEP = Settings.Step
        if STEP <= 0 then
            if secinfo.base_active_seccode == "SBRF" then
                STEP = 500
            elseif secinfo.base_active_seccode == "GAZR" then
                STEP = 500
            elseif secinfo.base_active_seccode == "VTBR" then
                STEP = 50
            elseif secinfo.base_active_seccode == "Eu" then
                STEP = 250
            elseif secinfo.base_active_seccode == "ED" then
                STEP = 25
            elseif secinfo.base_active_seccode == "SILV" then
                STEP = 10
            else
                STEP = 100
            end
        end
        FIRST = (rd.round(LINES / 2) + 1) * STEP * MINSTEP
    end
    local result = {}
    start = start - ((math.tointeger(rd.round(start / MINSTEP)) % STEP) * MINSTEP) + FIRST
    for x = 1, LINES, 1 do
        table.insert(result, start - (x * STEP * MINSTEP))
    end
    return table.unpack(result)
end
