-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- Some Functions have been copy/pasted from bot-scripting community members 
--- Including: 
-------------------------------------------------------------------------------

local utils = require( GetScriptDirectory().."/utility" )
--enemyData = require( GetScriptDirectory().."/enemy_data" )

ACTION_NONE			= "ACTION_NONE";
ACTION_RETREAT 		= "ACTION_RETREAT";
ACTION_FIGHT		= "ACTION_FIGHT";
ACTION_CHANNELING	= "ACTION_CHANNELING";
ACTION_MOVING		= "ACTION_MOVING";

local X = { currentAction = ACTION_NONE, prevAction = ACTION_NONE }

function X:new(o, prevTime, actionQueue)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	self.prevTime = prevTime or -1000.0
	self.actionQueue = actionQueue or {}
	return o
end

function X:getCurrentAction()
	return self.currentAction
end

function X:setCurrentAction(action)
	self.currentAction = action
end

function X:getPrevAction()
	return self.prevAction
end

function X:setPrevAction(action)
	self.prevAction = action
end

function X:getPrevTime()
	return self.prevTime
end

function X:setPrevTime(value)
	self.prevTime = value
end

function X:getActionQueue()
	return self.actionQueue
end

function X:printInfo()
	print("PrevTime Value: "..self:getPrevTime());
	print("Addr actionQueue Table: ", self:getActionQueue());
end

-------------------------------------------------------------------------------
-- ACTION MANAGEMENT - YOU SHOULDN'T NEED TO TOUCH THIS
-------------------------------------------------------------------------------

function X:PrintActionTransition(name)
	self:setCurrentAction(self:GetAction());
	
	if ( self:getCurrentAction() ~= self:getPrevAction() ) then
		print("["..name.."] Action Transition: "..self:getPrevAction().." --> "..self:getCurrentAction());
		self:setPrevAction(self:getCurrentAction());
	end
end

function X:AddAction(action)
	if action == ACTION_NONE then return end;
	
	local k = self:HasAction(action);
	if k then
		table.remove(self:getActionQueue(), k);
	end
	table.insert(self:getActionQueue(), 1, action);
end

function X:HasAction(action)
    for key, value in pairs(self:getActionQueue()) do
        if value == item then return key end
    end
    return false
end

function X:RemoveAction(action)
	if action == ACTION_NONE then return end;
	
	local k = self:HasAction(action);
	if k then
		table.remove(self:getActionQueue(), k);
	end
	
	self:setCurrentAction(self:GetAction());
end

function X:GetAction()
	if #self:getActionQueue() == 0 then
		return ACTION_NONE;
	end
	return self:getActionQueue()[1];
end

--X.prevEnemyDump = -1000.0

-------------------------------------------------------------------------------
-- MAIN THINK FUNCTION - DO NOT OVER-LOAD 
-------------------------------------------------------------------------------

function X:Think(bot, abilityPriority)
	if ( GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState() ~= GAME_STATE_PRE_GAME ) then return end;
	
	--[[
		FIRST DECISIONS THAT DON'T AFFECT THE MY ACTION STATES
		:: Leveling Up Abilities, Buying Items (in most cases), Using Courier
	--]]
	-- LEVEL UP ABILITIES
	local checkLevel, newTime = utils.TimePassed(self:getPrevTime(), 1.0);
	if checkLevel then
		prevTime = newTime;
		if bot:GetAbilityPoints() > 0 then
			utils.LevelUp(bot, abilityPriority);
		end
	end

	-- DEBUG NOTIFICATION
	self:setCurrentAction(self:GetAction());
	self:PrintActionTransition(utils.GetHeroName(bot));
	
	--[[
	-- UPDATE GLOBAL INFO --
	enemyData.UpdateEnemyInfo();
	
	-- DEBUG ENEMY DUMP
	checkLevel, newTime = utils.TimePassed(self.prevEnemyDump, 5.0);
	if checkLevel then
		self.prevEnemyDump = newTime;
		enemyData.PrintEnemyInfo();
	end
	
	
		NOW DECISIONS THAT MODIFY MY ACTION STATES
	--]]
		
	--AM I ALIVE
    if( not bot:IsAlive() ) then
		--print( "You are dead, nothing to do!!!");
		X:DoWhileDead(bot);
		return;
	end
	
	--AM I CHANNELING AN ABILITY/ITEM (i.e. TP Scroll, Ultimate, etc.)
	if ( bot:IsUsingAbility() ) then
		X:DoWhileChanneling(bot);
		return;
	end
	
	-- DETERMINE MY SURROUNDING INFO --
	local RANGE = 1200
	
	--GET HEROES WITHIN XYZ UNIT RANGE
	local EnemyHeroes = bot:GetNearbyHeroes(RANGE, true, BOT_MODE_NONE);
	local AllyHeroes = bot:GetNearbyHeroes(RANGE, false, BOT_MODE_NONE);
	
	--GET TOWERS WITHIN XYZ UNIT RANGE
	local EnemyTowers = bot:GetNearbyTowers(RANGE, true);
	local AllyTowers = bot:GetNearbyTowers(RANGE, false);
	
	--GET CREEPS WITHIN XYZ UNIT RANGE
	local EnemyCreeps = bot:GetNearbyCreeps(RANGE, true);
	local AllyCreeps = bot:GetNearbyCreeps(RANGE, false);
	
	if ( not X:Determine_AmISafe(bot, EnemyHeroes, EnemyTowers, EnemyCreeps) ) then
		X:DoRetreat(bot);
		return;		
	end
	
	if ( X:Determine_AmIFighting(bot, EnemyHeroes, AllyHeroes) ) then
		X:DoFight(bot);
		return;
	end
	
	if ( X:Determine_DoAlliesNeedHelp(bot, EnemyHeroes, AllyHeroes) ) then
		X:DoDefendAlly(bot);
		return;
	end
	
	if ( X:Determine_ShouldIPushLane(bot, EnemyHeroes, EnemyTowers, EnemyCreeps, AllyCreeps) ) then
		X:DoPushLane(bot);
		return;
	end
	
	if ( X:Determine_ShouldIDefendLane(bot, EnemyHeroes, AllyHeroes, AllyTowers, EnemyCreeps, AllyCreeps) ) then
		X:DoDefendLane(bot);
		return;
	end
	
	if ( X:Determine_ShouldTeamRoshan(bot, EnemyHeroes, EnemyTowers) ) then
		X:DoRoshan(bot);
		return;
	end
	
	if ( X:Determine_ShouldGetRune(bot) ) then
		X:DoGetRune(bot);
		return;
	end
	
	if ( X:Determine_CanFarmHere(bot) ) then
		X:DoFarm(bot);
		return;
	end
	
	local loc = X:Determine_WhereToMove(bot);
	X:DoMove(bot, loc);
end

-------------------------------------------------------------------------------
-- FUNCTION DEFINITIONS - OVER-LOAD THESE IN HERO LUA IF YOU DESIRE
-------------------------------------------------------------------------------

function X:DoWhileDead(bot)
	local bb = X:ConsiderBuyback(bot);
	if (bb) then
		bot:Action_Buyback();
	end
end

function X:DoWhileChanneling(bot)
	-- TODO: Check Items like Glimmer Cape for activation if wanted
	return;
end

function X:ConsiderBuyback(bot)
	-- TODO: Write Buyback logic here
	if ( bot:HasBuyback() ) then
		return false; -- FIXME: for now always return false
	end
	return false;
end

function X:Determine_AmISafe(bot, eHeroes, eTowers, eCreeps)
	return true;
end

function X:Determine_AmIFighting(bot, EnemyHeroes, AllyHeroes)
	return false;
end

function X:Determine_DoAlliesNeedHelp(bot, EnemyHeroes, AllyHeroes)
	return false;
end

function X:Determine_ShouldIPushLane(bot, EnemyHeroes, EnemyTowers, EnemyCreeps, AllyCreeps)
	return false;
end

function X:Determine_ShouldIDefendLane(bot, EnemyHeroes, AllyHeroes, AllyTowers, EnemyCreeps, AllyCreeps)
	return false;
end

function X:Determine_ShouldTeamRoshan(bot, EnemyHeroes, EnemyTowers)
	return false;
end

function X:Determine_ShouldGetRune(bot)
	return false;
end

function X:Determine_CanFarmHere(bot)
	return false;
end

function X:Determine_WhereToMove(bot)
	local loc = GetLocationAlongLane(bot:GetAssignedLane(), 0.5);
	local dist = GetUnitToLocationDistance(bot, loc);
	--print("Distance: " .. dist);
	if ( dist <= 1.0 ) then
		self:RemoveAction(ACTION_MOVING);
		return nil;
	end
	return loc;
end

function X:DoRetreat(bot)
	return;
end

function X:DoFight(bot)
	return;
end

function X:DoDefendAlly(bot)
	return;
end

function X:DoPushLane(bot)
	return;
end

function X:DoDefendLane(bot)
	return;
end

function X:DoRoshan(bot)
	return;
end

function X:DoGetRune(bot)
	return;
end

function X:DoFarm(bot)
	return;
end

function X:DoMove(bot, loc)
	if loc then
		self:AddAction(ACTION_MOVING);
		bot:Action_AttackMove(loc); -- MoveToLocation is quantized and imprecise
	end
end

return X;