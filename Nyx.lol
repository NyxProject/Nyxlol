-- Définition d'une fonction pour bypass les hooks
loadstring([[function LPH_NO_VIRTUALIZE(f) return f end]])()

-- // Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- // Global Settings
getgenv().Rake = {
    Settings = {
        Prediction = 0.125,
        JumpOffSet = 0.04,
        ByEzTerminals = nil,
        Resolver = false,
        AimPart = "UpperTorso",
        Misc = {
            AutoReload = true,
            AutoClicker = false,
            ForceHit = true,
            Whitelist = {
                UserWhitelist = false,
                HwidWhitelist = false
            },
            AdvancedMisc = {
                Desync = false,
                AutoShoot = false,
                AutoToxic = false
            }
        },
        Premium = {
            BlackList = false
        },
        AutoKick = {
            Kick = false
        },
        Important = {
            LookAt = true
        },
        AutoAir = {
            AutoAir = false,
            Delay = 0.1
        },
        AntiGroundShots = true,
        AutoShootCooldown = 0.3
    }
}

-- // Variables
local enabled = false
local whitelist = {"", "", "", ""}
local recentlySpawned = {}
local ClosestPart, Plr

-- // Fonction pour éviter le force hit après spawn
local function isRecentlySpawned(player)
    local lastSpawn = recentlySpawned[player]
    if lastSpawn then
        return (tick() - lastSpawn) < 2
    end
    return false
end

-- // Wall Check
local function isVisible(targetPart)
    if not targetPart or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Head") then
        return false
    end

    local origin = LocalPlayer.Character.Head.Position
    local direction = (targetPart.Position - origin).Unit * (targetPart.Position - origin).Magnitude

    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character, targetPart.Parent}
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.IgnoreWater = true

    local result = Workspace:Raycast(origin, direction, params)
    return result == nil
end

-- // Suivi des spawns
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        recentlySpawned[player] = tick()
    end)
end)

for _, player in pairs(Players:GetPlayers()) do
    player.CharacterAdded:Connect(function()
        recentlySpawned[player] = tick()
    end)
end

-- // Highlight
local function highlight(plr)
    if plr and plr.Character then
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character then
                for _, obj in pairs(player.Character:GetChildren()) do
                    if obj:IsA("Highlight") then
                        obj:Destroy()
                    end
                end
            end
        end
        for _, obj in pairs(plr.Character:GetChildren()) do
            if obj:IsA("Highlight") then
                obj:Destroy()
            end
        end
        local highlight = Instance.new("Highlight")
        highlight.Parent = plr.Character
        highlight.FillColor = Color3.new(0.411765, 0.501961, 1.000000)
        highlight.OutlineColor = Color3.new(0.031373, 0.031373, 0.031373)
        highlight.FillTransparency = 0.6
        highlight.OutlineTransparency = 0
    end
end

-- // Fonction pour trouver le joueur le plus proche de la souris avec wall check
local function getplayer()
    local Radius = 500
    local MousePos = UserInputService:GetMouseLocation()
    local Target

    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character and Player.Character:FindFirstChild("Humanoid") and Player.Character.Humanoid.Health > 0 then
            local RootPart = Player.Character:FindFirstChild("HumanoidRootPart")
            if RootPart and isVisible(RootPart) then
                local Viewport, onScreen = Workspace.CurrentCamera:WorldToViewportPoint(RootPart.Position)
                if onScreen and Radius > (Vector2.new(Viewport.X, Viewport.Y) - MousePos).Magnitude then
                    Radius = (Vector2.new(Viewport.X, Viewport.Y) - MousePos).Magnitude
                    Target = Player
                end
            end
        end
    end

    return Target
end

-- // Activation par touche "C"
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.C then
        enabled = not enabled
        if enabled then
            Plr = getplayer()
            if Plr then
                ClosestPart = Plr.Character and Plr.Character:FindFirstChild(getgenv().Rake.Settings.AimPart)
                highlight(Plr)
                warn("Aimbot Activé sur " .. Plr.Name)
            else
                warn("Aucun ennemi proche trouvé.")
            end
        else
            if Plr and Plr.Character then
                for _, obj in pairs(Plr.Character:GetChildren()) do
                    if obj:IsA("Highlight") then
                        obj:Destroy()
                    end
                end
            end
            Plr, ClosestPart = nil, nil
            warn("Aimbot Désactivé")
        end
    end
end)

-- // Tir automatique avec cooldown
local lastShotTime = 0

RunService.Heartbeat:Connect(function()
    if getgenv().Rake.Settings.Misc.ForceHit and enabled then
        if ClosestPart and Plr and not isRecentlySpawned(Plr) and isVisible(ClosestPart) then
            if not Plr.Character:FindFirstChildOfClass("ForceField") then
                if tick() - lastShotTime >= getgenv().Rake.Settings.AutoShootCooldown then
                    lastShotTime = tick()

                    local CurrentPosition = LocalPlayer.Character.HumanoidRootPart.Position
                    local ShootDirection = LocalPlayer.Character.HumanoidRootPart.CFrame.LookVector
                    local ShootPosition = CurrentPosition + ShootDirection * 10
                    local Normal = ShootDirection.Unit
                    local Offset = Normal * 0.5

                    local Args = {
                        [1] = "Shoot",
                        [2] = {
                            [1] = {
                                [1] = {
                                    ["Instance"] = ClosestPart,
                                    ["Normal"] = Normal,
                                    ["Position"] = CurrentPosition
                                }
                            },
                            [2] = {
                                [1] = {
                                    ["thePart"] = ClosestPart,
                                    ["theOffset"] = CFrame.new(Offset)
                                }
                            },
                            [3] = ShootPosition,
                            [4] = CurrentPosition,
                            [5] = tick()
                        }
                    }

                    ReplicatedStorage.MainEvent:FireServer(unpack(Args))
                end
            else
                warn("[ForceHit] " .. Plr.Name .. " est sous protection (ForceField). Tir bloqué.")
            end
        end
    end
end)

-- // Hook Mouse Hit Prediction
local mt = getrawmetatable(game)
local old = mt.__index
setreadonly(mt, false)

local PredictionValue = getgenv().Rake.Settings.Prediction

mt.__index = newcclosure(function(self, key)
    if not checkcaller() and enabled and typeof(self) == "Instance" and self:IsA("Mouse") and key == "Hit" then
        if Plr and Plr.Character and Plr.Character:FindFirstChild(getgenv().Rake.Settings.AimPart) then
            local target = Plr.Character[getgenv().Rake.Settings.AimPart]
            local Position = target.Position + (Plr.Character.Head.Velocity * PredictionValue)
            return CFrame.new(Position)
        end
    end
    return old(self, key)
end)
