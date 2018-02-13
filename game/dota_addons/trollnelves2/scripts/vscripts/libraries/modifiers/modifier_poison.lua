modifier_poison = class({})

function modifier_poison:OnCreated(event)
    local hero = self:GetParent()
    local value = hero.hpReg * 0.05
    self.value = value
    hero.hpRegDebuff = hero.hpRegDebuff + value
    CustomGameEventManager:Send_ServerToAllClients("custom_hp_reg", { value=(hero.hpReg-hero.hpRegDebuff),unit=hero:GetEntityIndex() })
end

function modifier_poison:OnRefresh(event)
end

function modifier_poison:OnDestroy(event)
    local hero = self:GetParent()
    local value = self.value
    hero.hpRegDebuff = hero.hpRegDebuff - value
    CustomGameEventManager:Send_ServerToAllClients("custom_hp_reg", { value=(hero.hpReg-hero.hpRegDebuff),unit=hero:GetEntityIndex() })
end

function modifier_poison:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_poison:IsHidden()
    return true
end

function modifier_poison:IsPurgable()
    return false
end

function modifier_poison:IsDebuff()
    return true
end