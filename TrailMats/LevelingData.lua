local _, T = ...
-- Factual recipe inputs and guide estimates reviewed 2026-10-06. See SOURCES.md.
-- Bands are planning intervals, not exact learning requirements or color tables.
T.levelingRecipes={}
T.levelingEdges={[165]={},[185]={},[129]={}}
local function recipe(key,profession,name,mats,source,output)
    local r={key=key,profession=profession,name=name,mats=mats,source=source or "Trainer",output=output}
    T.levelingRecipes[key]=r
    return key
end
local function edge(p,lo,hi,crafts,key)
    local list=T.levelingEdges[p]
    list[#list+1]={low=lo,high=hi,crafts=crafts,recipe=T.levelingRecipes[key]}
end
local function lw(key,name,mats,output,source) return recipe(key,165,name,mats,source,output) end
lw("scraps","Light Leather",{[2934]=3},{2318,2})
lw("kit","Light Armor Kit",{[2318]=1})
lw("light-hide","Cured Light Hide",{[783]=1,[4289]=1},{4231,2})
lw("gloves","Embossed Leather Gloves",{[2318]=3,[2320]=2})
lw("medium","Medium Leather",{[2318]=4},{2319,2})
lw("medium-hide","Cured Medium Hide",{[4232]=1,[4289]=1},{4233,2})
lw("belt","Fine Leather Belt",{[2318]=6,[2320]=2},{4246,2})
lw("pants","Light Leather Pants",{[2318]=10,[4231]=1,[2321]=1})
lw("dark-belt","Dark Leather Belt",{[4246]=1,[4233]=1,[2321]=2,[4340]=1})
lw("heavy","Heavy Leather",{[2319]=5},{4234,2})
lw("heavy-hide","Cured Heavy Hide",{[4235]=1,[4289]=3},{4236,2})
lw("hillman","Hillman's Leather Gloves",{[2319]=14,[2321]=4})
lw("shoulders","Barbaric Shoulders",{[4234]=8,[4236]=1,[2321]=2})
lw("guardian","Guardian Gloves",{[4234]=4,[4236]=1,[4291]=1})
lw("leggings","Barbaric Leggings",{[4234]=10,[2321]=2,[1206]=1},nil,"Vendor pattern; confirm availability")
lw("harness","Barbaric Harness",{[4234]=14,[2321]=2,[7071]=1})
lw("headband","Nightscape Headband",{[4304]=5,[4291]=2})
lw("night-pants","Nightscape Pants",{[4304]=14,[4291]=4},nil,"Artisan Leatherworking trainer")
edge(165,1,30,33,"scraps");edge(165,1,30,33,"kit")
edge(165,30,55,27,"light-hide");edge(165,55,75,21,"gloves")
edge(165,75,80,8,"medium");edge(165,80,90,10,"medium-hide")
edge(165,90,100,19,"belt");edge(165,100,115,24,"pants")
edge(165,115,125,10,"dark-belt");edge(165,125,130,7,"heavy")
edge(165,130,140,20,"heavy-hide");edge(165,140,155,20,"hillman")
edge(165,130,155,30,"hillman");edge(165,155,165,10,"shoulders")
edge(165,165,175,10,"guardian");edge(165,155,170,17,"leggings")
edge(165,170,175,5,"harness");edge(165,175,195,26,"guardian")
edge(165,195,210,21,"headband");edge(165,210,225,15,"night-pants")

local function cook(key,name,mats,source,lo,hi,crafts)
    recipe(key,185,name,mats,source);edge(185,lo,hi,crafts,key)
end
cook("smallfish","Brilliant Smallfish",{[6291]=1},"Vendor recipe",1,50,55)
cook("mackerel","Slitherskin Mackerel",{[6303]=1},"Vendor recipe",1,50,55)
cook("wolf","Charred Wolf Meat",{[2672]=1},nil,1,50,55)
cook("boar","Roasted Boar Meat",{[769]=1},nil,1,50,55)
cook("egg","Herb Baked Egg",{[6889]=1,[2678]=1},nil,1,50,55)
cook("spider","Kaldorei Spider Kabob",{[5465]=1},"Alliance quest recipe",1,50,55)
T.levelingRecipes.spider.faction="Alliance"
cook("snapper","Longjaw Mud Snapper",{[6289]=1},"Vendor recipe",50,100,55)
cook("albacore","Rainbow Fin Albacore",{[6361]=1},"Vendor recipe",50,100,55)
cook("clams","Boiled Clams",{[5503]=1,[159]=1},nil,50,100,55)
cook("coyote","Coyote Steak",{[2673]=1},nil,50,100,55)
cook("catfish","Bristle Whisker Catfish",{[6308]=1},"Vendor recipe",100,130,30)
edge(185,130,150,25,"catfish")
cook("crab","Crab Cake",{[2674]=1,[2678]=1},nil,100,130,40)
cook("ribs","Dry Pork Ribs",{[2677]=1,[2678]=1},nil,100,130,35)
cook("omelet","Curiously Tasty Omelet",{[3685]=1,[2692]=1},"Vendor recipe",130,150,20)
edge(185,150,175,27,"omelet")
cook("deviled","Goblin Deviled Clams",{[5504]=1,[2692]=1},nil,130,150,25)
cook("trout","Mithril Head Trout",{[8365]=1},"Vendor recipe",175,225,54)
cook("raptor","Roast Raptor",{[12184]=1,[2692]=1},"Vendor recipe",175,225,54)

recipe("linen",129,"Linen Bandage",{[2589]=1})
recipe("heavy-linen",129,"Heavy Linen Bandage",{[2589]=2})
recipe("minor-potion",129,"Minor Healing Potion",{[2447]=1,[2678]=1,[3371]=1})
recipe("wool",129,"Wool Bandage",{[2592]=1})
recipe("heavy-wool",129,"Heavy Wool Bandage",{[2592]=2})
recipe("silk",129,"Silk Bandage",{[4306]=1})
recipe("heavy-silk",129,"Heavy Silk Bandage",{[4306]=2},"Manual: Heavy Silk Bandage")
recipe("mageweave",129,"Mageweave Bandage",{[4338]=1},"Manual: Mageweave Bandage")
edge(129,1,40,50,"linen");edge(129,40,75,40,"heavy-linen")
edge(129,1,75,81,"minor-potion")
edge(129,75,80,12,"heavy-linen");edge(129,80,115,50,"wool")
edge(129,115,150,50,"heavy-wool");edge(129,150,180,42,"silk")
edge(129,180,210,46,"heavy-silk");edge(129,210,225,17,"mageweave")
edge(129,210,225,42,"heavy-silk")

-- Ingredients needed for intermediate crafts when starting halfway through a route.
-- Live output counts override the Forever spell-page reference yield of two.
T.levelingConversions={[4231]="light-hide",[4233]="medium-hide",[4246]="belt",[4236]="heavy-hide"}
T.levelingLimit=225 -- Later beta routes are not sufficiently verified to promise a complete list.
local names={[4233]="Cured Medium Hide",[4246]="Fine Leather Belt",[4234]="Heavy Leather",
    [4235]="Heavy Hide",[4236]="Cured Heavy Hide",[4340]="Gray Dye",[4291]="Silken Thread",
    [1206]="Moss Agate",[7071]="Iron Buckle",[4304]="Thick Leather",[2447]="Peacebloom",
    [3371]="Empty Vial",[4306]="Silk Cloth",[4338]="Mageweave Cloth",[3685]="Raptor Egg",
    [2692]="Hot Spices",[5504]="Tangy Clam Meat",[8365]="Raw Mithril Head Trout",[12184]="Raptor Flesh"}
for id,name in pairs(names) do T.items[id]=name end
T.levelingSupplies={}
for id in pairs(T.vendor) do T.levelingSupplies[id]=true end
for _,id in ipairs({4340,4291,3371,2692}) do T.levelingSupplies[id]=true end
