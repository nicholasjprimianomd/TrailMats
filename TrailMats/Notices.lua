local _, T = ...

-- Chat notices while leveling: each fires once per login for a given target or cap.
local noticed={train={},ready={},switched={}}
local lastTarget={}

local function sound()
    if T.settings.sound then T.Safe(PlaySound,SOUNDKIT and SOUNDKIT.READY_CHECK or 8960) end
end

function T.ReadyCrafts(op)
    local ready=op.batch
    for _,m in ipairs(op.materials) do ready=math.min(ready,math.floor(m.have/m.perCraft)) end
    return ready
end

function T.CheckNotices()
    if not T.plan or not T.settings then return end
    local s=T.settings
    for _,id in ipairs(T.order) do
        local skill=T.skills[id]
        if skill then
            local name=T.professions[id].name
            local op=T.plan.opportunities[id]
            if s.trainReminder and skill.rank>=skill.cap and skill.rank<300 and noticed.train[id]~=skill.cap then
                noticed.train[id]=skill.cap
                T.Print(name.." "..skill.rank.."/"..skill.cap..": visit a trainer for the next rank.")
            end
            -- Reaching the previous target's stopping skill means the recipe switch has arrived.
            local last=lastTarget[id]
            if s.craftNotices and last and skill.rank>=last.stop and skill.rank<skill.cap and noticed.switched[id]~=last.key then
                noticed.switched[id]=last.key
                local goal=T.FarmGoal(id)
                local nextName=op and op.name or goal and goal.recipe
                if nextName~=last.name then
                    T.Print(name.." "..skill.rank..": "..last.name.." target reached. "..
                        (nextName and ("Next: "..nextName..".") or "See Plan for the next recipe."))
                end
            end
            if op then
                local key=tostring(op.id)..":"..op.stop
                lastTarget[id]={key=key,name=op.name,stop=op.stop}
                if s.craftNotices then
                    local ready=T.ReadyCrafts(op)
                    if ready>=op.batch and noticed.ready[id]~=key then
                        noticed.ready[id]=key
                        T.Print(name..": "..op.name.." is ready to craft "..ready.." times (to skill "..op.stop..").");sound()
                    elseif ready<op.batch and noticed.ready[id]==key then noticed.ready[id]=nil end
                end
            end
        end
    end
end

function T.Welcome()
    if not T.saved or T.saved.welcomed then return end
    T.saved.welcomed=true
    T.Print("Type /tm or click the minimap button to open. /tm options opens the settings.")
end
