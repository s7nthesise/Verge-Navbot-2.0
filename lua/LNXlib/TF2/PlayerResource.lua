local PlayerResource = {}

function PlayerResource.GetPing()
    return entities.GetPlayerResources():GetPropDataTableInt("m_iPing")
end

function PlayerResource.GetScore()
    return entities.GetPlayerResources():GetPropDataTableInt("m_iScore")
end

function PlayerResource.GetDeaths()
    return entities.GetPlayerResources():GetPropDataTableInt("m_iDeaths")
end

function PlayerResource.GetConnected()
    return entities.GetPlayerResources():GetPropDataTableBool("m_bConnected")
end

function PlayerResource.GetTeam()
    return entities.GetPlayerResources():GetPropDataTableInt("m_iTeam")
end

function PlayerResource.GetAlive()
    return entities.GetPlayerResources():GetPropDataTableBool("m_bAlive")
end

function PlayerResource.GetHealth()
    return entities.GetPlayerResources():GetPropDataTableInt("m_iHealth")
end

function PlayerResource.GetAccountID()
    return entities.GetPlayerResources():GetPropDataTableInt("m_iAccountID")
end

function PlayerResource.GetValid()
    return entities.GetPlayerResources():GetPropDataTableBool("m_bValid")
end

function PlayerResource.GetUserID()
    return entities.GetPlayerResources():GetPropDataTableInt("m_iUserID")
end

function PlayerResource.GetTotalScore()
    return entities.GetPlayerResources():GetPropDataTableInt("m_iTotalScore")
end

function PlayerResource.GetMaxHealth()
    return entities.GetPlayerResources():GetPropDataTableInt("m_iMaxHealth")
end

function PlayerResource.GetMaxBuffedHealth()
    return entities.GetPlayerResources():GetPropDataTableInt("m_iMaxBuffedHealth")
end

function PlayerResource.GetPlayerClass()
    return entities.GetPlayerResources():GetPropDataTableInt("m_iPlayerClass")
end

function PlayerResource.GetArenaSpectator()
    return entities.GetPlayerResources():GetPropDataTableBool("m_bArenaSpectator")
end

function PlayerResource.GetActiveDominations()
    return entities.GetPlayerResources():GetPropDataTableInt("m_iActiveDominations")
end

function PlayerResource.GetNextRespawnTime()
    return entities.GetPlayerResources():GetPropDataTableFloat("m_flNextRespawnTime")
end

function PlayerResource.GetChargeLevel()
    return entities.GetPlayerResources():GetPropDataTableInt("m_iChargeLevel")
end

function PlayerResource.GetDamage()
    return entities.GetPlayerResources():GetPropDataTableInt("m_iDamage")
end

function PlayerResource.GetDamageAssist()
    return entities.GetPlayerResources():GetPropDataTableInt("m_iDamageAssist")
end

function PlayerResource.GetDamageBoss()
    return entities.GetPlayerResources():GetPropDataTableInt("m_iDamageBoss")
end

function PlayerResource.GetHealing()
    return entities.GetPlayerResources():GetPropDataTableInt("m_iHealing")
end

function PlayerResource.GetHealingAssist()
    return entities.GetPlayerResources():GetPropDataTableInt("m_iHealingAssist")
end

function PlayerResource.GetDamageBlocked()
    return entities.GetPlayerResources():GetPropDataTableInt("m_iDamageBlocked")
end

function PlayerResource.GetCurrencyCollected()
    return entities.GetPlayerResources():GetPropDataTableInt("m_iCurrencyCollected")
end

function PlayerResource.GetBonusPoints()
    return entities.GetPlayerResources():GetPropDataTableInt("m_iBonusPoints")
end

function PlayerResource.GetPlayerLevel()
    return entities.GetPlayerResources():GetPropDataTableInt("m_iPlayerLevel")
end

function PlayerResource.GetStreaks()
    return entities.GetPlayerResources():GetPropDataTableInt("m_iStreaks")
end

function PlayerResource.GetUpgradeRefundCredits()
    return entities.GetPlayerResources():GetPropDataTableInt("m_iUpgradeRefundCredits")
end

function PlayerResource.GetBuybackCredits()
    return entities.GetPlayerResources():GetPropDataTableInt("m_iBuybackCredits")
end

function PlayerResource.GetPartyLeaderRedTeamIndex()
    return entities.GetPlayerResources():GetPropDataTableInt("m_iPartyLeaderRedTeamIndex")
end

function PlayerResource.GetPartyLeaderBlueTeamIndex()
    return entities.GetPlayerResources():GetPropDataTableInt("m_iPartyLeaderBlueTeamIndex")
end

function PlayerResource.GetEventTeamStatus()
    return entities.GetPlayerResources():GetPropDataTableInt("m_iEventTeamStatus")
end

function PlayerResource.GetPlayerClassWhenKilled()
    return entities.GetPlayerResources():GetPropDataTableInt("m_iPlayerClassWhenKilled")
end

function PlayerResource.GetConnectionState()
    return entities.GetPlayerResources():GetPropDataTableInt("m_iConnectionState")
end

function PlayerResource.GetConnectTime()
    return entities.GetPlayerResources():GetPropDataTableFloat("m_flConnectTime")
end

return PlayerResource
