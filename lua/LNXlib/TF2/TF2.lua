local TF2 = {
    Helpers = require("lnxLib/TF2/Helpers"),
    Prediction = require("lnxLib/TF2/Prediction"),
    PlayerResource = require("lnxLib/TF2/PlayerResource"),

    WPlayer = require("lnxLib/TF2/Wrappers/WPlayer"),
    WEntity = require("lnxLib/TF2/Wrappers/WEntity"),
    WWeapon = require("lnxLib/TF2/Wrappers/WWeapon")
}

function TF2.Exit()
    print("TF2.Exit is a no-op (os.exit is blocked)")
end

function TF2.IsFriend(idx, inParty)
    if idx == client.GetLocalPlayerIndex() then return true end

    local playerInfo = client.GetPlayerInfo(idx)
    if steam.IsFriend(playerInfo.SteamID) then return true end
    if playerlist.GetPriority(playerInfo.UserID) < 0 then return true end

    if inParty then
        local partyMembers = party.GetMembers()
        if partyMembers then
            for _, member in ipairs(partyMembers) do
                if member == playerInfo.SteamID then return true end
            end
        end
    end

    return false
end

return TF2
