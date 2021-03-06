-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

local utils = require( GetScriptDirectory().."/utility" )

local RadiantBots = {
    "npc_dota_hero_phantom_assassin",
    "npc_dota_hero_crystal_maiden",
    "npc_dota_hero_bloodseeker",
    "npc_dota_hero_invoker",
    "npc_dota_hero_viper"
}

local Pos_1_Pool = {
    --"npc_dota_hero_drow_ranger",
    "npc_dota_hero_phantom_assassin"
}

local Pos_2_Pool = {
    "npc_dota_hero_invoker",
    "npc_dota_hero_lina"
}

local Pos_3_Pool = {
    "npc_dota_hero_viper"
}

local Pos_5_Pool = {
    "npc_dota_hero_crystal_maiden"
}

local Pos_X_Pool = {
    "npc_dota_hero_legion_commander",
    --"npc_dota_hero_bloodseeker"
}

local BotPool = {
    Pos_1_Pool, -- hard carry
    Pos_5_Pool, -- hard support
    Pos_X_Pool, -- semi-support, roamer, jungler
    Pos_2_Pool, -- mid
    Pos_3_Pool  -- offlane
}

local chosenHeroes = {}

local function HumansReady()
    local numHumans = 0
    local numHumansReady = 0
    local IDs = GetTeamPlayers(GetTeam())
    for index, id in pairs(IDs) do
        if not IsPlayerBot(id) then
            local humanBotName = GetSelectedHeroName(id)
            numHumans = numHumans + 1

            -- check bot name to see if human made selection
            if humanBotName ~= "" then
                numHumansReady = numHumansReady + 1
            end
        end
    end

    return numHumansReady == numHumans
end

function Think()
    gs = GetGameState()
    --print( "game state: ", gs )

    if ( gs == GAME_STATE_HERO_SELECTION ) then
        a = GetGameMode()

        if ( a == GAMEMODE_AP ) then
            --print ( "All Pick" )

            if GameTime() < 45 and not HumansReady() then
                return
            end

            local IDs = GetTeamPlayers(GetTeam())
            for index, id in pairs(IDs) do
                if IsPlayerBot(id) and IsPlayerInHeroSelectionControl(id) and GetSelectedHeroName(id) == "" then
                    local sizeOfPool = #BotPool[index]
                    for j = 1, sizeOfPool do
                        randomHero = BotPool[index][RandomInt(1, sizeOfPool)]
                        if not utils.InTable(chosenHeroes, randomHero) then
                            table.insert(chosenHeroes, randomHero)
                            SelectHero(id, randomHero)
                            break
                        end
                    end
                end
            end
        end
    end
end

function UpdateLaneAssignments()
    if ( GetTeam() == TEAM_RADIANT ) then
        return {
            [1] = LANE_BOT,
            [2] = LANE_BOT,
            [3] = LANE_BOT,
            [4] = LANE_MID,
            [5] = LANE_TOP,
        }
    elseif ( GetTeam() == TEAM_DIRE ) then
        return {
            [1] = LANE_TOP,
            [2] = LANE_TOP,
            [3] = LANE_TOP,
            [4] = LANE_MID,
            [5] = LANE_BOT,
        }
    end
end
