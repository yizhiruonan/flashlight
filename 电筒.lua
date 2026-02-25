local Script = {}
--属性定义
Script.propertys = {
循环频率 = {
	type = Mini.Number,-- 类型
	default = 0.05,-- 默认值
	displayName = "循环频率",-- 属性别名
	sort = 1, -- 属性排序
	minValue = 0.05, -- 最小值
	maxValue = 1,-- 最大值
	format = "%.2f秒",  -- 单位，可不填 %.0f 整数, %.1f 一位小数
	style = ComponentUIStyle.NumberSlider,--属性控件样式滑动条
	-- tips = "这是一个脚本组件的数值属性变量",
},
光照强度 = {
	type = Mini.Number,-- 类型
	default =10,-- 默认值
	displayName = "光照强度",-- 属性别名
	sort = 2, -- 属性排序
	minValue = 0, -- 最小值
	maxValue = 16,-- 最大值
	format = "lv%.0f",  -- 单位，可不填 %.0f 整数, %.1f 一位小数
	style = ComponentUIStyle.NumberSlider,--属性控件样式滑动条
	-- tips = "这是一个脚本组件的数值属性变量",
},

光照衰减强度 = {
	type = Mini.Number,-- 类型
	default = 50,-- 默认值
	displayName = "光照衰减",-- 属性别名
	sort = 3, -- 属性排序
	minValue = 0, -- 最小值
	maxValue = 100,-- 最大值
	format = "%.0f%",  -- 单位，可不填 %.0f 整数, %.1f 一位小数
	style = ComponentUIStyle.NumberSlider,--属性控件样式滑动条
	-- tips = "这是一个脚本组件的数值属性变量",
},

--[[每分钟消耗耐久 = {
	type = Mini.Number,-- 类型
	default = 100,-- 默认值
	displayName = "每分耗耐久",-- 属性别名
	sort = 4, -- 属性排序
	minValue = 0, -- 最小值
	-- maxValue = 1000,-- 最大值
	format = "每分钟消耗%.0f耐久度",  -- 单位，可不填 %.0f 整数, %.1f 一位小数
	style = ComponentUIStyle.NumberSlider,--属性控件样式滑动条
	-- tips = "这是一个脚本组件的数值属性变量",
},--]]
照明距离 = {
	type = Mini.Number,-- 类型
	default = 20,-- 默认值
	displayName = "照明距离",-- 属性别名
	sort = 4, -- 属性排序
	minValue = 1, -- 最小值
	maxValue = 100,-- 最大值
	format = "%.0f格",  -- 单位，可不填 %.0f 整数, %.1f 一位小数
	style = ComponentUIStyle.NumberSlider,--属性控件样式滑动条
	-- tips = "这是一个脚本组件的数值属性变量",
},


}

function Script:删除光源(uin, postab)
    if #postab == 0 then
        return
    end

    for k ,v in ipairs(postab) do
        World:SetLightByPos(v.x, v.y, v.z, 0, WorldId)
        --[[if k % 10 == 0 then
            self:ThreadWait(0.05)
        end--]]
    end
end

function Script:两点连线(postab, wz1, wz2, len)
    local kx, ky, kz = (wz2.x - wz1.x)/len, (wz2.y - wz1.y)/len, (wz2.z - wz1.z)/len
    for i = len, 0, -1 do
        table.insert(postab, {x=math.floor(wz1.x + i*kx), y=math.floor(wz1.y + i*ky), z=math.floor(wz1.z + i*kz)})
    end
end

function Script:创建光源(uin, postab, x, y, z, pitch, yaw)
    local l, 强度, 衰减 = self.照明距离, self.光照强度, self.光照衰减强度
    local cos_p, sin_p = math.cos(pitch), math.sin(pitch)
    local cos_y, sin_y = math.cos(yaw), math.sin(yaw)
    local 向量 = {
        x = -cos_p * sin_y,
        y = -sin_p,
        z = -cos_p * cos_y
    }
    local d = World:GetRayLength(x, y, z, x+向量.x*l, y+向量.y*l, z+向量.z*l, 1)
    local len = math.min(l, d or l)
    local 位置 = d and {x =x + 向量.x*len, y = y + 向量.y*len, z = z + 向量.z * len} or {x=x, y=y, z=z}
    self:两点连线(postab, {x=x, y=y, z=z}, 位置, len)

    if 衰减 > 0 then
        for i, v in ipairs(postab) do
            local posFactor = i / #postab
            local factor = 1 - (1 - posFactor) * (衰减 / 100)
            World:SetLightByPos(v.x, v.y, v.z, 强度 * factor, WorldId)
        end
    else
        for k, v in ipairs(postab) do
            World:SetLightByPos(v.x, v.y, v.z, 强度, WorldId)
        end
    end
end

function Script:动态更新光源(uin, 老postab, 新postab)
    local del = {}
    local 哈希表 = {}
    for _, v in ipairs(新postab) do
        哈希表[v.x..","..v.y..","..v.z] = true
    end
    
    for _, v in ipairs(老postab) do
        if not 哈希表[v.x..","..v.y..","..v.z] then
            table.insert(del, v)
        end
    end
    
    if #del > 0 then
        self:删除光源(uin, del)
    end
    
    self.V.uin.位置表 = 新postab
end

function Script:开启电筒(uin)
    local Cpitch, Cyaw = 0, 0
    local pitch, yaw = 0, 0
    local Cx, Cy, Cz = 0, 0, 0
    local x, y, z = 0, 0, 0
    local toolID = 0
    local postab = self.V.uin.位置表 or {}
    local T = self.循环频率

    while self.V.uin.循环开关 do
        x, y, z = Actor:GetPosition(uin)
        pitch, yaw = Actor:GetFacePitch(uin), Actor:GetFaceYaw(uin)
        toolID = Player:GetCurToolID(uin)
        if (x ~= Cx or y ~= Cy or z ~= Cz or pitch ~= Cpitch or yaw ~= Cyaw) and toolID == "r2_7610354416678439572_62704" then
            local 新postab = {}
            self:创建光源(uin, 新postab, x, y + 1.5, z, math.rad(pitch), math.rad(yaw))
            self:动态更新光源(uin, postab, 新postab)
            postab = 新postab
            Cx, Cy, Cz = x, y, z
            Cpitch, Cyaw = pitch, yaw
        elseif toolID ~= "r2_7610354416678439572_62704" then
            self:删除光源(uin, postab)
        end
        self:ThreadWait(T)
    end
    self:删除光源(uin, postab)
end


function Script:使用道具(e)
    local uin = e.eventobjid
    self.V.uin.循环开关 = not (self.V.uin.循环开关 or false)
    self.V.uin.位置表 = self.V.uin.位置表 or {}

    if self.V.uin.循环开关 then
        self:ThreadWork(function()
            self:开启电筒(uin)
        end)
        self:ThreadWork(function()
            Actor:PlaySoundEffectById(uin, 10650, 100, 1, false)
        end)
        self:ThreadWork(function()
            Player:NotifyGameInfo2Self(uin, "#G开启电筒")
        end)
    else
        self:ThreadWork(function()
            Actor:PlaySoundEffectById(uin, 10650, 100, 1, false)
        end)
        self:ThreadWork(function()
            Player:NotifyGameInfo2Self(uin, "#R关闭电筒")
        end)
    end
end

function Script:进入游戏(e)
    local uin = e.eventobjid
    self.V.uin = self.V.uin or {}
end

-- 组件启动时调用
function Script:OnStart()
    self.V = self.V or {}
    self:AddTriggerEvent(TriggerEvent.GameAnyPlayerEnterGame, self.进入游戏)
    self:AddTriggerEvent(TriggerEvent.PlayerUseItem, self.使用道具)
end

return Script
