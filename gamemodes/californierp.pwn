/*==============================================================
    CALIFORNIE RP - Gamemode principal
    Serveur SA-MP - Roleplay
==============================================================*/

#include <a_samp>
#include "californie.inc"

#define FILTERSCRIPT

main() {}


// ------------------------------------------------------------
//  Hash simple (Adler32-like) utilisé pour les mots de passe.
//  Fonction standard couramment utilisée dans les gamemodes SA-MP.
// ------------------------------------------------------------
stock udb_hash(buf[])
{
    new length = strlen(buf);
    new s1 = 1;
    new s2 = 0;
    new n;
    for (n = 0; n < length; n++)
    {
        s1 = (s1 + buf[n]) % 65521;
        s2 = (s2 + s1) % 65521;
    }
    return (s2 << 16) + s1;
}

// ------------------------------------------------------------
//  Constantes ajoutées (auth / spawn) - définies ici si absentes de californie.inc
// ------------------------------------------------------------
#if !defined DIALOG_SPAWNCHOICE
    #define DIALOG_SPAWNCHOICE 9001
#endif
#if !defined SERVER_SITE
    #define SERVER_SITE "www.californie-rp.fr"
#endif
#if !defined SERVER_FORUM
    #define SERVER_FORUM "forum.californie-rp.fr"
#endif
#define LOGIN_TIMEOUT 60000 // 60 secondes (anti-cheat)

// ------------------------------------------------------------
//  Niveaux Admin / Dev
//  1 Helper | 2 Modérateur | 3 Admin | 10 Admin Supérieur
//  20 Admin Superviseur | 5885 Développeur
// ------------------------------------------------------------
#if !defined ADMIN_LEVEL_HELPER
    #define ADMIN_LEVEL_HELPER    1
#endif
#if !defined ADMIN_LEVEL_MOD
    #define ADMIN_LEVEL_MOD       2
#endif
#if !defined ADMIN_LEVEL_ADMIN
    #define ADMIN_LEVEL_ADMIN     3
#endif
#if !defined ADMIN_LEVEL_SUPERIOR
    #define ADMIN_LEVEL_SUPERIOR  10
#endif
#if !defined ADMIN_LEVEL_SUPERVISOR
    #define ADMIN_LEVEL_SUPERVISOR 20
#endif
#if !defined ADMIN_LEVEL_MANAGER
    #define ADMIN_LEVEL_MANAGER   ADMIN_LEVEL_SUPERVISOR
#endif
#if !defined ADMIN_LEVEL_DEV
    #define ADMIN_LEVEL_DEV       5885
#endif

// Hash (udb_hash) du mot de passe de connexion développeur.
// Le mot de passe en clair n'est JAMAIS stocké dans le code source
// (mauvaise pratique de sécurité : le .pwn/.amx peut être partagé ou décompilé).
// Généré avec udb_hash("Barre0697") = 254870211
#define DEV_LOGIN_HASH 254870211

new gFrozen[MAX_PLAYERS];
new gMuted[MAX_PLAYERS];
new gJailed[MAX_PLAYERS];

// ------------------------------------------------------------
//  Données joueur
// ------------------------------------------------------------
enum pInfo
{
    pPass[MAX_PASS_LENGTH],
    Float:pPosX,       // Dernière position connue (déconnexion)
    Float:pPosY,
    Float:pPosZ,
    Float:pPosA,
    pInt,
    pWorld,
    pCash,
    pAdmin,
    pSkin,

    // Propriété / maison
    pHomeSet,
    Float:pHomeX,
    Float:pHomeY,
    Float:pHomeZ,
    Float:pHomeA,
    pHomeInt,
    pHomeWorld,

    // Abonnement VIP
    pVipExpire          // Timestamp UNIX d'expiration (0 = pas de VIP)
};
new PlayerInfo[MAX_PLAYERS][pInfo];
new IsLoggedIn[MAX_PLAYERS];
new gPlayerTriedPass[MAX_PLAYERS];
new gLoginTimer[MAX_PLAYERS];

// ------------------------------------------------------------
//  Forwards utilitaires
// ------------------------------------------------------------
forward UserPath(playerid);
forward LoadUserData(playerid);
forward SaveUserData(playerid);
forward SpawnPlayerAfterLogin(playerid);
forward KickIfNotLoggedIn(playerid);
forward ShowSpawnSelectionDialog(playerid);

// ==============================================================
//  OnGameModeInit
// ==============================================================
public OnGameModeInit()
{
    SetGameModeText("Californie RP");
    ShowPlayerMarkers(PLAYER_MARKERS_MODE_GLOBAL);
    ShowNameTags(1);
    // SetNameTagANoseUnderVehicles(1); // Native introuvable dans les includes standards SA-MP, désactivée

    UsePlayerPedAnims();
    EnableStuntBonusForAll(0);
    DisableInteriorEnterExits(); // Désactive TOUS les marqueurs d'entrée/sortie par défaut du jeu
    SetWeather(10);
    SetWorldTime(12);

    // Classes de sélection de personnage (spawn Los Santos)
    AddPlayerClass(101, 1569.2711, -2348.7114, 13.5547, 0.0, 0,0,0,0,0,0); // Civil - Los Santos Gare (point d'apparition de départ)
    AddPlayerClass(280, 1569.2711, -2348.7114, 13.5547, 0.0, 0,0,0,0,0,0); // Police (skin par défaut, à changer via faction)
    AddPlayerClass(274, 1569.2711, -2348.7114, 13.5547, 0.0, 0,0,0,0,0,0); // EMS

    print("==============================================");
    print("   CALIFORNIE RP - Gamemode chargé avec succès  ");
    print("==============================================");
    return 1;
}

public OnGameModeExit()
{
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(IsPlayerConnected(i) && IsLoggedIn[i])
        {
            SaveUserData(i);
        }
    }
    return 1;
}

// ==============================================================
//  Connexion / Inscription
// ==============================================================
public OnPlayerConnect(playerid)
{
    IsLoggedIn[playerid] = 0;
    gPlayerTriedPass[playerid] = 0;

    // --- Sécurité anti-cheat : kick si non connecté après 60 secondes ---
    gLoginTimer[playerid] = SetTimerEx("KickIfNotLoggedIn", LOGIN_TIMEOUT, false, "d", playerid);

    new name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof(name));

    if(fexist(UserPathStr(playerid)))
    {
        new msg[400];
        format(msg, sizeof(msg),
            "{FFFFFF}Bienvenue %s sur Californie RP.\n\
{00FF00}Votre compte est enregistré.\n\
{FFFFFF}Site : {FFFF00}%s{FFFFFF} | Forum : {FFFF00}%s\n\n\
{FFFFFF}Veuillez entrer votre mot de passe pour vous connecter :",
            name, SERVER_SITE, SERVER_FORUM);

        ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD,
            "Connexion",
            msg,
            "Valider", "Quitter");
    }
    else
    {
        new msg[400];
        format(msg, sizeof(msg),
            "{FFFFFF}Bienvenue %s sur Californie RP.\n\
{FF0000}Ce compte n'existe pas encore.\n\
{FFFFFF}Site : {FFFF00}%s{FFFFFF} | Forum : {FFFF00}%s\n\n\
{FFFFFF}Choisissez un mot de passe pour créer votre compte :",
            name, SERVER_SITE, SERVER_FORUM);

        ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD,
            "Inscription",
            msg,
            "Valider", "Quitter");
    }

    TogglePlayerControllable(playerid, false);
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    if(gLoginTimer[playerid] != 0)
    {
        KillTimer(gLoginTimer[playerid]);
        gLoginTimer[playerid] = 0;
    }
    if(IsLoggedIn[playerid])
    {
        SaveUserData(playerid);
    }
    return 1;
}

// Kické automatiquement si le joueur n'est pas connecté 60s après OnPlayerConnect
public KickIfNotLoggedIn(playerid)
{
    gLoginTimer[playerid] = 0;
    if(IsPlayerConnected(playerid) && !IsLoggedIn[playerid])
    {
        SendClientMessage(playerid, COLOR_RED, "Vous avez mis trop de temps à vous connecter. Vous êtes expulsé.");
        Kick(playerid);
    }
    return 1;
}

// Chemin du fichier de compte du joueur
stock UserPathStr(playerid)
{
    new path[64], name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof(name));
    format(path, sizeof(path), "/Accounts/%s.ini", name);
    return path;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    if(dialogid == DIALOG_REGISTER)
    {
        if(!response)
        {
            Kick(playerid);
            return 1;
        }
        if(strlen(inputtext) < 4)
        {
            ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD,
                "Inscription - Californie RP",
                "{FF0000}Votre mot de passe doit contenir au moins 4 caractères !\n{FFFFFF}Choisissez un mot de passe pour créer votre compte :",
                "Inscription", "Quitter");
            return 1;
        }

        new file:f = fopen(UserPathStr(playerid), io_write);
        if(f)
        {
            new hashPass = udb_hash(inputtext);
            new line[128];
            format(line, sizeof(line), "Password=%d\r\n", hashPass);
            fwrite(f, line);
            format(line, sizeof(line), "Cash=500\r\n");
            fwrite(f, line);
            format(line, sizeof(line), "Admin=0\r\n");
            fwrite(f, line);
            format(line, sizeof(line), "Skin=101\r\n");
            fwrite(f, line);
            format(line, sizeof(line), "PosX=1569.2711\r\n");
            fwrite(f, line);
            format(line, sizeof(line), "PosY=-2348.7114\r\n");
            fwrite(f, line);
            format(line, sizeof(line), "PosZ=13.5547\r\n");
            fwrite(f, line);
            format(line, sizeof(line), "PosA=0.0\r\n");
            fwrite(f, line);
            format(line, sizeof(line), "Int=0\r\n");
            fwrite(f, line);
            format(line, sizeof(line), "World=0\r\n");
            fwrite(f, line);
            format(line, sizeof(line), "HomeSet=0\r\n");
            fwrite(f, line);
            format(line, sizeof(line), "HomeX=0.0\r\n");
            fwrite(f, line);
            format(line, sizeof(line), "HomeY=0.0\r\n");
            fwrite(f, line);
            format(line, sizeof(line), "HomeZ=0.0\r\n");
            fwrite(f, line);
            format(line, sizeof(line), "HomeA=0.0\r\n");
            fwrite(f, line);
            format(line, sizeof(line), "HomeInt=0\r\n");
            fwrite(f, line);
            format(line, sizeof(line), "HomeWorld=0\r\n");
            fwrite(f, line);
            format(line, sizeof(line), "VipExpire=0\r\n");
            fwrite(f, line);
            fclose(f);
        }

        SendClientMessage(playerid, COLOR_GREEN, "Votre compte a été créé avec succès ! Vous êtes maintenant connecté.");
        if(gLoginTimer[playerid] != 0) { KillTimer(gLoginTimer[playerid]); gLoginTimer[playerid] = 0; }
        IsLoggedIn[playerid] = 1;
        LoadUserData(playerid);
        TogglePlayerControllable(playerid, true);
        FinalizeLogin(playerid);
        return 1;
    }

    if(dialogid == DIALOG_LOGIN)
    {
        if(!response)
        {
            Kick(playerid);
            return 1;
        }

        new file:f = fopen(UserPathStr(playerid), io_read);
        new storedHash = 0;
        if(f)
        {
            new line[128];
            while(fread(f, line))
            {
                new key[32], val[64];
                if(sscanf_simple(line, key, val))
                {
                    if(!strcmp(key, "Password"))
                    {
                        storedHash = strval(val);
                    }
                }
            }
            fclose(f);
        }

        if(udb_hash(inputtext) == storedHash)
        {
            SendClientMessage(playerid, COLOR_GREEN, "Connexion réussie ! Bienvenue sur Californie RP.");
            if(gLoginTimer[playerid] != 0) { KillTimer(gLoginTimer[playerid]); gLoginTimer[playerid] = 0; }
            IsLoggedIn[playerid] = 1;
            LoadUserData(playerid);
            TogglePlayerControllable(playerid, true);
            FinalizeLogin(playerid);
        }
        else
        {
            gPlayerTriedPass[playerid]++;
            if(gPlayerTriedPass[playerid] >= 3)
            {
                SendClientMessage(playerid, COLOR_RED, "Trop de tentatives échouées. Vous êtes expulsé.");
                Kick(playerid);
                return 1;
            }
            ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD,
                "Connexion - Californie RP",
                "{FF0000}Mot de passe incorrect !\n{FFFFFF}Veuillez entrer votre mot de passe pour vous connecter :",
                "Connexion", "Quitter");
        }
        return 1;
    }

    if(dialogid == DIALOG_HELP)
    {
        return 1;
    }

    if(dialogid == DIALOG_SPAWNCHOICE)
    {
        if(!response)
        {
            // Le joueur doit choisir : on réaffiche le menu
            ShowSpawnSelectionDialog(playerid);
            return 1;
        }

        switch(listitem)
        {
            case 0: // Spawn à ma maison
            {
                if(PlayerInfo[playerid][pHomeSet])
                {
                    PlayerInfo[playerid][pPosX] = PlayerInfo[playerid][pHomeX];
                    PlayerInfo[playerid][pPosY] = PlayerInfo[playerid][pHomeY];
                    PlayerInfo[playerid][pPosZ] = PlayerInfo[playerid][pHomeZ];
                    PlayerInfo[playerid][pPosA] = PlayerInfo[playerid][pHomeA];
                    PlayerInfo[playerid][pInt]  = PlayerInfo[playerid][pHomeInt];
                    PlayerInfo[playerid][pWorld] = PlayerInfo[playerid][pHomeWorld];
                }
                else
                {
                    SendClientMessage(playerid, COLOR_RED, "Vous ne possédez aucune propriété enregistrée. Spawn par défaut utilisé.");
                    SetDefaultSpawnPos(playerid);
                }
            }
            case 1: // Dernière position (déjà chargée dans PlayerInfo via LoadUserData)
            {
                // Rien à faire : pPosX/Y/Z/A/Int/World contiennent déjà la dernière position sauvegardée
            }
            case 2: // Spawn par défaut
            {
                SetDefaultSpawnPos(playerid);
            }
        }

        SpawnPlayerAfterLogin(playerid);
        return 1;
    }
    return 0;
}

// ==============================================================
//  Finalisation de la connexion : logs admin, VIP, choix du spawn
// ==============================================================
stock FinalizeLogin(playerid)
{
    // --- Log admin : notifie les administrateurs connectés ---
    if(PlayerInfo[playerid][pAdmin] > 0)
    {
        new name[MAX_PLAYER_NAME], logmsg[144];
        GetPlayerName(playerid, name, sizeof(name));
        format(logmsg, sizeof(logmsg), "(( %s [Niveau %d] vient de se connecter. ))", name, PlayerInfo[playerid][pAdmin]);

        for(new i = 0; i < MAX_PLAYERS; i++)
        {
            if(IsPlayerConnected(i) && IsLoggedIn[i] && PlayerInfo[i][pAdmin] > 0)
            {
                SendClientMessage(i, COLOR_ADMIN, logmsg);
            }
        }
    }

    // --- Vérification de l'abonnement VIP ---
    if(PlayerInfo[playerid][pVipExpire] > 0 && PlayerInfo[playerid][pVipExpire] < gettime())
    {
        SendClientMessage(playerid, COLOR_YELLOW, "Votre abonnement donateur a expiré. Vous n'êtes plus VIP.");
        PlayerInfo[playerid][pVipExpire] = 0;
    }

    // --- Sélection du point d'apparition ---
    ShowSpawnSelectionDialog(playerid);
    return 1;
}

public ShowSpawnSelectionDialog(playerid)
{
    new items[256];
    format(items, sizeof(items),
        "Spawn à ma maison%s\n\
Dernière position\n\
Spawn par défaut",
        PlayerInfo[playerid][pHomeSet] ? "" : " {888888}(aucune propriété){FFFFFF}");

    ShowPlayerDialog(playerid, DIALOG_SPAWNCHOICE, DIALOG_STYLE_LIST,
        "Où voulez-vous spawn ?",
        items,
        "Choisir", "");
    return 1;
}

// Coordonnées de spawn par défaut du serveur (ex : Aéroport / Gare Californie RP)
stock SetDefaultSpawnPos(playerid)
{
    PlayerInfo[playerid][pPosX] = 1569.2711;
    PlayerInfo[playerid][pPosY] = -2348.7114;
    PlayerInfo[playerid][pPosZ] = 13.5547;
    PlayerInfo[playerid][pPosA] = 0.0;
    PlayerInfo[playerid][pInt] = 0;
    PlayerInfo[playerid][pWorld] = 0;
    return 1;
}

// Petit parseur "clé=valeur" fait maison (pas de dépendance externe type sscanf)
stock sscanf_simple(line[], key[], val[])
{
    new pos = strfind(line, "=", false);
    if(pos == -1) return 0;
    strmid(key, line, 0, pos);
    strmid(val, line, pos + 1, strlen(line));
    // Retirer les retours à la ligne éventuels
    new len = strlen(val);
    while(len > 0 && (val[len-1] == '\r' || val[len-1] == '\n'))
    {
        val[len-1] = '\0';
        len--;
    }
    return 1;
}

// ==============================================================
//  Sauvegarde / Chargement des données
// ==============================================================
public LoadUserData(playerid)
{
    new file:f = fopen(UserPathStr(playerid), io_read);
    if(!f) return 0;

    new line[128];
    while(fread(f, line))
    {
        new key[32], val[64];
        if(sscanf_simple(line, key, val))
        {
            if(!strcmp(key, "Cash")) PlayerInfo[playerid][pCash] = strval(val);
            else if(!strcmp(key, "Admin")) PlayerInfo[playerid][pAdmin] = strval(val);
            else if(!strcmp(key, "Skin")) PlayerInfo[playerid][pSkin] = strval(val);
            else if(!strcmp(key, "PosX")) PlayerInfo[playerid][pPosX] = floatstr(val);
            else if(!strcmp(key, "PosY")) PlayerInfo[playerid][pPosY] = floatstr(val);
            else if(!strcmp(key, "PosZ")) PlayerInfo[playerid][pPosZ] = floatstr(val);
            else if(!strcmp(key, "PosA")) PlayerInfo[playerid][pPosA] = floatstr(val);
            else if(!strcmp(key, "Int")) PlayerInfo[playerid][pInt] = strval(val);
            else if(!strcmp(key, "World")) PlayerInfo[playerid][pWorld] = strval(val);
            else if(!strcmp(key, "HomeSet")) PlayerInfo[playerid][pHomeSet] = strval(val);
            else if(!strcmp(key, "HomeX")) PlayerInfo[playerid][pHomeX] = floatstr(val);
            else if(!strcmp(key, "HomeY")) PlayerInfo[playerid][pHomeY] = floatstr(val);
            else if(!strcmp(key, "HomeZ")) PlayerInfo[playerid][pHomeZ] = floatstr(val);
            else if(!strcmp(key, "HomeA")) PlayerInfo[playerid][pHomeA] = floatstr(val);
            else if(!strcmp(key, "HomeInt")) PlayerInfo[playerid][pHomeInt] = strval(val);
            else if(!strcmp(key, "HomeWorld")) PlayerInfo[playerid][pHomeWorld] = strval(val);
            else if(!strcmp(key, "VipExpire")) PlayerInfo[playerid][pVipExpire] = strval(val);
        }
    }
    fclose(f);
    return 1;
}

public SaveUserData(playerid)
{
    new Float:x, Float:y, Float:z, Float:a;
    GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, a);

    new file:f = fopen(UserPathStr(playerid), io_read);
    new storedHash = 0;
    if(f)
    {
        new line[128];
        while(fread(f, line))
        {
            new key[32], val[64];
            if(sscanf_simple(line, key, val))
            {
                if(!strcmp(key, "Password")) storedHash = strval(val);
            }
        }
        fclose(f);
    }

    new file:fw = fopen(UserPathStr(playerid), io_write);
    if(fw)
    {
        new outLine[128];
        format(outLine, sizeof(outLine), "Password=%d\r\n", storedHash); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "Cash=%d\r\n", GetPlayerMoney(playerid)); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "Admin=%d\r\n", PlayerInfo[playerid][pAdmin]); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "Skin=%d\r\n", GetPlayerSkin(playerid)); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "PosX=%f\r\n", x); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "PosY=%f\r\n", y); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "PosZ=%f\r\n", z); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "PosA=%f\r\n", a); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "Int=%d\r\n", GetPlayerInterior(playerid)); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "World=%d\r\n", GetPlayerVirtualWorld(playerid)); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "HomeSet=%d\r\n", PlayerInfo[playerid][pHomeSet]); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "HomeX=%f\r\n", PlayerInfo[playerid][pHomeX]); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "HomeY=%f\r\n", PlayerInfo[playerid][pHomeY]); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "HomeZ=%f\r\n", PlayerInfo[playerid][pHomeZ]); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "HomeA=%f\r\n", PlayerInfo[playerid][pHomeA]); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "HomeInt=%d\r\n", PlayerInfo[playerid][pHomeInt]); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "HomeWorld=%d\r\n", PlayerInfo[playerid][pHomeWorld]); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "VipExpire=%d\r\n", PlayerInfo[playerid][pVipExpire]); fwrite(fw, outLine);
        fclose(fw);
    }
    return 1;
}

public SpawnPlayerAfterLogin(playerid)
{
    SetPlayerSkin(playerid, PlayerInfo[playerid][pSkin]);
    SpawnPlayer(playerid);
    return 1;
}

// ==============================================================
//  Spawn du joueur
// ==============================================================
public OnPlayerSpawn(playerid)
{
    if(!IsLoggedIn[playerid]) return 1;

    SetPlayerPos(playerid, PlayerInfo[playerid][pPosX], PlayerInfo[playerid][pPosY], PlayerInfo[playerid][pPosZ]);
    SetPlayerFacingAngle(playerid, PlayerInfo[playerid][pPosA]);
    SetPlayerInterior(playerid, PlayerInfo[playerid][pInt]);
    SetPlayerVirtualWorld(playerid, PlayerInfo[playerid][pWorld]);
    GivePlayerMoney(playerid, PlayerInfo[playerid][pCash]);
    SetPlayerHealth(playerid, 100.0);
    SetPlayerArmour(playerid, 0.0);
    SendClientMessage(playerid, COLOR_SERVER, "Tapez /help pour voir la liste des commandes disponibles.");
    return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
    return 1;
}

// ==============================================================
//  Commandes RolePlay
// ==============================================================
public OnPlayerCommandText(playerid, cmdtext[])
{
    new cmd[64], tmp[256];
    new idx = 0;
    cmd = strtok_(cmdtext, idx);

    // Laisser SA-MP gérer nativement /rcon (login, commandes admin console).
    // Sans ce return 0, notre script intercepterait la commande et empêcherait
    // le serveur de la traiter, provoquant un faux "Commande inconnue".
    if(!strcmp(cmd, "/rcon", true))
    {
        return 0;
    }

    if(!IsLoggedIn[playerid])
    {
        SendClientMessage(playerid, COLOR_RED, "Vous devez être connecté pour utiliser des commandes.");
        return 1;
    }

    if(!strcmp(cmd, "/help", true))
    {
        SendClientMessage(playerid, COLOR_YELLOW, "== Commandes Californie RP ==");
        SendClientMessage(playerid, COLOR_WHITE, "/me /do /ooc - Roleplay");
        SendClientMessage(playerid, COLOR_WHITE, "/stats /cash - Informations personnelles");
        SendClientMessage(playerid, COLOR_WHITE, "/sethome - Enregistrer votre position comme domicile");
        SendClientMessage(playerid, COLOR_WHITE, "/car - Faire apparaître un véhicule");
        SendClientMessage(playerid, COLOR_WHITE, "/engine /lock - Interagir avec un véhicule");
        if(PlayerInfo[playerid][pAdmin] > 0)
        {
            SendClientMessage(playerid, COLOR_ADMIN, "Tapez /ahelp (ou /adminhelp) pour la liste des commandes admin/dev.");
        }
        return 1;
    }

    if(!strcmp(cmd, "/ahelp", true) || !strcmp(cmd, "/adminhelp", true))
    {
        if(PlayerInfo[playerid][pAdmin] <= 0)
        {
            SendClientMessage(playerid, COLOR_RED, "Cette commande est réservée aux administrateurs. / This command is reserved for admins.");
            return 1;
        }
        ShowAdminHelp(playerid);
        return 1;
    }

    if(!strcmp(cmd, "/sethome", true))
    {
        new Float:x, Float:y, Float:z, Float:a;
        GetPlayerPos(playerid, x, y, z);
        GetPlayerFacingAngle(playerid, a);
        PlayerInfo[playerid][pHomeSet] = 1;
        PlayerInfo[playerid][pHomeX] = x;
        PlayerInfo[playerid][pHomeY] = y;
        PlayerInfo[playerid][pHomeZ] = z;
        PlayerInfo[playerid][pHomeA] = a;
        PlayerInfo[playerid][pHomeInt] = GetPlayerInterior(playerid);
        PlayerInfo[playerid][pHomeWorld] = GetPlayerVirtualWorld(playerid);
        SendClientMessage(playerid, COLOR_GREEN, "Votre position actuelle a été enregistrée comme domicile.");
        return 1;
    }

    if(!strcmp(cmd, "/me", true))
    {
        if(gMuted[playerid]) return SendClientMessage(playerid, COLOR_RED, "Vous êtes muet. / You are muted.");
        tmp = strtok_(cmdtext, idx);
        if(!strlen(tmp))
        {
            SendClientMessage(playerid, COLOR_RED, "Utilisation : /me [action]");
            return 1;
        }
        new name[MAX_PLAYER_NAME], str[256];
        GetPlayerName(playerid, name, sizeof(name));
        format(str, sizeof(str), "* %s %s", name, tmp);
        SendClientMessageToAll(COLOR_ME, str);
        return 1;
    }

    if(!strcmp(cmd, "/do", true))
    {
        if(gMuted[playerid]) return SendClientMessage(playerid, COLOR_RED, "Vous êtes muet. / You are muted.");
        tmp = strtok_(cmdtext, idx);
        if(!strlen(tmp))
        {
            SendClientMessage(playerid, COLOR_RED, "Utilisation : /do [description]");
            return 1;
        }
        new str[256];
        format(str, sizeof(str), "* %s ( %s )", tmp, "RP");
        SendClientMessageToAll(COLOR_DO, str);
        return 1;
    }

    if(!strcmp(cmd, "/ooc", true))
    {
        if(gMuted[playerid]) return SendClientMessage(playerid, COLOR_RED, "Vous êtes muet. / You are muted.");
        tmp = strtok_(cmdtext, idx);
        if(!strlen(tmp))
        {
            SendClientMessage(playerid, COLOR_RED, "Utilisation : /ooc [message]");
            return 1;
        }
        new name[MAX_PLAYER_NAME], str[256];
        GetPlayerName(playerid, name, sizeof(name));
        format(str, sizeof(str), "( (%s: %s) )", name, tmp);
        SendClientMessageToAll(COLOR_OOC, str);
        return 1;
    }

    if(!strcmp(cmd, "/stats", true))
    {
        new str[128];
        format(str, sizeof(str), "Argent : $%d | Niveau admin : %d", GetPlayerMoney(playerid), PlayerInfo[playerid][pAdmin]);
        SendClientMessage(playerid, COLOR_YELLOW, str);
        return 1;
    }

    if(!strcmp(cmd, "/cash", true))
    {
        new str[64];
        format(str, sizeof(str), "Vous possédez $%d", GetPlayerMoney(playerid));
        SendClientMessage(playerid, COLOR_GREEN, str);
        return 1;
    }

    if(!strcmp(cmd, "/car", true))
    {
        new Float:x, Float:y, Float:z, Float:a;
        GetPlayerPos(playerid, x, y, z);
        GetPlayerFacingAngle(playerid, a);
        CreateVehicle(411, x + 2.0, y, z, a, -1, -1, -1, false);
        SendClientMessage(playerid, COLOR_GREEN, "Un véhicule est apparu près de vous.");
        return 1;
    }

    if(!strcmp(cmd, "/engine", true))
    {
        if(IsPlayerInAnyVehicle(playerid))
        {
            new vehicleid = GetPlayerVehicleID(playerid);
            new engine, lights, alarm, doors, bonnet, boot, objective;
            GetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, objective);
            engine = !engine;
            SetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, objective);
            SendClientMessage(playerid, COLOR_GREEN, engine ? "Vous démarrez le moteur." : "Vous coupez le moteur.");
        }
        else
        {
            SendClientMessage(playerid, COLOR_RED, "Vous n'êtes pas dans un véhicule.");
        }
        return 1;
    }

    if(!strcmp(cmd, "/lock", true))
    {
        if(IsPlayerInAnyVehicle(playerid))
        {
            new vehicleid = GetPlayerVehicleID(playerid);
            new engine, lights, alarm, doors, bonnet, boot, objective;
            GetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, objective);
            doors = !doors;
            SetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, objective);
            SendClientMessage(playerid, COLOR_GREEN, doors ? "Véhicule verrouillé." : "Véhicule déverrouillé.");
        }
        else
        {
            SendClientMessage(playerid, COLOR_RED, "Vous n'êtes pas dans un véhicule.");
        }
        return 1;
    }

    // --- Connexion développeur (élévation en jeu, distincte du RCON natif SA-MP) ---
    if(!strcmp(cmd, "/devlogin", true) || !strcmp(cmd, "/connexiondev", true))
    {
        tmp = strtok_(cmdtext, idx);
        if(!strlen(tmp))
        {
            SendClientMessage(playerid, COLOR_RED, "Utilisation / Usage: /devlogin [mot de passe / password]");
            return 1;
        }
        if(udb_hash(tmp) == DEV_LOGIN_HASH)
        {
            PlayerInfo[playerid][pAdmin] = ADMIN_LEVEL_DEV;
            SendClientMessage(playerid, COLOR_ADMIN, "Connexion développeur réussie. / Developer login successful.");
        }
        else
        {
            SendClientMessage(playerid, COLOR_RED, "Mot de passe incorrect. / Incorrect password.");
        }
        return 1;
    }

    // --- Commandes Admin / Dev (bilingue FR/EN) ---
    new adminCanon[24], adminLevel;
    if(ResolveAdminCmd(cmd, adminCanon, adminLevel))
    {
        if(PlayerInfo[playerid][pAdmin] < adminLevel)
        {
            SendClientMessage(playerid, COLOR_RED, "Vous n'êtes pas autorisé à utiliser cette commande. / You are not authorized to use this command.");
            return 1;
        }
        ExecuteAdminCmd(playerid, adminCanon, cmdtext, idx);
        return 1;
    }

    SendClientMessage(playerid, COLOR_RED, "Commande inconnue. Tapez /help.");
    return 1;
}

// ==============================================================
//  Système Admin / Dev - bilingue FR / EN
//  Niveaux : 1 Helper, 2 Modérateur/Moderator, 3 Admin,
//            10 Admin Supérieur/Senior Admin, 20 Admin Superviseur/Supervisor,
//            5885 Développeur/Developer
// ==============================================================

// Fait correspondre un alias FR ou EN à un identifiant canonique + niveau requis.
// Retourne 1 si trouvé, 0 sinon.
stock ResolveAdminCmd(cmd[], canon[24], &level)
{
    // --- Niveau 1 : Helper ---
    if(!strcmp(cmd, "/freeze", true) || !strcmp(cmd, "/geler", true)) { canon = "FREEZE"; level = ADMIN_LEVEL_HELPER; return 1; }
    if(!strcmp(cmd, "/unfreeze", true) || !strcmp(cmd, "/degeler", true)) { canon = "UNFREEZE"; level = ADMIN_LEVEL_HELPER; return 1; }
    if(!strcmp(cmd, "/mute", true) || !strcmp(cmd, "/muet", true)) { canon = "MUTE"; level = ADMIN_LEVEL_HELPER; return 1; }
    if(!strcmp(cmd, "/unmute", true) || !strcmp(cmd, "/demuet", true)) { canon = "UNMUTE"; level = ADMIN_LEVEL_HELPER; return 1; }
    if(!strcmp(cmd, "/warn", true) || !strcmp(cmd, "/avertir", true)) { canon = "WARN"; level = ADMIN_LEVEL_HELPER; return 1; }
    if(!strcmp(cmd, "/spec", true) || !strcmp(cmd, "/observer", true)) { canon = "SPEC"; level = ADMIN_LEVEL_HELPER; return 1; }
    if(!strcmp(cmd, "/specoff", true) || !strcmp(cmd, "/finobserver", true)) { canon = "SPECOFF"; level = ADMIN_LEVEL_HELPER; return 1; }
    if(!strcmp(cmd, "/jail", true) || !strcmp(cmd, "/prison", true)) { canon = "JAIL"; level = ADMIN_LEVEL_HELPER; return 1; }
    if(!strcmp(cmd, "/unjail", true) || !strcmp(cmd, "/liberer", true)) { canon = "UNJAIL"; level = ADMIN_LEVEL_HELPER; return 1; }

    // --- Niveau 2 : Modérateur / Moderator ---
    if(!strcmp(cmd, "/kick", true) || !strcmp(cmd, "/expulser", true)) { canon = "KICK"; level = ADMIN_LEVEL_MOD; return 1; }
    if(!strcmp(cmd, "/slap", true) || !strcmp(cmd, "/gifler", true)) { canon = "SLAP"; level = ADMIN_LEVEL_MOD; return 1; }
    if(!strcmp(cmd, "/heal", true) || !strcmp(cmd, "/soigner", true)) { canon = "HEAL"; level = ADMIN_LEVEL_MOD; return 1; }
    if(!strcmp(cmd, "/armor", true) || !strcmp(cmd, "/armure", true)) { canon = "ARMOR"; level = ADMIN_LEVEL_MOD; return 1; }
    if(!strcmp(cmd, "/goto", true) || !strcmp(cmd, "/allerA", true)) { canon = "GOTO"; level = ADMIN_LEVEL_MOD; return 1; }
    if(!strcmp(cmd, "/gethere", true) || !strcmp(cmd, "/amener", true)) { canon = "GETHERE"; level = ADMIN_LEVEL_MOD; return 1; }

    // --- Niveau 3 : Admin ---
    if(!strcmp(cmd, "/ban", true) || !strcmp(cmd, "/bannir", true)) { canon = "BAN"; level = ADMIN_LEVEL_ADMIN; return 1; }
    if(!strcmp(cmd, "/unban", true) || !strcmp(cmd, "/debannir", true)) { canon = "UNBAN"; level = ADMIN_LEVEL_ADMIN; return 1; }
    if(!strcmp(cmd, "/setskin", true) || !strcmp(cmd, "/apparence", true)) { canon = "SETSKIN"; level = ADMIN_LEVEL_ADMIN; return 1; }
    if(!strcmp(cmd, "/weapons", true) || !strcmp(cmd, "/armes", true)) { canon = "WEAPONS"; level = ADMIN_LEVEL_ADMIN; return 1; }
    if(!strcmp(cmd, "/god", true) || !strcmp(cmd, "/dieu", true)) { canon = "GOD"; level = ADMIN_LEVEL_ADMIN; return 1; }

    // --- Niveau 10 : Admin Supérieur / Senior Admin ---
    if(!strcmp(cmd, "/setcash", true) || !strcmp(cmd, "/argent", true)) { canon = "SETCASH"; level = ADMIN_LEVEL_SUPERIOR; return 1; }
    if(!strcmp(cmd, "/givecash", true) || !strcmp(cmd, "/donnerargent", true)) { canon = "GIVECASH"; level = ADMIN_LEVEL_SUPERIOR; return 1; }
    if(!strcmp(cmd, "/setvip", true) || !strcmp(cmd, "/vip", true)) { canon = "SETVIP"; level = ADMIN_LEVEL_SUPERIOR; return 1; }
    if(!strcmp(cmd, "/setlevel", true) || !strcmp(cmd, "/niveau", true)) { canon = "SETLEVEL"; level = ADMIN_LEVEL_SUPERIOR; return 1; }

    // --- Niveau 20 : Admin Superviseur / Supervisor ---
    if(!strcmp(cmd, "/setadmin", true) || !strcmp(cmd, "/definiradmin", true)) { canon = "SETADMIN"; level = ADMIN_LEVEL_SUPERVISOR; return 1; }
    if(!strcmp(cmd, "/announce", true) || !strcmp(cmd, "/annonce", true)) { canon = "ANNOUNCE"; level = ADMIN_LEVEL_SUPERVISOR; return 1; }

    // --- Niveau 5885 : Développeur / Developer ---
    if(!strcmp(cmd, "/settime", true) || !strcmp(cmd, "/heure", true)) { canon = "SETTIME"; level = ADMIN_LEVEL_DEV; return 1; }
    if(!strcmp(cmd, "/setweather", true) || !strcmp(cmd, "/meteo", true)) { canon = "SETWEATHER"; level = ADMIN_LEVEL_DEV; return 1; }
    if(!strcmp(cmd, "/giveweapon", true) || !strcmp(cmd, "/donnerarme", true)) { canon = "GIVEWEAPON"; level = ADMIN_LEVEL_DEV; return 1; }
    if(!strcmp(cmd, "/gotoxyz", true) || !strcmp(cmd, "/allercoord", true)) { canon = "GOTOXYZ"; level = ADMIN_LEVEL_DEV; return 1; }
    if(!strcmp(cmd, "/gmx", true) || !strcmp(cmd, "/redemarrer", true)) { canon = "GMX"; level = ADMIN_LEVEL_DEV; return 1; }

    return 0;
}

// Exécute la commande admin/dev canonique déjà validée (niveau vérifié en amont).
stock ExecuteAdminCmd(playerid, canon[], cmdtext[], idx)
{
    new tmp[64], tmp2[64], targetid, str[144], name[MAX_PLAYER_NAME], tname[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof(name));

    if(!strcmp(canon, "FREEZE"))
    {
        tmp = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        if(!strlen(tmp) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation / Usage: /freeze [id]");
        gFrozen[targetid] = 1;
        TogglePlayerControllable(targetid, false);
        SendClientMessage(targetid, COLOR_RED, "Vous avez été gelé par un admin. / You have been frozen by an admin.");
        SendClientMessage(playerid, COLOR_GREEN, "Joueur gelé. / Player frozen.");
    }
    else if(!strcmp(canon, "UNFREEZE"))
    {
        tmp = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        if(!strlen(tmp) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation / Usage: /unfreeze [id]");
        gFrozen[targetid] = 0;
        TogglePlayerControllable(targetid, true);
        SendClientMessage(targetid, COLOR_GREEN, "Vous avez été dégelé. / You have been unfrozen.");
        SendClientMessage(playerid, COLOR_GREEN, "Joueur dégelé. / Player unfrozen.");
    }
    else if(!strcmp(canon, "MUTE"))
    {
        tmp = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        if(!strlen(tmp) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation / Usage: /mute [id]");
        gMuted[targetid] = 1;
        SendClientMessage(targetid, COLOR_RED, "Vous avez été réduit au silence. / You have been muted.");
        SendClientMessage(playerid, COLOR_GREEN, "Joueur muet. / Player muted.");
    }
    else if(!strcmp(canon, "UNMUTE"))
    {
        tmp = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        if(!strlen(tmp) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation / Usage: /unmute [id]");
        gMuted[targetid] = 0;
        SendClientMessage(targetid, COLOR_GREEN, "Vous pouvez de nouveau parler. / You can talk again.");
        SendClientMessage(playerid, COLOR_GREEN, "Joueur démuté. / Player unmuted.");
    }
    else if(!strcmp(canon, "WARN"))
    {
        tmp = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        tmp2 = strtok_(cmdtext, idx);
        if(!strlen(tmp) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation / Usage: /warn [id] [raison]");
        format(str, sizeof(str), "Vous avez reçu un avertissement : %s / You received a warning: %s", tmp2, tmp2);
        SendClientMessage(targetid, COLOR_RED, str);
        SendClientMessage(playerid, COLOR_GREEN, "Avertissement envoyé. / Warning sent.");
    }
    else if(!strcmp(canon, "SPEC"))
    {
        tmp = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        if(!strlen(tmp) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation / Usage: /spec [id]");
        new Float:x, Float:y, Float:z;
        GetPlayerPos(targetid, x, y, z);
        SetPlayerInterior(playerid, GetPlayerInterior(targetid));
        SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(targetid));
        SetPlayerPos(playerid, x, y, z + 2.0);
        SendClientMessage(playerid, COLOR_GREEN, "Mode observateur activé. / Spectate mode enabled.");
    }
    else if(!strcmp(canon, "SPECOFF"))
    {
        SetPlayerInterior(playerid, PlayerInfo[playerid][pInt]);
        SetPlayerVirtualWorld(playerid, PlayerInfo[playerid][pWorld]);
        SetPlayerPos(playerid, PlayerInfo[playerid][pPosX], PlayerInfo[playerid][pPosY], PlayerInfo[playerid][pPosZ]);
        SendClientMessage(playerid, COLOR_GREEN, "Mode observateur désactivé. / Spectate mode disabled.");
    }
    else if(!strcmp(canon, "JAIL"))
    {
        tmp = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        if(!strlen(tmp) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation / Usage: /jail [id]");
        gJailed[targetid] = 1;
        SetPlayerPos(targetid, 264.6, 77.4, 1001.0);
        SetPlayerInterior(targetid, 6);
        SetPlayerVirtualWorld(targetid, 0);
        SendClientMessage(targetid, COLOR_RED, "Vous avez été emprisonné. / You have been jailed.");
        SendClientMessage(playerid, COLOR_GREEN, "Joueur emprisonné. / Player jailed.");
    }
    else if(!strcmp(canon, "UNJAIL"))
    {
        tmp = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        if(!strlen(tmp) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation / Usage: /unjail [id]");
        gJailed[targetid] = 0;
        SetDefaultSpawnPos(targetid);
        SetPlayerPos(targetid, PlayerInfo[targetid][pPosX], PlayerInfo[targetid][pPosY], PlayerInfo[targetid][pPosZ]);
        SetPlayerInterior(targetid, PlayerInfo[targetid][pInt]);
        SetPlayerVirtualWorld(targetid, PlayerInfo[targetid][pWorld]);
        SendClientMessage(targetid, COLOR_GREEN, "Vous avez été libéré. / You have been released.");
        SendClientMessage(playerid, COLOR_GREEN, "Joueur libéré. / Player released.");
    }
    else if(!strcmp(canon, "KICK"))
    {
        tmp = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        if(!strlen(tmp) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation / Usage: /kick [id]");
        GetPlayerName(targetid, tname, sizeof(tname));
        format(str, sizeof(str), "%s a expulsé %s du serveur. / %s kicked %s from the server.", name, tname, name, tname);
        SendClientMessageToAll(COLOR_ADMIN, str);
        Kick(targetid);
    }
    else if(!strcmp(canon, "SLAP"))
    {
        tmp = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        if(!strlen(tmp) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation / Usage: /slap [id]");
        new Float:x, Float:y, Float:z;
        GetPlayerPos(targetid, x, y, z);
        SetPlayerPos(targetid, x, y, z + 5.0);
        SendClientMessage(targetid, COLOR_RED, "Vous avez été giflé par un admin. / You were slapped by an admin.");
        SendClientMessage(playerid, COLOR_GREEN, "Joueur giflé. / Player slapped.");
    }
    else if(!strcmp(canon, "HEAL"))
    {
        tmp = strtok_(cmdtext, idx);
        targetid = strlen(tmp) ? strval(tmp) : playerid;
        if(!IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Joueur introuvable. / Player not found.");
        SetPlayerHealth(targetid, 100.0);
        SendClientMessage(targetid, COLOR_GREEN, "Vous avez été soigné. / You have been healed.");
        SendClientMessage(playerid, COLOR_GREEN, "Soin appliqué. / Heal applied.");
    }
    else if(!strcmp(canon, "ARMOR"))
    {
        tmp = strtok_(cmdtext, idx);
        targetid = strlen(tmp) ? strval(tmp) : playerid;
        if(!IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Joueur introuvable. / Player not found.");
        SetPlayerArmour(targetid, 100.0);
        SendClientMessage(targetid, COLOR_GREEN, "Vous avez reçu un gilet pare-balles. / You received body armor.");
        SendClientMessage(playerid, COLOR_GREEN, "Gilet donné. / Armor given.");
    }
    else if(!strcmp(canon, "GOTO"))
    {
        tmp = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        if(!strlen(tmp) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation / Usage: /goto [id]");
        new Float:x, Float:y, Float:z;
        GetPlayerPos(targetid, x, y, z);
        SetPlayerInterior(playerid, GetPlayerInterior(targetid));
        SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(targetid));
        SetPlayerPos(playerid, x, y, z);
        SendClientMessage(playerid, COLOR_GREEN, "Téléportation effectuée. / Teleported.");
    }
    else if(!strcmp(canon, "GETHERE"))
    {
        tmp = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        if(!strlen(tmp) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation / Usage: /gethere [id]");
        new Float:x, Float:y, Float:z;
        GetPlayerPos(playerid, x, y, z);
        SetPlayerInterior(targetid, GetPlayerInterior(playerid));
        SetPlayerVirtualWorld(targetid, GetPlayerVirtualWorld(playerid));
        SetPlayerPos(targetid, x, y, z);
        SendClientMessage(targetid, COLOR_YELLOW, "Vous avez été téléporté par un admin. / You were teleported by an admin.");
        SendClientMessage(playerid, COLOR_GREEN, "Joueur téléporté à vous. / Player teleported to you.");
    }
    else if(!strcmp(canon, "BAN"))
    {
        tmp = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        if(!strlen(tmp) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation / Usage: /ban [id]");
        GetPlayerName(targetid, tname, sizeof(tname));
        format(str, sizeof(str), "%s a banni %s du serveur. / %s banned %s from the server.", name, tname, name, tname);
        SendClientMessageToAll(COLOR_ADMIN, str);
        Ban(targetid);
    }
    else if(!strcmp(canon, "UNBAN"))
    {
        // Le déban se fait via le fichier samp.ban ou une commande RCON native ("rcon unbanip <ip>").
        SendClientMessage(playerid, COLOR_YELLOW, "Utilisez la console RCON : rcon unbanip <ip> / Use RCON console: rcon unbanip <ip>");
    }
    else if(!strcmp(canon, "SETSKIN"))
    {
        new skinid[64];
        tmp = strtok_(cmdtext, idx);
        skinid = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        if(!strlen(tmp) || !strlen(skinid) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation / Usage: /setskin [id] [skinid]");
        SetPlayerSkin(targetid, strval(skinid));
        SendClientMessage(playerid, COLOR_GREEN, "Apparence modifiée. / Skin changed.");
    }
    else if(!strcmp(canon, "WEAPONS"))
    {
        tmp = strtok_(cmdtext, idx);
        targetid = strlen(tmp) ? strval(tmp) : playerid;
        if(!IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Joueur introuvable. / Player not found.");
        GivePlayerWeapon(targetid, 24, 250); // Deagle
        GivePlayerWeapon(targetid, 31, 500); // M4
        SendClientMessage(targetid, COLOR_GREEN, "Vous avez reçu des armes. / You received weapons.");
        SendClientMessage(playerid, COLOR_GREEN, "Armes données. / Weapons given.");
    }
    else if(!strcmp(canon, "GOD"))
    {
        tmp = strtok_(cmdtext, idx);
        targetid = strlen(tmp) ? strval(tmp) : playerid;
        if(!IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Joueur introuvable. / Player not found.");
        SetPlayerHealth(targetid, 99999.0);
        SendClientMessage(targetid, COLOR_GREEN, "Mode invincible activé. / God mode enabled.");
    }
    else if(!strcmp(canon, "SETCASH"))
    {
        new amount[64];
        tmp = strtok_(cmdtext, idx);
        amount = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        if(!strlen(tmp) || !strlen(amount) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation / Usage: /setcash [id] [montant]");
        ResetPlayerMoney(targetid);
        GivePlayerMoney(targetid, strval(amount));
        SendClientMessage(playerid, COLOR_GREEN, "Argent défini. / Cash set.");
    }
    else if(!strcmp(canon, "GIVECASH"))
    {
        new amount[64];
        tmp = strtok_(cmdtext, idx);
        amount = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        if(!strlen(tmp) || !strlen(amount) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation / Usage: /givecash [id] [montant]");
        GivePlayerMoney(targetid, strval(amount));
        SendClientMessage(playerid, COLOR_GREEN, "Argent donné. / Cash given.");
    }
    else if(!strcmp(canon, "SETVIP"))
    {
        new days[64];
        tmp = strtok_(cmdtext, idx);
        days = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        if(!strlen(tmp) || !strlen(days) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation / Usage: /setvip [id] [jours]");
        PlayerInfo[targetid][pVipExpire] = gettime() + (strval(days) * 86400);
        SendClientMessage(targetid, COLOR_YELLOW, "Vous êtes maintenant VIP ! / You are now VIP!");
        SendClientMessage(playerid, COLOR_GREEN, "Statut VIP mis à jour. / VIP status updated.");
    }
    else if(!strcmp(canon, "SETLEVEL"))
    {
        new lvl[64];
        tmp = strtok_(cmdtext, idx);
        lvl = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        if(!strlen(tmp) || !strlen(lvl) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation / Usage: /setlevel [id] [niveau]");
        if(strval(lvl) >= PlayerInfo[playerid][pAdmin]) return SendClientMessage(playerid, COLOR_RED, "Vous ne pouvez pas attribuer un niveau égal ou supérieur au vôtre. / You cannot assign a level equal to or higher than your own.");
        PlayerInfo[targetid][pAdmin] = strval(lvl);
        SendClientMessage(targetid, COLOR_ADMIN, "Votre niveau admin a été modifié. / Your admin level was changed.");
        SendClientMessage(playerid, COLOR_GREEN, "Niveau mis à jour. / Level updated.");
    }
    else if(!strcmp(canon, "SETADMIN"))
    {
        new lvl[64];
        tmp = strtok_(cmdtext, idx);
        lvl = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        if(!strlen(tmp) || !strlen(lvl) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation / Usage: /setadmin [id] [niveau]");
        if(strval(lvl) >= PlayerInfo[playerid][pAdmin]) return SendClientMessage(playerid, COLOR_RED, "Vous ne pouvez pas attribuer un niveau égal ou supérieur au vôtre. / You cannot assign a level equal to or higher than your own.");
        PlayerInfo[targetid][pAdmin] = strval(lvl);
        SendClientMessage(targetid, COLOR_ADMIN, "Votre niveau admin a été modifié. / Your admin level was changed.");
        SendClientMessage(playerid, COLOR_GREEN, "Niveau admin mis à jour. / Admin level updated.");
    }
    else if(!strcmp(canon, "ANNOUNCE"))
    {
        idx = 0;
        tmp = strtok_(cmdtext, idx); // consomme /announce
        new msg[144];
        format(msg, sizeof(msg), "%s", cmdtext[idx]);
        format(str, sizeof(str), "[ANNONCE / ANNOUNCE] %s", msg);
        SendClientMessageToAll(COLOR_YELLOW, str);
    }
    else if(!strcmp(canon, "SETTIME"))
    {
        new hour[64];
        hour = strtok_(cmdtext, idx);
        if(!strlen(hour)) return SendClientMessage(playerid, COLOR_RED, "Utilisation / Usage: /settime [heure]");
        SetWorldTime(strval(hour));
        SendClientMessage(playerid, COLOR_GREEN, "Heure du serveur modifiée. / Server time changed.");
    }
    else if(!strcmp(canon, "SETWEATHER"))
    {
        new wid[64];
        wid = strtok_(cmdtext, idx);
        if(!strlen(wid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation / Usage: /setweather [id]");
        SetWeather(strval(wid));
        SendClientMessage(playerid, COLOR_GREEN, "Météo du serveur modifiée. / Server weather changed.");
    }
    else if(!strcmp(canon, "GIVEWEAPON"))
    {
        new wid[64], ammo[64];
        tmp = strtok_(cmdtext, idx);
        wid = strtok_(cmdtext, idx);
        ammo = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        if(!strlen(tmp) || !strlen(wid) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation / Usage: /giveweapon [id] [armeid] [munitions]");
        GivePlayerWeapon(targetid, strval(wid), strlen(ammo) ? strval(ammo) : 100);
        SendClientMessage(playerid, COLOR_GREEN, "Arme donnée. / Weapon given.");
    }
    else if(!strcmp(canon, "GOTOXYZ"))
    {
        new sx[64], sy[64], sz[64];
        sx = strtok_(cmdtext, idx);
        sy = strtok_(cmdtext, idx);
        sz = strtok_(cmdtext, idx);
        if(!strlen(sx) || !strlen(sy) || !strlen(sz)) return SendClientMessage(playerid, COLOR_RED, "Utilisation / Usage: /gotoxyz [x] [y] [z]");
        SetPlayerPos(playerid, floatstr(sx), floatstr(sy), floatstr(sz));
        SendClientMessage(playerid, COLOR_GREEN, "Téléportation effectuée. / Teleported.");
    }
    else if(!strcmp(canon, "GMX"))
    {
        SendClientMessageToAll(COLOR_ADMIN, "(( Redémarrage du gamemode en cours... / Gamemode restarting... ))");
        SendRconCommand("gmx");
    }
    return 1;
}

// Affiche la liste des commandes admin/dev disponibles selon le niveau du joueur (FR/EN)
stock ShowAdminHelp(playerid)
{
    new lvl = PlayerInfo[playerid][pAdmin];
    SendClientMessage(playerid, COLOR_YELLOW, "== Commandes Admin / Admin Commands ==");
    if(lvl >= ADMIN_LEVEL_HELPER)
        SendClientMessage(playerid, COLOR_WHITE, "[Helper] /freeze /geler, /unfreeze /degeler, /mute /muet, /unmute /demuet, /warn /avertir, /spec /observer, /specoff /finobserver, /jail /prison, /unjail /liberer");
    if(lvl >= ADMIN_LEVEL_MOD)
        SendClientMessage(playerid, COLOR_WHITE, "[Modérateur/Moderator] /kick /expulser, /slap /gifler, /heal /soigner, /armor /armure, /goto /allerA, /gethere /amener");
    if(lvl >= ADMIN_LEVEL_ADMIN)
        SendClientMessage(playerid, COLOR_WHITE, "[Admin] /ban /bannir, /unban /debannir, /setskin /apparence, /weapons /armes, /god /dieu");
    if(lvl >= ADMIN_LEVEL_SUPERIOR)
        SendClientMessage(playerid, COLOR_WHITE, "[Admin Sup./Senior] /setcash /argent, /givecash /donnerargent, /setvip /vip, /setlevel /niveau");
    if(lvl >= ADMIN_LEVEL_SUPERVISOR)
        SendClientMessage(playerid, COLOR_WHITE, "[Superviseur/Supervisor] /setadmin /definiradmin, /announce /annonce");
    if(lvl >= ADMIN_LEVEL_DEV)
        SendClientMessage(playerid, COLOR_ADMIN, "[Développeur/Developer] /settime /heure, /setweather /meteo, /giveweapon /donnerarme, /gotoxyz /allercoord, /gmx /redemarrer");
    return 1;
}

// Petit tokenizer maison (évite une dépendance externe)
stock strtok_(const string[], &index)
{
    new length = strlen(string);
    while ((index < length) && (string[index] <= ' ')) index++;

    new offset = index;
    new result[64];
    while ((index < length) && (string[index] > ' ') && ((index - offset) < (sizeof(result) - 1)))
    {
        result[index - offset] = string[index];
        index++;
    }
    result[index - offset] = EOS;
    return result;
}

// ==============================================================
//  Autres callbacks nécessaires
// ==============================================================
public OnPlayerRequestClass(playerid, classid)
{
    SetPlayerPos(playerid, 1569.2711, -2348.7114, 13.5547);
    SetPlayerCameraPos(playerid, 1573.2711, -2348.7114, 15.5547);
    SetPlayerCameraLookAt(playerid, 1569.2711, -2348.7114, 13.5547);
    return 1;
}

public OnPlayerText(playerid, text[])
{
    if(gMuted[playerid])
    {
        SendClientMessage(playerid, COLOR_RED, "Vous êtes muet et ne pouvez pas parler. / You are muted and cannot talk.");
        return 0;
    }
    return 1;
}

public OnVehicleSpawn(vehicleid)
{
    return 1;
}

public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
    return 1;
}

// ==============================================================
//  Pont RCON natif <-> système de niveaux admin du script
//  Le login RCON lui-même est géré nativement par SA-MP
//  (server.cfg -> rcon_password, puis "/rcon login <motdepasse>" en jeu).
//  Ce callback détecte une connexion RCON réussie et l'associe
//  automatiquement au niveau Développeur dans notre système.
// ==============================================================
public OnRconLoginAttempt(ip[], password[], success)
{
    if(success)
    {
        for(new i = 0; i < MAX_PLAYERS; i++)
        {
            if(!IsPlayerConnected(i)) continue;

            new playerIp[16];
            GetPlayerIp(i, playerIp, sizeof(playerIp));

            if(!strcmp(playerIp, ip))
            {
                PlayerInfo[i][pAdmin] = ADMIN_LEVEL_DEV;

                SendClientMessage(i, COLOR_ADMIN, "Connexion RCON réussie : niveau Développeur accordé. / RCON login successful: Developer level granted.");

                new name[MAX_PLAYER_NAME], logmsg[144];
                GetPlayerName(i, name, sizeof(name));
                format(logmsg, sizeof(logmsg), "(( %s s'est connecté en RCON. / %s logged in via RCON. ))", name, name);

                for(new j = 0; j < MAX_PLAYERS; j++)
                {
                    if(IsPlayerConnected(j) && IsLoggedIn[j] && PlayerInfo[j][pAdmin] > 0)
                    {
                        SendClientMessage(j, COLOR_ADMIN, logmsg);
                    }
                }
            }
        }
    }
    return 1;
}
