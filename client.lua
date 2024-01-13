local QBCore = exports['qb-core']:GetCoreObject()

local function AddInteractionForProp(propModel)
    exports['qb-target']:AddTargetModel(propModel, { -- This is really the only thing you need to modify to make it work with other frameworks (ESX, Standalone, ETC...)
        options = {
            {
                type = "client",
                event = "pickupprop:client:PickupProp",
                icon = "fas fa-hand",
                label = "Pickup",
                propModel = propModel,
            },
        },
        distance = 1.5,
    })
end

for _, prop in pairs(Config.interactableProps) do
    AddInteractionForProp(prop)
end

local holdingEntity = false
local heldEntity = nil
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if holdingEntity and heldEntity then
            local playerPed = PlayerPedId()
            local headPos = GetPedBoneCoords(playerPed, 0x796e, 0.0, 0.0, 0.0)
            DrawText3Ds(headPos.x, headPos.y, headPos.z + 0.5, "[Y] Drop Prop") -- This text only appears for the player with the picked up prop

            if not IsEntityPlayingAnim(playerPed, "anim@heists@box_carry@", "idle", 3) then
                RequestAnimDict("anim@heists@box_carry@")
                while not HasAnimDictLoaded("anim@heists@box_carry@") do
                    Citizen.Wait(100)
                end
                TaskPlayAnim(playerPed, "anim@heists@box_carry@", "idle", 8.0, -8.0, -1, 50, 0, false, false, false)
            end

            if IsControlJustReleased(0, 246) then  -- 246 is the Y key, you can find the list of all the key numbers at https://docs.fivem.net/docs/game-references/controls/
                TriggerEvent('pickupprop:client:PickupProp', {entity = heldEntity})
            end
            if not IsEntityAttached(heldEntity) then
                holdingEntity = false
                heldEntity = nil
            end
        end
    end
end)

RegisterNetEvent('pickupprop:client:PickupProp', function(data)
    local playerPed = PlayerPedId()
    local propModel = data.propModel
    local entityHit = GetClosestObjectOfType(GetEntityCoords(playerPed), propModel, 2.0)
    local entityType = GetEntityType(entityHit)
    local entityModel = GetEntityModel(entityHit)
    local coords = GetEntityCoords(entityHit)

    if not holdingEntity and entityType == 3 then
        TriggerServerEvent('pickupprop:server:DeletePropForAll', coords, propModel) -- This event is to sync the deletion of the props (check the server.lua for more info)

        local coords = GetEntityCoords(entityHit)
        local clonedEntity = CreateObject(entityModel, coords.x, coords.y, coords.z, true, true, true)
        SetModelAsNoLongerNeeded(entityModel)

        holdingEntity = true
        heldEntity = clonedEntity
        RequestAnimDict("anim@heists@box_carry@")
        
        while not HasAnimDictLoaded("anim@heists@box_carry@") do
            Citizen.Wait(100)
        end

        TaskPlayAnim(playerPed, "anim@heists@box_carry@", "idle", 8.0, -8.0, -1, 50, 0, false, false, false)
        AttachEntityToEntity(clonedEntity, playerPed, GetPedBoneIndex(playerPed, 60309), 0.0, 0.2, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
        TriggerEvent("QBCore:Notify", "Picked Up!", "success")
    elseif holdingEntity then
        holdingEntity = false
        ClearPedTasks(playerPed)
        DetachEntity(heldEntity, true, true)
        local playerCoords = GetEntityCoords(playerPed)
        SetEntityCoords(heldEntity, playerCoords.x, playerCoords.y, playerCoords.z - 1, false, false, false, false)
        SetEntityHeading(heldEntity, GetEntityHeading(playerPed))
        TriggerEvent("QBCore:Notify", "Dropped!", "success")
    end
end)


RegisterNetEvent('pickupprop:client:DeleteProp', function(coords, model)
    local object = GetClosestObjectOfType(coords, model, 1.0)
    if object then
        SetEntityAsMissionEntity(object, true, true)
        DeleteObject(object)
    end
end)


function GetClosestObjectOfType(coords, model, radius)
    local object = nil
    local closestObject = nil
    local closestDist = radius + 0.01
    local modelHash = GetHashKey(model)

    for object in EnumerateObjects() do
        if GetEntityModel(object) == modelHash then
            local objCoords = GetEntityCoords(object)
            local dist = #(coords - objCoords)
            if dist < closestDist then
                closestDist = dist
                closestObject = object
            end
        end
    end

    return closestObject
end


function EnumerateObjects()
    return coroutine.wrap(function()
        local handle, object = FindFirstObject()
        local success
        repeat
            coroutine.yield(object)
            success, object = FindNextObject(handle)
        until not success
        EndFindObject(handle)
    end)
end

function DrawText3Ds(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    local scale = (1 / GetDistanceBetweenCoords(px, py, pz, x, y, z, 1)) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov

    if onScreen then
        SetTextScale(0.0 * scale, 0.35 * scale)
        SetTextFont(0)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextDropshadow(0, 0, 0, 0, 155)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end
