modifier_poison = class({})

if IsServer() then
    function modifier_poison:OnCreated(event)
        local hero = self:GetParent()
        local value = hero.hpReg * 0.05
        hero.hpRegDebuff = hero.hpRegDebuff + value
        Timers:CreateTimer(3,function()
            hero.hpRegDebuff = hero.hpRegDebuff - value
            CustomGameEventManager:Send_ServerToAllClients("custom_hp_reg", { value=math.max(hero.hpReg-hero.hpRegDebuff,0),unit=hero:GetEntityIndex() })
        end)
        CustomGameEventManager:Send_ServerToAllClients("custom_hp_reg", { value=math.max(hero.hpReg-hero.hpRegDebuff,0),unit=hero:GetEntityIndex() })
    end

    function modifier_poison:OnRefresh(event)
        local hero = self:GetParent()
        local value = hero.hpReg * 0.05
        hero.hpRegDebuff = hero.hpRegDebuff + value
        Timers:CreateTimer(3,function()
            hero.hpRegDebuff = hero.hpRegDebuff - value
            CustomGameEventManager:Send_ServerToAllClients("custom_hp_reg", { value=math.max(hero.hpReg-hero.hpRegDebuff,0),unit=hero:GetEntityIndex() })
        end)
        CustomGameEventManager:Send_ServerToAllClients("custom_hp_reg", { value=math.max(hero.hpReg-hero.hpRegDebuff,0),unit=hero:GetEntityIndex() })
    end

    function modifier_poison:GetAttributes()
        return {[MODIFIER_ATTRIBUTE_MULTIPLE] = true,
                [MODIFIER_ATTRIBUTE_PERMANENT] = true
                }
    end

    function modifier_poison:IsHidden()
        return false
    end

    function modifier_poison:IsPurgable()
        return false
    end

    function modifier_poison:IsDebuff()
        return true
    end
end