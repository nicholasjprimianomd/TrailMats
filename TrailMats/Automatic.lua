local _, T = ...

-- Use reviewed guide counts, not a guessed probability or a user-selected batch.
-- A target ends at the next recommended recipe switch, even if it is still yellow.
function T.AutomaticTarget(profession,name,rank,cap)
    local at=rank;local count=0;local segments={}
    while at<(cap or T.levelingLimit) do
        local chosen
        for _,e in ipairs(T.levelingEdges[profession] or {}) do
            if e.recipe.name==name and e.low<=at and at<e.high then
                if not chosen or e.low>chosen.low then chosen=e end
            end
        end
        if not chosen then break end
        local stop=math.min(chosen.high,cap or T.levelingLimit)
        local crafts=math.ceil((stop-at)*chosen.crafts/(chosen.high-chosen.low))
        segments[#segments+1]={low=at,high=stop,crafts=crafts}
        count=count+crafts;at=stop
    end
    if count==0 then return nil end
    return {crafts=count,stop=at,segments=segments}
end

function T.TargetText(op)
    return "About "..op.batch.." crafts to skill "..op.stop..". Stop at that skill or when the recipe turns green. Quantities update as you gain skill."
end
