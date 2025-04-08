local KeyframePlayer = loadstring(game:HttpGet("https://raw.githubusercontent.com/xsinew/Untel-Reanimate/refs/heads/main/Animator.lua"), "Animator")()
local ReanimRemote = game:GetService("ReplicatedStorage").VRModuleR6.Remotes.Communication

local function GetJointData(Joint)
    if Joint then
        return {
            Joint = Joint,
            GoTo = Joint.C1
        }
    end
end

function getC1(weld, targetCFrame)
    local basePart = weld.Part1
    if basePart and basePart:IsA("BasePart") then
        return targetCFrame:ToObjectSpace(basePart.CFrame):Inverse()
    end
    return nil
end

local module = {}
module.__index = module

function module.GetCustomAssetFromUrl(url, filename)
    local bin = game:HttpGet(url)
    writefile(filename, bin)
    local ret = getcustomasset(filename)
    pcall(delfile, filename)
    return ret
end

function module.new(character)
    local self = setmetatable({}, module)
	self.character = character
    self.rig = KeyframePlayer.GenerateRig(self.character)
    self.reanimated = false
    self.playing = false

    function self:reanim()
        if not self.character or self.reanimated then return end
        self.reanimated = true
        task.spawn(function()
            while self.character and task.wait(0.03) do
                local jointTable = {}
                for _, obj in pairs(self.character:GetDescendants()) do
                    if obj:IsA("Motor6D") or obj:IsA("Weld") then
                        table.insert(jointTable, GetJointData(obj))
                    end
                end
    
                ReanimRemote:FireServer(jointTable)
            end
        end)
    end
    
    function self:playKeyframe(keyframe, speed)
        if not self.character then return end
        if not self.reanimated then self:reanim() end
        self.character.Humanoid.HipHeight = 0.3
        self.keyframeMap = KeyframePlayer.GenerateKeyframe(keyframe)
        self.currentAnim = KeyframePlayer.new(self.rig, self.keyframeMap)
        self.currentAnim.Looped = true
        self.currentAnim:Play(speed or 1)
        self.playing = true
        self.character.Humanoid.Died:Once(function()
            self:stopKeyframe()
        end)
        task.spawn(function()
            while self.playing and task.wait() do
                for i,v in pairs(self.character.Humanoid:GetPlayingAnimationTracks()) do
                    v:Stop()
                end
            end
        end)
    end
    
    function self:stopKeyframe()
        if self.currentAnim then
            self.character.Humanoid.HipHeight = 0
            self.currentAnim:Stop()
            task.wait(0.3)
            for i=1, 10 do
                self.currentAnim:ResetMotors()
            end
            self.currentAnim = nil
            self.playing = false
        end
    end

    return self
end

return module
