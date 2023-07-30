-------------------------------
--- Author: Rostal
-------------------------------

local tab_root = gui.add_tab("WeaponAttribute by_Rostal")
local tab_weapon_list = tab_root:add_tab(" > 修改属性的武器列表")

local mod_weapons = {}

--[[
    byte    uint8_t
	word    uint16_t
	dword   uint32_t
	qword   uint64_t
]]

local weapon_attr_list <const> = {
    { name = "weapon_hash", offset = 0x10, type = "dword", text = "武器Hash" },
    { name = "anim_reload_time", offset = 0x134, type = "float", text = "换弹动作速度" },
    { name = "vehicle_reload_time", offset = 0x130, type = "float", text = "载具内换弹时间" },
    { name = "time_between_shots", offset = 0x13c, type = "float", text = "射击间隔时间" },
    { name = "alternate_wait_time", offset = 0x150, type = "float", text = "载具武器射击间隔时间" },
    { name = "reload_time_mp", offset = 0x128, type = "float", text = "载具武器装弹时间(线上)" },
    { name = "reload_time_sp", offset = 0x12c, type = "float", text = "载具武器装弹时间(线下)" },
}



--------------------
-- Functions
--------------------

local function toast(text)
    gui.show_message("TEST", text)
end

local function get_ped_weapon_info(ped)
    if ENTITY.DOES_ENTITY_EXIST(ped) and ENTITY.IS_ENTITY_A_PED(ped) then
        local ped_ptr = memory.handle_to_ptr(ped)
        local CPedWeaponManager = ped_ptr:add(0x10B8):deref()

        local CWeaponInfo = CPedWeaponManager:add(0x20):deref()
        if CWeaponInfo:is_valid() and WEAPON.IS_PED_ARMED(ped, 4) then
            return CWeaponInfo
        end

        local CVehicleWeaponInfo = CPedWeaponManager:add(0x70):deref()
        if CVehicleWeaponInfo:is_valid() then
            return CVehicleWeaponInfo
        end
    end
    return 0
end

local function get_weapon_info_data(CWeaponInfo)
    local data = {}
    for key, item in pairs(weapon_attr_list) do
        local value = 0
        if item.type == "dword" then
            value = CWeaponInfo:add(item.offset):get_dword()
        elseif item.type == "float" then
            value = CWeaponInfo:add(item.offset):get_float()
        end
        data[item.name] = value
    end
    return data
end

local function set_weapon_info_data(CWeaponInfo, data)
    if mod_weapons[data["weapon_hash"]] == nil then
        add_sub_page_weapon(CWeaponInfo)
    end

    for key, item in pairs(weapon_attr_list) do
        local name = item.name
        if name ~= "weapon_hash" and data[name] ~= nil then
            if item.type == "float" then
                CWeaponInfo:add(item.offset):set_float(data[name])
            end
        end
    end
end

local function get_weapon_hash(CWeaponInfo)
    return CWeaponInfo:add(0x10):get_dword()
end

local function generate_attr_inputs(tab_parent)
    local attr_inputs = {}
    for key, item in pairs(weapon_attr_list) do
        if item.name ~= "weapon_hash" then
            if item.type == "float" then
                attr_inputs[item.name] = tab_parent:add_input_float(item.text)
            end
        end
    end
    return attr_inputs
end

local function get_attr_inputs_value(input_tables)
    local data = {}
    for key, item in pairs(weapon_attr_list) do
        local name = item.name
        if name ~= "weapon_hash" then
            data[name] = input_tables[name]:get_value()
        end
    end
    return data
end

local function set_attr_inputs_value(input_tables, data)
    for key, item in pairs(weapon_attr_list) do
        local name = item.name
        if name ~= "weapon_hash" and data[name] ~= nil then
            input_tables[name]:set_value(data[name])
        end
    end
end



--------------------
-- Main Page
--------------------
local cur_attr_text
local cur_attr_inputs = {}

tab_root:add_button("读取当前武器属性", function()
    local CWeaponInfo = get_ped_weapon_info(PLAYER.PLAYER_PED_ID())
    if CWeaponInfo ~= 0 then
        local data = get_weapon_info_data(CWeaponInfo)
        cur_attr_text:set_text("武器Hash: " .. data["weapon_hash"])
        set_attr_inputs_value(cur_attr_inputs, data)
    end
end)

cur_attr_text = tab_root:add_text("武器Hash: 0")
cur_attr_inputs = generate_attr_inputs(tab_root)

tab_root:add_button("修改当前武器属性", function()
    local CWeaponInfo = get_ped_weapon_info(PLAYER.PLAYER_PED_ID())
    if CWeaponInfo ~= 0 then
        local data = get_attr_inputs_value(cur_attr_inputs)
        data["weapon_hash"] = get_weapon_hash(CWeaponInfo)
        set_weapon_info_data(CWeaponInfo, data)
        gui.show_message("当前武器: " .. data["weapon_hash"], "属性已修改")
    end
end)


tab_root:add_separator()
tab_root:add_text("预设")

tab_root:add_button("载具导弹 无限快速连发", function()
    local CWeaponInfo = get_ped_weapon_info(PLAYER.PLAYER_PED_ID())
    if CWeaponInfo ~= 0 then
        local data = {
            ["weapon_hash"] = get_weapon_hash(CWeaponInfo),
            ["time_between_shots"] = 0.2,
            ["alternate_wait_time"] = 0.2,
            ["reload_time_mp"] = 0,
            ["reload_time_sp"] = 0
        }
        set_weapon_info_data(CWeaponInfo, data)
        gui.show_message("武器: " .. data["weapon_hash"], "属性已修改")
    end
end)
tab_root:add_sameline()
tab_root:add_button("载具机枪 快速射击", function()
    local CWeaponInfo = get_ped_weapon_info(PLAYER.PLAYER_PED_ID())
    if CWeaponInfo ~= 0 then
        local data = {
            ["weapon_hash"] = get_weapon_hash(CWeaponInfo),
            ["time_between_shots"] = 0,
            ["alternate_wait_time"] = 0,
            ["reload_time_mp"] = 0,
            ["reload_time_sp"] = 0
        }
        set_weapon_info_data(CWeaponInfo, data)
        gui.show_message("武器: " .. data["weapon_hash"], "属性已修改")
    end
end)


tab_root:add_separator()
tab_root:add_text("特定预设")

local lazer_weapon_info = 0
-- 3800181289 VEHICLE_WEAPON_PLAYER_LAZER
tab_root:add_button("天煞九头蛇 原版机炮", function()
    if lazer_weapon_info == 0 or lazer_weapon_info:is_null() then
        local CWeaponInfo = get_ped_weapon_info(PLAYER.PLAYER_PED_ID())
        if CWeaponInfo ~= 0 then
            local weapon_hash = get_weapon_hash(CWeaponInfo)
            if weapon_hash == 3800181289 then
                lazer_weapon_info = CWeaponInfo
            else
                gui.show_message("天煞九头蛇 机炮属性修改", "要坐进飞机并将武器切换到机炮")
                return
            end
        end
    end

    lazer_weapon_info:add(0x24):set_float(0)
    lazer_weapon_info:add(0x13c):set_float(0.03999999911)
    lazer_weapon_info:add(0x150):set_float(-1)
    gui.show_message("天煞九头蛇 机炮属性修改", "机炮属性已修改为原版")
end)
tab_root:add_sameline()
tab_root:add_button("天煞九头蛇 削弱机炮", function()
    if lazer_weapon_info == 0 or lazer_weapon_info:is_null() then
        local CWeaponInfo = get_ped_weapon_info(PLAYER.PLAYER_PED_ID())
        if CWeaponInfo ~= 0 then
            local weapon_hash = get_weapon_hash(CWeaponInfo)
            if weapon_hash == 3800181289 then
                lazer_weapon_info = CWeaponInfo
            else
                gui.show_message("天煞九头蛇 机炮属性修改", "要坐进飞机并将武器切换到机炮")
                return
            end
        end
    end

    lazer_weapon_info:add(0x24):set_float(85)
    lazer_weapon_info:add(0x13c):set_float(0.125)
    lazer_weapon_info:add(0x150):set_float(0.125)
    gui.show_message("天煞九头蛇 机炮属性修改", "机炮属性已修改为削弱")
end)


tab_root:add_separator()
tab_root:add_text("使用说明")
tab_root:add_text("属性修改后一般会一直生效，即使线上线下切换\n" ..
    "需要先修改当前武器（切换到对应武器），修改后就可以在 > 修改属性的武器列表 直接修改属性，无需切换到对应武器\n" ..
    "修改载具武器属性后，其它拥有相同武器Hash的载具都会一并修改\n" ..
    "无法修改近战类武器和投掷类武器")

tab_root:add_separator()
tab_root:add_text("属性说明")
tab_root:add_text("换弹动作速度、载具内换弹时间：只对手持武器有效\n" ..
    "射击间隔时间：载具导弹射击一轮后的冷却时间\n" ..
    "载具武器射击间隔时间：载具左右两侧导弹的射击间隔时间")



--------------------
-- Sub Page
--------------------
local sub_attr_text
local sub_attr_inputs = {}
local sub_weapon_index = 1
local sub_weapon_info = 0
local sub_weapon_default_data = {}

function generate_sub_page()
    mod_weapons = {}
    sub_weapon_index = 1
    sub_attr_text = tab_weapon_list:add_text("武器Hash: 0")
    sub_attr_inputs = generate_attr_inputs(tab_weapon_list)

    tab_weapon_list:add_button("修改武器属性", function()
        if sub_weapon_info ~= 0 then
            local data = get_attr_inputs_value(sub_attr_inputs)
            data["weapon_hash"] = get_weapon_hash(sub_weapon_info)
            set_weapon_info_data(sub_weapon_info, data)
            gui.show_message("武器: " .. data["weapon_hash"], "属性已修改")
        end
    end)

    tab_weapon_list:add_separator()
    tab_weapon_list:add_button("全部恢复默认属性", function()
        for hash, item in pairs(mod_weapons) do
            set_weapon_info_data(item.weapon_info, item.default_data)
        end
        gui.show_message("全部武器恢复默认属性", "完成")
    end)
    tab_weapon_list:add_sameline()
    tab_weapon_list:add_button("[!] 清空武器列表", function()
        tab_weapon_list:clear()
        generate_sub_page()
    end)
    tab_weapon_list:add_sameline()
    tab_weapon_list:add_text("清空前恢复默认属性，否则将无法恢复")

    tab_weapon_list:add_separator()
    tab_weapon_list:add_text("武器列表")
end

function add_sub_page_weapon(CWeaponInfo)
    local default_data = get_weapon_info_data(CWeaponInfo)
    local weapon_hash = default_data["weapon_hash"]

    local button_name = sub_weapon_index .. ". " .. weapon_hash
    tab_weapon_list:add_button(button_name, function()
        local data = get_weapon_info_data(CWeaponInfo)
        sub_attr_text:set_text("武器Hash: " .. weapon_hash)
        set_attr_inputs_value(sub_attr_inputs, data)
        sub_weapon_info = CWeaponInfo
    end)
    tab_weapon_list:add_sameline()
    tab_weapon_list:add_button(sub_weapon_index .. ". 恢复默认属性", function()
        set_weapon_info_data(CWeaponInfo, default_data)
        gui.show_message("武器: " .. weapon_hash, "已恢复为默认属性")
    end)

    mod_weapons[weapon_hash] = { weapon_info = CWeaponInfo, default_data = default_data }
    sub_weapon_index = sub_weapon_index + 1
end

generate_sub_page()
