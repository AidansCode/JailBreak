function CheckEnoughPlayers()
  local countNonSpectators = team.NumPlayers(TEAM_PRISONERS) + team.NumPlayers(TEAM_GUARDS)

  if ROUND_STATE == NOT_ENOUGH_PLAYERS then

    if countNonSpectators > 1 then --We're good to go!
      ChangeRoundState(STARTING)
      return true
    else
      return false
    end

  else --ROUND_STATE ~= NOT_ENOUGH_PLAYERS

    if countNonSpectators < 2 then --No longer good to go :(
      ChangeRoundState(NOT_ENOUGH_PLAYERS)
      return false
    else
      return true
    end

  end
end

function ShouldRoundEnd()
  if ROUND_STATE ~= IN_PROGRESS then return end
  local alivePrisoners = #GetAlivePlayersOnTeam(TEAM_PRISONERS)
  local aliveGuards = #GetAlivePlayersOnTeam(TEAM_GUARDS)

  if (aliveGuards == 0 or alivePrisoners == 0) then
    --The round is over, move timer to 0 and end
    timer.Remove(ROUND_TIMER_IDENTIFIER)
    ROUND_TIME_LEFT = 0

    --Figure out who won (if anyone)
    local winner = false
    if (aliveGuards > alivePrisoners) then
      winner = TEAM_GUARDS
    elseif (alivePrisoners > aliveGuards) then
      winner = TEAM_PRISONERS
    end
    ChangeRoundState(ENDING, winner)
  end
end

function ChangeRoundState(newRoundState, winner)
  ROUND_STATE = newRoundState

  BroadcastRoundState()

  if (ROUND_STATE == ENDING) then
    hook.Call("RoundStateChange", nil, ROUND_STATE, winner)
  else
    hook.Call("RoundStateChange", nil, ROUND_STATE)
  end
end

function CheckAffectsRoundState()
  if (not CheckEnoughPlayers()) then return end

  if (ROUND_STATE == IN_PROGRESS) then
    ShouldRoundEnd()
  elseif (ROUND_STATE == NOT_ENOUGH_PLAYERS) then
    CheckEnoughPlayers()
  end
end

function DecrementRoundsLeft()
  ROUNDS_LEFT_IN_MAP = ROUNDS_LEFT_IN_MAP - 1

  local plural = 's'
  local areOrIs = 'are'
  if (ROUNDS_LEFT_IN_MAP == 1) then
    plural = ''
    areOrIs = 'is'
  end

  PrintMessage(HUD_PRINTTALK, 'There ' .. areOrIs .. ' ' .. ROUNDS_LEFT_IN_MAP .. ' round' .. plural .. ' left this map!')
end

function CheckCanRunAnotherRound()
  if (ROUNDS_LEFT_IN_MAP > 0) then
    return true
  else
    SwitchToRandomMap()
    return false
  end
end

function SwitchToRandomMap()
  local availableMaps = Helpers.GetAvailableNextMaps()
  local nextMap = ''
  if (#availableMaps > 0) then
    nextMap = Helpers.StripFileExtension(availableMaps[math.random(#availableMaps)])
  else
    nextMap = game.GetMap()
  end

  for i=1, 5 do
    PrintMessage(HUD_PRINTTALK, 'Changing level to "' .. nextMap .. '" in 5 seconds...')
  end

  timer.Simple(5, function()
    RunConsoleCommand("changelevel", nextMap)
  end )
end
