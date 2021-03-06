// XEH POST INIT //////////////////////////////////////////////////////////////////////////////////
/*
    - Big thanks to diwako for the help with assembling most of the more complicated code in here.
    - File that handles what happens post init.
*/
///////////////////////////////////////////////////////////////////////////////////////////////////
// EVERYONE ///////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
//DISABLE VARIOUS
enableSentences false;
enableEnvironment [false, true];
enableSaving [false,false];

//ZEUS PINGED EH
["ModuleCurator_F", "initPost", {
    params ["_module"];
    _module addEventHandler ["CuratorPinged", {
        params ["_curator", "_unit"];
        private _zeus = getAssignedCuratorUnit _curator;
        if (isNull _zeus) then {
            unassignCurator _curator;
            deleteVehicle _curator;
        } else {
            if (_zeus == player) then {
                systemChat format ["%1 just pinged", name _unit];
                format ["Ping received by %1!",name player] remoteExec ["systemChat", _unit];
            };
        };
    }];
}, false, [], true] call CBA_fnc_addClassEventHandler;

//ACRE CHANNEL LABLES
[] execVM "framework\shared\init\acreChannelLabels.sqf";



///////////////////////////////////////////////////////////////////////////////////////////////////
// SERVER /////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
if (isServer) then {
    //BROADCAST WARMUP IF ENABLED
    if (var_warmup) then {
        lmf_warmup = true;
        publicVariable "lmf_warmup";
        [] execVM "framework\server\init\resetDate.sqf";
    } else {
        lmf_warmup = false;
        publicVariable "lmf_warmup";
    };

    //CREATE VARIOUS MARKERS
    [] execVM "framework\server\init\markers.sqf";

    //CREATE CUSTOM SPECTATOR CHANNEL
    radio_channel_1 = radioChannelCreate [[1,0.6,0,1], "SPECTATOR", "%UNIT_NAME", []];
};



///////////////////////////////////////////////////////////////////////////////////////////////////
// AI /////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
//CHANCE FOR AI TO WAKE UP
["ace_unconscious", {
    params [["_unit", objNull],["_state", false]];
    if (ace_medical_enableUnconsciousnessAI == 0 || {!_state || {!(local _unit) || {isPlayer _unit}}}) exitWith {};

    [_unit] spawn {
        params [["_unit", objNull]];
        while {alive _unit && {_unit getVariable ["ACE_isUnconscious", false]}} do {
            sleep 5;
            if (12.5 > random 100) then {
                [_unit, false] call ace_medical_fnc_setUnconscious;
            };
            sleep 15;
        };
    };
}] call CBA_fnc_addEventHandler;



///////////////////////////////////////////////////////////////////////////////////////////////////
// PLAYER /////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
//MAKE SURE ITS REALLY A PLAYER
if !(hasinterface) exitWith {};
waitUntil {!isNull player};

//GROUP MARKERS
if (var_groupMarkers) then {[] execVM "framework\player\init\groupMarkers.sqf";};

//UNIT TRACKER
if (var_unitTracker) then {[] execVM "framework\player\init\unitTracker.sqf";};

//TEAM COLORS
[] execVM "framework\player\init\teamColors.sqf";

//PLAYER RATING
player addEventHandler ["HandleRating", {0}];

//EXPLOSION EFFECT
player addEventHandler ["Explosion", {
	_this spawn lmf_player_fnc_explosionEH;
}];

//HIT EFFECT
player addEventHandler ["Hit", {
	_this spawn lmf_player_fnc_hitEH;
}];

//KILLED EH
player addEventHandler ["Killed", {
	_this spawn lmf_player_fnc_killedEH;
}];

//KILLED MESSAGES
["acex_killtracker_death",{
    params ["_killerName", "_killInfo"];
    [{systemChat format ["Died: %1 %2", _this select 0, _this select 1];}, [_killerName,_killInfo], 3] call CBA_fnc_waitAndExecute;
}] call CBA_fnc_addEventHandler;

//RESPAWN EH
player addEventHandler ["Respawn", {
    _this spawn lmf_player_fnc_respawnEH;
}];

//DISABLE WAYPOINT MARKERS
if !(var_playerGear) then {
    if ((roleDescription player) find "Helicopter Pilot" >= 0 || {(roleDescription player) find "Fighter Pilot" >= 0}) then {}
    else {
        onMapSingleClick "_shift";
    };
};

//BRIEFING
[] execVM "framework\player\init\briefing.sqf";

//SET PLAYER TRAITS
player setVariable ["ACE_isEngineer", 1, true];
player setVariable ["ACE_medical_medicClass", 1, true];

//PLAYER GEAR
if (var_playerGear) then {
    [player] call lmf_player_fnc_initPlayerGear;
    player addEventHandler ["InventoryClosed", {
	    params ["_unit", "_container"];
        [_unit,""] call bis_fnc_setUnitInsignia;
	    [_unit,player_insignia] call bis_fnc_setUnitInsignia;
    }];
};

//ACRE CHANNEL PRESET
[] execVM "framework\player\init\acreChannelPreset.sqf";

//PLAYER CAMOCOEF
[{player setUnitTrait ["camouflageCoef",var_camoCoef];}, [], 5] call CBA_fnc_waitAndExecute;

//ACE ACTIONS
[] execVM "framework\player\init\aceActions.sqf";

//ARSENAL
if (var_personalArsenal) then {
    [] execVM "framework\player\init\personalArsenal.sqf";
};

//JIP
if (CBA_missionTime > 5*60) then {
    [] execVM "framework\player\init\jipTeleport.sqf";
};

//INTRO + WARMUP
[] execVM "framework\player\init\warmup.sqf";

//CHANNEL SETUP
0 enableChannel false;
1 enableChannel true;
2 enableChannel false;
3 enableChannel true;
4 enableChannel false;
5 enableChannel false;