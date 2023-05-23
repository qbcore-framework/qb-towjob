local QBCore = exports['qb-core']:GetCoreObject()
local PlayerJob = {}
local JobsDone = 0
local NpcOn = false
local CurrentLocation = {}
local CurrentBlip = nil
local LastVehicle = 0
local VehicleSpawned = false
local selectedVeh = nil
local showMarker = false
local CurrentBlip2 = nil
local CurrentTow = nil
local drawDropOff = false

-- Functions

local function getRandomVehicleLocation()
    local randomVehicle = math.random(1, #Config.Locations["towspots"])
    while (randomVehicle == LastVehicle) do
        Wait(10)
        randomVehicle = math.random(1, #Config.Locations["towspots"])
    end
    return randomVehicle
end

local function drawDropOffMarker()
    CreateThread(function()
        while drawDropOff do
            DrawMarker(2, Config.Locations["dropoff"].coords.x, Config.Locations["dropoff"].coords.y, Config.Locations["dropoff"].coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.2, 0.15, 200, 0, 0, 222, false, false, false, true, false, false, false)
            Wait(0)
        end
    end)
end

local function getVehicleInDirection(coordFrom, coordTo)
	local rayHandle = CastRayPointToPoint(coordFrom.x, coordFrom.y, coordFrom.z, coordTo.x, coordTo.y, coordTo.z, 10, PlayerPedId(), 0)
	local _, _, _, _, vehicle = GetRaycastResult(rayHandle)
	return vehicle
end

local function isTowVehicle(vehicle)
    for k in pairs(Config.Vehicles) do
        if GetEntityModel(vehicle) == joaat(k) then
            return true
        end
    end
    return false
end

-- Old Menu Code (being removed)

local function MenuGarage()
    local towMenu = {
        {
            header = Lang:t("menu.header"),
            isMenuHeader = true
        }
    }
    for k in pairs(Config.Vehicles) do
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
        header = Lang:t("menu.close_menu"),
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

local function CreateZone(type, number)
    local coords
    local heading
    local boxName
    local event
    local label
    local size

    if type == "main" then
        event = "qb-tow:client:PaySlip"
        label = Lang:t("label.payslip")
        coords = vector3(Config.Locations[type].coords.x, Config.Locations[type].coords.y, Config.Locations[type].coords.z)
        heading = Config.Locations[type].coords.h
        boxName = Config.Locations[type].label
        size = 3
    elseif type == "vehicle" then
        event = "qb-tow:client:Vehicle"
        label = Lang:t("label.vehicle")
        coords = vector3(Config.Locations[type].coords.x, Config.Locations[type].coords.y, Config.Locations[type].coords.z)
        heading = Config.Locations[type].coords.h
        boxName = Config.Locations[type].label
        size = 5
    elseif type == "towspots" then
        event = "qb-tow:client:SpawnNPCVehicle"
        label = Lang:t("label.npcz")
        coords = vector3(Config.Locations[type][number].coords.x, Config.Locations[type][number].coords.y, Config.Locations[type][number].coords.z)
        heading = Config.Locations[type][number].coords.h
        boxName = Config.Locations[type][number].name
        size = 50
    end

    if Config.UseTarget and type == "main" then
        exports['qb-target']:AddBoxZone(boxName, coords, size, size, {
            minZ = coords.z - 5.0,
            maxZ = coords.z + 5.0,
            name = boxName,
            heading = heading,
            debugPoly = false,
        }, {
            options = {
                {
                    type = "client",
                    event = event,
                    label = label,
                },
            },
            distance = 2
        })
    else
        local zone = BoxZone:Create(
            coords, size, size, {
                minZ = coords.z - 5.0,
                maxZ = coords.z + 5.0,
                name = boxName,
                debugPoly = false,
                heading = heading,
            })

        local zoneCombo = ComboZone:Create({zone}, {name = boxName, debugPoly = false})
        zoneCombo:onPlayerInOut(function(isPointInside)
            if isPointInside then
                if type == "main" then
                    TriggerEvent('qb-tow:client:PaySlip')
                elseif type == "vehicle" then
                    TriggerEvent('qb-tow:client:Vehicle')
                elseif type == "towspots" then
                    TriggerEvent('qb-tow:client:SpawnNPCVehicle')
                end
            end
        end)
        if type == "vehicle" then
            local zoneMark = BoxZone:Create(
                coords, 20, 20, {
                    minZ = coords.z - 5.0,
                    maxZ = coords.z + 5.0,
                    name = boxName,
                    debugPoly = false,
                    heading = heading,
                })

            local zoneComboV = ComboZone:Create({zoneMark}, {name = boxName, debugPoly = false})
            zoneComboV:onPlayerInOut(function(isPointInside)
                if isPointInside then
                    TriggerEvent('qb-tow:client:ShowMarker', true)
                else
                    TriggerEvent('qb-tow:client:ShowMarker', false)
                end
            end)
        elseif type == "towspots" then
            CurrentLocation.zoneCombo = zoneCombo
        end
    end
end

local function deliverVehicle(vehicle)
    DeleteVehicle(vehicle)
    RemoveBlip(CurrentBlip2)
    JobsDone = JobsDone + 1
    VehicleSpawned = false
    QBCore.Functions.Notify(Lang:t("mission.delivered_vehicle"), "success")
    QBCore.Functions.Notify(Lang:t("mission.get_new_vehicle"))

    local randomLocation = getRandomVehicleLocation()
    CurrentLocation.x = Config.Locations["towspots"][randomLocation].coords.x
    CurrentLocation.y = Config.Locations["towspots"][randomLocation].coords.y
    CurrentLocation.z = Config.Locations["towspots"][randomLocation].coords.z
    CurrentLocation.model = Config.Locations["towspots"][randomLocation].model
    CurrentLocation.id = randomLocation
    CreateZone("towspots", randomLocation)

    CurrentBlip = AddBlipForCoord(CurrentLocation.x, CurrentLocation.y, CurrentLocation.z)
    SetBlipColour(CurrentBlip, 3)
    SetBlipRoute(CurrentBlip, true)
    SetBlipRouteColour(CurrentBlip, 3)
end

local function CreateElements()
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

    CreateZone("main")
    CreateZone("vehicle")
end
-- Events

RegisterNetEvent('qb-tow:client:SpawnVehicle', function()
    local vehicleInfo = selectedVeh
    local coords = Config.Locations["vehicle"].coords
    QBCore.Functions.TriggerCallback('QBCore:Server:SpawnVehicle', function(netId)
        local veh = NetToVeh(netId)
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
    end, vehicleInfo, coords, false)
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerJob = QBCore.Functions.GetPlayerData().job

    if PlayerJob.name == "tow" then
        CreateElements()
    end
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo

    if PlayerJob.name == "tow" then
        CreateElements()
    end
end)

RegisterNetEvent('jobs:client:ToggleNpc', function()
    if QBCore.Functions.GetPlayerData().job.name == "tow" then
        if CurrentTow ~= nil then
            QBCore.Functions.Notify(Lang:t("error.finish_work"), "error")
            return
        end

        -- Check if the player is inside a vehicle named "flatbed"
        local playerPed = PlayerPedId()
        local playerVehicle = GetVehiclePedIsIn(playerPed, false)
        local playerVehicleModel = GetEntityModel(playerVehicle)
        local towableVehicles = Config.Vehicles

        local isTowable = false
        for vehicleName, _ in pairs(towableVehicles) do
            local vehicleModel = GetHashKey(vehicleName)
            if playerVehicleModel == vehicleModel then
                isTowable = true
                break
            end
        end

        if not isTowable then
            QBCore.Functions.Notify("You must be inside one of the towable vehicles to toggle the NPC.", "error")
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
            CreateZone("towspots", randomLocation)

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

            if NpcOn and CurrentLocation then
                if GetEntityModel(targetVehicle) ~= joaat(CurrentLocation.model) then
                    QBCore.Functions.Notify(Lang:t("error.vehicle_not_correct"), "error")
                    return
                end
            end
            if not IsPedInAnyVehicle(PlayerPedId()) then
                if vehicle ~= targetVehicle then
                    local towPos = GetEntityCoords(vehicle)
                    local targetPos = GetEntityCoords(targetVehicle)
                    if #(towPos - targetPos) < 11.0 then
                        QBCore.Functions.Progressbar("towing_vehicle", Lang:t("mission.towing_vehicle"), 5000, false, true, {
                            disableMovement = true,
                            disableCarMovement = true,
                            disableMouse = false,
                            disableCombat = true,
                        }, {
                            animDict = animDict,
                            anim = anim,
                            flags = 16,
                        }, {}, {}, function() -- Done
                            StopAnimTask(PlayerPedId(), animDict, anim, 1.0)
                            AttachEntityToEntity(targetVehicle, vehicle, GetEntityBoneIndexByName(vehicle, 'bodyshell'), 0.0, -1.5 + -0.85, 0.0 + 1.15, 0, 0, 0, 1, 1, 0, 1, 0, 1)
                            FreezeEntityPosition(targetVehicle, true)
                            CurrentTow = targetVehicle
                            if NpcOn then
                                RemoveBlip(CurrentBlip)
                                QBCore.Functions.Notify(Lang:t("mission.goto_depot"), "primary", 5000)
                                CurrentBlip2 = AddBlipForCoord(Config.Locations["dropoff"].coords.x, Config.Locations["dropoff"].coords.y, Config.Locations["dropoff"].coords.z)
                                SetBlipColour(CurrentBlip2, 3)
                                SetBlipRoute(CurrentBlip2, true)
                                SetBlipRouteColour(CurrentBlip2, 3)
                                drawDropOff = true
                                drawDropOffMarker()
                                local vehNetID = NetworkGetNetworkIdFromEntity(targetVehicle)
                                TriggerServerEvent('qb-tow:server:nano', vehNetID)
                                --remove zone
                                CurrentLocation.zoneCombo:destroy()
                            end
                            QBCore.Functions.Notify(Lang:t("mission.vehicle_towed"), "success")
                        end, function() -- Cancel
                            StopAnimTask(PlayerPedId(), animDict, anim, 1.0)
                            QBCore.Functions.Notify(Lang:t("error.failed"), "error")
                        end)
                    end
                end
            end
        else
            QBCore.Functions.Progressbar("untowing_vehicle", Lang:t("mission.untowing_vehicle"), 5000, false, true, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }, {
                animDict = animDict,
                anim = anim,
                flags = 16,
            }, {}, {}, function() -- Done
                StopAnimTask(PlayerPedId(), animDict, anim, 1.0)
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
                RemoveBlip(CurrentBlip2)
                CurrentTow = nil
                drawDropOff = false
                QBCore.Functions.Notify(Lang:t("mission.vehicle_takenoff"), "success")
            end, function() -- Cancel
                StopAnimTask(PlayerPedId(), animDict, anim, 1.0)
                QBCore.Functions.Notify(Lang:t("error.failed"), "error")
            end)
        end
    else
        QBCore.Functions.Notify(Lang:t("error.not_towing_vehicle"), "error")
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
        QBCore.Functions.Notify(Lang:t("error.too_far_away"), 'error')
    end
end)

RegisterNetEvent('qb-tow:client:Vehicle', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if not CurrentTow then
        if vehicle and isTowVehicle(vehicle) then
            DeleteVehicle(GetVehiclePedIsIn(PlayerPedId()))
            TriggerServerEvent('qb-tow:server:DoBail', false)
        else
            MenuGarage()
        end
    else
        QBCore.Functions.Notify(Lang:t("error.finish_work"), "error")
    end
end)

RegisterNetEvent('qb-tow:client:PaySlip', function()
    if JobsDone > 0 then
        RemoveBlip(CurrentBlip)
        TriggerServerEvent("qb-tow:server:11101110", JobsDone)
        JobsDone = 0
        NpcOn = false
    else
        QBCore.Functions.Notify(Lang:t("error.no_work_done"), "error")
    end
end)

RegisterNetEvent('qb-tow:client:SpawnNPCVehicle', function()
    if not VehicleSpawned then
        QBCore.Functions.TriggerCallback('QBCore:Server:SpawnVehicle', function(netId)
            local veh = NetToVeh(netId)
            exports['LegacyFuel']:SetFuel(veh, 0.0)
            VehicleSpawned = true
        end, CurrentLocation.model, CurrentLocation, false)
    end
end)

RegisterNetEvent('qb-tow:client:ShowMarker', function(active)
    if PlayerJob.name == "tow" then
        showMarker = active
    end
end)

-- Threads
CreateThread(function()
    while true do
        if showMarker then
            DrawMarker(2, Config.Locations["vehicle"].coords.x, Config.Locations["vehicle"].coords.y, Config.Locations["vehicle"].coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.2, 0.15, 200, 0, 0, 222, false, false, false, true, false, false, false)
            --DrawMarker(2, Config.Locations["vehicle"].coords.x, Config.Locations["vehicle"].coords.y, Config.Locations["vehicle"].coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.2, 0.15, 200, 200, 200, 222, false, false, false, true, false, false, false)
            Wait(0)
        else
            Wait(1000)
        end
    end
end)



--- Depot Systemmmmmmm

RegisterNetEvent('qb-towjob:client:Depotmenu')
AddEventHandler('qb-towjob:client:Depotmenu', function()  
    TriggerEvent('qb-menu:client:openMenu', {
        {
            header = "Depot",
            isMenuHeader = true
        },
        {
            id = 2,
            header = "Custom Invoice",
            txt = "Robbery | Kidnapping | Killing | Crime",
            params = {
                event = "qb-towjob:client:Depotwithinput",
                -- args = 8000
            }
        },
        {
            id = 3,
            header = "Depot: $8000",
            txt = "Driving Reckless | Reversing a highway | Reversing a branch road",
            params = {
                event = "qb-towjob:client:DepotVehicle",
                args = { amount = 8000, depotreason = 'Traffic violation like "driving reckless, reversing a highway or branch road"' }
            }
        },
        {
            id = 4,
            header = "Depot: $5000",
            txt = "Leave the vehicle on the street | Obstructing traffic",
            params = {
                event = "qb-towjob:client:DepotVehicle",
                args = { amount = 5000, depotreason = "Obstructing and leaving the vehicle on the street" }
            }
        },
        {
            id = 5,
            header = "Depot: $2500",
            txt = "Parking in places not designated for parking | Parking on the sidewalk | Parking in front of government places",
            params = {
                event = "qb-towjob:client:DepotVehicle",
                args = { amount = 2500, depotreason = "Parking in unallocated places" }
            }
        },
        {
            header = "Close",
            icon = "fas fa-xmark",
            txt = "",
            params = {
                event = "",
            }
        },
    })
end)

RegisterNetEvent('qb-towjob:client:DepotVehicle')
AddEventHandler('qb-towjob:client:DepotVehicle', function(args)
    local amount = args.amount
    local depotreason = args.depotreason
    local vehicle = QBCore.Functions.GetClosestVehicle()
    
    if vehicle ~= nil and vehicle ~= 0 then
        local bodyDamage = math.ceil(GetVehicleBodyHealth(vehicle))
        local engineDamage = math.ceil(GetVehicleEngineHealth(vehicle))
        local totalFuel = exports['LegacyFuel']:GetFuel(vehicle)
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        local vehpos = GetEntityCoords(vehicle)
        
        if #(pos - vehpos) < 5.0 and not IsPedInAnyVehicle(ped) then
            local plate = QBCore.Functions.GetPlate(vehicle)

            QBCore.Functions.Progressbar("untowing_vehicle", "Depoting "..plate, 7000, false, true, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }, {}, {}, {}, function() -- Done
                TriggerServerEvent('qb-garages:server:removeOutsideVehicles', plate)
                TriggerServerEvent("qb-towjob:server:Depot", plate, amount, depotreason)
                if Config.Debug then
                    print("^5Debug^7: ^2Vehicle has been depoted by menu (Not custom input) ^6Plate: "..plate..", ^2For ^6"..depotreason.." ^2Reason^7")
                end
                QBCore.Functions.DeleteVehicle(vehicle)
            end, function() -- Cancel
                QBCore.Functions.Notify(Lang:t("error.failed"), "error")
            end)
        end
    end
end)

RegisterNetEvent('qb-towjob:client:Depotwithinput', function(args)
    local vehicle = QBCore.Functions.GetClosestVehicle()
    
    if vehicle ~= nil and vehicle ~= 0 then
        local bodyDamage = math.ceil(GetVehicleBodyHealth(vehicle))
        local engineDamage = math.ceil(GetVehicleEngineHealth(vehicle))
        local totalFuel = exports['LegacyFuel']:GetFuel(vehicle)
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        local vehpos = GetEntityCoords(vehicle)
        
        if #(pos - vehpos) < 5.0 and not IsPedInAnyVehicle(ped) then
            local dialog = exports['qb-input']:ShowInput({
                header = 'Depot System',
                submitText = "Submit",
                inputs = {
                    {
                        text = 'Reason',
                        name = "resinvoice",
                        type = "text",
                        isRequired = true
                    },
                    {
                        text = 'Invoice',
                        name = "idinvoice",
                        type = "number",
                        isRequired = true
                    },
                }
            })

            if dialog ~= nil then
                local idinvoice = tonumber(dialog['idinvoice'])
                local resinvoice = dialog['resinvoice']
                
                if idinvoice > 0 then
                    local plate = QBCore.Functions.GetPlate(vehicle)

                    QBCore.Functions.Progressbar("untowing_vehicle", "Depoting "..plate, 5000, false, true, {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    }, {}, {}, {}, function() -- Done
                        TriggerServerEvent('qb-garages:server:removeOutsideVehicles', plate)
                        TriggerServerEvent("qb-towjob:server:Depot", plate, idinvoice, resinvoice)
                        Wait(500)
                        QBCore.Functions.DeleteVehicle(vehicle)
                        if Config.Debug then
                            print("^5Debug^7: ^2Vehicle has been depoted by input (custom input) ^6Plate: "..plate..", ^2For ^6"..resinvoice.." ^2Reason^7")
                        end
                    end, function() -- Cancel
                        QBCore.Functions.Notify("Depot process canceled.", "error")
                    end)
                else
                    QBCore.Functions.Notify("Please enter a valid invoice amount.", "error")
                end
            end
        end
    end
end)

CreateThread(function()
    exports['qb-target']:AddTargetBone(Config.depotbones, {
        options = {
            ["Vehicledepot"] = {
                type = "client",
                event = "qb-towjob:client:Depotmenu",
                icon = "fas fa-car-side",
                distance = 1.5,
                label = "Depot Vehicle",
                job = "tow"
            }
        }
    })
end)
