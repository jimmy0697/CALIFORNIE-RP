/*==============================================================
    CALIFORNIE RP - Gamemode principal
    Serveur SA-MP - Roleplay
==============================================================*/

#include <a_samp>
#include "californie.inc"

#define FILTERSCRIPT

main() {}


// ------------------------------------------------------------
//  Hash simple (Adler32-like) utilise pour les mots de passe.
//  Fonction standard couramment utilisee dans les gamemodes SA-MP.
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
//  Constantes ajoutees (auth / spawn) - definies ici si absentes de californie.inc
// ------------------------------------------------------------
#if !defined DIALOG_SPAWNCHOICE
    #define DIALOG_SPAWNCHOICE 9001
#endif
#if !defined DIALOG_CLIMAT
    #define DIALOG_CLIMAT 9002
#endif
#if !defined DIALOG_PAPIERS
    #define DIALOG_PAPIERS 9003
#endif
#if !defined DIALOG_PAPIERS_RECUS
    #define DIALOG_PAPIERS_RECUS 9005
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
//  1 Helper | 2 Moderateur | 3 Admin | 10 Admin Superieur
//  20 Admin Superviseur | 5885 Developpeur
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

// Hash (udb_hash) du mot de passe de connexion developpeur.
// Le mot de passe en clair n'est JAMAIS stocke dans le code source
// (mauvaise pratique de securite : le .pwn/.amx peut etre partage ou decompile).
// Genere avec udb_hash("Barre0697") = 254870211
#define DEV_LOGIN_HASH 254870211

// ------------------------------------------------------------
//  Systeme de climat
//  5 etats climatiques, changement automatique aleatoire toutes
//  les 10 minutes, ou manuellement par un admin via /climat (menu).
// ------------------------------------------------------------
#define CLIMATE_SOLEIL      0
#define CLIMATE_PLUIE        1
#define CLIMATE_BROUILLARD   2
#define CLIMATE_ORAGE        3
#define CLIMATE_HIVER        4
#define CLIMATE_COUNT        5
#define CLIMATE_INTERVAL     600000 // 10 minutes en millisecondes

// Correspondance climat -> WeatherID SA-MP (voir sampwiki.blast.hk/wiki/WeatherID).
// 8 et 12 sont des approximations : le SA-MP natif n'a pas de vrai orage avec
// eclairs animes ni de neige ; a ajuster en jeu si un autre rendu te convient mieux.
new const gClimateWeatherID[CLIMATE_COUNT] = { 1, 8, 9, 8, 12 };

// Messages d'ambiance diffuses a tous les joueurs lors du changement de climat
new const gClimateMessage[CLIMATE_COUNT][160] = {
    "Le soleil brille sur Californie, les habitants profitent d'une journee radieuse.",
    "La pluie s'abat sur les rues, les passants se pressent pour trouver un abri.",
    "Un brouillard epais recouvre la ville, rendant chaque pas mysterieux.",
    "Le tonnerre gronde et les eclairs illuminent le ciel menacant.",
    "L'hiver s'installe sur Californie, les rues se couvrent de givre et l'air glacial ralentit la ville."
};

// Noms courts affiches dans le menu /climat et les messages admin
new const gClimateName[CLIMATE_COUNT][16] = {
    "Soleil", "Pluie", "Brouillard", "Orage", "Hiver"
};

new gCurrentClimate = CLIMATE_SOLEIL;
forward ClimateCycleTimer();

new gFrozen[MAX_PLAYERS];
new gMuted[MAX_PLAYERS];
new gJailed[MAX_PLAYERS];

// --- Affichage TextDraw des documents (carte d'identite, permis, port d'armes) ---
#define MAX_CARD_TD 9
new PlayerText:gCardTD[MAX_PLAYERS][MAX_CARD_TD];
new bool:gCardTDShown[MAX_PLAYERS];

// ------------------------------------------------------------
//  Donnees joueur
// ------------------------------------------------------------
enum pInfo
{
    pPass[MAX_PASS_LENGTH],
    Float:pPosX,       // Derniere position connue (deconnexion)
    Float:pPosY,
    Float:pPosZ,
    Float:pPosA,
    pInt,
    pWorld,
    pCash,
    pAdmin,
    pSkin,

    // Propriete / maison
    pHomeSet,
    Float:pHomeX,
    Float:pHomeY,
    Float:pHomeZ,
    Float:pHomeA,
    pHomeInt,
    pHomeWorld,

    // Abonnement VIP
    pVipExpire,          // Timestamp UNIX d'expiration (0 = pas de VIP)

    // Papiers / documents
    pIDNum,              // Numero de carte d'identite (attribue a l'inscription)
    pDateNaissance[11],  // Date de naissance JJ/MM/AAAA
    pPermisConduire,     // 0 = non possede, 1 = possede
    pPortArme            // 0 = non possede, 1 = possede
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

// ------------------------------------------------------------
//  Applique un climat donne : change la meteo et previent tout
//  le monde avec le message d'ambiance correspondant.
// ------------------------------------------------------------
stock ApplyClimate(id)
{
    if(id < 0 || id >= CLIMATE_COUNT) return 0;

    gCurrentClimate = id;
    SetWeather(gClimateWeatherID[id]);
    SendClientMessageToAll(COLOR_YELLOW, gClimateMessage[id]);
    return 1;
}

// ------------------------------------------------------------
//  Tire un climat aleatoire different du climat actuel et
//  l'applique. Appele automatiquement toutes les 10 minutes.
// ------------------------------------------------------------
public ClimateCycleTimer()
{
    new next = random(CLIMATE_COUNT);
    while(next == gCurrentClimate)
    {
        next = random(CLIMATE_COUNT);
    }
    ApplyClimate(next);
    return 1;
}

// ------------------------------------------------------------
//  Affiche le menu de selection du climat (reserve aux admins).
// ------------------------------------------------------------
stock ShowClimateMenu(playerid)
{
    new items[160];
    format(items, sizeof(items),
        "%d - %s\n%d - %s\n%d - %s\n%d - %s\n%d - %s",
        CLIMATE_SOLEIL, gClimateName[CLIMATE_SOLEIL],
        CLIMATE_PLUIE, gClimateName[CLIMATE_PLUIE],
        CLIMATE_BROUILLARD, gClimateName[CLIMATE_BROUILLARD],
        CLIMATE_ORAGE, gClimateName[CLIMATE_ORAGE],
        CLIMATE_HIVER, gClimateName[CLIMATE_HIVER]);

    ShowPlayerDialog(playerid, DIALOG_CLIMAT, DIALOG_STYLE_LIST,
        "Changer le climat",
        items,
        "Choisir", "Annuler");
    return 1;
}

// ==============================================================
//  OnGameModeInit
// ==============================================================
public OnGameModeInit()
{
    SetGameModeText("Californie RP");
    ShowPlayerMarkers(PLAYER_MARKERS_MODE_GLOBAL);
    ShowNameTags(1);
    // SetNameTagANoseUnderVehicles(1); // Native introuvable dans les includes standards SA-MP, desactivee

    UsePlayerPedAnims();
    EnableStuntBonusForAll(0);
    DisableInteriorEnterExits(); // Desactive TOUS les marqueurs d'entree/sortie par defaut du jeu
    SetWorldTime(12);

    // --- Systeme de climat : etat initial + cycle automatique aleatoire ---
    gCurrentClimate = CLIMATE_SOLEIL;
    SetWeather(gClimateWeatherID[CLIMATE_SOLEIL]);
    SetTimer("ClimateCycleTimer", CLIMATE_INTERVAL, true);

    // Classes de selection de personnage (spawn Los Santos)
    AddPlayerClass(101, 1569.2711, -2348.7114, 13.5547, 0.0, 0,0,0,0,0,0); // Civil - Los Santos Gare (point d'apparition de depart)
    AddPlayerClass(280, 1569.2711, -2348.7114, 13.5547, 0.0, 0,0,0,0,0,0); // Police (skin par defaut, a changer via faction)
    AddPlayerClass(274, 1569.2711, -2348.7114, 13.5547, 0.0, 0,0,0,0,0,0); // EMS

    print("==============================================");
    print("   CALIFORNIE RP - Gamemode charge avec succes  ");
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
    gCardTDShown[playerid] = false;
    for(new i = 0; i < MAX_CARD_TD; i++) gCardTD[playerid][i] = PlayerText:INVALID_TEXT_DRAW;

    // --- Securite anti-cheat : kick si non connecte apres 60 secondes ---
    gLoginTimer[playerid] = SetTimerEx("KickIfNotLoggedIn", LOGIN_TIMEOUT, false, "d", playerid);

    new name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof(name));

    if(fexist(UserPathStr(playerid)))
    {
        new msg[400];
        format(msg, sizeof(msg),
            "{FFFFFF}Bienvenue %s sur Californie RP.\n\
{00FF00}Votre compte est enregistre.\n\
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
{FFFFFF}Choisissez un mot de passe pour creer votre compte :",
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
    DestroyCardTD(playerid);
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

// Kicke automatiquement si le joueur n'est pas connecte 60s apres OnPlayerConnect
public KickIfNotLoggedIn(playerid)
{
    gLoginTimer[playerid] = 0;
    if(IsPlayerConnected(playerid) && !IsLoggedIn[playerid])
    {
        SendClientMessage(playerid, COLOR_RED, "Vous avez mis trop de temps a vous connecter. Vous etes expulse.");
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

// Chemin du fichier de recus de paiement du joueur
stock ReceiptPathStr(playerid)
{
    new path[64], name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof(name));
    format(path, sizeof(path), "/Recus/%s.ini", name);
    return path;
}

// ------------------------------------------------------------
//  Ajoute un recu de paiement au dossier du joueur (vehicule,
//  amende/PV, fourriere, etc). A appeler depuis n'importe quel
//  systeme qui prend de l'argent a un joueur.
//  Exemple : AddReceipt(playerid, "Amende", 250, "Exces de vitesse");
// ------------------------------------------------------------
stock AddReceipt(playerid, const type[], montant, const description[])
{
    new file:f = fopen(ReceiptPathStr(playerid), io_append);
    if(!f) return 0;

    new y, m, d, h, mi, s;
    getdate(y, m, d);
    gettime(h, mi, s);

    new line[160];
    format(line, sizeof(line), "%s|%d|%02d/%02d/%d %02d:%02d|%s\r\n", type, montant, d, m, y, h, mi, description);
    fwrite(f, line);
    fclose(f);
    return 1;
}

// ------------------------------------------------------------
//  Affiche les 15 derniers recus de paiement du joueur.
// ------------------------------------------------------------
stock ShowReceipts(playerid)
{
    new file:f = fopen(ReceiptPathStr(playerid), io_read);
    if(!f)
    {
        ShowPlayerDialog(playerid, DIALOG_PAPIERS_RECUS, DIALOG_STYLE_MSGBOX,
            "Recus de paiement",
            "Vous n'avez aucun recu de paiement pour le moment.",
            "OK", "");
        return 1;
    }

    new lines[15][160];
    new count = 0;
    new line[160];
    while(fread(f, line))
    {
        if(count < 15)
        {
            format(lines[count], 160, "%s", line);
            count++;
        }
        else
        {
            // Decale le buffer pour ne garder que les 15 plus recents
            for(new i = 0; i < 14; i++) format(lines[i], 160, "%s", lines[i + 1]);
            format(lines[14], 160, "%s", line);
        }
    }
    fclose(f);

    if(count == 0)
    {
        ShowPlayerDialog(playerid, DIALOG_PAPIERS_RECUS, DIALOG_STYLE_MSGBOX,
            "Recus de paiement",
            "Vous n'avez aucun recu de paiement pour le moment.",
            "OK", "");
        return 1;
    }

    new msg[1200];
    msg[0] = 0;
    for(new i = 0; i < count; i++)
    {
        new type[32], montant[16], date[24], desc[64];
        sscanf_receipt(lines[i], type, montant, date, desc);
        new entry[160];
        format(entry, sizeof(entry), "{FFFF00}%s{FFFFFF} - %s$ - %s\n{888888}%s{FFFFFF}\n", type, montant, date, desc);
        strcat(msg, entry, sizeof(msg));
    }

    ShowPlayerDialog(playerid, DIALOG_PAPIERS_RECUS, DIALOG_STYLE_MSGBOX,
        "Recus de paiement (15 derniers)",
        msg,
        "OK", "");
    return 1;
}

// Decoupe une ligne de recu "Type|Montant|Date|Description" en 4 champs
stock sscanf_receipt(const line[], type[], montant[], date[], desc[])
{
    new parts[4][64];
    new idx = 0, partIdx = 0, len = strlen(line);
    for(new i = 0; i < len; i++)
    {
        if(line[i] == '|' && partIdx < 3)
        {
            parts[partIdx][idx] = 0;
            partIdx++;
            idx = 0;
        }
        else
        {
            if(idx < 63) { parts[partIdx][idx] = line[i]; idx++; }
        }
    }
    parts[partIdx][idx] = 0;

    format(type, 32, "%s", parts[0]);
    format(montant, 16, "%s", parts[1]);
    format(date, 24, "%s", parts[2]);
    format(desc, 64, "%s", parts[3]);
    return 1;
}

// ------------------------------------------------------------
//  Affiche le menu principal des papiers / documents du joueur.
// ------------------------------------------------------------
stock ShowPapiersMenu(playerid)
{
    ShowPlayerDialog(playerid, DIALOG_PAPIERS, DIALOG_STYLE_LIST,
        "Mes papiers",
        "Carte d'identite\nPermis de conduire\nPort d'armes\nRecus de paiement",
        "Choisir", "Fermer");
    return 1;
}

// ------------------------------------------------------------
//  Detruit la carte TextDraw actuellement affichee pour un joueur,
//  s'il y en a une. A appeler avant d'en afficher une nouvelle,
//  a la deconnexion, et quand le joueur clique sur "Fermer".
// ------------------------------------------------------------
stock DestroyCardTD(playerid)
{
    if(!gCardTDShown[playerid]) return 0;

    for(new i = 0; i < MAX_CARD_TD; i++)
    {
        if(gCardTD[playerid][i] != PlayerText:INVALID_TEXT_DRAW)
        {
            PlayerTextDrawDestroy(playerid, gCardTD[playerid][i]);
            gCardTD[playerid][i] = PlayerText:INVALID_TEXT_DRAW;
        }
    }
    gCardTDShown[playerid] = false;
    return 1;
}

// ------------------------------------------------------------
//  Affiche un document (carte d'identite / permis / port d'armes)
//  sous forme de carte TextDraw stylee, avec l'apparence du joueur
//  en apercu (comme une photo) et un bouton de fermeture cliquable.
//
//  previewmodel = skin du joueur a afficher en "photo" (-1 pour aucun)
// ------------------------------------------------------------
stock ShowDocumentCard(playerid, const cardTitle[], const cardLine1[], const cardLine2[], const cardLine3[], const cardLine4[], previewmodel)
{
    DestroyCardTD(playerid); // Evite les doublons si une carte est deja affichee

    // 0: fond principal de la carte
    gCardTD[playerid][0] = CreatePlayerTextDraw(playerid, 180.0, 140.0, "_");
    PlayerTextDrawTextSize(playerid, gCardTD[playerid][0], 460.0, 340.0);
    PlayerTextDrawUseBox(playerid, gCardTD[playerid][0], 1);
    PlayerTextDrawBoxColor(playerid, gCardTD[playerid][0], 0x1B1B1BE6);
    PlayerTextDrawColor(playerid, gCardTD[playerid][0], 0x00000000);

    // 1: bandeau superieur (accent dore, style carte officielle)
    gCardTD[playerid][1] = CreatePlayerTextDraw(playerid, 180.0, 140.0, "_");
    PlayerTextDrawTextSize(playerid, gCardTD[playerid][1], 460.0, 162.0);
    PlayerTextDrawUseBox(playerid, gCardTD[playerid][1], 1);
    PlayerTextDrawBoxColor(playerid, gCardTD[playerid][1], 0xC8A951FF);
    PlayerTextDrawColor(playerid, gCardTD[playerid][1], 0x00000000);

    // 2: titre du document
    gCardTD[playerid][2] = CreatePlayerTextDraw(playerid, 190.0, 145.0, cardTitle);
    PlayerTextDrawFont(playerid, gCardTD[playerid][2], 2);
    PlayerTextDrawLetterSize(playerid, gCardTD[playerid][2], 0.28, 1.2);
    PlayerTextDrawColor(playerid, gCardTD[playerid][2], 0x000000FF);
    PlayerTextDrawSetShadow(playerid, gCardTD[playerid][2], 0);

    // 3: cadre de la "photo" (apparence du joueur)
    gCardTD[playerid][3] = CreatePlayerTextDraw(playerid, 190.0, 172.0, "_");
    PlayerTextDrawTextSize(playerid, gCardTD[playerid][3], 270.0, 300.0);
    PlayerTextDrawUseBox(playerid, gCardTD[playerid][3], 1);
    PlayerTextDrawBoxColor(playerid, gCardTD[playerid][3], 0x00000090);
    PlayerTextDrawColor(playerid, gCardTD[playerid][3], 0x00000000);

    // 4: apercu 3D de l'apparence du joueur (fait office de photo)
    gCardTD[playerid][4] = CreatePlayerTextDraw(playerid, 190.0, 172.0, "_");
    PlayerTextDrawTextSize(playerid, gCardTD[playerid][4], 270.0, 300.0);
    if(previewmodel != -1)
    {
        PlayerTextDrawSetPreviewModel(playerid, gCardTD[playerid][4], previewmodel);
        PlayerTextDrawSetPreviewRot(playerid, gCardTD[playerid][4], 0.0, 0.0, 0.0, 1.0);
    }

    // 5: bloc des informations (nom, numero, date, statut)
    new fields[256];
    format(fields, sizeof(fields), "%s~n~~n~%s~n~~n~%s~n~~n~%s", cardLine1, cardLine2, cardLine3, cardLine4);
    gCardTD[playerid][5] = CreatePlayerTextDraw(playerid, 300.0, 175.0, fields);
    PlayerTextDrawFont(playerid, gCardTD[playerid][5], 1);
    PlayerTextDrawLetterSize(playerid, gCardTD[playerid][5], 0.22, 1.3);
    PlayerTextDrawColor(playerid, gCardTD[playerid][5], 0xFFFFFFFF);
    PlayerTextDrawSetShadow(playerid, gCardTD[playerid][5], 0);

    // 6: mention en bas de carte
    gCardTD[playerid][6] = CreatePlayerTextDraw(playerid, 190.0, 455.0, "Californie RP - Document officiel");
    PlayerTextDrawFont(playerid, gCardTD[playerid][6], 1);
    PlayerTextDrawLetterSize(playerid, gCardTD[playerid][6], 0.15, 0.8);
    PlayerTextDrawColor(playerid, gCardTD[playerid][6], 0x888888FF);

    // 7: bouton de fermeture (cadre rouge cliquable)
    gCardTD[playerid][7] = CreatePlayerTextDraw(playerid, 615.0, 145.0, "_");
    PlayerTextDrawTextSize(playerid, gCardTD[playerid][7], 640.0, 162.0);
    PlayerTextDrawUseBox(playerid, gCardTD[playerid][7], 1);
    PlayerTextDrawBoxColor(playerid, gCardTD[playerid][7], 0xAA0000FF);
    PlayerTextDrawColor(playerid, gCardTD[playerid][7], 0x00000000);
    PlayerTextDrawSetSelectable(playerid, gCardTD[playerid][7], 1);

    // 8: croix du bouton de fermeture
    gCardTD[playerid][8] = CreatePlayerTextDraw(playerid, 620.0, 148.0, "X");
    PlayerTextDrawFont(playerid, gCardTD[playerid][8], 1);
    PlayerTextDrawLetterSize(playerid, gCardTD[playerid][8], 0.3, 1.2);
    PlayerTextDrawColor(playerid, gCardTD[playerid][8], 0xFFFFFFFF);
    PlayerTextDrawSetSelectable(playerid, gCardTD[playerid][8], 1);

    for(new i = 0; i < MAX_CARD_TD; i++)
    {
        PlayerTextDrawShow(playerid, gCardTD[playerid][i]);
    }
    gCardTDShown[playerid] = true;

    SelectTextDraw(playerid, 0xFFFFFFAA);
    return 1;
}

// ------------------------------------------------------------
//  Gere le clic sur le bouton "Fermer" (ou la touche ECHAP) de
//  la carte de document affichee.
// ------------------------------------------------------------
public OnPlayerClickPlayerTextDraw(playerid, PlayerText:playertextid)
{
    if(!gCardTDShown[playerid]) return 0;

    if(playertextid == gCardTD[playerid][7] || playertextid == gCardTD[playerid][8] || playertextid == PlayerText:INVALID_TEXT_DRAW)
    {
        CancelSelectTextDraw(playerid);
        DestroyCardTD(playerid);
    }
    return 1;
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
                "{FF0000}Votre mot de passe doit contenir au moins 4 caracteres !\n{FFFFFF}Choisissez un mot de passe pour creer votre compte :",
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
            format(line, sizeof(line), "IDNum=%d\r\n", 100000 + random(900000));
            fwrite(f, line);
            format(line, sizeof(line), "DateNaissance=01/01/1990\r\n");
            fwrite(f, line);
            format(line, sizeof(line), "PermisConduire=0\r\n");
            fwrite(f, line);
            format(line, sizeof(line), "PortArme=0\r\n");
            fwrite(f, line);
            fclose(f);
        }

        SendClientMessage(playerid, COLOR_GREEN, "Votre compte a ete cree avec succes ! Vous etes maintenant connecte.");
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
            SendClientMessage(playerid, COLOR_GREEN, "Connexion reussie ! Bienvenue sur Californie RP.");
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
                SendClientMessage(playerid, COLOR_RED, "Trop de tentatives echouees. Vous etes expulse.");
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
            // Le joueur doit choisir : on reaffiche le menu
            ShowSpawnSelectionDialog(playerid);
            return 1;
        }

        switch(listitem)
        {
            case 0: // Spawn a ma maison
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
                    SendClientMessage(playerid, COLOR_RED, "Vous ne possedez aucune propriete enregistree. Spawn par defaut utilise.");
                    SetDefaultSpawnPos(playerid);
                }
            }
            case 1: // Derniere position (deja chargee dans PlayerInfo via LoadUserData)
            {
                // Rien a faire : pPosX/Y/Z/A/Int/World contiennent deja la derniere position sauvegardee
            }
            case 2: // Spawn par defaut
            {
                SetDefaultSpawnPos(playerid);
            }
        }

        SpawnPlayerAfterLogin(playerid);
        return 1;
    }

    if(dialogid == DIALOG_CLIMAT)
    {
        if(!response) return 1; // Annule

        new str[96];
        ApplyClimate(listitem);
        format(str, sizeof(str), "Climat change en : %s.", gClimateName[listitem]);
        SendClientMessage(playerid, COLOR_GREEN, str);
        return 1;
    }

    if(dialogid == DIALOG_PAPIERS)
    {
        if(!response) return 1; // Ferme

        new name[MAX_PLAYER_NAME];
        GetPlayerName(playerid, name, sizeof(name));

        if(listitem == 0) // Carte d'identite
        {
            new l1[64], l2[64], l3[64], l4[64];
            format(l1, sizeof(l1), "Nom : %s", name);
            format(l2, sizeof(l2), "Numero : %d", PlayerInfo[playerid][pIDNum]);
            format(l3, sizeof(l3), "Naissance : %s", PlayerInfo[playerid][pDateNaissance]);
            format(l4, sizeof(l4), "Statut : Valide");
            ShowDocumentCard(playerid, "Carte d'identite", l1, l2, l3, l4, GetPlayerSkin(playerid));
        }
        else if(listitem == 1) // Permis de conduire
        {
            new l1[64], l2[64], l3[64], l4[64];
            format(l1, sizeof(l1), "Titulaire : %s", name);
            if(PlayerInfo[playerid][pPermisConduire])
            {
                format(l2, sizeof(l2), "Categorie : B");
                format(l3, sizeof(l3), "Statut : Valide");
            }
            else
            {
                format(l2, sizeof(l2), "Statut : NON POSSEDE");
                format(l3, sizeof(l3), "");
            }
            format(l4, sizeof(l4), "");
            ShowDocumentCard(playerid, "Permis de conduire", l1, l2, l3, l4, GetPlayerSkin(playerid));
        }
        else if(listitem == 2) // Port d'armes
        {
            new l1[64], l2[64], l3[64], l4[64];
            format(l1, sizeof(l1), "Titulaire : %s", name);
            if(PlayerInfo[playerid][pPortArme])
            {
                format(l2, sizeof(l2), "Statut : Valide");
            }
            else
            {
                format(l2, sizeof(l2), "Statut : NON POSSEDE");
            }
            format(l3, sizeof(l3), "");
            format(l4, sizeof(l4), "");
            ShowDocumentCard(playerid, "Port d'armes", l1, l2, l3, l4, GetPlayerSkin(playerid));
        }
        else if(listitem == 3) // Recus de paiement
        {
            ShowReceipts(playerid);
        }
        return 1;
    }

    if(dialogid == DIALOG_PAPIERS_RECUS)
    {
        return 1;
    }
    return 0;
}

// ==============================================================
//  Finalisation de la connexion : logs admin, VIP, choix du spawn
// ==============================================================
stock FinalizeLogin(playerid)
{
    // --- Log admin : notifie les administrateurs connectes ---
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

    // --- Verification de l'abonnement VIP ---
    if(PlayerInfo[playerid][pVipExpire] > 0 && PlayerInfo[playerid][pVipExpire] < gettime())
    {
        SendClientMessage(playerid, COLOR_YELLOW, "Votre abonnement donateur a expire. Vous n'etes plus VIP.");
        PlayerInfo[playerid][pVipExpire] = 0;
    }

    // --- Selection du point d'apparition ---
    ShowSpawnSelectionDialog(playerid);
    return 1;
}

public ShowSpawnSelectionDialog(playerid)
{
    new items[256];
    format(items, sizeof(items),
        "Spawn a ma maison%s\n\
Derniere position\n\
Spawn par defaut",
        PlayerInfo[playerid][pHomeSet] ? "" : " {888888}(aucune propriete){FFFFFF}");

    ShowPlayerDialog(playerid, DIALOG_SPAWNCHOICE, DIALOG_STYLE_LIST,
        "Ou voulez-vous spawn ?",
        items,
        "Choisir", "");
    return 1;
}

// Coordonnees de spawn par defaut du serveur (ex : Aeroport / Gare Californie RP)
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

// Petit parseur "cle=valeur" fait maison (pas de dependance externe type sscanf)
stock sscanf_simple(line[], key[], val[])
{
    new pos = strfind(line, "=", false);
    if(pos == -1) return 0;
    strmid(key, line, 0, pos);
    strmid(val, line, pos + 1, strlen(line));
    // Retirer les retours a la ligne eventuels
    new len = strlen(val);
    while(len > 0 && (val[len-1] == '\r' || val[len-1] == '\n'))
    {
        val[len-1] = '\0';
        len--;
    }
    return 1;
}

// ==============================================================
//  Sauvegarde / Chargement des donnees
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
            else if(!strcmp(key, "IDNum")) PlayerInfo[playerid][pIDNum] = strval(val);
            else if(!strcmp(key, "DateNaissance")) format(PlayerInfo[playerid][pDateNaissance], 11, "%s", val);
            else if(!strcmp(key, "PermisConduire")) PlayerInfo[playerid][pPermisConduire] = strval(val);
            else if(!strcmp(key, "PortArme")) PlayerInfo[playerid][pPortArme] = strval(val);
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
        format(outLine, sizeof(outLine), "IDNum=%d\r\n", PlayerInfo[playerid][pIDNum]); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "DateNaissance=%s\r\n", PlayerInfo[playerid][pDateNaissance]); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "PermisConduire=%d\r\n", PlayerInfo[playerid][pPermisConduire]); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "PortArme=%d\r\n", PlayerInfo[playerid][pPortArme]); fwrite(fw, outLine);
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
    SendClientMessage(playerid, COLOR_SERVER, "Tapez /aide pour voir la liste des commandes disponibles.");
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

    // Laisser SA-MP gerer nativement /rcon (login, commandes admin console).
    // Sans ce return 0, notre script intercepterait la commande et empecherait
    // le serveur de la traiter, provoquant un faux "Commande inconnue".
    if(!strcmp(cmd, "/rcon", true))
    {
        return 0;
    }

    if(!IsLoggedIn[playerid])
    {
        SendClientMessage(playerid, COLOR_RED, "Vous devez etre connecte pour utiliser des commandes.");
        return 1;
    }

    if(!strcmp(cmd, "/aide", true))
    {
        SendClientMessage(playerid, COLOR_YELLOW, "== Commandes Californie RP ==");
        SendClientMessage(playerid, COLOR_WHITE, "/me /do /ooc - Roleplay");
        SendClientMessage(playerid, COLOR_WHITE, "/stats /cash - Informations personnelles");
        SendClientMessage(playerid, COLOR_WHITE, "/sethome - Enregistrer votre position comme domicile");
        SendClientMessage(playerid, COLOR_WHITE, "/car - Faire apparaitre un vehicule");
        SendClientMessage(playerid, COLOR_WHITE, "/engine /lock - Interagir avec un vehicule");
        SendClientMessage(playerid, COLOR_WHITE, "/papiers - Voir votre carte d'identite, permis, port d'armes et recus");
        if(PlayerInfo[playerid][pAdmin] > 0)
        {
            SendClientMessage(playerid, COLOR_ADMIN, "Tapez /aideadmin pour la liste des commandes admin/dev.");
        }
        return 1;
    }

    if(!strcmp(cmd, "/aideadmin", true))
    {
        if(PlayerInfo[playerid][pAdmin] <= 0)
        {
            SendClientMessage(playerid, COLOR_RED, "Cette commande est reservee aux administrateurs.");
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
        SendClientMessage(playerid, COLOR_GREEN, "Votre position actuelle a ete enregistree comme domicile.");
        return 1;
    }

    if(!strcmp(cmd, "/me", true))
    {
        if(gMuted[playerid]) return SendClientMessage(playerid, COLOR_RED, "Vous etes muet.");
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
        if(gMuted[playerid]) return SendClientMessage(playerid, COLOR_RED, "Vous etes muet.");
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
        if(gMuted[playerid]) return SendClientMessage(playerid, COLOR_RED, "Vous etes muet.");
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
        format(str, sizeof(str), "Vous possedez $%d", GetPlayerMoney(playerid));
        SendClientMessage(playerid, COLOR_GREEN, str);
        return 1;
    }

    if(!strcmp(cmd, "/car", true))
    {
        new Float:x, Float:y, Float:z, Float:a;
        GetPlayerPos(playerid, x, y, z);
        GetPlayerFacingAngle(playerid, a);
        CreateVehicle(411, x + 2.0, y, z, a, -1, -1, -1, false);
        SendClientMessage(playerid, COLOR_GREEN, "Un vehicule est apparu pres de vous.");
        return 1;
    }

    if(!strcmp(cmd, "/papiers", true))
    {
        ShowPapiersMenu(playerid);
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
            SendClientMessage(playerid, COLOR_GREEN, engine ? "Vous demarrez le moteur." : "Vous coupez le moteur.");
        }
        else
        {
            SendClientMessage(playerid, COLOR_RED, "Vous n'etes pas dans un vehicule.");
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
            SendClientMessage(playerid, COLOR_GREEN, doors ? "Vehicule verrouille." : "Vehicule deverrouille.");
        }
        else
        {
            SendClientMessage(playerid, COLOR_RED, "Vous n'etes pas dans un vehicule.");
        }
        return 1;
    }

    // --- Connexion developpeur (elevation en jeu, distincte du RCON natif SA-MP) ---
    if(!strcmp(cmd, "/connexiondev", true))
    {
        tmp = strtok_(cmdtext, idx);
        if(!strlen(tmp))
        {
            SendClientMessage(playerid, COLOR_RED, "Utilisation : /connexiondev [mot de passe]");
            return 1;
        }
        if(udb_hash(tmp) == DEV_LOGIN_HASH)
        {
            PlayerInfo[playerid][pAdmin] = ADMIN_LEVEL_DEV;
            SendClientMessage(playerid, COLOR_ADMIN, "Connexion developpeur reussie.");
        }
        else
        {
            SendClientMessage(playerid, COLOR_RED, "Mot de passe incorrect.");
        }
        return 1;
    }

    // --- Commandes Admin / Dev ---
    new adminCanon[24], adminLevel;
    if(ResolveAdminCmd(cmd, adminCanon, adminLevel))
    {
        if(PlayerInfo[playerid][pAdmin] < adminLevel)
        {
            SendClientMessage(playerid, COLOR_RED, "Vous n'etes pas autorise a utiliser cette commande.");
            return 1;
        }
        ExecuteAdminCmd(playerid, adminCanon, cmdtext, idx);
        return 1;
    }

    SendClientMessage(playerid, COLOR_RED, "Commande inconnue. Tapez /aide.");
    return 1;
}

// ==============================================================
//  Systeme Admin / Dev
//  Niveaux : 1 Helper, 2 Moderateur, 3 Admin,
//            10 Admin Superieur, 20 Admin Superviseur,
//            5885 Developpeur
// ==============================================================

// Fait correspondre une commande FR a un identifiant canonique + niveau requis.
// Retourne 1 si trouve, 0 sinon.
stock ResolveAdminCmd(cmd[], canon[24], &level)
{
    // --- Niveau 1 : Helper ---
    if(!strcmp(cmd, "/geler", true)) { canon = "FREEZE"; level = ADMIN_LEVEL_HELPER; return 1; }
    if(!strcmp(cmd, "/degeler", true)) { canon = "UNFREEZE"; level = ADMIN_LEVEL_HELPER; return 1; }
    if(!strcmp(cmd, "/muet", true)) { canon = "MUTE"; level = ADMIN_LEVEL_HELPER; return 1; }
    if(!strcmp(cmd, "/demuet", true)) { canon = "UNMUTE"; level = ADMIN_LEVEL_HELPER; return 1; }
    if(!strcmp(cmd, "/avertir", true)) { canon = "WARN"; level = ADMIN_LEVEL_HELPER; return 1; }
    if(!strcmp(cmd, "/observer", true)) { canon = "SPEC"; level = ADMIN_LEVEL_HELPER; return 1; }
    if(!strcmp(cmd, "/finobserver", true)) { canon = "SPECOFF"; level = ADMIN_LEVEL_HELPER; return 1; }
    if(!strcmp(cmd, "/prison", true)) { canon = "JAIL"; level = ADMIN_LEVEL_HELPER; return 1; }
    if(!strcmp(cmd, "/liberer", true)) { canon = "UNJAIL"; level = ADMIN_LEVEL_HELPER; return 1; }

    // --- Niveau 2 : Moderateur ---
    if(!strcmp(cmd, "/expulser", true)) { canon = "KICK"; level = ADMIN_LEVEL_MOD; return 1; }
    if(!strcmp(cmd, "/gifler", true)) { canon = "SLAP"; level = ADMIN_LEVEL_MOD; return 1; }
    if(!strcmp(cmd, "/soigner", true)) { canon = "HEAL"; level = ADMIN_LEVEL_MOD; return 1; }
    if(!strcmp(cmd, "/armure", true)) { canon = "ARMOR"; level = ADMIN_LEVEL_MOD; return 1; }
    if(!strcmp(cmd, "/allerA", true)) { canon = "GOTO"; level = ADMIN_LEVEL_MOD; return 1; }
    if(!strcmp(cmd, "/amener", true)) { canon = "GETHERE"; level = ADMIN_LEVEL_MOD; return 1; }
    if(!strcmp(cmd, "/climat", true)) { canon = "CLIMAT"; level = ADMIN_LEVEL_MOD; return 1; }
    if(!strcmp(cmd, "/definirpermis", true)) { canon = "DEFPERMIS"; level = ADMIN_LEVEL_MOD; return 1; }
    if(!strcmp(cmd, "/definirport", true)) { canon = "DEFPORT"; level = ADMIN_LEVEL_MOD; return 1; }
    if(!strcmp(cmd, "/amende", true)) { canon = "AMENDE"; level = ADMIN_LEVEL_MOD; return 1; }
    if(!strcmp(cmd, "/fourriere", true)) { canon = "FOURRIERE"; level = ADMIN_LEVEL_MOD; return 1; }

    // --- Niveau 3 : Admin ---
    if(!strcmp(cmd, "/bannir", true)) { canon = "BAN"; level = ADMIN_LEVEL_ADMIN; return 1; }
    if(!strcmp(cmd, "/debannir", true)) { canon = "UNBAN"; level = ADMIN_LEVEL_ADMIN; return 1; }
    if(!strcmp(cmd, "/apparence", true)) { canon = "SETSKIN"; level = ADMIN_LEVEL_ADMIN; return 1; }
    if(!strcmp(cmd, "/armes", true)) { canon = "WEAPONS"; level = ADMIN_LEVEL_ADMIN; return 1; }
    if(!strcmp(cmd, "/dieu", true)) { canon = "GOD"; level = ADMIN_LEVEL_ADMIN; return 1; }

    // --- Niveau 10 : Admin Superieur ---
    if(!strcmp(cmd, "/argent", true)) { canon = "SETCASH"; level = ADMIN_LEVEL_SUPERIOR; return 1; }
    if(!strcmp(cmd, "/donnerargent", true)) { canon = "GIVECASH"; level = ADMIN_LEVEL_SUPERIOR; return 1; }
    if(!strcmp(cmd, "/vip", true)) { canon = "SETVIP"; level = ADMIN_LEVEL_SUPERIOR; return 1; }
    if(!strcmp(cmd, "/niveau", true)) { canon = "SETLEVEL"; level = ADMIN_LEVEL_SUPERIOR; return 1; }

    // --- Niveau 20 : Admin Superviseur ---
    if(!strcmp(cmd, "/definiradmin", true)) { canon = "SETADMIN"; level = ADMIN_LEVEL_SUPERVISOR; return 1; }
    if(!strcmp(cmd, "/annonce", true)) { canon = "ANNOUNCE"; level = ADMIN_LEVEL_SUPERVISOR; return 1; }

    // --- Niveau 5885 : Developpeur ---
    if(!strcmp(cmd, "/heure", true)) { canon = "SETTIME"; level = ADMIN_LEVEL_DEV; return 1; }
    if(!strcmp(cmd, "/meteo", true)) { canon = "SETWEATHER"; level = ADMIN_LEVEL_DEV; return 1; }
    if(!strcmp(cmd, "/donnerarme", true)) { canon = "GIVEWEAPON"; level = ADMIN_LEVEL_DEV; return 1; }
    if(!strcmp(cmd, "/allercoord", true)) { canon = "GOTOXYZ"; level = ADMIN_LEVEL_DEV; return 1; }
    if(!strcmp(cmd, "/redemarrer", true)) { canon = "GMX"; level = ADMIN_LEVEL_DEV; return 1; }
    if(!strcmp(cmd, "/cmdrcon", true)) { canon = "RCONCMD"; level = ADMIN_LEVEL_DEV; return 1; }

    return 0;
}

// Execute la commande admin/dev canonique deja validee (niveau verifie en amont).
stock ExecuteAdminCmd(playerid, canon[], cmdtext[], idx)
{
    new tmp[64], tmp2[64], targetid, str[144], name[MAX_PLAYER_NAME], tname[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof(name));

    if(!strcmp(canon, "FREEZE"))
    {
        tmp = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        if(!strlen(tmp) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation : /geler [id]");
        gFrozen[targetid] = 1;
        TogglePlayerControllable(targetid, false);
        SendClientMessage(targetid, COLOR_RED, "Vous avez ete gele par un admin.");
        SendClientMessage(playerid, COLOR_GREEN, "Joueur gele.");
    }
    else if(!strcmp(canon, "UNFREEZE"))
    {
        tmp = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        if(!strlen(tmp) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation : /degeler [id]");
        gFrozen[targetid] = 0;
        TogglePlayerControllable(targetid, true);
        SendClientMessage(targetid, COLOR_GREEN, "Vous avez ete degele.");
        SendClientMessage(playerid, COLOR_GREEN, "Joueur degele.");
    }
    else if(!strcmp(canon, "MUTE"))
    {
        tmp = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        if(!strlen(tmp) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation : /muet [id]");
        gMuted[targetid] = 1;
        SendClientMessage(targetid, COLOR_RED, "Vous avez ete reduit au silence.");
        SendClientMessage(playerid, COLOR_GREEN, "Joueur muet.");
    }
    else if(!strcmp(canon, "UNMUTE"))
    {
        tmp = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        if(!strlen(tmp) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation : /demuet [id]");
        gMuted[targetid] = 0;
        SendClientMessage(targetid, COLOR_GREEN, "Vous pouvez de nouveau parler.");
        SendClientMessage(playerid, COLOR_GREEN, "Joueur demute.");
    }
    else if(!strcmp(canon, "WARN"))
    {
        tmp = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        tmp2 = strtok_(cmdtext, idx);
        if(!strlen(tmp) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation : /avertir [id] [raison]");
        format(str, sizeof(str), "Vous avez recu un avertissement : %s", tmp2);
        SendClientMessage(targetid, COLOR_RED, str);
        SendClientMessage(playerid, COLOR_GREEN, "Avertissement envoye.");
    }
    else if(!strcmp(canon, "SPEC"))
    {
        tmp = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        if(!strlen(tmp) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation : /observer [id]");
        new Float:x, Float:y, Float:z;
        GetPlayerPos(targetid, x, y, z);
        SetPlayerInterior(playerid, GetPlayerInterior(targetid));
        SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(targetid));
        SetPlayerPos(playerid, x, y, z + 2.0);
        SendClientMessage(playerid, COLOR_GREEN, "Mode observateur active.");
    }
    else if(!strcmp(canon, "SPECOFF"))
    {
        SetPlayerInterior(playerid, PlayerInfo[playerid][pInt]);
        SetPlayerVirtualWorld(playerid, PlayerInfo[playerid][pWorld]);
        SetPlayerPos(playerid, PlayerInfo[playerid][pPosX], PlayerInfo[playerid][pPosY], PlayerInfo[playerid][pPosZ]);
        SendClientMessage(playerid, COLOR_GREEN, "Mode observateur desactive.");
    }
    else if(!strcmp(canon, "JAIL"))
    {
        tmp = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        if(!strlen(tmp) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation : /prison [id]");
        gJailed[targetid] = 1;
        SetPlayerPos(targetid, 264.6, 77.4, 1001.0);
        SetPlayerInterior(targetid, 6);
        SetPlayerVirtualWorld(targetid, 0);
        SendClientMessage(targetid, COLOR_RED, "Vous avez ete emprisonne.");
        SendClientMessage(playerid, COLOR_GREEN, "Joueur emprisonne.");
    }
    else if(!strcmp(canon, "UNJAIL"))
    {
        tmp = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        if(!strlen(tmp) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation : /liberer [id]");
        gJailed[targetid] = 0;
        SetDefaultSpawnPos(targetid);
        SetPlayerPos(targetid, PlayerInfo[targetid][pPosX], PlayerInfo[targetid][pPosY], PlayerInfo[targetid][pPosZ]);
        SetPlayerInterior(targetid, PlayerInfo[targetid][pInt]);
        SetPlayerVirtualWorld(targetid, PlayerInfo[targetid][pWorld]);
        SendClientMessage(targetid, COLOR_GREEN, "Vous avez ete libere.");
        SendClientMessage(playerid, COLOR_GREEN, "Joueur libere.");
    }
    else if(!strcmp(canon, "KICK"))
    {
        tmp = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        if(!strlen(tmp) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation : /expulser [id]");
        GetPlayerName(targetid, tname, sizeof(tname));
        format(str, sizeof(str), "%s a expulse %s du serveur.", name, tname);
        SendClientMessageToAll(COLOR_ADMIN, str);
        Kick(targetid);
    }
    else if(!strcmp(canon, "SLAP"))
    {
        tmp = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        if(!strlen(tmp) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation : /gifler [id]");
        new Float:x, Float:y, Float:z;
        GetPlayerPos(targetid, x, y, z);
        SetPlayerPos(targetid, x, y, z + 5.0);
        SendClientMessage(targetid, COLOR_RED, "Vous avez ete gifle par un admin.");
        SendClientMessage(playerid, COLOR_GREEN, "Joueur gifle.");
    }
    else if(!strcmp(canon, "HEAL"))
    {
        tmp = strtok_(cmdtext, idx);
        targetid = strlen(tmp) ? strval(tmp) : playerid;
        if(!IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Joueur introuvable.");
        SetPlayerHealth(targetid, 100.0);
        SendClientMessage(targetid, COLOR_GREEN, "Vous avez ete soigne.");
        SendClientMessage(playerid, COLOR_GREEN, "Soin applique.");
    }
    else if(!strcmp(canon, "ARMOR"))
    {
        tmp = strtok_(cmdtext, idx);
        targetid = strlen(tmp) ? strval(tmp) : playerid;
        if(!IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Joueur introuvable.");
        SetPlayerArmour(targetid, 100.0);
        SendClientMessage(targetid, COLOR_GREEN, "Vous avez recu un gilet pare-balles.");
        SendClientMessage(playerid, COLOR_GREEN, "Gilet donne.");
    }
    else if(!strcmp(canon, "GOTO"))
    {
        tmp = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        if(!strlen(tmp) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation : /allerA [id]");
        new Float:x, Float:y, Float:z;
        GetPlayerPos(targetid, x, y, z);
        SetPlayerInterior(playerid, GetPlayerInterior(targetid));
        SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(targetid));
        SetPlayerPos(playerid, x, y, z);
        SendClientMessage(playerid, COLOR_GREEN, "Teleportation effectuee.");
    }
    else if(!strcmp(canon, "GETHERE"))
    {
        tmp = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        if(!strlen(tmp) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation : /amener [id]");
        new Float:x, Float:y, Float:z;
        GetPlayerPos(playerid, x, y, z);
        SetPlayerInterior(targetid, GetPlayerInterior(playerid));
        SetPlayerVirtualWorld(targetid, GetPlayerVirtualWorld(playerid));
        SetPlayerPos(targetid, x, y, z);
        SendClientMessage(targetid, COLOR_YELLOW, "Vous avez ete teleporte par un admin.");
        SendClientMessage(playerid, COLOR_GREEN, "Joueur teleporte a vous.");
    }
    else if(!strcmp(canon, "CLIMAT"))
    {
        ShowClimateMenu(playerid);
    }
    else if(!strcmp(canon, "DEFPERMIS"))
    {
        tmp = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        tmp2 = strtok_(cmdtext, idx);
        if(!strlen(tmp) || !strlen(tmp2) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation : /definirpermis [id] [0/1]");
        PlayerInfo[targetid][pPermisConduire] = strval(tmp2);
        if(PlayerInfo[targetid][pPermisConduire])
        {
            SendClientMessage(targetid, COLOR_GREEN, "Vous avez obtenu votre permis de conduire.");
            SendClientMessage(playerid, COLOR_GREEN, "Permis de conduire accorde.");
        }
        else
        {
            SendClientMessage(targetid, COLOR_RED, "Votre permis de conduire vous a ete retire.");
            SendClientMessage(playerid, COLOR_GREEN, "Permis de conduire retire.");
        }
    }
    else if(!strcmp(canon, "DEFPORT"))
    {
        tmp = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        tmp2 = strtok_(cmdtext, idx);
        if(!strlen(tmp) || !strlen(tmp2) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation : /definirport [id] [0/1]");
        PlayerInfo[targetid][pPortArme] = strval(tmp2);
        if(PlayerInfo[targetid][pPortArme])
        {
            SendClientMessage(targetid, COLOR_GREEN, "Vous avez obtenu votre port d'armes.");
            SendClientMessage(playerid, COLOR_GREEN, "Port d'armes accorde.");
        }
        else
        {
            SendClientMessage(targetid, COLOR_RED, "Votre port d'armes vous a ete retire.");
            SendClientMessage(playerid, COLOR_GREEN, "Port d'armes retire.");
        }
    }
    else if(!strcmp(canon, "AMENDE"))
    {
        new tmp3[64];
        tmp = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        tmp2 = strtok_(cmdtext, idx);
        tmp3 = strtok_(cmdtext, idx);
        if(!strlen(tmp) || !strlen(tmp2) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation : /amende [id] [montant] [raison]");
        if(!strlen(tmp3)) format(tmp3, sizeof(tmp3), "Non precisee");

        GivePlayerMoney(targetid, -strval(tmp2));
        AddReceipt(targetid, "Amende (PV)", strval(tmp2), tmp3);

        format(str, sizeof(str), "Vous avez recu une amende de %d$ : %s", strval(tmp2), tmp3);
        SendClientMessage(targetid, COLOR_RED, str);
        format(str, sizeof(str), "Amende de %d$ infligee. Recu ajoute au dossier du joueur.", strval(tmp2));
        SendClientMessage(playerid, COLOR_GREEN, str);
    }
    else if(!strcmp(canon, "FOURRIERE"))
    {
        tmp = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        tmp2 = strtok_(cmdtext, idx);
        if(!strlen(tmp) || !strlen(tmp2) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation : /fourriere [id] [montant]");

        GivePlayerMoney(targetid, -strval(tmp2));
        AddReceipt(targetid, "Fourriere", strval(tmp2), "Recuperation du vehicule en fourriere");

        format(str, sizeof(str), "Vous avez recupere votre vehicule en fourriere pour %d$.", strval(tmp2));
        SendClientMessage(targetid, COLOR_YELLOW, str);
        SendClientMessage(playerid, COLOR_GREEN, "Frais de fourriere prelevees. Recu ajoute au dossier du joueur.");
    }
    else if(!strcmp(canon, "BAN"))
    {
        tmp = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        if(!strlen(tmp) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation : /bannir [id]");
        GetPlayerName(targetid, tname, sizeof(tname));
        format(str, sizeof(str), "%s a banni %s du serveur.", name, tname);
        SendClientMessageToAll(COLOR_ADMIN, str);
        Ban(targetid);
    }
    else if(!strcmp(canon, "UNBAN"))
    {
        // Le deban se fait via le fichier samp.ban ou une commande RCON native ("rcon unbanip <ip>").
        SendClientMessage(playerid, COLOR_YELLOW, "Utilisez la console RCON : rcon unbanip <ip>");
    }
    else if(!strcmp(canon, "SETSKIN"))
    {
        new skinid[64];
        tmp = strtok_(cmdtext, idx);
        skinid = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        if(!strlen(tmp) || !strlen(skinid) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation : /apparence [id] [skinid]");
        SetPlayerSkin(targetid, strval(skinid));
        SendClientMessage(playerid, COLOR_GREEN, "Apparence modifiee.");
    }
    else if(!strcmp(canon, "WEAPONS"))
    {
        tmp = strtok_(cmdtext, idx);
        targetid = strlen(tmp) ? strval(tmp) : playerid;
        if(!IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Joueur introuvable.");
        GivePlayerWeapon(targetid, 24, 250); // Deagle
        GivePlayerWeapon(targetid, 31, 500); // M4
        SendClientMessage(targetid, COLOR_GREEN, "Vous avez recu des armes.");
        SendClientMessage(playerid, COLOR_GREEN, "Armes donnees.");
    }
    else if(!strcmp(canon, "GOD"))
    {
        tmp = strtok_(cmdtext, idx);
        targetid = strlen(tmp) ? strval(tmp) : playerid;
        if(!IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Joueur introuvable.");
        SetPlayerHealth(targetid, 99999.0);
        SendClientMessage(targetid, COLOR_GREEN, "Mode invincible active.");
    }
    else if(!strcmp(canon, "SETCASH"))
    {
        new amount[64];
        tmp = strtok_(cmdtext, idx);
        amount = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        if(!strlen(tmp) || !strlen(amount) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation : /argent [id] [montant]");
        ResetPlayerMoney(targetid);
        GivePlayerMoney(targetid, strval(amount));
        SendClientMessage(playerid, COLOR_GREEN, "Argent defini.");
    }
    else if(!strcmp(canon, "GIVECASH"))
    {
        new amount[64];
        tmp = strtok_(cmdtext, idx);
        amount = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        if(!strlen(tmp) || !strlen(amount) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation : /donnerargent [id] [montant]");
        GivePlayerMoney(targetid, strval(amount));
        SendClientMessage(playerid, COLOR_GREEN, "Argent donne.");
    }
    else if(!strcmp(canon, "SETVIP"))
    {
        new days[64];
        tmp = strtok_(cmdtext, idx);
        days = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        if(!strlen(tmp) || !strlen(days) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation : /vip [id] [jours]");
        PlayerInfo[targetid][pVipExpire] = gettime() + (strval(days) * 86400);
        SendClientMessage(targetid, COLOR_YELLOW, "Vous etes maintenant VIP !");
        SendClientMessage(playerid, COLOR_GREEN, "Statut VIP mis a jour.");
    }
    else if(!strcmp(canon, "SETLEVEL"))
    {
        new lvl[64];
        tmp = strtok_(cmdtext, idx);
        lvl = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        if(!strlen(tmp) || !strlen(lvl) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation : /niveau [id] [niveau]");
        if(strval(lvl) >= PlayerInfo[playerid][pAdmin]) return SendClientMessage(playerid, COLOR_RED, "Vous ne pouvez pas attribuer un niveau egal ou superieur au votre.");
        PlayerInfo[targetid][pAdmin] = strval(lvl);
        SendClientMessage(targetid, COLOR_ADMIN, "Votre niveau admin a ete modifie.");
        SendClientMessage(playerid, COLOR_GREEN, "Niveau mis a jour.");
    }
    else if(!strcmp(canon, "SETADMIN"))
    {
        new lvl[64];
        tmp = strtok_(cmdtext, idx);
        lvl = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        if(!strlen(tmp) || !strlen(lvl) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation : /definiradmin [id] [niveau]");
        if(strval(lvl) >= PlayerInfo[playerid][pAdmin]) return SendClientMessage(playerid, COLOR_RED, "Vous ne pouvez pas attribuer un niveau egal ou superieur au votre.");
        PlayerInfo[targetid][pAdmin] = strval(lvl);
        SendClientMessage(targetid, COLOR_ADMIN, "Votre niveau admin a ete modifie.");
        SendClientMessage(playerid, COLOR_GREEN, "Niveau admin mis a jour.");
    }
    else if(!strcmp(canon, "ANNOUNCE"))
    {
        idx = 0;
        tmp = strtok_(cmdtext, idx); // consomme /announce
        new msg[144];
        format(msg, sizeof(msg), "%s", cmdtext[idx]);
        format(str, sizeof(str), "[ANNONCE] %s", msg);
        SendClientMessageToAll(COLOR_YELLOW, str);
    }
    else if(!strcmp(canon, "SETTIME"))
    {
        new hour[64];
        hour = strtok_(cmdtext, idx);
        if(!strlen(hour)) return SendClientMessage(playerid, COLOR_RED, "Utilisation : /heure [heure]");
        SetWorldTime(strval(hour));
        SendClientMessage(playerid, COLOR_GREEN, "Heure du serveur modifiee.");
    }
    else if(!strcmp(canon, "SETWEATHER"))
    {
        new wid[64];
        wid = strtok_(cmdtext, idx);
        if(!strlen(wid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation : /meteo [id]");
        SetWeather(strval(wid));
        SendClientMessage(playerid, COLOR_GREEN, "Meteo du serveur modifiee.");
    }
    else if(!strcmp(canon, "GIVEWEAPON"))
    {
        new wid[64], ammo[64];
        tmp = strtok_(cmdtext, idx);
        wid = strtok_(cmdtext, idx);
        ammo = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        if(!strlen(tmp) || !strlen(wid) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation : /donnerarme [id] [armeid] [munitions]");
        GivePlayerWeapon(targetid, strval(wid), strlen(ammo) ? strval(ammo) : 100);
        SendClientMessage(playerid, COLOR_GREEN, "Arme donnee.");
    }
    else if(!strcmp(canon, "GOTOXYZ"))
    {
        new sx[64], sy[64], sz[64];
        sx = strtok_(cmdtext, idx);
        sy = strtok_(cmdtext, idx);
        sz = strtok_(cmdtext, idx);
        if(!strlen(sx) || !strlen(sy) || !strlen(sz)) return SendClientMessage(playerid, COLOR_RED, "Utilisation : /allercoord [x] [y] [z]");
        SetPlayerPos(playerid, floatstr(sx), floatstr(sy), floatstr(sz));
        SendClientMessage(playerid, COLOR_GREEN, "Teleportation effectuee.");
    }
    else if(!strcmp(canon, "GMX"))
    {
        SendClientMessageToAll(COLOR_ADMIN, "(( Redemarrage du gamemode en cours... ))");
        SendRconCommand("gmx");
    }
    else if(!strcmp(canon, "RCONCMD"))
    {
        if(cmdtext[idx] == '\0')
        {
            SendClientMessage(playerid, COLOR_RED, "Utilisation : /cmdrcon <commande> (ex: /cmdrcon banip 1.2.3.4)");
            SendClientMessage(playerid, COLOR_WHITE, "Commandes disponibles : echo, exec, cmdlist, varlist, exit, kick, ban, gmx, changemode, say, reloadbans, reloadlog, players, banip, unbanip, gravity, weather, loadfs, unloadfs, reloadfs");
            return 1;
        }
        SendRconCommand(cmdtext[idx]);

        new name[MAX_PLAYER_NAME], logmsg[192];
        GetPlayerName(playerid, name, sizeof(name));
        format(logmsg, sizeof(logmsg), "(( %s a execute la commande RCON: %s ))", name, cmdtext[idx]);
        for(new j = 0; j < MAX_PLAYERS; j++)
        {
            if(IsPlayerConnected(j) && IsLoggedIn[j] && PlayerInfo[j][pAdmin] >= ADMIN_LEVEL_SUPERVISOR)
            {
                SendClientMessage(j, COLOR_ADMIN, logmsg);
            }
        }
        SendClientMessage(playerid, COLOR_GREEN, "Commande RCON envoyee.");
    }
    return 1;
}

// Affiche la liste des commandes admin/dev disponibles selon le niveau du joueur
stock ShowAdminHelp(playerid)
{
    new lvl = PlayerInfo[playerid][pAdmin];
    SendClientMessage(playerid, COLOR_YELLOW, "== Commandes Admin ==");
    if(lvl >= ADMIN_LEVEL_HELPER)
        SendClientMessage(playerid, COLOR_WHITE, "[Helper] /geler, /degeler, /muet, /demuet, /avertir, /observer, /finobserver, /prison, /liberer");
    if(lvl >= ADMIN_LEVEL_MOD)
        SendClientMessage(playerid, COLOR_WHITE, "[Moderateur] /expulser, /gifler, /soigner, /armure, /allerA, /amener, /climat, /definirpermis, /definirport, /amende, /fourriere");
    if(lvl >= ADMIN_LEVEL_ADMIN)
        SendClientMessage(playerid, COLOR_WHITE, "[Admin] /bannir, /debannir, /apparence, /armes, /dieu");
    if(lvl >= ADMIN_LEVEL_SUPERIOR)
        SendClientMessage(playerid, COLOR_WHITE, "[Admin Sup.] /argent, /donnerargent, /vip, /niveau");
    if(lvl >= ADMIN_LEVEL_SUPERVISOR)
        SendClientMessage(playerid, COLOR_WHITE, "[Superviseur] /definiradmin, /annonce");
    if(lvl >= ADMIN_LEVEL_DEV)
        SendClientMessage(playerid, COLOR_ADMIN, "[Developpeur] /heure, /meteo, /donnerarme, /allercoord, /redemarrer, /cmdrcon (acces complet RCON)");
    return 1;
}

// Petit tokenizer maison (evite une dependance externe)
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
//  Autres callbacks necessaires
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
        SendClientMessage(playerid, COLOR_RED, "Vous etes muet et ne pouvez pas parler.");
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
//  Pont RCON natif <-> systeme de niveaux admin du script
//  Le login RCON lui-meme est gere nativement par SA-MP
//  (server.cfg -> rcon_password, puis "/rcon login <motdepasse>" en jeu).
//  Ce callback detecte une connexion RCON reussie et l'associe
//  automatiquement au niveau Developpeur dans notre systeme.
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

                SendClientMessage(i, COLOR_ADMIN, "Connexion RCON reussie : niveau Developpeur accorde.");

                new name[MAX_PLAYER_NAME], logmsg[144];
                GetPlayerName(i, name, sizeof(name));
                format(logmsg, sizeof(logmsg), "(( %s s'est connecte en RCON. ))", name);

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
