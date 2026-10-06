local _, T = ...
T.professions = {
    [165] = {name = "Leatherworking", craft = true},
    [185] = {name = "Cooking", craft = true},
    [129] = {name = "First Aid", craft = true},
    [393] = {name = "Skinning"}, [356] = {name = "Fishing"},
}
T.order = {165, 185, 129, 393, 356}
T.items = {
    [2318]="Light Leather", [2934]="Ruined Leather Scraps", [2319]="Medium Leather",
    [2589]="Linen Cloth", [2592]="Wool Cloth", [6889]="Small Egg",
    [5465]="Small Spider Leg", [6291]="Raw Brilliant Smallfish",
    [6303]="Raw Slitherskin Mackerel", [6289]="Raw Longjaw Mud Snapper",
    [6361]="Raw Rainbow Fin Albacore", [2672]="Stringy Wolf Meat",
    [769]="Chunk of Boar Meat", [2674]="Crawler Meat",
    [2320]="Coarse Thread", [2678]="Mild Spices", [159]="Refreshing Spring Water",
}
T.vendor = {[2320]=true, [2678]=true, [159]=true}
T.fish = {[6291]=true, [6303]=true, [6289]=true, [6361]=true}
T.leather = {[2318]=true, [2934]=true, [2319]=true}

-- Small factual seed, not a copied leveling guide. Live reagent quantities take
-- precedence after opening a profession. See SOURCES.md for per-family evidence.
-- stop is an intentionally conservative planning boundary, not a claimed grey skill.
T.recipes = {
    {id=2152, profession=165, name="Light Armor Kit", start=1, stop=45, mats={[2318]=1}, factor=1.35},
    {id=3756, profession=165, name="Embossed Leather Gloves", start=45, stop=75, mats={[2318]=3,[2320]=2}, factor=1.25},
    {id=8604, profession=185, name="Herb Baked Egg", start=1, stop=50, mats={[6889]=1,[2678]=1}, factor=1.25},
    {id=6412, profession=185, name="Kaldorei Spider Kabob", start=1, stop=50, mats={[5465]=1}, factor=1.25},
    {id=7751, profession=185, name="Brilliant Smallfish", start=1, stop=50, mats={[6291]=1}, factor=1.25},
    {id=7752, profession=185, name="Slitherskin Mackerel", start=1, stop=50, mats={[6303]=1}, factor=1.25},
    {id=2538, profession=185, name="Charred Wolf Meat", start=1, stop=50, mats={[2672]=1}, factor=1.25},
    {id=2540, profession=185, name="Roasted Boar Meat", start=1, stop=50, mats={[769]=1}, factor=1.25},
    {id=7753, profession=185, name="Longjaw Mud Snapper", start=50, stop=100, mats={[6289]=1}, factor=1.3},
    {id=7827, profession=185, name="Rainbow Fin Albacore", start=50, stop=100, mats={[6361]=1}, factor=1.3},
    {id=3275, profession=129, name="Linen Bandage", start=1, stop=40, mats={[2589]=1}, factor=1.35},
    {id=3276, profession=129, name="Heavy Linen Bandage", start=40, stop=80, mats={[2589]=2}, factor=1.5},
    {id=3277, profession=129, name="Wool Bandage", start=80, stop=115, mats={[2592]=1}, factor=1.5},
}

-- These are *candidates* from Classic, never asserted to be confirmed Forever
-- skin loot. No generic "every beast drops leather" rule is used.
T.skinCandidates = {
    [141]= {2032,2033,2034,2042,2043},
    [148]= {2069,2070,2071,2163,2164,2165,2237,2321,2322,2323},
}
T.zones = {
    [141] = {name="Teldrassil", map=1438,
        water="Lake Al'Ameth: smallfish / mud snapper. Coast: mackerel (reference).",
        fishing="Fish while questing; keep fish your current Cooking recipe can use."},
    [148] = {name="Darkshore", map=1439,
        water="Inland rivers: smallfish / mud snapper. Coast: mackerel / albacore.",
        fishing="Try inland water or the coast; catches vary. Use a lure if fish escape."},
}
T.mapAreas = {[1438]=141, [1439]=148}
-- Location reference only; a Forever database URL does not prove new samples.
T.water = {
    [141]={[6291]="Lake Al'Ameth",[6289]="Lake Al'Ameth",[6303]="coastal water"},
    [148]={[6291]="inland rivers",[6289]="inland rivers",[6303]="coastal water",[6361]="coastal water"},
}
T.probabilityFactor = {optimal=1, medium=1.5, easy=2.5}
