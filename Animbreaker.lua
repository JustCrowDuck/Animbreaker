--[[
    Animbreaker for Neverlose.cc V3

    @author: InkCrow
    @discord: InkCrow#2173
    @last update: 9/26/2022
]]





_DEBUG = true


local crow = {}

crow.api = {
    create  = ui.create;
}



crow.funs = {
    gradient_text = function (r1, g1, b1, a1, r2, g2, b2, a2, text)
        local output = ''
        local len = #text-1
        local rinc = (r2 - r1) / len
        local ginc = (g2 - g1) / len
        local binc = (b2 - b1) / len
        local ainc = (a2 - a1) / len
        for i=1, len+1 do
            output = output .. ('\a%02x%02x%02x%02x%s'):format(r1, g1, b1, a1, text:sub(i, i))
            r1 = r1 + rinc
            g1 = g1 + ginc
            b1 = b1 + binc
            a1 = a1 + ainc
        end
    
        return output
    end;

    RenderStudioPoseParameter = ffi.cast("struct {char pad[8]; float m_flStart; float m_flEnd; float m_flState;}*(__thiscall*)(void*, int)", utils.opcode_scan("client.dll", "55 8B EC 8B 45 08 57 8B F9 8B 4F 04 85 C9 75 15"));


    Animbreaker = function (player_ptr, layer, start_val, end_val)
        player_ptr = ffi.cast("unsigned int", player_ptr)
        if player_ptr == 0x0 then
            return false
        end
        local studio_hdr = ffi.cast("void**", player_ptr + 0x2950)[0]
        if studio_hdr == nil then
            return false
        end
        local pose_params = crow.funs.RenderStudioPoseParameter(studio_hdr, layer)
        if pose_params == nil or pose_params == 0x0 then
            return
        end
        if crow.variables.animbreaker_cache[layer] == nil then
            crow.variables.animbreaker_cache[layer] = {}
            crow.variables.animbreaker_cache[layer].m_flStart = pose_params.m_flStart
            crow.variables.animbreaker_cache[layer].m_flEnd = pose_params.m_flEnd
            crow.variables.animbreaker_cache[layer].m_flState = pose_params.m_flState
            crow.variables.animbreaker_cache[layer].installed = false
            return true
        end
        if start_val ~= nil and not crow.variables.animbreaker_cache[layer].installed then
            pose_params.m_flStart = start_val
            pose_params.m_flEnd = end_val
            pose_params.m_flState = (pose_params.m_flStart + pose_params.m_flEnd) / 2
            crow.variables.animbreaker_cache[layer].installed = true
            return true
        end
        if crow.variables.animbreaker_cache[layer].installed then
            pose_params.m_flStart = crow.variables.animbreaker_cache[layer].m_flStart
            pose_params.m_flEnd = crow.variables.animbreaker_cache[layer].m_flEnd
            pose_params.m_flState = crow.variables.animbreaker_cache[layer].m_flState
            crow.variables.animbreaker_cache[layer].installed = false
            return true
        end
        return false
    end;
}


crow.ui = {
    Misc    = crow.api.create(crow.funs.gradient_text(50,245,215,255,75,85,240,255,"Animbreaker"))
}


crow.menu = {
    Animbreaker     = crow.ui.Misc:switch(crow.funs.gradient_text(50,245,215,255,75,85,240,255,"Animbreaker"), false);
    Leg_Fucker      = crow.ui.Misc:switch("Leg Fucker", false);
    Static_Leg      = crow.ui.Misc:switch("Static Leg in Air", false);
    Pitch0          = crow.ui.Misc:switch("0 Pitch on Land", false);
}


crow.variables = {
    Leg_Movement    = ui.find("Aimbot", "Anti Aim", "Misc", "Leg Movement");
    animbreaker_cache = {};
    pitch0_tick     = 0;
    me_index        = 0;
}



crow.callback_on_createmove = function(cmd)
    local me = entity.get_local_player()
    if not me then return end
    local on_land = me["m_vecVelocity[2]"] == 0
    crow.variables.me_index = me[0]
    
    for k, v in pairs(crow.variables.animbreaker_cache) do
        crow.funs.Animbreaker(crow.variables.me_index, k)
    end


    if crow.menu.Animbreaker:get() then
        if not on_land then crow.variables.pitch0_tick = 32 end
        
        if crow.menu.Leg_Fucker:get() then
            crow.variables.Leg_Movement:override(globals.tickcount % 3 == 0 and "Walking" or "Sliding")
            crow.funs.Animbreaker(crow.variables.me_index, 0, -180, -179)
        end

        if crow.menu.Static_Leg:get() and not on_land then
            crow.funs.Animbreaker(crow.variables.me_index, 6, 0.9, 1)
        end

        if crow.menu.Pitch0:get() and crow.variables.pitch0_tick > 0 and on_land then
            if crow.variables.pitch0_tick < 30 then crow.funs.Animbreaker(crow.variables.me_index, 12, 0.999, 1) end
            crow.variables.pitch0_tick = crow.variables.pitch0_tick - 1
        end
    end


end -- createmove end





crow.callback_on_render = function()
    local Animbreaker = crow.menu.Animbreaker:get()

    crow.menu.Leg_Fucker:set_visible(Animbreaker)
    crow.menu.Static_Leg:set_visible(Animbreaker)
    crow.menu.Pitch0:set_visible(Animbreaker)

end -- render end



local texd = crow.funs.gradient_text(50,245,215,255,75,85,240,255,'Animbreaker')
ui.sidebar(texd,'blind')


events.createmove:set(crow.callback_on_createmove)
events.render:set(crow.callback_on_render)



events.shutdown:set(function()
    for k, v in pairs(crow.variables.animbreaker_cache) do
        crow.funs.Animbreaker(crow.variables.me_index, k)
    end
    crow = nil
end)