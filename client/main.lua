local QBCore = exports['qb-core']:GetCoreObject()
local PlayerJob = {}
local JobsDone = 0
local NpcOn = false
local CurrentLocation = {}
local CurrentBlip = nil
local LastVehicle = 0
local VehicleSpawned = false
local selectedVeh = nil
local ranWorkThread = false

-- Functions

local function getRandomVehicleLocation()
    local randomVehicle = math.random(1, #Config.Locations["towspots"])
    while (randomVehicle == LastVehicle) do
        Wait(10)
        randomVehicle = math.random(1, #Config.Locations["towspots"])
    end
    return randomVehicle
end

local function deliverVehicle(vehicle)
    DeleteVehicle(vehicle)
    RemoveBlip(CurrentBlip2)
    JobsDone = JobsDone + 1
    VehicleSpawned = false
    QBCore.Functions.Notify("You Have Delivered A Vehicle", "success")
    QBCore.Functions.Notify("A New Vehicle Can Be Picked Up")

    local randomLocation = getRandomVehicleLocation()
    CurrentLocation.x = Config.Locations["towspots"][randomLocation].coords.x
    CurrentLocation.y = Config.Locations["towspots"][randomLocation].coords.y
    CurrentLocation.z = Config.Locations["towspots"][randomLocation].coords.z
    CurrentLocation.model = Config.Locations["towspots"][randomLocation].model
    CurrentLocation.id = randomLocation

    CurrentBlip = AddBlipForCoord(CurrentLocation.x, CurrentLocation.y, CurrentLocation.z)
    SetBlipColour(CurrentBlip, 3)
    SetBlipRoute(CurrentBlip, true)
    SetBlipRouteColour(CurrentBlip, 3)
end

local function getVehicleInDirection(coordFrom, coordTo)
	local rayHandle = CastRayPointToPoint(coordFrom.x, coordFrom.y, coordFrom.z, coordTo.x, coordTo.y, coordTo.z, 10, PlayerPedId(), 0)
	local a, b, c, d, vehicle = GetRaycastResult(rayHandle)
	return vehicle
end

local function isTowVehicle(vehicle)
    local retval = false
    for k, v in pairs(Config.Vehicles) do
        if GetEntityModel(vehicle) == GetHashKey(k) then
            retval = true
        end
    end
    return retval
end

local function DrawText3D(x, y, z, text)
	SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x,y,z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

local function doCarDamage(currentVehicle)
	local smash = false
	local damageOutside = false
	local damageOutside2 = false
	local engine = 199.0
	local body = 149.0
	if engine < 200.0 then
		engine = 200.0
    end

    if engine  > 1000.0 then
        engine = 950.0
    end

	if body < 150.0 then
		body = 150.0
	end
	if body < 950.0 then
		smash = true
	end

	if body < 920.0 then
		damageOutside = true
	end

	if body < 920.0 then
		damageOutside2 = true
	end

    Wait(100)
    SetVehicleEngineHealth(currentVehicle, engine)
	if smash then
		SmashVehicleWindow(currentVehicle, 0)
		SmashVehicleWindow(currentVehicle, 1)
		SmashVehicleWindow(currentVehicle, 2)
		SmashVehicleWindow(currentVehicle, 3)
		SmashVehicleWindow(currentVehicle, 4)
	end
	if damageOutside then
		SetVehicleDoorBroken(currentVehicle, 1, true)
		SetVehicleDoorBroken(currentVehicle, 6, true)
		SetVehicleDoorBroken(currentVehicle, 4, true)
	end
	if damageOutside2 then
		SetVehicleTyreBurst(currentVehicle, 1, false, 990.0)
		SetVehicleTyreBurst(currentVehicle, 2, false, 990.0)
		SetVehicleTyreBurst(currentVehicle, 3, false, 990.0)
		SetVehicleTyreBurst(currentVehicle, 4, false, 990.0)
	end
	if body < 1000 then
		SetVehicleBodyHealth(currentVehicle, 985.1)
	end
end

-- Old Menu Code (being removed)

local function MenuGarage()
    local towMenu = {
        {
            header = "Available Trucks",
            isMenuHeader = true
        }
    }
    for k, v in pairs(Config.Vehicles) do
        towMenu[#towMenu+1] = {
            header = Config.Vehicles[k],
            params = {
                event = "qb-tow:client:TakeOutVehicle",
                args = {
                    vehicle = k
                }
            }
        }
    end

    towMenu[#towMenu+1] = {
        header = "⬅ Close Menu",
        txt = "",
        params = {
            event = "qb-menu:client:closeMenu"
        }

    }
    exports['qb-menu']:openMenu(towMenu)
end

local function CloseMenuFull()
    exports['qb-menu']:closeMenu()
end

-- Events

RegisterNetEvent('qb-tow:client:SpawnVehicle', function()
    local vehicleInfo = selectedVeh
    local coords = Config.Locations["vehicle"].coords
    QBCore.Functions.SpawnVehicle(vehicleInfo, function(veh)
        SetVehicleNumberPlateText(veh, "TOWR"..tostring(math.random(1000, 9999)))
        SetEntityHeading(veh, coords.w)
        exports['LegacyFuel']:SetFuel(veh, 100.0)
        SetEntityAsMissionEntity(veh, true, true)
        CloseMenuFull()
        TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
        TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
        SetVehicleEngineOn(veh, true, true)
        for i = 1, 9, 1 do
            SetVehicleExtra(veh, i, 0)
        end
    end, coords, true)
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerJob = QBCore.Functions.GetPlayerData().job

    if PlayerJob.name == "tow" then
        local TowBlip = AddBlipForCoord(Config.Locations["main"].coords.x, Config.Locations["main"].coords.y, Config.Locations["main"].coords.z)
        SetBlipSprite(TowBlip, 477)
        SetBlipDisplay(TowBlip, 4)
        SetBlipScale(TowBlip, 0.6)
        SetBlipAsShortRange(TowBlip, true)
        SetBlipColour(TowBlip, 15)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(Config.Locations["main"].label)
        EndTextCommandSetBlipName(TowBlip)

        local TowVehBlip = AddBlipForCoord(Config.Locations["vehicle"].coords.x, Config.Locations["vehicle"].coords.y, Config.Locations["vehicle"].coords.z)
        SetBlipSprite(TowVehBlip, 326)
        SetBlipDisplay(TowVehBlip, 4)
        SetBlipScale(TowVehBlip, 0.6)
        SetBlipAsShortRange(TowVehBlip, true)
        SetBlipColour(TowVehBlip, 15)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(Config.Locations["vehicle"].label)
        EndTextCommandSetBlipName(TowVehBlip)

        RunWorkThread()
    end
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo

    if PlayerJob.name == "tow" then
        local TowBlip = AddBlipForCoord(Config.Locations["main"].coords.x, Config.Locations["main"].coords.y, Config.Locations["main"].coords.z)
        SetBlipSprite(TowBlip, 477)
        SetBlipDisplay(TowBlip, 4)
        SetBlipScale(TowBlip, 0.6)
        SetBlipAsShortRange(TowBlip, true)
        SetBlipColour(TowBlip, 15)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(Config.Locations["main"].label)
        EndTextCommandSetBlipName(TowBlip)

        local TowVehBlip = AddBlipForCoord(Config.Locations["vehicle"].coords.x, Config.Locations["vehicle"].coords.y, Config.Locations["vehicle"].coords.z)
        SetBlipSprite(TowVehBlip, 326)
        SetBlipDisplay(TowVehBlip, 4)
        SetBlipScale(TowVehBlip, 0.6)
        SetBlipAsShortRange(TowVehBlip, true)
        SetBlipColour(TowVehBlip, 15)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(Config.Locations["vehicle"].label)
        EndTextCommandSetBlipName(TowVehBlip)

        RunWorkThread()
    end
end)

RegisterNetEvent('jobs:client:ToggleNpc', function()
    if QBCore.Functions.GetPlayerData().job.name == "tow" then
        if CurrentTow ~= nil then
            QBCore.Functions.Notify("First Finish Your Work", "error")
            return
        end
        NpcOn = not NpcOn
        if NpcOn then
            local randomLocation = getRandomVehicleLocation()
            CurrentLocation.x = Config.Locations["towspots"][randomLocation].coords.x
            CurrentLocation.y = Config.Locations["towspots"][randomLocation].coords.y
            CurrentLocation.z = Config.Locations["towspots"][randomLocation].coords.z
            CurrentLocation.model = Config.Locations["towspots"][randomLocation].model
            CurrentLocation.id = randomLocation

            CurrentBlip = AddBlipForCoord(CurrentLocation.x, CurrentLocation.y, CurrentLocation.z)
            SetBlipColour(CurrentBlip, 3)
            SetBlipRoute(CurrentBlip, true)
            SetBlipRouteColour(CurrentBlip, 3)
        else
            if DoesBlipExist(CurrentBlip) then
                RemoveBlip(CurrentBlip)
                CurrentLocation = {}
                CurrentBlip = nil
            end
            VehicleSpawned = false
        end
    end
end)

RegisterNetEvent('qb-tow:client:TowVehicle', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), true)
    if isTowVehicle(vehicle) then
        if CurrentTow == nil then
            local playerped = PlayerPedId()
            local coordA = GetEntityCoords(playerped, 1)
            local coordB = GetOffsetFromEntityInWorldCoords(playerped, 0.0, 5.0, 0.0)
            local targetVehicle = getVehicleInDirection(coordA, coordB)

            if NpcOn and CurrentLocation ~= nil then
                if GetEntityModel(targetVehicle) ~= GetHashKey(CurrentLocation.model) then
                    QBCore.Functions.Notify("This Is Not The Right Vehicle", "error")
                    return
                end
            end
            if not IsPedInAnyVehicle(PlayerPedId()) then
                if vehicle ~= targetVehicle then
                    NetworkRequestControlOfEntity(targetVehicle)
                    local towPos = GetEntityCoords(vehicle)
                    local targetPos = GetEntityCoords(targetVehicle)
                    if #(towPos - targetPos) < 11.0 then
                        QBCore.Functions.Progressbar("towing_vehicle", "Hoisting the Vehicle...", 5000, false, true, {
                            disableMovement = true,
                            disableCarMovement = true,
                            disableMouse = false,
                            disableCombat = true,
                        }, {
                            animDict = "mini@repair",
                            anim = "fixing_a_ped",
                            flags = 16,
                        }, {}, {}, function() -- Done
                            StopAnimTask(PlayerPedId(), "mini@repair", "fixing_a_ped", 1.0)
                            AttachEntityToEntity(targetVehicle, vehicle, GetEntityBoneIndexByName(vehicle, 'bodyshell'), 0.0, -1.5 + -0.85, 0.0 + 1.15, 0, 0, 0, 1, 1, 0, 1, 0, 1)
                            FreezeEntityPosition(targetVehicle, true)
                            CurrentTow = targetVehicle
                            if NpcOn then
                                RemoveBlip(CurrentBlip)
                                QBCore.Functions.Notify("Take The Vehicle To Hayes Depot", "success", 5000)
                                CurrentBlip2 = AddBlipForCoord(491.00, -1314.69, 29.25)
                                SetBlipColour(CurrentBlip2, 3)
                                SetBlipRoute(CurrentBlip2, true)
                                SetBlipRouteColour(CurrentBlip2, 3)
                                local chance = math.random(1,100)
                                if chance < 26 then
                                    TriggerServerEvent('qb-tow:server:nano')
                                end
                            end
                            QBCore.Functions.Notify("Vehicle Towed")
                        end, function() -- Cancel
                            StopAnimTask(PlayerPedId(), "mini@repair", "fixing_a_ped", 1.0)
                            QBCore.Functions.Notify("Failed", "error")
                        end)
                    end
                end
            end
        else
            QBCore.Functions.Progressbar("untowing_vehicle", "Remove The Vehicle", 5000, false, true, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }, {
                animDict = "mini@repair",
                anim = "fixing_a_ped",
                flags = 16,
            }, {}, {}, function() -- Done
                StopAnimTask(PlayerPedId(), "mini@repair", "fixing_a_ped", 1.0)
                FreezeEntityPosition(CurrentTow, false)
                Wait(250)
                AttachEntityToEntity(CurrentTow, vehicle, 20, -0.0, -15.0, 1.0, 0.0, 0.0, 0.0, false, false, false, false, 20, true)
                DetachEntity(CurrentTow, true, true)
                if NpcOn then
                    local targetPos = GetEntityCoords(CurrentTow)
                    if #(targetPos - vector3(Config.Locations["vehicle"].coords.x, Config.Locations["vehicle"].coords.y, Config.Locations["vehicle"].coords.z)) < 25.0 then
                        deliverVehicle(CurrentTow)
                    end
                end
                CurrentTow = nil
                QBCore.Functions.Notify("Vehicle Taken Off")
            end, function() -- Cancel
                StopAnimTask(PlayerPedId(), "mini@repair", "fixing_a_ped", 1.0)
                QBCore.Functions.Notify("Failed", "error")
            end)
        end
    else
        QBCore.Functions.Notify("You Must Have Been In A Towing Vehicle First", "error")
    end
end)

RegisterNetEvent('qb-tow:client:TakeOutVehicle', function(data)
    local coords = Config.Locations["vehicle"].coords
    coords = vector3(coords.x, coords.y, coords.z)
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    if #(pos - coords) <= 5 then
        local vehicleInfo = data.vehicle
        TriggerServerEvent('qb-tow:server:DoBail', true, vehicleInfo)
        selectedVeh = vehicleInfo
    else
        QBCore.Functions.Notify('You are too far away', 'error')
    end
end)

RegisterNetEvent('qb-tow:client:SelectVehicle', function()
    local coords = Config.Locations["vehicle"].coords
    coords = vector3(coords.x, coords.y, coords.z)
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)

    if #(pos - coords) <= 5 then
        MenuGarage()
    else
        QBCore.Functions.Notify('You are too far away', 'error')
    end
end)

-- Threads
function RunWorkThread()
    if not ranWorkThread then
        ranWorkThread = true

        CreateThread(function()
            local shownHeader = false

            while LocalPlayer.state.isLoggedIn and PlayerJob.name == "tow" do
                local sleep = 1000
                local pos = GetEntityCoords(PlayerPedId())
                local vehicleCoords = vector3(Config.Locations["vehicle"].coords.x, Config.Locations["vehicle"].coords.y, Config.Locations["vehicle"].coords.z)
                local mainCoords = vector3(Config.Locations["main"].coords.x, Config.Locations["main"].coords.y, Config.Locations["main"].coords.z)

                if #(pos - vehicleCoords) <= 5 then
                    local x = vehicleCoords.x
                    local y = vehicleCoords.y
                    local z = vehicleCoords.z

                    DrawMarker(2, x,y,z , 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.2, 0.15, 200, 200, 200, 222, false, false, false, true, false, false, false)
                    if #(pos - vehicleCoords) < 1.5 then
                        if IsPedInAnyVehicle(PlayerPedId(), false) then
                            DrawText3D(x,y,z, "~g~E~w~ - Store Vehicle")
                        else
                            if not shownHeader then
                                shownHeader = true
                                exports['qb-menu']:showHeader({
                                    {
                                        header = "Select Vehicle",
                                        params = {
                                            event = 'qb-tow:client:SelectVehicle',
                                            args = {}
                                        },
                                    }
                                })
                            end

                        end

                        if IsControlJustReleased(0, 38) then
                            if IsPedInAnyVehicle(PlayerPedId(), false) then
                                DeleteVehicle(GetVehiclePedIsIn(PlayerPedId()))
                                TriggerServerEvent('qb-tow:server:DoBail', false)
                            end
                        end
                    end
                    sleep = 5
                else
                    if shownHeader then
                        shownHeader = false
                        exports['qb-menu']:closeMenu()
                    end
                end

                if #(pos - mainCoords) < 4.5 then
                    if #(pos - mainCoords) < 1.5 then
                        local x = mainCoords.x
                        local y = mainCoords.y
                        local z = mainCoords.z

                        DrawText3D(x,y,z, "~g~E~w~ - Payslip")
                        if IsControlJustReleased(0, 38) then
                            if JobsDone > 0 then
                                RemoveBlip(CurrentBlip)
                                TriggerServerEvent("qb-tow:server:11101110", JobsDone)
                                JobsDone = 0
                                NpcOn = false
                            else
                                QBCore.Functions.Notify("You have not done any work yet.", "error")
                            end
                        end
                    elseif #(pos - mainCoords) < 2.5 then
                        local x = mainCoords.x
                        local y = mainCoords.y
                        local z = mainCoords.z
                        DrawText3D(x,y,z, "Payslip")
                    end
                    sleep = 5
                end

                if NpcOn and CurrentLocation ~= nil and next(CurrentLocation) ~= nil then
                    if #(pos - vector3(CurrentLocation.x, CurrentLocation.y, CurrentLocation.z)) < 50.0 and not VehicleSpawned then
                        VehicleSpawned = true
                        QBCore.Functions.SpawnVehicle(CurrentLocation.model, function(veh)
                            exports['LegacyFuel']:SetFuel(veh, 0.0)
                            if math.random(1,2) == 1 then
                                doCarDamage(veh)
                            end
                        end, CurrentLocation, true)
                    end
                    sleep = 5
                end

                Wait(sleep)
            end
        end)

        ranWorkThread = false
    end
end