RegisterNetEvent('pickupprop:server:DeletePropForAll')
AddEventHandler('pickupprop:server:DeletePropForAll', function(coords, model)
    TriggerClientEvent('pickupprop:client:DeleteProp', -1, coords, model) -- This is the deletion trigger
end)

--[[
So basically, you can't really delete a prop if it was spawned in by the map and not by a player
The deletion trigger will trigger for everyone in the server but will only really delete the prop for people that are within a 400 (in game distance units) radius
If someone leaves that radius then the prop will spawn back but this is only for map spawned props, everything else will be deleted
In larger servers, this might cause the slightest performance loss because its triggering a trigger for everyone on the server even though not everyone needs it
Sorry for the yap, I don't put much effort into free scripts but I just wanted to give a little explaination 
]]
