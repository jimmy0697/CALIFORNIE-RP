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
#define MAX_CARD_FIELDS 9
#define CARD_TD_BOTTOM (8 + (MAX_CARD_FIELDS * 2))
#define CARD_TD_CLOSE_BOX (CARD_TD_BOTTOM + 1)
#define CARD_TD_CLOSE_CROSS (CARD_TD_BOTTOM + 2)
#define MAX_CARD_TD (CARD_TD_CLOSE_CROSS + 1)
new PlayerText:gCardTD[MAX_PLAYERS][MAX_CARD_TD];
new bool:gCardTDShown[MAX_PLAYERS];

// --- Interface Connexion / Inscription (style terminal ASCII, TDs separes par couleur) ---
#define TD_LOGIN_BG                  0
#define TD_LOGIN_TITLE_NAME          1
#define TD_LOGIN_TITLE_SUFFIX        2
#define TD_LOGIN_BORDER_TOP          3
#define TD_LOGIN_SUBTITLE            4
#define TD_LOGIN_BORDER_MID          5
#define TD_LOGIN_TERMINAL_LABEL      6
#define TD_LOGIN_TERMINAL_VALUE      7
#define TD_LOGIN_IDENTITY_LABEL      8
#define TD_LOGIN_IDENTITY_VALUE      9
#define TD_LOGIN_STATUS_LABEL        10
#define TD_LOGIN_STATUS_VALUE        11
#define TD_LOGIN_OPERATORS_LABEL     12
#define TD_LOGIN_OPERATORS_VALUE     13
#define TD_LOGIN_SEPARATOR           14
#define TD_LOGIN_DESCRIPTION         15
#define TD_LOGIN_BORDER_BOTTOM       16
#define TD_LOGIN_INPUT_BORDER        17
#define TD_LOGIN_INPUT_BOX           18
#define TD_LOGIN_INPUT_TEXT          19
#define TD_LOGIN_BUTTON_CREATE       20
#define TD_LOGIN_BUTTON_QUIT         21
#define MAX_LOGIN_TDS                22

new PlayerText:gLoginTD[MAX_PLAYERS][MAX_LOGIN_TDS];
new bool:gLoginTDShown[MAX_PLAYERS];
new gPlayerInputPassword[MAX_PLAYERS][MAX_PASS_LENGTH];

#define DIALOG_PASSWORD_INPUT 9000
#define DIALOG_LOGIN 9004
#define DIALOG_REGISTER 9006
#define DIALOG_CHARSETUP_DOB 9007
#define DIALOG_CHARSETUP_MARITAL 9008
#define DIALOG_CHARSETUP_BIRTHPLACE 9009

// ------------------------------------------------------------
//  Creation de personnage (apres inscription) : sexe, age, skin
//  (au format textdraw avec previsualisation 3D, "CHARACTER SETUP")
//  puis date de naissance / situation matrimoniale / lieu de
//  naissance (dialogs natifs), avant creation reelle du compte.
// ------------------------------------------------------------
#define MAX_CHARSETUP_TDS 21
#define CS_TD_BORDER         0
#define CS_TD_BG             1
#define CS_TD_TITLE_BAR      2
#define CS_TD_TITLE          3
#define CS_TD_GENDER_LABEL   4
#define CS_TD_MALE_BORDER    5
#define CS_TD_MALE_BTN       6
#define CS_TD_FEMALE_BORDER  7
#define CS_TD_FEMALE_BTN     8
#define CS_TD_AGE_LABEL      9
#define CS_TD_AGE_BOX        10
#define CS_TD_AGE_MINUS      11
#define CS_TD_AGE_VALUE      12
#define CS_TD_AGE_PLUS       13
#define CS_TD_SKIN_LABEL     14
#define CS_TD_SKIN_BOX       15
#define CS_TD_SKIN_MINUS     16
#define CS_TD_SKIN_VALUE     17
#define CS_TD_SKIN_PLUS      18
#define CS_TD_CONFIRM_BORDER 19
#define CS_TD_CONFIRM_BTN    20

new PlayerText:gCSTD[MAX_PLAYERS][MAX_CHARSETUP_TDS];
new bool:gCharSetupShown[MAX_PLAYERS];
new gCharGender[MAX_PLAYERS];     // 0 = Homme, 1 = Femme
new gCharAge[MAX_PLAYERS];
new gCharSkinIndex[MAX_PLAYERS];
new gPendingPassHash[MAX_PLAYERS];
new gCharDOB[MAX_PLAYERS][11];
new gCharMarital[MAX_PLAYERS][16];
new gCharBirthplace[MAX_PLAYERS][32];

// Skins civils uniquement : les skins de faction (police, armee, gangs,
// SWAT, FBI, pompiers, ambulanciers, etc.) et les skins "metier" en
// uniforme (mecanicien, ouvrier, chauffeur, croupier, etc.) sont exclus.
// Liste facilement modifiable si besoin d'ajouter/retirer des IDs.
new const MALE_CIV_SKINS[] = {
    14,18,20,21,22,23,26,32,33,34,43,44,45,46,47,48,51,52,57,58,
    59,60,72,73,94,95,96,98,99,101,136,170,183,184,185,186,188,189,200,221,
    222,223,228,229,235,236,241,242,250
};
new const FEMALE_CIV_SKINS[] = {
    9,10,39,40,41,53,54,55,56,69,76,88,89,90,91,92,93,138,139,140,
    151,169,196,197,198,199,201,215,216,219,224,225,226,231,232,233,263
};

// Les 14 villes/regions de San Andreas au choix pour le lieu de naissance
new const BIRTHPLACE_CITIES[14][24] = {
    "Los Santos", "San Fierro", "Las Venturas", "Angel Pine", "Blueberry",
    "Dillimore", "El Quebrados", "Fort Carson", "Montgomery", "Palomino Creek",
    "Red County", "Tierra Robada", "Bone County", "Whetstone"
};

#define COLOR_DARK_BG       0x000000B0
#define COLOR_GREEN_ACCENT  0x00FF00FF
#define COLOR_ORANGE        0xFF8000FF
#define COLOR_CYAN          0x00FFFFFF
#define COLOR_MAGENTA       0xFF00FFFF
#define COLOR_PINK          0xFF66CCFF
#define COLOR_WHITE         0xFFFFFFFF
#define COLOR_GREY          0xAAAAAAFF


// Reglages ajustables en direct via /devcarte (developpeur uniquement),
// sans avoir besoin de recompiler pour chaque essai.
new Float:gCardBaseX = 180.0;
new Float:gCardBaseY = 140.0;
new Float:gPreviewRotX = 0.0;
new Float:gPreviewRotY = 0.0;
new Float:gPreviewRotZ = 0.0;
new Float:gPreviewZoom = 1.0;

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
    pPermisConduire,     // Permis vehicule : 0 = non possede, 1 = possede
    pPortArme,           // 0 = non possede, 1 = possede

    // Informations personnelles (carte d'identite)
    pSexe[2],            // "H" ou "F"
    pAge,                // Age du personnage
    pLieuNaissance[32],  // Lieu de naissance
    pDateDelivID[11],    // Date de delivrance de la carte d'identite
    pSituationMatrimoniale[16], // "Celibataire" ou "Marie(e)"

    // Permis de conduire par categorie
    pPermisPL,           // Poids lourd : 0/1
    pPermisAvion,        // 0/1
    pPermisBateau,       // 0/1
    pPermisMoto,         // 0/1
    pDatePermisVehicule[11],
    pDatePermisPL[11],
    pDatePermisAvion[11],
    pDatePermisBateau[11],
    pDatePermisMoto[11],

    // Port d'armes
    pProfession[32],
    pTypeArme[32],
    pNomArme[32],

    // Besoins vitaux (0 a 100)
    pFaim,                // Faim : diminue avec le temps, /manger pour remonter
    pSoif,                // Soif : diminue avec le temps, /boire pour remonter
    pFatigue,             // Fatigue : augmente avec le temps, /dormir pour redescendre
    pStress,              // Stress : augmente si besoins critiques, redescend sinon
    pMoral                // Moral : diminue si stress/besoins critiques, remonte sinon
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
forward FinalizeAccountCreation(playerid);
forward NeedsUpdateTimer();

// ------------------------------------------------------------
//  Systeme de besoins vitaux (soif / faim / stress / moral / fatigue)
//  Tick toutes les 60 secondes pour chaque joueur connecte et spawn.
// ------------------------------------------------------------
#define NEEDS_INTERVAL       60000  // 1 minute
#define NEEDS_FAIM_DECAY     2
#define NEEDS_SOIF_DECAY     3
#define NEEDS_FATIGUE_GAIN   1
#define NEEDS_SEUIL_CRITIQUE 25     // en dessous de ce seuil : impact stress/moral
#define NEEDS_FATIGUE_HAUTE  75     // au dessus : impact stress
#define NEEDS_DEGATS_CRITIQUE 3.0   // degats de sante par tick si faim ou soif a 0

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

// ------------------------------------------------------------
//  Borne une valeur de besoin entre 0 et 100.
// ------------------------------------------------------------
stock ClampNeed(val)
{
    if(val < 0) return 0;
    if(val > 100) return 100;
    return val;
}

// ------------------------------------------------------------
//  Tick des besoins vitaux : appele toutes les NEEDS_INTERVAL ms.
//  Fait baisser faim/soif, monter la fatigue, ajuste stress/moral,
//  et inflige des degats de sante en cas de faim/soif a 0.
// ------------------------------------------------------------
public NeedsUpdateTimer()
{
    for(new playerid = 0; playerid < MAX_PLAYERS; playerid++)
    {
        if(!IsPlayerConnected(playerid) || !IsLoggedIn[playerid]) continue;

        new playerState = GetPlayerState(playerid);
        if(playerState == PLAYER_STATE_NONE || playerState == PLAYER_STATE_WASTED || playerState == PLAYER_STATE_SPECTATING) continue;

        // --- Faim / Soif / Fatigue ---
        PlayerInfo[playerid][pFaim] = ClampNeed(PlayerInfo[playerid][pFaim] - NEEDS_FAIM_DECAY);
        PlayerInfo[playerid][pSoif] = ClampNeed(PlayerInfo[playerid][pSoif] - NEEDS_SOIF_DECAY);
        PlayerInfo[playerid][pFatigue] = ClampNeed(PlayerInfo[playerid][pFatigue] + NEEDS_FATIGUE_GAIN);

        new critique = (PlayerInfo[playerid][pFaim] <= NEEDS_SEUIL_CRITIQUE
                     || PlayerInfo[playerid][pSoif] <= NEEDS_SEUIL_CRITIQUE
                     || PlayerInfo[playerid][pFatigue] >= NEEDS_FATIGUE_HAUTE);

        // --- Stress : monte si un besoin est critique, redescend doucement sinon ---
        if(critique)
        {
            PlayerInfo[playerid][pStress] = ClampNeed(PlayerInfo[playerid][pStress] + 2);
        }
        else
        {
            PlayerInfo[playerid][pStress] = ClampNeed(PlayerInfo[playerid][pStress] - 1);
        }

        // --- Moral : diminue si stress eleve ou faim/soif a 0, remonte doucement sinon ---
        if(PlayerInfo[playerid][pStress] >= 50 || PlayerInfo[playerid][pFaim] == 0 || PlayerInfo[playerid][pSoif] == 0)
        {
            PlayerInfo[playerid][pMoral] = ClampNeed(PlayerInfo[playerid][pMoral] - 2);
        }
        else
        {
            PlayerInfo[playerid][pMoral] = ClampNeed(PlayerInfo[playerid][pMoral] + 1);
        }

        // --- Alertes au joueur ---
        if(PlayerInfo[playerid][pFaim] == NEEDS_SEUIL_CRITIQUE)
        {
            SendClientMessage(playerid, COLOR_YELLOW, "Vous commencez a avoir tres faim. Pensez a manger (/manger).");
        }
        if(PlayerInfo[playerid][pSoif] == NEEDS_SEUIL_CRITIQUE)
        {
            SendClientMessage(playerid, COLOR_YELLOW, "Vous commencez a avoir tres soif. Pensez a boire (/boire).");
        }
        if(PlayerInfo[playerid][pFatigue] == NEEDS_FATIGUE_HAUTE)
        {
            SendClientMessage(playerid, COLOR_YELLOW, "Vous etes epuise. Pensez a dormir (/dormir).");
        }

        // --- Degats de sante si faim ou soif totalement a 0 ---
        if(PlayerInfo[playerid][pFaim] == 0 || PlayerInfo[playerid][pSoif] == 0)
        {
            new Float:health;
            GetPlayerHealth(playerid, health);
            if(health > 1.0)
            {
                health -= NEEDS_DEGATS_CRITIQUE;
                if(health < 1.0) health = 1.0;
                SetPlayerHealth(playerid, health);
                SendClientMessage(playerid, COLOR_RED, "Votre sante decline : vous devez manger et boire d'urgence !");
            }
        }
    }
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

    // --- Systeme de besoins vitaux : degradation automatique toutes les minutes ---
    SetTimer("NeedsUpdateTimer", NEEDS_INTERVAL, true);

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
    
    gLoginTDShown[playerid] = false;
    for(new i = 0; i < MAX_LOGIN_TDS; i++) gLoginTD[playerid][i] = PlayerText:INVALID_TEXT_DRAW;
    gPlayerInputPassword[playerid][0] = EOS;

    gCharSetupShown[playerid] = false;
    for(new i = 0; i < MAX_CHARSETUP_TDS; i++) gCSTD[playerid][i] = PlayerText:INVALID_TEXT_DRAW;
    gCharGender[playerid] = 0;
    gCharAge[playerid] = 18;
    gCharSkinIndex[playerid] = 0;
    gPendingPassHash[playerid] = 0;
    gCharDOB[playerid][0] = EOS;
    gCharMarital[playerid][0] = EOS;
    gCharBirthplace[playerid][0] = EOS;

    // --- Valeurs par defaut des besoins vitaux (ecrasees par LoadUserData si presentes dans le fichier) ---
    PlayerInfo[playerid][pFaim] = 100;
    PlayerInfo[playerid][pSoif] = 100;
    PlayerInfo[playerid][pFatigue] = 0;
    PlayerInfo[playerid][pStress] = 0;
    PlayerInfo[playerid][pMoral] = 100;

    // --- Securite anti-cheat : kick si non connecte apres 60 secondes ---
    gLoginTimer[playerid] = SetTimerEx("KickIfNotLoggedIn", LOGIN_TIMEOUT, false, "d", playerid);

    new name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof(name));

    if(fexist(UserPathStr(playerid)))
    {
        ShowLoginRegisterDialog(playerid, false, name);
    }
    else
    {
        ShowLoginRegisterDialog(playerid, true, name);
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
    new File:f = fopen(ReceiptPathStr(playerid), io_append);
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
    new File:f = fopen(ReceiptPathStr(playerid), io_read);
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
//  Transforme un pseudo au format SA-MP "Prenom_Nom" en
//  "Prenom Nom" lisible, pour l'affichage sur les cartes.
// ------------------------------------------------------------
stock FormatFullName(dest[], destSize, const src[])
{
    new len = strlen(src);
    if(len >= destSize) len = destSize - 1;

    for(new i = 0; i < len; i++)
    {
        if(src[i] == '_') dest[i] = ' ';
        else dest[i] = src[i];
    }
    dest[len] = EOS;
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
//  accentColor  = couleur propre a ce type de carte (bandeau, logo, libelles)
//  cardNumber   = numero a 3 chiffres, unique par carte et par joueur (haut droite)
//  fieldLabels  = libelles des informations (affiches dans accentColor)
//  fieldValues  = valeurs correspondantes (affichees en blanc, sauf couleur forcee)
//  fieldColors  = couleur de chaque valeur (0xFFFFFFFF par defaut, vert si "valide")
//  fieldCount   = nombre de lignes reellement utilisees (<= MAX_CARD_FIELDS)
//  previewmodel = skin du joueur a afficher en "photo" (-1 pour aucun)
// ------------------------------------------------------------
stock ShowDocumentCard(playerid, const cardTitle[], accentColor, cardNumber, const fieldLabels[][24], const fieldValues[][48], const fieldColors[], fieldCount, previewmodel)
{
    DestroyCardTD(playerid); // Evite les doublons si une carte est deja affichee

    new Float:bx = gCardBaseX;
    new Float:by = gCardBaseY;

    // 0: fond principal de la carte
    gCardTD[playerid][0] = CreatePlayerTextDraw(playerid, bx, by, "_");
    PlayerTextDrawTextSize(playerid, gCardTD[playerid][0], bx + 280.0, by + 240.0);
    PlayerTextDrawUseBox(playerid, gCardTD[playerid][0], 1);
    PlayerTextDrawBoxColor(playerid, gCardTD[playerid][0], 0x1B1B1BE6);
    PlayerTextDrawColor(playerid, gCardTD[playerid][0], 0x00000000);

    // 1: bandeau superieur, dans la couleur propre a ce type de carte
    gCardTD[playerid][1] = CreatePlayerTextDraw(playerid, bx, by, "_");
    PlayerTextDrawTextSize(playerid, gCardTD[playerid][1], bx + 280.0, by + 24.0);
    PlayerTextDrawUseBox(playerid, gCardTD[playerid][1], 1);
    PlayerTextDrawBoxColor(playerid, gCardTD[playerid][1], accentColor);
    PlayerTextDrawColor(playerid, gCardTD[playerid][1], 0x00000000);

    // 2: titre du document (gros, blanc avec ombre : bien visible sur toutes les couleurs)
    gCardTD[playerid][2] = CreatePlayerTextDraw(playerid, bx + 34.0, by + 5.0, cardTitle);
    PlayerTextDrawFont(playerid, gCardTD[playerid][2], 2);
    PlayerTextDrawLetterSize(playerid, gCardTD[playerid][2], 0.26, 1.3);
    PlayerTextDrawColor(playerid, gCardTD[playerid][2], 0xFFFFFFFF);
    PlayerTextDrawSetShadow(playerid, gCardTD[playerid][2], 1);

    // 3: logo (en haut a gauche)
    gCardTD[playerid][3] = CreatePlayerTextDraw(playerid, bx + 4.0, by + 3.0, "_");
    PlayerTextDrawTextSize(playerid, gCardTD[playerid][3], bx + 28.0, by + 21.0);
    PlayerTextDrawUseBox(playerid, gCardTD[playerid][3], 1);
    PlayerTextDrawBoxColor(playerid, gCardTD[playerid][3], 0x00000090);
    PlayerTextDrawColor(playerid, gCardTD[playerid][3], 0x00000000);

    // 4: texte du logo ("CA" = Californie)
    gCardTD[playerid][4] = CreatePlayerTextDraw(playerid, bx + 7.0, by + 6.0, "CA");
    PlayerTextDrawFont(playerid, gCardTD[playerid][4], 2);
    PlayerTextDrawLetterSize(playerid, gCardTD[playerid][4], 0.22, 1.1);
    PlayerTextDrawColor(playerid, gCardTD[playerid][4], 0xFFFFFFFF);

    // 5: numero unique de la carte (en haut a droite)
    new numStr[16];
    format(numStr, sizeof(numStr), "#%03d", cardNumber);
    gCardTD[playerid][5] = CreatePlayerTextDraw(playerid, bx + 232.0, by + 6.0, numStr);
    PlayerTextDrawFont(playerid, gCardTD[playerid][5], 2);
    PlayerTextDrawLetterSize(playerid, gCardTD[playerid][5], 0.22, 1.1);
    PlayerTextDrawColor(playerid, gCardTD[playerid][5], 0xFFFFFFFF);
    PlayerTextDrawSetShadow(playerid, gCardTD[playerid][5], 1);

    // 6: cadre de la "photo" (apparence du joueur)
    gCardTD[playerid][6] = CreatePlayerTextDraw(playerid, bx + 10.0, by + 28.0, "_");
    PlayerTextDrawTextSize(playerid, gCardTD[playerid][6], bx + 100.0, by + 208.0);
    PlayerTextDrawUseBox(playerid, gCardTD[playerid][6], 1);
    PlayerTextDrawBoxColor(playerid, gCardTD[playerid][6], 0x00000090);
    PlayerTextDrawColor(playerid, gCardTD[playerid][6], 0x00000000);

    // 7: apercu 3D de l'apparence du joueur (fait office de photo)
    gCardTD[playerid][7] = CreatePlayerTextDraw(playerid, bx + 10.0, by + 28.0, "_");
    PlayerTextDrawTextSize(playerid, gCardTD[playerid][7], bx + 100.0, by + 208.0);
    if(previewmodel != -1)
    {
        PlayerTextDrawFont(playerid, gCardTD[playerid][7], 5);
        PlayerTextDrawSetPreviewModel(playerid, gCardTD[playerid][7], previewmodel);
        PlayerTextDrawSetPreviewRot(playerid, gCardTD[playerid][7], gPreviewRotX, gPreviewRotY, gPreviewRotZ, gPreviewZoom);
    }

    // 8+: champs d'information. Libelle dans la couleur de la carte, valeur en blanc
    // (ou dans la couleur forcee par l'appelant, ex: vert pour "Valide").
    new fCount = fieldCount;
    if(fCount > MAX_CARD_FIELDS) fCount = MAX_CARD_FIELDS;

    new Float:rowY;
    new labelIdx, valueIdx;

    for(new i = 0; i < fCount; i++)
    {
        rowY = by + 30.0 + (i * 20.0);
        labelIdx = 8 + (i * 2);
        valueIdx = labelIdx + 1;

        gCardTD[playerid][labelIdx] = CreatePlayerTextDraw(playerid, bx + 110.0, rowY, fieldLabels[i]);
        PlayerTextDrawFont(playerid, gCardTD[playerid][labelIdx], 1);
        PlayerTextDrawLetterSize(playerid, gCardTD[playerid][labelIdx], 0.17, 0.9);
        PlayerTextDrawColor(playerid, gCardTD[playerid][labelIdx], accentColor);
        PlayerTextDrawSetShadow(playerid, gCardTD[playerid][labelIdx], 0);

        gCardTD[playerid][valueIdx] = CreatePlayerTextDraw(playerid, bx + 190.0, rowY, fieldValues[i]);
        PlayerTextDrawFont(playerid, gCardTD[playerid][valueIdx], 1);
        PlayerTextDrawLetterSize(playerid, gCardTD[playerid][valueIdx], 0.17, 0.9);
        PlayerTextDrawColor(playerid, gCardTD[playerid][valueIdx], fieldColors[i]);
        PlayerTextDrawSetShadow(playerid, gCardTD[playerid][valueIdx], 0);
    }

    // Mention de bas de carte
    gCardTD[playerid][CARD_TD_BOTTOM] = CreatePlayerTextDraw(playerid, bx + 10.0, by + 216.0, "ETAT DE LA CALIFORNIE");
    PlayerTextDrawFont(playerid, gCardTD[playerid][CARD_TD_BOTTOM], 1);
    PlayerTextDrawLetterSize(playerid, gCardTD[playerid][CARD_TD_BOTTOM], 0.19, 1.0);
    PlayerTextDrawColor(playerid, gCardTD[playerid][CARD_TD_BOTTOM], 0xAAAAAAFF);

    // Bouton de fermeture (cadre rouge cliquable)
    gCardTD[playerid][CARD_TD_CLOSE_BOX] = CreatePlayerTextDraw(playerid, bx + 255.0, by + 3.0, "_");
    PlayerTextDrawTextSize(playerid, gCardTD[playerid][CARD_TD_CLOSE_BOX], bx + 276.0, by + 21.0);
    PlayerTextDrawUseBox(playerid, gCardTD[playerid][CARD_TD_CLOSE_BOX], 1);
    PlayerTextDrawBoxColor(playerid, gCardTD[playerid][CARD_TD_CLOSE_BOX], 0xAA0000FF);
    PlayerTextDrawColor(playerid, gCardTD[playerid][CARD_TD_CLOSE_BOX], 0x00000000);
    PlayerTextDrawSetSelectable(playerid, gCardTD[playerid][CARD_TD_CLOSE_BOX], 1);

    // Croix du bouton de fermeture
    gCardTD[playerid][CARD_TD_CLOSE_CROSS] = CreatePlayerTextDraw(playerid, bx + 260.0, by + 6.0, "X");
    PlayerTextDrawFont(playerid, gCardTD[playerid][CARD_TD_CLOSE_CROSS], 1);
    PlayerTextDrawLetterSize(playerid, gCardTD[playerid][CARD_TD_CLOSE_CROSS], 0.3, 1.2);
    PlayerTextDrawColor(playerid, gCardTD[playerid][CARD_TD_CLOSE_CROSS], 0xFFFFFFFF);
    PlayerTextDrawSetSelectable(playerid, gCardTD[playerid][CARD_TD_CLOSE_CROSS], 1);

    for(new i = 0; i < MAX_CARD_TD; i++)
    {
        if(gCardTD[playerid][i] != PlayerText:INVALID_TEXT_DRAW)
        {
            PlayerTextDrawShow(playerid, gCardTD[playerid][i]);
        }
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
    if(gLoginTDShown[playerid])
    {
        if(playertextid == gLoginTD[playerid][TD_LOGIN_INPUT_BOX])
        {
            ShowPasswordInputDialog(playerid);
            return 1;
        }
        if(playertextid == gLoginTD[playerid][TD_LOGIN_BUTTON_CREATE])
        {
            new name[MAX_PLAYER_NAME];
            GetPlayerName(playerid, name, sizeof(name));
            if(fexist(UserPathStr(playerid)))
            {
                // On simule OnDialogResponse pour DIALOG_LOGIN
                OnDialogResponse(playerid, DIALOG_LOGIN, 1, 0, gPlayerInputPassword[playerid]);
            }
            else
            {
                // On simule OnDialogResponse pour DIALOG_REGISTER
                OnDialogResponse(playerid, DIALOG_REGISTER, 1, 0, gPlayerInputPassword[playerid]);
            }
            return 1;
        }
        if(playertextid == gLoginTD[playerid][TD_LOGIN_BUTTON_QUIT] || playertextid == PlayerText:INVALID_TEXT_DRAW)
        {
            Kick(playerid);
            return 1;
        }
    }

    if(gCharSetupShown[playerid])
    {
        if(playertextid == gCSTD[playerid][CS_TD_MALE_BTN])
        {
            gCharGender[playerid] = 0;
            gCharSkinIndex[playerid] = 0;
            RefreshCharSetupGenderVisual(playerid);
            RefreshCharSetupSkinDisplay(playerid);
            return 1;
        }
        if(playertextid == gCSTD[playerid][CS_TD_FEMALE_BTN])
        {
            gCharGender[playerid] = 1;
            gCharSkinIndex[playerid] = 0;
            RefreshCharSetupGenderVisual(playerid);
            RefreshCharSetupSkinDisplay(playerid);
            return 1;
        }
        if(playertextid == gCSTD[playerid][CS_TD_AGE_MINUS])
        {
            if(gCharAge[playerid] > 16) gCharAge[playerid]--;
            RefreshCharSetupAgeDisplay(playerid);
            return 1;
        }
        if(playertextid == gCSTD[playerid][CS_TD_AGE_PLUS])
        {
            if(gCharAge[playerid] < 90) gCharAge[playerid]++;
            RefreshCharSetupAgeDisplay(playerid);
            return 1;
        }
        if(playertextid == gCSTD[playerid][CS_TD_SKIN_MINUS])
        {
            new maxSkins = (gCharGender[playerid] == 1) ? sizeof(FEMALE_CIV_SKINS) : sizeof(MALE_CIV_SKINS);
            gCharSkinIndex[playerid] = (gCharSkinIndex[playerid] + maxSkins - 1) % maxSkins;
            RefreshCharSetupSkinDisplay(playerid);
            return 1;
        }
        if(playertextid == gCSTD[playerid][CS_TD_SKIN_PLUS])
        {
            new maxSkins = (gCharGender[playerid] == 1) ? sizeof(FEMALE_CIV_SKINS) : sizeof(MALE_CIV_SKINS);
            gCharSkinIndex[playerid] = (gCharSkinIndex[playerid] + 1) % maxSkins;
            RefreshCharSetupSkinDisplay(playerid);
            return 1;
        }
        if(playertextid == gCSTD[playerid][CS_TD_CONFIRM_BTN])
        {
            HideCharacterSetupTD(playerid);
            CancelSelectTextDraw(playerid);
            ShowDOBInputDialog(playerid);
            return 1;
        }
        return 1;
    }

    if(gCardTDShown[playerid])
    {
        if(playertextid == gCardTD[playerid][CARD_TD_CLOSE_BOX] || playertextid == gCardTD[playerid][CARD_TD_CLOSE_CROSS] || playertextid == PlayerText:INVALID_TEXT_DRAW)
        {
            CancelSelectTextDraw(playerid);
            DestroyCardTD(playerid);
        }
        return 1;
    }
    return 0;
}

// ------------------------------------------------------------
//  Ecran de connexion / inscription au format dialog natif
//  (meme forme, meme fond, meme taille d'ecriture et memes
//  dimensions que le systeme "Liberty State")
// ------------------------------------------------------------
stock ShowLoginRegisterDialog(playerid, bool:isRegister, const playerName[])
{
    new count = 0;
    for(new i = 0; i < MAX_PLAYERS; i++) if(IsPlayerConnected(i)) count++;

    new title[64];
    format(title, sizeof(title), "CALIFORNIE {FFFFFF}// ACCES SYSTEME");

    new body[600];
    format(body, sizeof(body),
        "+==================================================+\n"\
        "{FF00FF}CALIFORNIE // SYSTEME D'ACCES v2.0{FFFFFF}\n"\
        "+==================================================+\n"\
        "\n"\
        "TERMINAL    : {00FFFF}%s{FFFFFF}\n"\
        "IDENTITE    : {00FFFF}%s{FFFFFF}\n"\
        "STATUT      : {%s}[ INCONNU ]{FFFFFF}\n"\
        "OPERATEURS  : {00FFFF}%d connecte(s){FFFFFF}\n"\
        "\n"\
        "--------------------------------------------------\n"\
        "%s\n"\
        "+==================================================+",
        isRegister ? "INSCRIPTION" : "CONNEXION",
        playerName,
        isRegister ? "FF66CC" : "00FFFF",
        count,
        isRegister ?
            "Ce pseudonyme n'est pas encore enregistre.\nDefinissez un mot de passe pour creer\nvotre profil sur Californie." :
            "Veuillez entrer votre mot de passe\npour vous connecter."
    );

    ShowPlayerDialog(playerid, isRegister ? DIALOG_REGISTER : DIALOG_LOGIN, DIALOG_STYLE_PASSWORD,
        title, body, isRegister ? "Creer compte" : "Valider", "Quitter");
    return 1;
}

stock ShowLoginRegisterTD(playerid, bool:isRegister, const playerName[])
{
    HideLoginRegisterTD(playerid);

    new Float:baseX = 320.0;
    new Float:baseY = 90.0;
    new Float:boxH = isRegister ? 225.0 : 195.0;
    new str[144];

    // ------------------------------------------------------------
    //  Fond sombre unique derriere tout le panneau (titre + bloc)
    // ------------------------------------------------------------
    gLoginTD[playerid][TD_LOGIN_BG] = CreatePlayerTextDraw(playerid, baseX - 150.0, baseY - 4.0, "_");
    PlayerTextDrawTextSize(playerid, gLoginTD[playerid][TD_LOGIN_BG], baseX + 150.0, baseY + boxH);
    PlayerTextDrawUseBox(playerid, gLoginTD[playerid][TD_LOGIN_BG], 1);
    PlayerTextDrawBoxColor(playerid, gLoginTD[playerid][TD_LOGIN_BG], COLOR_DARK_BG);
    PlayerTextDrawColor(playerid, gLoginTD[playerid][TD_LOGIN_BG], 0x00000000);
    PlayerTextDrawShow(playerid, gLoginTD[playerid][TD_LOGIN_BG]);

    // ------------------------------------------------------------
    //  Titre : "CALIFORNIE" (cyan) + "// ACCES SYSTEME" (blanc)
    // ------------------------------------------------------------
    gLoginTD[playerid][TD_LOGIN_TITLE_NAME] = CreatePlayerTextDraw(playerid, baseX - 145.0, baseY, "CALIFORNIE");
    PlayerTextDrawFont(playerid, gLoginTD[playerid][TD_LOGIN_TITLE_NAME], 2);
    PlayerTextDrawLetterSize(playerid, gLoginTD[playerid][TD_LOGIN_TITLE_NAME], 0.24, 1.2);
    PlayerTextDrawColor(playerid, gLoginTD[playerid][TD_LOGIN_TITLE_NAME], COLOR_CYAN);
    PlayerTextDrawSetShadow(playerid, gLoginTD[playerid][TD_LOGIN_TITLE_NAME], 0);
    PlayerTextDrawShow(playerid, gLoginTD[playerid][TD_LOGIN_TITLE_NAME]);

    gLoginTD[playerid][TD_LOGIN_TITLE_SUFFIX] = CreatePlayerTextDraw(playerid, baseX - 55.0, baseY, "// ACCES SYSTEME");
    PlayerTextDrawFont(playerid, gLoginTD[playerid][TD_LOGIN_TITLE_SUFFIX], 2);
    PlayerTextDrawLetterSize(playerid, gLoginTD[playerid][TD_LOGIN_TITLE_SUFFIX], 0.24, 1.2);
    PlayerTextDrawColor(playerid, gLoginTD[playerid][TD_LOGIN_TITLE_SUFFIX], COLOR_WHITE);
    PlayerTextDrawSetShadow(playerid, gLoginTD[playerid][TD_LOGIN_TITLE_SUFFIX], 0);
    PlayerTextDrawShow(playerid, gLoginTD[playerid][TD_LOGIN_TITLE_SUFFIX]);

    new Float:currentY = baseY + 22.0;

    // ------------------------------------------------------------
    //  Bordure ASCII superieure
    // ------------------------------------------------------------
    gLoginTD[playerid][TD_LOGIN_BORDER_TOP] = CreatePlayerTextDraw(playerid, baseX - 145.0, currentY, "+=================================================+");
    PlayerTextDrawFont(playerid, gLoginTD[playerid][TD_LOGIN_BORDER_TOP], 1);
    PlayerTextDrawLetterSize(playerid, gLoginTD[playerid][TD_LOGIN_BORDER_TOP], 0.145, 0.8);
    PlayerTextDrawColor(playerid, gLoginTD[playerid][TD_LOGIN_BORDER_TOP], COLOR_CYAN);
    PlayerTextDrawSetShadow(playerid, gLoginTD[playerid][TD_LOGIN_BORDER_TOP], 0);
    PlayerTextDrawShow(playerid, gLoginTD[playerid][TD_LOGIN_BORDER_TOP]);

    currentY += 13.0;

    // ------------------------------------------------------------
    //  Sous-titre "CALIFORNIE // SYSTEME D'ACCES v2.0" (magenta)
    // ------------------------------------------------------------
    gLoginTD[playerid][TD_LOGIN_SUBTITLE] = CreatePlayerTextDraw(playerid, baseX, currentY, "CALIFORNIE // SYSTEME D'ACCES v2.0");
    PlayerTextDrawAlignment(playerid, gLoginTD[playerid][TD_LOGIN_SUBTITLE], 2);
    PlayerTextDrawFont(playerid, gLoginTD[playerid][TD_LOGIN_SUBTITLE], 1);
    PlayerTextDrawLetterSize(playerid, gLoginTD[playerid][TD_LOGIN_SUBTITLE], 0.17, 0.9);
    PlayerTextDrawColor(playerid, gLoginTD[playerid][TD_LOGIN_SUBTITLE], COLOR_MAGENTA);
    PlayerTextDrawSetShadow(playerid, gLoginTD[playerid][TD_LOGIN_SUBTITLE], 0);
    PlayerTextDrawShow(playerid, gLoginTD[playerid][TD_LOGIN_SUBTITLE]);

    currentY += 13.0;

    gLoginTD[playerid][TD_LOGIN_BORDER_MID] = CreatePlayerTextDraw(playerid, baseX - 145.0, currentY, "+=================================================+");
    PlayerTextDrawFont(playerid, gLoginTD[playerid][TD_LOGIN_BORDER_MID], 1);
    PlayerTextDrawLetterSize(playerid, gLoginTD[playerid][TD_LOGIN_BORDER_MID], 0.145, 0.8);
    PlayerTextDrawColor(playerid, gLoginTD[playerid][TD_LOGIN_BORDER_MID], COLOR_CYAN);
    PlayerTextDrawSetShadow(playerid, gLoginTD[playerid][TD_LOGIN_BORDER_MID], 0);
    PlayerTextDrawShow(playerid, gLoginTD[playerid][TD_LOGIN_BORDER_MID]);

    currentY += 18.0;

    // ------------------------------------------------------------
    //  TERMINAL / IDENTITE / STATUT / OPERATEURS
    //  (label blanc + valeur coloree, 2 TextDraws par ligne)
    // ------------------------------------------------------------
    gLoginTD[playerid][TD_LOGIN_TERMINAL_LABEL] = CreatePlayerTextDraw(playerid, baseX - 135.0, currentY, "TERMINAL :");
    PlayerTextDrawFont(playerid, gLoginTD[playerid][TD_LOGIN_TERMINAL_LABEL], 1);
    PlayerTextDrawLetterSize(playerid, gLoginTD[playerid][TD_LOGIN_TERMINAL_LABEL], 0.19, 0.85);
    PlayerTextDrawColor(playerid, gLoginTD[playerid][TD_LOGIN_TERMINAL_LABEL], COLOR_WHITE);
    PlayerTextDrawSetShadow(playerid, gLoginTD[playerid][TD_LOGIN_TERMINAL_LABEL], 0);
    PlayerTextDrawShow(playerid, gLoginTD[playerid][TD_LOGIN_TERMINAL_LABEL]);

    format(str, sizeof(str), "%s", isRegister ? "INSCRIPTION" : "CONNEXION");
    gLoginTD[playerid][TD_LOGIN_TERMINAL_VALUE] = CreatePlayerTextDraw(playerid, baseX - 55.0, currentY, str);
    PlayerTextDrawFont(playerid, gLoginTD[playerid][TD_LOGIN_TERMINAL_VALUE], 1);
    PlayerTextDrawLetterSize(playerid, gLoginTD[playerid][TD_LOGIN_TERMINAL_VALUE], 0.19, 0.85);
    PlayerTextDrawColor(playerid, gLoginTD[playerid][TD_LOGIN_TERMINAL_VALUE], COLOR_CYAN);
    PlayerTextDrawSetShadow(playerid, gLoginTD[playerid][TD_LOGIN_TERMINAL_VALUE], 0);
    PlayerTextDrawShow(playerid, gLoginTD[playerid][TD_LOGIN_TERMINAL_VALUE]);

    currentY += 14.0;

    gLoginTD[playerid][TD_LOGIN_IDENTITY_LABEL] = CreatePlayerTextDraw(playerid, baseX - 135.0, currentY, "IDENTITE :");
    PlayerTextDrawFont(playerid, gLoginTD[playerid][TD_LOGIN_IDENTITY_LABEL], 1);
    PlayerTextDrawLetterSize(playerid, gLoginTD[playerid][TD_LOGIN_IDENTITY_LABEL], 0.19, 0.85);
    PlayerTextDrawColor(playerid, gLoginTD[playerid][TD_LOGIN_IDENTITY_LABEL], COLOR_WHITE);
    PlayerTextDrawSetShadow(playerid, gLoginTD[playerid][TD_LOGIN_IDENTITY_LABEL], 0);
    PlayerTextDrawShow(playerid, gLoginTD[playerid][TD_LOGIN_IDENTITY_LABEL]);

    format(str, sizeof(str), "%s", playerName);
    gLoginTD[playerid][TD_LOGIN_IDENTITY_VALUE] = CreatePlayerTextDraw(playerid, baseX - 55.0, currentY, str);
    PlayerTextDrawFont(playerid, gLoginTD[playerid][TD_LOGIN_IDENTITY_VALUE], 1);
    PlayerTextDrawLetterSize(playerid, gLoginTD[playerid][TD_LOGIN_IDENTITY_VALUE], 0.19, 0.85);
    PlayerTextDrawColor(playerid, gLoginTD[playerid][TD_LOGIN_IDENTITY_VALUE], COLOR_PINK);
    PlayerTextDrawSetShadow(playerid, gLoginTD[playerid][TD_LOGIN_IDENTITY_VALUE], 0);
    PlayerTextDrawShow(playerid, gLoginTD[playerid][TD_LOGIN_IDENTITY_VALUE]);

    currentY += 14.0;

    gLoginTD[playerid][TD_LOGIN_STATUS_LABEL] = CreatePlayerTextDraw(playerid, baseX - 135.0, currentY, "STATUT :");
    PlayerTextDrawFont(playerid, gLoginTD[playerid][TD_LOGIN_STATUS_LABEL], 1);
    PlayerTextDrawLetterSize(playerid, gLoginTD[playerid][TD_LOGIN_STATUS_LABEL], 0.19, 0.85);
    PlayerTextDrawColor(playerid, gLoginTD[playerid][TD_LOGIN_STATUS_LABEL], COLOR_WHITE);
    PlayerTextDrawSetShadow(playerid, gLoginTD[playerid][TD_LOGIN_STATUS_LABEL], 0);
    PlayerTextDrawShow(playerid, gLoginTD[playerid][TD_LOGIN_STATUS_LABEL]);

    format(str, sizeof(str), "[ %s ]", isRegister ? "INCONNU" : "ENREGISTRE");
    gLoginTD[playerid][TD_LOGIN_STATUS_VALUE] = CreatePlayerTextDraw(playerid, baseX - 55.0, currentY, str);
    PlayerTextDrawFont(playerid, gLoginTD[playerid][TD_LOGIN_STATUS_VALUE], 1);
    PlayerTextDrawLetterSize(playerid, gLoginTD[playerid][TD_LOGIN_STATUS_VALUE], 0.19, 0.85);
    PlayerTextDrawColor(playerid, gLoginTD[playerid][TD_LOGIN_STATUS_VALUE], isRegister ? COLOR_PINK : COLOR_CYAN);
    PlayerTextDrawSetShadow(playerid, gLoginTD[playerid][TD_LOGIN_STATUS_VALUE], 0);
    PlayerTextDrawShow(playerid, gLoginTD[playerid][TD_LOGIN_STATUS_VALUE]);

    currentY += 14.0;

    gLoginTD[playerid][TD_LOGIN_OPERATORS_LABEL] = CreatePlayerTextDraw(playerid, baseX - 135.0, currentY, "OPERATEURS :");
    PlayerTextDrawFont(playerid, gLoginTD[playerid][TD_LOGIN_OPERATORS_LABEL], 1);
    PlayerTextDrawLetterSize(playerid, gLoginTD[playerid][TD_LOGIN_OPERATORS_LABEL], 0.19, 0.85);
    PlayerTextDrawColor(playerid, gLoginTD[playerid][TD_LOGIN_OPERATORS_LABEL], COLOR_WHITE);
    PlayerTextDrawSetShadow(playerid, gLoginTD[playerid][TD_LOGIN_OPERATORS_LABEL], 0);
    PlayerTextDrawShow(playerid, gLoginTD[playerid][TD_LOGIN_OPERATORS_LABEL]);

    new count = 0;
    for(new i = 0; i < MAX_PLAYERS; i++) if(IsPlayerConnected(i)) count++;
    format(str, sizeof(str), "%d connecte(s)", count);
    gLoginTD[playerid][TD_LOGIN_OPERATORS_VALUE] = CreatePlayerTextDraw(playerid, baseX - 40.0, currentY, str);
    PlayerTextDrawFont(playerid, gLoginTD[playerid][TD_LOGIN_OPERATORS_VALUE], 1);
    PlayerTextDrawLetterSize(playerid, gLoginTD[playerid][TD_LOGIN_OPERATORS_VALUE], 0.19, 0.85);
    PlayerTextDrawColor(playerid, gLoginTD[playerid][TD_LOGIN_OPERATORS_VALUE], COLOR_CYAN);
    PlayerTextDrawSetShadow(playerid, gLoginTD[playerid][TD_LOGIN_OPERATORS_VALUE], 0);
    PlayerTextDrawShow(playerid, gLoginTD[playerid][TD_LOGIN_OPERATORS_VALUE]);

    currentY += 20.0;

    // ------------------------------------------------------------
    //  Ligne de separation en tirets
    // ------------------------------------------------------------
    gLoginTD[playerid][TD_LOGIN_SEPARATOR] = CreatePlayerTextDraw(playerid, baseX - 135.0, currentY, "-------------------------------------------");
    PlayerTextDrawFont(playerid, gLoginTD[playerid][TD_LOGIN_SEPARATOR], 1);
    PlayerTextDrawLetterSize(playerid, gLoginTD[playerid][TD_LOGIN_SEPARATOR], 0.145, 0.8);
    PlayerTextDrawColor(playerid, gLoginTD[playerid][TD_LOGIN_SEPARATOR], COLOR_GREY);
    PlayerTextDrawSetShadow(playerid, gLoginTD[playerid][TD_LOGIN_SEPARATOR], 0);
    PlayerTextDrawShow(playerid, gLoginTD[playerid][TD_LOGIN_SEPARATOR]);

    currentY += 12.0;

    // ------------------------------------------------------------
    //  Texte de description (blanc, multi-lignes)
    // ------------------------------------------------------------
    format(str, sizeof(str), "%s", isRegister ?
        "Ce pseudonyme n'est pas encore enregistre.\nDefinissez un mot de passe pour creer\nvotre profil sur Californie."
        :
        "Veuillez entrer votre mot de passe\npour vous connecter."
    );
    gLoginTD[playerid][TD_LOGIN_DESCRIPTION] = CreatePlayerTextDraw(playerid, baseX - 135.0, currentY, str);
    PlayerTextDrawFont(playerid, gLoginTD[playerid][TD_LOGIN_DESCRIPTION], 1);
    PlayerTextDrawLetterSize(playerid, gLoginTD[playerid][TD_LOGIN_DESCRIPTION], 0.19, 0.85);
    PlayerTextDrawColor(playerid, gLoginTD[playerid][TD_LOGIN_DESCRIPTION], COLOR_WHITE);
    PlayerTextDrawSetShadow(playerid, gLoginTD[playerid][TD_LOGIN_DESCRIPTION], 0);
    PlayerTextDrawShow(playerid, gLoginTD[playerid][TD_LOGIN_DESCRIPTION]);

    currentY += (isRegister ? 42.0 : 28.0);

    gLoginTD[playerid][TD_LOGIN_BORDER_BOTTOM] = CreatePlayerTextDraw(playerid, baseX - 145.0, currentY, "+=================================================+");
    PlayerTextDrawFont(playerid, gLoginTD[playerid][TD_LOGIN_BORDER_BOTTOM], 1);
    PlayerTextDrawLetterSize(playerid, gLoginTD[playerid][TD_LOGIN_BORDER_BOTTOM], 0.145, 0.8);
    PlayerTextDrawColor(playerid, gLoginTD[playerid][TD_LOGIN_BORDER_BOTTOM], COLOR_CYAN);
    PlayerTextDrawSetShadow(playerid, gLoginTD[playerid][TD_LOGIN_BORDER_BOTTOM], 0);
    PlayerTextDrawShow(playerid, gLoginTD[playerid][TD_LOGIN_BORDER_BOTTOM]);

    currentY += 20.0;

    // ------------------------------------------------------------
    //  Champ de saisie : bordure orange + boite noire de remplissage
    // ------------------------------------------------------------
    gLoginTD[playerid][TD_LOGIN_INPUT_BORDER] = CreatePlayerTextDraw(playerid, baseX - 145.0, currentY, "_");
    PlayerTextDrawTextSize(playerid, gLoginTD[playerid][TD_LOGIN_INPUT_BORDER], baseX + 145.0, currentY + 22.0);
    PlayerTextDrawUseBox(playerid, gLoginTD[playerid][TD_LOGIN_INPUT_BORDER], 1);
    PlayerTextDrawBoxColor(playerid, gLoginTD[playerid][TD_LOGIN_INPUT_BORDER], COLOR_ORANGE);
    PlayerTextDrawColor(playerid, gLoginTD[playerid][TD_LOGIN_INPUT_BORDER], 0x00000000);
    PlayerTextDrawShow(playerid, gLoginTD[playerid][TD_LOGIN_INPUT_BORDER]);

    gLoginTD[playerid][TD_LOGIN_INPUT_BOX] = CreatePlayerTextDraw(playerid, baseX - 143.0, currentY + 2.0, "_");
    PlayerTextDrawTextSize(playerid, gLoginTD[playerid][TD_LOGIN_INPUT_BOX], baseX + 143.0, currentY + 20.0);
    PlayerTextDrawUseBox(playerid, gLoginTD[playerid][TD_LOGIN_INPUT_BOX], 1);
    PlayerTextDrawBoxColor(playerid, gLoginTD[playerid][TD_LOGIN_INPUT_BOX], 0x000000E0);
    PlayerTextDrawColor(playerid, gLoginTD[playerid][TD_LOGIN_INPUT_BOX], 0x00000000);
    PlayerTextDrawSetSelectable(playerid, gLoginTD[playerid][TD_LOGIN_INPUT_BOX], 1);
    PlayerTextDrawShow(playerid, gLoginTD[playerid][TD_LOGIN_INPUT_BOX]);

    gLoginTD[playerid][TD_LOGIN_INPUT_TEXT] = CreatePlayerTextDraw(playerid, baseX - 138.0, currentY + 4.0, "");
    PlayerTextDrawFont(playerid, gLoginTD[playerid][TD_LOGIN_INPUT_TEXT], 1);
    PlayerTextDrawLetterSize(playerid, gLoginTD[playerid][TD_LOGIN_INPUT_TEXT], 0.2, 0.9);
    PlayerTextDrawColor(playerid, gLoginTD[playerid][TD_LOGIN_INPUT_TEXT], COLOR_WHITE);
    PlayerTextDrawSetShadow(playerid, gLoginTD[playerid][TD_LOGIN_INPUT_TEXT], 0);
    PlayerTextDrawShow(playerid, gLoginTD[playerid][TD_LOGIN_INPUT_TEXT]);

    currentY += 30.0;

    // ------------------------------------------------------------
    //  Boutons ">> CREER COMPTE" / ">> VALIDER" (cyan) et "Quitter" (rouge)
    // ------------------------------------------------------------
    gLoginTD[playerid][TD_LOGIN_BUTTON_CREATE] = CreatePlayerTextDraw(playerid, baseX - 145.0, currentY, isRegister ? ">> CREER COMPTE" : ">> VALIDER");
    PlayerTextDrawFont(playerid, gLoginTD[playerid][TD_LOGIN_BUTTON_CREATE], 2);
    PlayerTextDrawLetterSize(playerid, gLoginTD[playerid][TD_LOGIN_BUTTON_CREATE], 0.21, 1.0);
    PlayerTextDrawColor(playerid, gLoginTD[playerid][TD_LOGIN_BUTTON_CREATE], COLOR_CYAN);
    PlayerTextDrawSetShadow(playerid, gLoginTD[playerid][TD_LOGIN_BUTTON_CREATE], 0);
    PlayerTextDrawSetSelectable(playerid, gLoginTD[playerid][TD_LOGIN_BUTTON_CREATE], 1);
    PlayerTextDrawShow(playerid, gLoginTD[playerid][TD_LOGIN_BUTTON_CREATE]);

    gLoginTD[playerid][TD_LOGIN_BUTTON_QUIT] = CreatePlayerTextDraw(playerid, baseX + 85.0, currentY, "Quitter");
    PlayerTextDrawFont(playerid, gLoginTD[playerid][TD_LOGIN_BUTTON_QUIT], 2);
    PlayerTextDrawLetterSize(playerid, gLoginTD[playerid][TD_LOGIN_BUTTON_QUIT], 0.21, 1.0);
    PlayerTextDrawColor(playerid, gLoginTD[playerid][TD_LOGIN_BUTTON_QUIT], COLOR_RED);
    PlayerTextDrawSetShadow(playerid, gLoginTD[playerid][TD_LOGIN_BUTTON_QUIT], 0);
    PlayerTextDrawSetSelectable(playerid, gLoginTD[playerid][TD_LOGIN_BUTTON_QUIT], 1);
    PlayerTextDrawShow(playerid, gLoginTD[playerid][TD_LOGIN_BUTTON_QUIT]);

    gLoginTDShown[playerid] = true;
    return 1;
}

stock HideLoginRegisterTD(playerid)
{
    if(!gLoginTDShown[playerid]) return 0;

    for(new i = 0; i < MAX_LOGIN_TDS; i++)
    {
        if(gLoginTD[playerid][i] != PlayerText:INVALID_TEXT_DRAW)
        {
            PlayerTextDrawDestroy(playerid, gLoginTD[playerid][i]);
            gLoginTD[playerid][i] = PlayerText:INVALID_TEXT_DRAW;
        }
    }
    gLoginTDShown[playerid] = false;
    return 1;
}

stock ShowPasswordInputDialog(playerid)
{
    ShowPlayerDialog(playerid, DIALOG_PASSWORD_INPUT, DIALOG_STYLE_PASSWORD, "Saisie du mot de passe", "Veuillez entrer votre mot de passe :", "Valider", "Annuler");
    return 1;
}

// ==============================================================
//  CHARACTER SETUP - sexe / age / skin avec previsualisation 3D
//  (le joueur voit son personnage en vrai, dans un salon prive,
//  identique au principe utilise sur Liberty State)
// ==============================================================

// Position d'attente utilisee pour la previsualisation du personnage.
// Chaque joueur y est isole via SetPlayerVirtualWorld(playerid, playerid+1)
// pour ne jamais voir ni etre vu par un autre joueur en pleine creation.
// L'interieur 3 est reutilise a plusieurs endroits reels de la map SA (Jizzy's Club,
// Johnson House, Wheel Arch Angels...). L'ancienne position (-1449.9767, -337.8399, 999.6797)
// ne correspond a aucun de ces emplacements reels : le joueur se retrouvait donc hors du
// decor charge, d'ou le fond bleu/vide (ciel) au lieu d'une piece.
// On utilise ici les coordonnees reelles de l'interieur "Jizzy's Club" (int 3), qui offre
// un vrai sol/plafond/eclairage, avec les memes offsets camera qu'avant.
#define CHARSETUP_INT 3
new const Float:CHARSETUP_POS[4] = {-2637.6900, 1404.2400, 906.4600, 332.0};
new const Float:CHARSETUP_CAM_POS[3] = {-2639.4133, 1407.4799, 906.7803};
new const Float:CHARSETUP_CAM_LOOK[3] = {-2637.6900, 1404.2400, 906.6803};

stock GetCurrentSkinForCharSetup(playerid)
{
    if(gCharGender[playerid] == 1)
        return FEMALE_CIV_SKINS[gCharSkinIndex[playerid] % sizeof(FEMALE_CIV_SKINS)];
    return MALE_CIV_SKINS[gCharSkinIndex[playerid] % sizeof(MALE_CIV_SKINS)];
}

stock ShowCharacterSetupTD(playerid)
{
    HideCharacterSetupTD(playerid);

    gCharGender[playerid] = 0;
    gCharAge[playerid] = 18;
    gCharSkinIndex[playerid] = 0;

    // --- Salon prive de previsualisation ---
    SetPlayerVirtualWorld(playerid, playerid + 1);
    SetPlayerInterior(playerid, CHARSETUP_INT);
    SetPlayerPos(playerid, CHARSETUP_POS[0], CHARSETUP_POS[1], CHARSETUP_POS[2]);
    SetPlayerFacingAngle(playerid, CHARSETUP_POS[3]);
    SetPlayerCameraPos(playerid, CHARSETUP_CAM_POS[0], CHARSETUP_CAM_POS[1], CHARSETUP_CAM_POS[2]);
    SetPlayerCameraLookAt(playerid, CHARSETUP_CAM_LOOK[0], CHARSETUP_CAM_LOOK[1], CHARSETUP_CAM_LOOK[2]);
    TogglePlayerControllable(playerid, false);
    SetPlayerSkin(playerid, GetCurrentSkinForCharSetup(playerid));

    new Float:baseX = 20.0;
    new Float:baseY = 150.0;

    // --- Bordure exterieure du panneau (liseré bleu, style "Liberty State") ---
    gCSTD[playerid][CS_TD_BORDER] = CreatePlayerTextDraw(playerid, baseX - 6.0, baseY - 6.0, "_");
    PlayerTextDrawTextSize(playerid, gCSTD[playerid][CS_TD_BORDER], baseX + 156.0, baseY + 190.0);
    PlayerTextDrawUseBox(playerid, gCSTD[playerid][CS_TD_BORDER], 1);
    PlayerTextDrawBoxColor(playerid, gCSTD[playerid][CS_TD_BORDER], 0x3C8FE6FF);
    PlayerTextDrawColor(playerid, gCSTD[playerid][CS_TD_BORDER], 0x00000000);
    PlayerTextDrawShow(playerid, gCSTD[playerid][CS_TD_BORDER]);

    // --- Fond principal (opaque, comme sur la reference) ---
    gCSTD[playerid][CS_TD_BG] = CreatePlayerTextDraw(playerid, baseX - 3.0, baseY - 3.0, "_");
    PlayerTextDrawTextSize(playerid, gCSTD[playerid][CS_TD_BG], baseX + 153.0, baseY + 187.0);
    PlayerTextDrawUseBox(playerid, gCSTD[playerid][CS_TD_BG], 1);
    PlayerTextDrawBoxColor(playerid, gCSTD[playerid][CS_TD_BG], 0x0A0A14EE);
    PlayerTextDrawColor(playerid, gCSTD[playerid][CS_TD_BG], 0x00000000);
    PlayerTextDrawShow(playerid, gCSTD[playerid][CS_TD_BG]);

    // --- Bandeau titre "CHARACTER SETUP" ---
    gCSTD[playerid][CS_TD_TITLE_BAR] = CreatePlayerTextDraw(playerid, baseX - 3.0, baseY - 3.0, "_");
    PlayerTextDrawTextSize(playerid, gCSTD[playerid][CS_TD_TITLE_BAR], baseX + 153.0, baseY + 13.0);
    PlayerTextDrawUseBox(playerid, gCSTD[playerid][CS_TD_TITLE_BAR], 1);
    PlayerTextDrawBoxColor(playerid, gCSTD[playerid][CS_TD_TITLE_BAR], 0x1E3A66E6);
    PlayerTextDrawColor(playerid, gCSTD[playerid][CS_TD_TITLE_BAR], 0x00000000);
    PlayerTextDrawShow(playerid, gCSTD[playerid][CS_TD_TITLE_BAR]);

    gCSTD[playerid][CS_TD_TITLE] = CreatePlayerTextDraw(playerid, baseX + 4.0, baseY - 3.0, "CHARACTER SETUP");
    PlayerTextDrawFont(playerid, gCSTD[playerid][CS_TD_TITLE], 2);
    PlayerTextDrawLetterSize(playerid, gCSTD[playerid][CS_TD_TITLE], 0.115, 0.75);
    PlayerTextDrawColor(playerid, gCSTD[playerid][CS_TD_TITLE], COLOR_CYAN);
    PlayerTextDrawSetShadow(playerid, gCSTD[playerid][CS_TD_TITLE], 0);
    PlayerTextDrawShow(playerid, gCSTD[playerid][CS_TD_TITLE]);

    // ================= GENDER =================
    gCSTD[playerid][CS_TD_GENDER_LABEL] = CreatePlayerTextDraw(playerid, baseX + 4.0, baseY + 18.0, "GENDER");
    PlayerTextDrawFont(playerid, gCSTD[playerid][CS_TD_GENDER_LABEL], 2);
    PlayerTextDrawLetterSize(playerid, gCSTD[playerid][CS_TD_GENDER_LABEL], 0.105, 0.65);
    PlayerTextDrawColor(playerid, gCSTD[playerid][CS_TD_GENDER_LABEL], COLOR_WHITE);
    PlayerTextDrawSetShadow(playerid, gCSTD[playerid][CS_TD_GENDER_LABEL], 0);
    PlayerTextDrawShow(playerid, gCSTD[playerid][CS_TD_GENDER_LABEL]);

    // Liseré MALE (s'allume en blanc quand selectionne)
    gCSTD[playerid][CS_TD_MALE_BORDER] = CreatePlayerTextDraw(playerid, baseX + 3.0, baseY + 30.0, "_");
    PlayerTextDrawTextSize(playerid, gCSTD[playerid][CS_TD_MALE_BORDER], baseX + 76.0, baseY + 49.0);
    PlayerTextDrawUseBox(playerid, gCSTD[playerid][CS_TD_MALE_BORDER], 1);
    PlayerTextDrawBoxColor(playerid, gCSTD[playerid][CS_TD_MALE_BORDER], 0x0A0A14EE);
    PlayerTextDrawColor(playerid, gCSTD[playerid][CS_TD_MALE_BORDER], 0x00000000);
    PlayerTextDrawShow(playerid, gCSTD[playerid][CS_TD_MALE_BORDER]);

    gCSTD[playerid][CS_TD_MALE_BTN] = CreatePlayerTextDraw(playerid, baseX + 5.0, baseY + 34.0, "MALE");
    PlayerTextDrawFont(playerid, gCSTD[playerid][CS_TD_MALE_BTN], 2);
    PlayerTextDrawLetterSize(playerid, gCSTD[playerid][CS_TD_MALE_BTN], 0.115, 0.75);
    PlayerTextDrawTextSize(playerid, gCSTD[playerid][CS_TD_MALE_BTN], baseX + 74.0, baseY + 47.0);
    PlayerTextDrawUseBox(playerid, gCSTD[playerid][CS_TD_MALE_BTN], 1);
    PlayerTextDrawBoxColor(playerid, gCSTD[playerid][CS_TD_MALE_BTN], 0x1544AAFF);
    PlayerTextDrawColor(playerid, gCSTD[playerid][CS_TD_MALE_BTN], COLOR_WHITE);
    PlayerTextDrawAlignment(playerid, gCSTD[playerid][CS_TD_MALE_BTN], 2);
    PlayerTextDrawSetShadow(playerid, gCSTD[playerid][CS_TD_MALE_BTN], 0);
    PlayerTextDrawSetSelectable(playerid, gCSTD[playerid][CS_TD_MALE_BTN], 1);
    PlayerTextDrawShow(playerid, gCSTD[playerid][CS_TD_MALE_BTN]);

    // Liseré FEMALE (s'allume en blanc quand selectionne)
    gCSTD[playerid][CS_TD_FEMALE_BORDER] = CreatePlayerTextDraw(playerid, baseX + 80.0, baseY + 30.0, "_");
    PlayerTextDrawTextSize(playerid, gCSTD[playerid][CS_TD_FEMALE_BORDER], baseX + 153.0, baseY + 49.0);
    PlayerTextDrawUseBox(playerid, gCSTD[playerid][CS_TD_FEMALE_BORDER], 1);
    PlayerTextDrawBoxColor(playerid, gCSTD[playerid][CS_TD_FEMALE_BORDER], 0x0A0A14EE);
    PlayerTextDrawColor(playerid, gCSTD[playerid][CS_TD_FEMALE_BORDER], 0x00000000);
    PlayerTextDrawShow(playerid, gCSTD[playerid][CS_TD_FEMALE_BORDER]);

    gCSTD[playerid][CS_TD_FEMALE_BTN] = CreatePlayerTextDraw(playerid, baseX + 82.0, baseY + 34.0, "FEMALE");
    PlayerTextDrawFont(playerid, gCSTD[playerid][CS_TD_FEMALE_BTN], 2);
    PlayerTextDrawLetterSize(playerid, gCSTD[playerid][CS_TD_FEMALE_BTN], 0.115, 0.75);
    PlayerTextDrawTextSize(playerid, gCSTD[playerid][CS_TD_FEMALE_BTN], baseX + 151.0, baseY + 47.0);
    PlayerTextDrawUseBox(playerid, gCSTD[playerid][CS_TD_FEMALE_BTN], 1);
    PlayerTextDrawBoxColor(playerid, gCSTD[playerid][CS_TD_FEMALE_BTN], 0xCC1F8FFF);
    PlayerTextDrawColor(playerid, gCSTD[playerid][CS_TD_FEMALE_BTN], COLOR_WHITE);
    PlayerTextDrawAlignment(playerid, gCSTD[playerid][CS_TD_FEMALE_BTN], 2);
    PlayerTextDrawSetShadow(playerid, gCSTD[playerid][CS_TD_FEMALE_BTN], 0);
    PlayerTextDrawSetSelectable(playerid, gCSTD[playerid][CS_TD_FEMALE_BTN], 1);
    PlayerTextDrawShow(playerid, gCSTD[playerid][CS_TD_FEMALE_BTN]);

    // ================= AGE =================
    gCSTD[playerid][CS_TD_AGE_LABEL] = CreatePlayerTextDraw(playerid, baseX + 4.0, baseY + 55.0, "AGE");
    PlayerTextDrawFont(playerid, gCSTD[playerid][CS_TD_AGE_LABEL], 2);
    PlayerTextDrawLetterSize(playerid, gCSTD[playerid][CS_TD_AGE_LABEL], 0.105, 0.65);
    PlayerTextDrawColor(playerid, gCSTD[playerid][CS_TD_AGE_LABEL], COLOR_WHITE);
    PlayerTextDrawSetShadow(playerid, gCSTD[playerid][CS_TD_AGE_LABEL], 0);
    PlayerTextDrawShow(playerid, gCSTD[playerid][CS_TD_AGE_LABEL]);

    gCSTD[playerid][CS_TD_AGE_BOX] = CreatePlayerTextDraw(playerid, baseX + 3.0, baseY + 66.0, "_");
    PlayerTextDrawTextSize(playerid, gCSTD[playerid][CS_TD_AGE_BOX], baseX + 153.0, baseY + 81.0);
    PlayerTextDrawUseBox(playerid, gCSTD[playerid][CS_TD_AGE_BOX], 1);
    PlayerTextDrawBoxColor(playerid, gCSTD[playerid][CS_TD_AGE_BOX], 0x1B1B28E6);
    PlayerTextDrawColor(playerid, gCSTD[playerid][CS_TD_AGE_BOX], 0x00000000);
    PlayerTextDrawShow(playerid, gCSTD[playerid][CS_TD_AGE_BOX]);

    gCSTD[playerid][CS_TD_AGE_MINUS] = CreatePlayerTextDraw(playerid, baseX + 8.0, baseY + 68.0, "<<<");
    PlayerTextDrawFont(playerid, gCSTD[playerid][CS_TD_AGE_MINUS], 2);
    PlayerTextDrawLetterSize(playerid, gCSTD[playerid][CS_TD_AGE_MINUS], 0.115, 0.75);
    PlayerTextDrawColor(playerid, gCSTD[playerid][CS_TD_AGE_MINUS], COLOR_CYAN);
    PlayerTextDrawSetShadow(playerid, gCSTD[playerid][CS_TD_AGE_MINUS], 0);
    PlayerTextDrawSetSelectable(playerid, gCSTD[playerid][CS_TD_AGE_MINUS], 1);
    PlayerTextDrawShow(playerid, gCSTD[playerid][CS_TD_AGE_MINUS]);

    gCSTD[playerid][CS_TD_AGE_VALUE] = CreatePlayerTextDraw(playerid, baseX + 78.0, baseY + 68.0, "18");
    PlayerTextDrawFont(playerid, gCSTD[playerid][CS_TD_AGE_VALUE], 2);
    PlayerTextDrawLetterSize(playerid, gCSTD[playerid][CS_TD_AGE_VALUE], 0.12, 0.75);
    PlayerTextDrawColor(playerid, gCSTD[playerid][CS_TD_AGE_VALUE], COLOR_WHITE);
    PlayerTextDrawAlignment(playerid, gCSTD[playerid][CS_TD_AGE_VALUE], 2);
    PlayerTextDrawSetShadow(playerid, gCSTD[playerid][CS_TD_AGE_VALUE], 0);
    PlayerTextDrawShow(playerid, gCSTD[playerid][CS_TD_AGE_VALUE]);

    gCSTD[playerid][CS_TD_AGE_PLUS] = CreatePlayerTextDraw(playerid, baseX + 142.0, baseY + 68.0, ">>>");
    PlayerTextDrawFont(playerid, gCSTD[playerid][CS_TD_AGE_PLUS], 2);
    PlayerTextDrawLetterSize(playerid, gCSTD[playerid][CS_TD_AGE_PLUS], 0.115, 0.75);
    PlayerTextDrawColor(playerid, gCSTD[playerid][CS_TD_AGE_PLUS], COLOR_CYAN);
    PlayerTextDrawSetShadow(playerid, gCSTD[playerid][CS_TD_AGE_PLUS], 0);
    PlayerTextDrawSetSelectable(playerid, gCSTD[playerid][CS_TD_AGE_PLUS], 1);
    PlayerTextDrawShow(playerid, gCSTD[playerid][CS_TD_AGE_PLUS]);

    // ================= SKIN =================
    gCSTD[playerid][CS_TD_SKIN_LABEL] = CreatePlayerTextDraw(playerid, baseX + 4.0, baseY + 87.0, "SKIN");
    PlayerTextDrawFont(playerid, gCSTD[playerid][CS_TD_SKIN_LABEL], 2);
    PlayerTextDrawLetterSize(playerid, gCSTD[playerid][CS_TD_SKIN_LABEL], 0.105, 0.65);
    PlayerTextDrawColor(playerid, gCSTD[playerid][CS_TD_SKIN_LABEL], COLOR_WHITE);
    PlayerTextDrawSetShadow(playerid, gCSTD[playerid][CS_TD_SKIN_LABEL], 0);
    PlayerTextDrawShow(playerid, gCSTD[playerid][CS_TD_SKIN_LABEL]);

    gCSTD[playerid][CS_TD_SKIN_BOX] = CreatePlayerTextDraw(playerid, baseX + 3.0, baseY + 98.0, "_");
    PlayerTextDrawTextSize(playerid, gCSTD[playerid][CS_TD_SKIN_BOX], baseX + 153.0, baseY + 113.0);
    PlayerTextDrawUseBox(playerid, gCSTD[playerid][CS_TD_SKIN_BOX], 1);
    PlayerTextDrawBoxColor(playerid, gCSTD[playerid][CS_TD_SKIN_BOX], 0x1B1B28E6);
    PlayerTextDrawColor(playerid, gCSTD[playerid][CS_TD_SKIN_BOX], 0x00000000);
    PlayerTextDrawShow(playerid, gCSTD[playerid][CS_TD_SKIN_BOX]);

    gCSTD[playerid][CS_TD_SKIN_MINUS] = CreatePlayerTextDraw(playerid, baseX + 8.0, baseY + 100.0, "<<<");
    PlayerTextDrawFont(playerid, gCSTD[playerid][CS_TD_SKIN_MINUS], 2);
    PlayerTextDrawLetterSize(playerid, gCSTD[playerid][CS_TD_SKIN_MINUS], 0.115, 0.75);
    PlayerTextDrawColor(playerid, gCSTD[playerid][CS_TD_SKIN_MINUS], COLOR_CYAN);
    PlayerTextDrawSetShadow(playerid, gCSTD[playerid][CS_TD_SKIN_MINUS], 0);
    PlayerTextDrawSetSelectable(playerid, gCSTD[playerid][CS_TD_SKIN_MINUS], 1);
    PlayerTextDrawShow(playerid, gCSTD[playerid][CS_TD_SKIN_MINUS]);

    gCSTD[playerid][CS_TD_SKIN_VALUE] = CreatePlayerTextDraw(playerid, baseX + 78.0, baseY + 100.0, "1/49");
    PlayerTextDrawFont(playerid, gCSTD[playerid][CS_TD_SKIN_VALUE], 2);
    PlayerTextDrawLetterSize(playerid, gCSTD[playerid][CS_TD_SKIN_VALUE], 0.12, 0.75);
    PlayerTextDrawColor(playerid, gCSTD[playerid][CS_TD_SKIN_VALUE], COLOR_WHITE);
    PlayerTextDrawAlignment(playerid, gCSTD[playerid][CS_TD_SKIN_VALUE], 2);
    PlayerTextDrawSetShadow(playerid, gCSTD[playerid][CS_TD_SKIN_VALUE], 0);
    PlayerTextDrawShow(playerid, gCSTD[playerid][CS_TD_SKIN_VALUE]);

    gCSTD[playerid][CS_TD_SKIN_PLUS] = CreatePlayerTextDraw(playerid, baseX + 142.0, baseY + 100.0, ">>>");
    PlayerTextDrawFont(playerid, gCSTD[playerid][CS_TD_SKIN_PLUS], 2);
    PlayerTextDrawLetterSize(playerid, gCSTD[playerid][CS_TD_SKIN_PLUS], 0.115, 0.75);
    PlayerTextDrawColor(playerid, gCSTD[playerid][CS_TD_SKIN_PLUS], COLOR_CYAN);
    PlayerTextDrawSetShadow(playerid, gCSTD[playerid][CS_TD_SKIN_PLUS], 0);
    PlayerTextDrawSetSelectable(playerid, gCSTD[playerid][CS_TD_SKIN_PLUS], 1);
    PlayerTextDrawShow(playerid, gCSTD[playerid][CS_TD_SKIN_PLUS]);

    // ================= CONFIRMER =================
    gCSTD[playerid][CS_TD_CONFIRM_BORDER] = CreatePlayerTextDraw(playerid, baseX + 3.0, baseY + 119.0, "_");
    PlayerTextDrawTextSize(playerid, gCSTD[playerid][CS_TD_CONFIRM_BORDER], baseX + 153.0, baseY + 138.0);
    PlayerTextDrawUseBox(playerid, gCSTD[playerid][CS_TD_CONFIRM_BORDER], 1);
    PlayerTextDrawBoxColor(playerid, gCSTD[playerid][CS_TD_CONFIRM_BORDER], 0x33CC33FF);
    PlayerTextDrawColor(playerid, gCSTD[playerid][CS_TD_CONFIRM_BORDER], 0x00000000);
    PlayerTextDrawShow(playerid, gCSTD[playerid][CS_TD_CONFIRM_BORDER]);

    gCSTD[playerid][CS_TD_CONFIRM_BTN] = CreatePlayerTextDraw(playerid, baseX + 5.0, baseY + 122.0, "CONFIRMER");
    PlayerTextDrawFont(playerid, gCSTD[playerid][CS_TD_CONFIRM_BTN], 2);
    PlayerTextDrawLetterSize(playerid, gCSTD[playerid][CS_TD_CONFIRM_BTN], 0.13, 0.8);
    PlayerTextDrawTextSize(playerid, gCSTD[playerid][CS_TD_CONFIRM_BTN], baseX + 151.0, baseY + 136.0);
    PlayerTextDrawUseBox(playerid, gCSTD[playerid][CS_TD_CONFIRM_BTN], 1);
    PlayerTextDrawBoxColor(playerid, gCSTD[playerid][CS_TD_CONFIRM_BTN], 0x0F260FE6);
    PlayerTextDrawColor(playerid, gCSTD[playerid][CS_TD_CONFIRM_BTN], 0x33FF33FF);
    PlayerTextDrawAlignment(playerid, gCSTD[playerid][CS_TD_CONFIRM_BTN], 2);
    PlayerTextDrawSetShadow(playerid, gCSTD[playerid][CS_TD_CONFIRM_BTN], 0);
    PlayerTextDrawSetSelectable(playerid, gCSTD[playerid][CS_TD_CONFIRM_BTN], 1);
    PlayerTextDrawShow(playerid, gCSTD[playerid][CS_TD_CONFIRM_BTN]);

    gCharSetupShown[playerid] = true;
    RefreshCharSetupGenderVisual(playerid);
    SelectTextDraw(playerid, 0x00FF00FF);
    return 1;
}

stock HideCharacterSetupTD(playerid)
{
    if(!gCharSetupShown[playerid]) return 0;

    for(new i = 0; i < MAX_CHARSETUP_TDS; i++)
    {
        if(gCSTD[playerid][i] != PlayerText:INVALID_TEXT_DRAW)
        {
            PlayerTextDrawDestroy(playerid, gCSTD[playerid][i]);
            gCSTD[playerid][i] = PlayerText:INVALID_TEXT_DRAW;
        }
    }
    gCharSetupShown[playerid] = false;
    return 1;
}

stock RefreshCharSetupGenderVisual(playerid)
{
    if(gCharGender[playerid] == 0)
    {
        PlayerTextDrawBoxColor(playerid, gCSTD[playerid][CS_TD_MALE_BORDER], COLOR_WHITE);
        PlayerTextDrawBoxColor(playerid, gCSTD[playerid][CS_TD_FEMALE_BORDER], 0x0A0A14EE);
    }
    else
    {
        PlayerTextDrawBoxColor(playerid, gCSTD[playerid][CS_TD_FEMALE_BORDER], COLOR_WHITE);
        PlayerTextDrawBoxColor(playerid, gCSTD[playerid][CS_TD_MALE_BORDER], 0x0A0A14EE);
    }
    PlayerTextDrawShow(playerid, gCSTD[playerid][CS_TD_MALE_BORDER]);
    PlayerTextDrawShow(playerid, gCSTD[playerid][CS_TD_FEMALE_BORDER]);
    return 1;
}

stock RefreshCharSetupSkinDisplay(playerid)
{
    new maxSkins = (gCharGender[playerid] == 1) ? sizeof(FEMALE_CIV_SKINS) : sizeof(MALE_CIV_SKINS);
    new str[16];
    format(str, sizeof(str), "%d/%d", gCharSkinIndex[playerid] + 1, maxSkins);
    PlayerTextDrawSetString(playerid, gCSTD[playerid][CS_TD_SKIN_VALUE], str);
    SetPlayerSkin(playerid, GetCurrentSkinForCharSetup(playerid));
    return 1;
}

stock RefreshCharSetupAgeDisplay(playerid)
{
    new str[8];
    format(str, sizeof(str), "%d", gCharAge[playerid]);
    PlayerTextDrawSetString(playerid, gCSTD[playerid][CS_TD_AGE_VALUE], str);
    return 1;
}

// Appelee lorsque le joueur clique "CONFIRMER" sur l'ecran CHARACTER SETUP :
// on enchaine avec les papiers d'identite (date de naissance, situation
// matrimoniale, lieu de naissance) avant de creer reellement le compte.
stock ShowDOBInputDialog(playerid)
{
    ShowPlayerDialog(playerid, DIALOG_CHARSETUP_DOB, DIALOG_STYLE_INPUT,
        "Date de naissance",
        "Entrez votre date de naissance au format JJ/MM/AAAA :\n(exemple : 14/07/2000)",
        "Valider", "");
    return 1;
}

stock ShowMaritalStatusDialog(playerid)
{
    ShowPlayerDialog(playerid, DIALOG_CHARSETUP_MARITAL, DIALOG_STYLE_LIST,
        "Situation matrimoniale",
        "Celibataire\nMarie(e)",
        "Choisir", "");
    return 1;
}

stock ShowBirthplaceDialog(playerid)
{
    new items[400];
    items[0] = EOS;
    for(new i = 0; i < 14; i++)
    {
        strcat(items, BIRTHPLACE_CITIES[i], sizeof(items));
        if(i != 13) strcat(items, "\n", sizeof(items));
    }
    ShowPlayerDialog(playerid, DIALOG_CHARSETUP_BIRTHPLACE, DIALOG_STYLE_LIST,
        "Lieu de naissance",
        items,
        "Choisir", "");
    return 1;
}

// Validation simple du format JJ/MM/AAAA (10 caracteres, separateurs '/')
stock IsValidDateFormat(const date[])
{
    if(strlen(date) != 10) return 0;
    if(date[2] != '/' || date[5] != '/') return 0;
    for(new i = 0; i < 10; i++)
    {
        if(i == 2 || i == 5) continue;
        if(date[i] < '0' || date[i] > '9') return 0;
    }
    new day = ((date[0] - '0') * 10) + (date[1] - '0');
    new month = ((date[3] - '0') * 10) + (date[4] - '0');
    if(day < 1 || day > 31) return 0;
    if(month < 1 || month > 12) return 0;
    return 1;
}

// Ecrit reellement le compte sur le disque, une fois que le joueur a
// termine la creation de son personnage (sexe/age/skin + papiers).
public FinalizeAccountCreation(playerid)
{
    new File:f = fopen(UserPathStr(playerid), io_write);
    if(f)
    {
        new chosenSkin = GetCurrentSkinForCharSetup(playerid);
        new line[128];

        format(line, sizeof(line), "Password=%d\r\n", gPendingPassHash[playerid]);
        fwrite(f, line);
        format(line, sizeof(line), "Cash=100000\r\n");
        fwrite(f, line);
        format(line, sizeof(line), "Admin=0\r\n");
        fwrite(f, line);
        format(line, sizeof(line), "Skin=%d\r\n", chosenSkin);
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
        format(line, sizeof(line), "DateNaissance=%s\r\n", gCharDOB[playerid]);
        fwrite(f, line);
        format(line, sizeof(line), "PermisConduire=0\r\n");
        fwrite(f, line);
        format(line, sizeof(line), "PortArme=0\r\n");
        fwrite(f, line);

        new regY, regM, regD;
        getdate(regY, regM, regD);
        format(line, sizeof(line), "Sexe=%s\r\n", (gCharGender[playerid] == 1) ? "F" : "H");
        fwrite(f, line);
        format(line, sizeof(line), "Age=%d\r\n", gCharAge[playerid]);
        fwrite(f, line);
        format(line, sizeof(line), "LieuNaissance=%s\r\n", gCharBirthplace[playerid]);
        fwrite(f, line);
        format(line, sizeof(line), "DateDelivID=%02d/%02d/%04d\r\n", regD, regM, regY);
        fwrite(f, line);
        format(line, sizeof(line), "SituationMatrimoniale=%s\r\n", gCharMarital[playerid]);
        fwrite(f, line);
        format(line, sizeof(line), "PermisPL=0\r\n");
        fwrite(f, line);
        format(line, sizeof(line), "PermisAvion=0\r\n");
        fwrite(f, line);
        format(line, sizeof(line), "PermisBateau=0\r\n");
        fwrite(f, line);
        format(line, sizeof(line), "PermisMoto=0\r\n");
        fwrite(f, line);
        format(line, sizeof(line), "DatePermisVehicule=--/--/----\r\n");
        fwrite(f, line);
        format(line, sizeof(line), "DatePermisPL=--/--/----\r\n");
        fwrite(f, line);
        format(line, sizeof(line), "DatePermisAvion=--/--/----\r\n");
        fwrite(f, line);
        format(line, sizeof(line), "DatePermisBateau=--/--/----\r\n");
        fwrite(f, line);
        format(line, sizeof(line), "DatePermisMoto=--/--/----\r\n");
        fwrite(f, line);
        format(line, sizeof(line), "Profession=Sans emploi\r\n");
        fwrite(f, line);
        format(line, sizeof(line), "TypeArme=Aucun\r\n");
        fwrite(f, line);
        format(line, sizeof(line), "NomArme=Aucun\r\n");
        fwrite(f, line);
        format(line, sizeof(line), "Faim=100\r\n");
        fwrite(f, line);
        format(line, sizeof(line), "Soif=100\r\n");
        fwrite(f, line);
        format(line, sizeof(line), "Fatigue=0\r\n");
        fwrite(f, line);
        format(line, sizeof(line), "Stress=0\r\n");
        fwrite(f, line);
        format(line, sizeof(line), "Moral=100\r\n");
        fwrite(f, line);
        fclose(f);

        SendClientMessage(playerid, COLOR_GREEN, "Votre compte a ete cree avec succes ! Vous etes maintenant connecte.");
        if(gLoginTimer[playerid] != 0) { KillTimer(gLoginTimer[playerid]); gLoginTimer[playerid] = 0; }
        IsLoggedIn[playerid] = 1;
        LoadUserData(playerid);
        SetPlayerVirtualWorld(playerid, 0);
        TogglePlayerControllable(playerid, true);
        CancelSelectTextDraw(playerid);
        FinalizeLogin(playerid);
    }
    else
    {
        new pname[MAX_PLAYER_NAME], errmsg[160];
        GetPlayerName(playerid, pname, sizeof(pname));
        format(errmsg, sizeof(errmsg), "[ERREUR] Impossible de creer le fichier de compte pour %s (dossier /scriptfiles/Accounts/ manquant sur le serveur ?)", pname);
        print(errmsg);
        SendClientMessage(playerid, COLOR_RED, "Erreur serveur : impossible de creer votre compte. Contactez un administrateur.");
        Kick(playerid);
    }
    return 1;
}


public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    if(dialogid == DIALOG_PASSWORD_INPUT)
    {
        if(response)
        {
            format(gPlayerInputPassword[playerid], MAX_PASS_LENGTH, "%s", inputtext);
            new stars[MAX_PASS_LENGTH];
            for(new i = 0; i < strlen(inputtext); i++) stars[i] = '*';
            stars[strlen(inputtext)] = EOS;
            PlayerTextDrawSetString(playerid, gLoginTD[playerid][TD_LOGIN_INPUT_TEXT], stars);
        }
        return 1;
    }

    if(dialogid == DIALOG_REGISTER)
    {
        if(!response)
        {
            Kick(playerid);
            return 1;
        }
        if(strlen(inputtext) < 4)
        {
            SendClientMessage(playerid, COLOR_RED, "Votre mot de passe doit contenir au moins 4 caracteres !");
            new rname[MAX_PLAYER_NAME];
            GetPlayerName(playerid, rname, sizeof(rname));
            ShowLoginRegisterDialog(playerid, true, rname);
            return 1;
        }

        // Le mot de passe est valide : on ne cree pas encore le compte.
        // On enchaine avec la creation du personnage (sexe/age/skin puis
        // papiers d'identite) ; le compte n'est ecrit sur le disque qu'a
        // la toute fin, dans FinalizeAccountCreation().
        gPendingPassHash[playerid] = udb_hash(inputtext);
        ShowCharacterSetupTD(playerid);
        return 1;
    }

    if(dialogid == DIALOG_CHARSETUP_DOB)
    {
        if(!response)
        {
            ShowDOBInputDialog(playerid);
            return 1;
        }
        if(!IsValidDateFormat(inputtext))
        {
            SendClientMessage(playerid, COLOR_RED, "Format invalide ! Utilisez JJ/MM/AAAA (exemple : 14/07/2000).");
            ShowDOBInputDialog(playerid);
            return 1;
        }
        format(gCharDOB[playerid], 11, "%s", inputtext);
        ShowMaritalStatusDialog(playerid);
        return 1;
    }

    if(dialogid == DIALOG_CHARSETUP_MARITAL)
    {
        if(!response)
        {
            ShowMaritalStatusDialog(playerid);
            return 1;
        }
        format(gCharMarital[playerid], 16, "%s", (listitem == 1) ? "Marie(e)" : "Celibataire");
        ShowBirthplaceDialog(playerid);
        return 1;
    }

    if(dialogid == DIALOG_CHARSETUP_BIRTHPLACE)
    {
        if(!response)
        {
            ShowBirthplaceDialog(playerid);
            return 1;
        }
        if(listitem < 0 || listitem >= 14) listitem = 0;
        format(gCharBirthplace[playerid], 32, "%s", BIRTHPLACE_CITIES[listitem]);
        FinalizeAccountCreation(playerid);
        return 1;
    }

    if(dialogid == DIALOG_LOGIN)
    {
        if(!response)
        {
            Kick(playerid);
            return 1;
        }

        new File:f = fopen(UserPathStr(playerid), io_read);
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
            CancelSelectTextDraw(playerid);
            HideLoginRegisterTD(playerid);
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
            SendClientMessage(playerid, COLOR_RED, "Mot de passe incorrect ! Veuillez reessayer.");
            new rname[MAX_PLAYER_NAME];
            GetPlayerName(playerid, rname, sizeof(rname));
            ShowLoginRegisterDialog(playerid, false, rname);
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

        new name[MAX_PLAYER_NAME], fullName[MAX_PLAYER_NAME];
        GetPlayerName(playerid, name, sizeof(name));
        FormatFullName(fullName, sizeof(fullName), name);

        if(listitem == 0) // Carte d'identite
        {
            new labels[MAX_CARD_FIELDS][24], values[MAX_CARD_FIELDS][48], colors[MAX_CARD_FIELDS];
            new numCarte = 100 + (PlayerInfo[playerid][pIDNum] % 900);

            format(labels[0], 24, "NOM ET PRENOM");
            format(values[0], 48, "%s", fullName);
            colors[0] = 0xFFFFFFFF;

            format(labels[1], 24, "SEXE");
            format(values[1], 48, "%s", (!strcmp(PlayerInfo[playerid][pSexe], "F")) ? ("Femme") : ("Homme"));
            colors[1] = 0xFFFFFFFF;

            format(labels[2], 24, "AGE");
            format(values[2], 48, "%d ans", PlayerInfo[playerid][pAge]);
            colors[2] = 0xFFFFFFFF;

            format(labels[3], 24, "DATE DE NAISSANCE");
            format(values[3], 48, "%s", PlayerInfo[playerid][pDateNaissance]);
            colors[3] = 0xFFFFFFFF;

            format(labels[4], 24, "LIEU DE NAISSANCE");
            format(values[4], 48, "%s", PlayerInfo[playerid][pLieuNaissance]);
            colors[4] = 0xFFFFFFFF;

            format(labels[5], 24, "DATE DE DELIVRANCE");
            format(values[5], 48, "%s", PlayerInfo[playerid][pDateDelivID]);
            colors[5] = 0xFFFFFFFF;

            format(labels[6], 24, "SITUATION");
            format(values[6], 48, "%s", PlayerInfo[playerid][pSituationMatrimoniale]);
            colors[6] = 0xFFFFFFFF;

            ShowDocumentCard(playerid, "CARTE D'IDENTITE", 0x1A3E8CFF, numCarte, labels, values, colors, 7, GetPlayerSkin(playerid));
        }
        else if(listitem == 1) // Permis de conduire
        {
            new labels[MAX_CARD_FIELDS][24], values[MAX_CARD_FIELDS][48], colors[MAX_CARD_FIELDS];
            new numPermis = 100 + ((PlayerInfo[playerid][pIDNum] + 300) % 900);

            format(labels[0], 24, "NOM ET PRENOM");
            format(values[0], 48, "%s", fullName);
            colors[0] = 0xFFFFFFFF;

            format(labels[1], 24, "SEXE");
            format(values[1], 48, "%s", (!strcmp(PlayerInfo[playerid][pSexe], "F")) ? ("Femme") : ("Homme"));
            colors[1] = 0xFFFFFFFF;

            format(labels[2], 24, "AGE");
            format(values[2], 48, "%d ans", PlayerInfo[playerid][pAge]);
            colors[2] = 0xFFFFFFFF;

            format(labels[3], 24, "VEHICULE");
            if(PlayerInfo[playerid][pPermisConduire]) { format(values[3], 48, "Valide - %s", PlayerInfo[playerid][pDatePermisVehicule]); colors[3] = 0x33CC33FF; }
            else { format(values[3], 48, "Non obtenu"); colors[3] = 0xFFFFFFFF; }

            format(labels[4], 24, "POIDS LOURD");
            if(PlayerInfo[playerid][pPermisPL]) { format(values[4], 48, "Valide - %s", PlayerInfo[playerid][pDatePermisPL]); colors[4] = 0x33CC33FF; }
            else { format(values[4], 48, "Non obtenu"); colors[4] = 0xFFFFFFFF; }

            format(labels[5], 24, "AVION");
            if(PlayerInfo[playerid][pPermisAvion]) { format(values[5], 48, "Valide - %s", PlayerInfo[playerid][pDatePermisAvion]); colors[5] = 0x33CC33FF; }
            else { format(values[5], 48, "Non obtenu"); colors[5] = 0xFFFFFFFF; }

            format(labels[6], 24, "BATEAU");
            if(PlayerInfo[playerid][pPermisBateau]) { format(values[6], 48, "Valide - %s", PlayerInfo[playerid][pDatePermisBateau]); colors[6] = 0x33CC33FF; }
            else { format(values[6], 48, "Non obtenu"); colors[6] = 0xFFFFFFFF; }

            format(labels[7], 24, "MOTO");
            if(PlayerInfo[playerid][pPermisMoto]) { format(values[7], 48, "Valide - %s", PlayerInfo[playerid][pDatePermisMoto]); colors[7] = 0x33CC33FF; }
            else { format(values[7], 48, "Non obtenu"); colors[7] = 0xFFFFFFFF; }

            ShowDocumentCard(playerid, "PERMIS DE CONDUIRE", 0xC97A1EFF, numPermis, labels, values, colors, 8, GetPlayerSkin(playerid));
        }
        else if(listitem == 2) // Port d'armes
        {
            new labels[MAX_CARD_FIELDS][24], values[MAX_CARD_FIELDS][48], colors[MAX_CARD_FIELDS];
            new numPort = 100 + ((PlayerInfo[playerid][pIDNum] + 600) % 900);

            format(labels[0], 24, "NOM ET PRENOM");
            format(values[0], 48, "%s", fullName);
            colors[0] = 0xFFFFFFFF;

            format(labels[1], 24, "PROFESSION");
            format(values[1], 48, "%s", PlayerInfo[playerid][pProfession]);
            colors[1] = 0xFFFFFFFF;

            format(labels[2], 24, "TYPE D'ARME");
            format(values[2], 48, "%s", PlayerInfo[playerid][pTypeArme]);
            colors[2] = 0xFFFFFFFF;

            format(labels[3], 24, "NOM DE L'ARME");
            format(values[3], 48, "%s", PlayerInfo[playerid][pNomArme]);
            colors[3] = 0xFFFFFFFF;

            ShowDocumentCard(playerid, "PORT D'ARMES", 0x8C1A1AFF, numPort, labels, values, colors, 4, GetPlayerSkin(playerid));
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
//
// NOTE : ne repose plus sur strmid(). Sur ce serveur, strmid() se comportait
// de facon incoherente (KLEN=0 / VLEN=0 alors que la ligne source, ex.
// "Admin=0", etait correcte) : il ne copiait rien du tout. C'etait la cause
// racine de tous les champs charges a 0/vide (pCash y compris). On copie donc
// desormais caractere par caractere, sans dependre de cette fonction native.
stock sscanf_simple(line[], key[], val[], maxKey = sizeof key, maxVal = sizeof val)
{
    new pos = strfind(line, "=", false);
    if(pos == -1) return 0;

    new i;
    for(i = 0; i < pos && i < (maxKey - 1); i++)
    {
        key[i] = line[i];
    }
    key[i] = '\0';

    new lineLen = strlen(line);
    new j = 0;
    for(i = pos + 1; i < lineLen && j < (maxVal - 1); i++, j++)
    {
        val[j] = line[i];
    }
    val[j] = '\0';

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
    new File:f = fopen(UserPathStr(playerid), io_read);
    if(!f)
    {
        return 0;
    }

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
            else if(!strcmp(key, "Sexe")) format(PlayerInfo[playerid][pSexe], 2, "%s", val);
            else if(!strcmp(key, "Age")) PlayerInfo[playerid][pAge] = strval(val);
            else if(!strcmp(key, "LieuNaissance")) format(PlayerInfo[playerid][pLieuNaissance], 32, "%s", val);
            else if(!strcmp(key, "DateDelivID")) format(PlayerInfo[playerid][pDateDelivID], 11, "%s", val);
            else if(!strcmp(key, "SituationMatrimoniale")) format(PlayerInfo[playerid][pSituationMatrimoniale], 16, "%s", val);
            else if(!strcmp(key, "PermisPL")) PlayerInfo[playerid][pPermisPL] = strval(val);
            else if(!strcmp(key, "PermisAvion")) PlayerInfo[playerid][pPermisAvion] = strval(val);
            else if(!strcmp(key, "PermisBateau")) PlayerInfo[playerid][pPermisBateau] = strval(val);
            else if(!strcmp(key, "PermisMoto")) PlayerInfo[playerid][pPermisMoto] = strval(val);
            else if(!strcmp(key, "DatePermisVehicule")) format(PlayerInfo[playerid][pDatePermisVehicule], 11, "%s", val);
            else if(!strcmp(key, "DatePermisPL")) format(PlayerInfo[playerid][pDatePermisPL], 11, "%s", val);
            else if(!strcmp(key, "DatePermisAvion")) format(PlayerInfo[playerid][pDatePermisAvion], 11, "%s", val);
            else if(!strcmp(key, "DatePermisBateau")) format(PlayerInfo[playerid][pDatePermisBateau], 11, "%s", val);
            else if(!strcmp(key, "DatePermisMoto")) format(PlayerInfo[playerid][pDatePermisMoto], 11, "%s", val);
            else if(!strcmp(key, "Profession")) format(PlayerInfo[playerid][pProfession], 32, "%s", val);
            else if(!strcmp(key, "TypeArme")) format(PlayerInfo[playerid][pTypeArme], 32, "%s", val);
            else if(!strcmp(key, "NomArme")) format(PlayerInfo[playerid][pNomArme], 32, "%s", val);
            else if(!strcmp(key, "Faim")) PlayerInfo[playerid][pFaim] = strval(val);
            else if(!strcmp(key, "Soif")) PlayerInfo[playerid][pSoif] = strval(val);
            else if(!strcmp(key, "Fatigue")) PlayerInfo[playerid][pFatigue] = strval(val);
            else if(!strcmp(key, "Stress")) PlayerInfo[playerid][pStress] = strval(val);
            else if(!strcmp(key, "Moral")) PlayerInfo[playerid][pMoral] = strval(val);
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

    new File:f = fopen(UserPathStr(playerid), io_read);
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

    new File:fw = fopen(UserPathStr(playerid), io_write);
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
        format(outLine, sizeof(outLine), "Sexe=%s\r\n", PlayerInfo[playerid][pSexe]); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "Age=%d\r\n", PlayerInfo[playerid][pAge]); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "LieuNaissance=%s\r\n", PlayerInfo[playerid][pLieuNaissance]); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "DateDelivID=%s\r\n", PlayerInfo[playerid][pDateDelivID]); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "SituationMatrimoniale=%s\r\n", PlayerInfo[playerid][pSituationMatrimoniale]); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "PermisPL=%d\r\n", PlayerInfo[playerid][pPermisPL]); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "PermisAvion=%d\r\n", PlayerInfo[playerid][pPermisAvion]); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "PermisBateau=%d\r\n", PlayerInfo[playerid][pPermisBateau]); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "PermisMoto=%d\r\n", PlayerInfo[playerid][pPermisMoto]); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "DatePermisVehicule=%s\r\n", PlayerInfo[playerid][pDatePermisVehicule]); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "DatePermisPL=%s\r\n", PlayerInfo[playerid][pDatePermisPL]); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "DatePermisAvion=%s\r\n", PlayerInfo[playerid][pDatePermisAvion]); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "DatePermisBateau=%s\r\n", PlayerInfo[playerid][pDatePermisBateau]); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "DatePermisMoto=%s\r\n", PlayerInfo[playerid][pDatePermisMoto]); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "Profession=%s\r\n", PlayerInfo[playerid][pProfession]); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "TypeArme=%s\r\n", PlayerInfo[playerid][pTypeArme]); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "NomArme=%s\r\n", PlayerInfo[playerid][pNomArme]); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "Faim=%d\r\n", PlayerInfo[playerid][pFaim]); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "Soif=%d\r\n", PlayerInfo[playerid][pSoif]); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "Fatigue=%d\r\n", PlayerInfo[playerid][pFatigue]); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "Stress=%d\r\n", PlayerInfo[playerid][pStress]); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "Moral=%d\r\n", PlayerInfo[playerid][pMoral]); fwrite(fw, outLine);
        fclose(fw);
    }
    return 1;
}

public SpawnPlayerAfterLogin(playerid)
{
    SpawnPlayer(playerid);
    return 1;
}

// ==============================================================
//  Spawn du joueur
// ==============================================================
public OnPlayerSpawn(playerid)
{
    if(!IsLoggedIn[playerid]) return 1;

    // Le skin doit etre applique APRES SpawnPlayer(), jamais avant :
    // sinon le client garde le skin de la classe de selection (AddPlayerClass)
    // et ecrase silencieusement le skin choisi/enregistre du joueur.
    SetPlayerSkin(playerid, PlayerInfo[playerid][pSkin]);

    SetPlayerPos(playerid, PlayerInfo[playerid][pPosX], PlayerInfo[playerid][pPosY], PlayerInfo[playerid][pPosZ]);
    SetPlayerFacingAngle(playerid, PlayerInfo[playerid][pPosA]);
    SetPlayerInterior(playerid, PlayerInfo[playerid][pInt]);
    SetPlayerVirtualWorld(playerid, PlayerInfo[playerid][pWorld]);
    ResetPlayerMoney(playerid);
    GivePlayerMoney(playerid, PlayerInfo[playerid][pCash]);
    SetPlayerHealth(playerid, 100.0);
    SetPlayerArmour(playerid, 0.0);
    SendClientMessage(playerid, COLOR_SERVER, "Tapez /aide pour voir la liste des commandes disponibles.");
    return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
    if(IsLoggedIn[playerid])
    {
        PlayerInfo[playerid][pCash] = GetPlayerMoney(playerid);
    }
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
        SendClientMessage(playerid, COLOR_WHITE, "/manger /boire /dormir - Gerer vos besoins vitaux");
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
        format(str, sizeof(str), "Faim : %d/100 | Soif : %d/100 | Fatigue : %d/100",
            PlayerInfo[playerid][pFaim], PlayerInfo[playerid][pSoif], PlayerInfo[playerid][pFatigue]);
        SendClientMessage(playerid, COLOR_WHITE, str);
        format(str, sizeof(str), "Stress : %d/100 | Moral : %d/100",
            PlayerInfo[playerid][pStress], PlayerInfo[playerid][pMoral]);
        SendClientMessage(playerid, COLOR_WHITE, str);
        return 1;
    }

    if(!strcmp(cmd, "/manger", true))
    {
        if(PlayerInfo[playerid][pFaim] >= 100)
        {
            SendClientMessage(playerid, COLOR_YELLOW, "Vous n'avez pas faim.");
            return 1;
        }
        new const PRIX_REPAS = 50;
        if(GetPlayerMoney(playerid) < PRIX_REPAS)
        {
            SendClientMessage(playerid, COLOR_RED, "Vous n'avez pas assez d'argent pour manger ($50).");
            return 1;
        }
        GivePlayerMoney(playerid, -PRIX_REPAS);
        PlayerInfo[playerid][pFaim] = ClampNeed(PlayerInfo[playerid][pFaim] + 40);
        SendClientMessage(playerid, COLOR_GREEN, "Vous mangez un morceau. Votre faim diminue. (-$50)");
        return 1;
    }

    if(!strcmp(cmd, "/boire", true))
    {
        if(PlayerInfo[playerid][pSoif] >= 100)
        {
            SendClientMessage(playerid, COLOR_YELLOW, "Vous n'avez pas soif.");
            return 1;
        }
        new const PRIX_BOISSON = 25;
        if(GetPlayerMoney(playerid) < PRIX_BOISSON)
        {
            SendClientMessage(playerid, COLOR_RED, "Vous n'avez pas assez d'argent pour boire ($25).");
            return 1;
        }
        GivePlayerMoney(playerid, -PRIX_BOISSON);
        PlayerInfo[playerid][pSoif] = ClampNeed(PlayerInfo[playerid][pSoif] + 40);
        SendClientMessage(playerid, COLOR_GREEN, "Vous buvez une gorgee. Votre soif diminue. (-$25)");
        return 1;
    }

    if(!strcmp(cmd, "/dormir", true))
    {
        if(PlayerInfo[playerid][pFatigue] <= 0)
        {
            SendClientMessage(playerid, COLOR_YELLOW, "Vous n'etes pas fatigue.");
            return 1;
        }
        PlayerInfo[playerid][pFatigue] = 0;
        PlayerInfo[playerid][pStress] = ClampNeed(PlayerInfo[playerid][pStress] - 20);
        SendClientMessage(playerid, COLOR_GREEN, "Vous avez dormi. Votre fatigue est retombee et votre stress a diminue.");
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
    if(!strcmp(cmd, "/definirsexe", true)) { canon = "DEFSEXE"; level = ADMIN_LEVEL_MOD; return 1; }
    if(!strcmp(cmd, "/definirage", true)) { canon = "DEFAGE"; level = ADMIN_LEVEL_MOD; return 1; }
    if(!strcmp(cmd, "/definirnaissance", true)) { canon = "DEFNAISSANCE"; level = ADMIN_LEVEL_MOD; return 1; }
    if(!strcmp(cmd, "/definirprofession", true)) { canon = "DEFPROFESSION"; level = ADMIN_LEVEL_MOD; return 1; }
    if(!strcmp(cmd, "/definirarme", true)) { canon = "DEFARME"; level = ADMIN_LEVEL_MOD; return 1; }
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
    if(!strcmp(cmd, "/devcarte", true)) { canon = "DEVCARTE"; level = ADMIN_LEVEL_DEV; return 1; }

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
        new tmpType[64], tmpVal[64], today[11], regY, regM, regD;
        tmp = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        tmpType = strtok_(cmdtext, idx);
        tmpVal = strtok_(cmdtext, idx);

        if(!strlen(tmp) || !strlen(tmpType) || !strlen(tmpVal) || !IsPlayerConnected(targetid))
            return SendClientMessage(playerid, COLOR_RED, "Utilisation : /definirpermis [id] [vehicule/pl/avion/bateau/moto] [0/1]");

        new value = strval(tmpVal);
        getdate(regY, regM, regD);
        format(today, sizeof(today), "%02d/%02d/%04d", regD, regM, regY);

        new permisLabel[24];
        new bool:handled = true;

        if(!strcmp(tmpType, "vehicule", true))
        {
            PlayerInfo[targetid][pPermisConduire] = value;
            format(PlayerInfo[targetid][pDatePermisVehicule], 11, "%s", (value) ? (today) : ("--/--/----"));
            format(permisLabel, 24, "vehicule");
        }
        else if(!strcmp(tmpType, "pl", true))
        {
            PlayerInfo[targetid][pPermisPL] = value;
            format(PlayerInfo[targetid][pDatePermisPL], 11, "%s", (value) ? (today) : ("--/--/----"));
            format(permisLabel, 24, "poids lourd");
        }
        else if(!strcmp(tmpType, "avion", true))
        {
            PlayerInfo[targetid][pPermisAvion] = value;
            format(PlayerInfo[targetid][pDatePermisAvion], 11, "%s", (value) ? (today) : ("--/--/----"));
            format(permisLabel, 24, "avion");
        }
        else if(!strcmp(tmpType, "bateau", true))
        {
            PlayerInfo[targetid][pPermisBateau] = value;
            format(PlayerInfo[targetid][pDatePermisBateau], 11, "%s", (value) ? (today) : ("--/--/----"));
            format(permisLabel, 24, "bateau");
        }
        else if(!strcmp(tmpType, "moto", true))
        {
            PlayerInfo[targetid][pPermisMoto] = value;
            format(PlayerInfo[targetid][pDatePermisMoto], 11, "%s", (value) ? (today) : ("--/--/----"));
            format(permisLabel, 24, "moto");
        }
        else
        {
            handled = false;
            SendClientMessage(playerid, COLOR_RED, "Type invalide. Utilisez : vehicule, pl, avion, bateau ou moto.");
        }

        if(handled)
        {
            new msg[128];
            if(value)
            {
                format(msg, sizeof(msg), "Vous avez obtenu votre permis (%s).", permisLabel);
                SendClientMessage(targetid, COLOR_GREEN, msg);
                SendClientMessage(playerid, COLOR_GREEN, "Permis accorde.");
            }
            else
            {
                format(msg, sizeof(msg), "Votre permis (%s) vous a ete retire.", permisLabel);
                SendClientMessage(targetid, COLOR_RED, msg);
                SendClientMessage(playerid, COLOR_GREEN, "Permis retire.");
            }
        }
    }
    else if(!strcmp(canon, "DEFSEXE"))
    {
        tmp = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        tmp2 = strtok_(cmdtext, idx);
        if(!strlen(tmp) || !strlen(tmp2) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation : /definirsexe [id] [H/F]");
        if(strcmp(tmp2, "H", true) && strcmp(tmp2, "F", true)) return SendClientMessage(playerid, COLOR_RED, "Sexe invalide. Utilisez H ou F.");
        format(PlayerInfo[targetid][pSexe], 2, "%s", (!strcmp(tmp2, "F", true)) ? ("F") : ("H"));
        SendClientMessage(playerid, COLOR_GREEN, "Sexe mis a jour.");
    }
    else if(!strcmp(canon, "DEFAGE"))
    {
        tmp = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        tmp2 = strtok_(cmdtext, idx);
        if(!strlen(tmp) || !strlen(tmp2) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation : /definirage [id] [age]");
        PlayerInfo[targetid][pAge] = strval(tmp2);
        SendClientMessage(playerid, COLOR_GREEN, "Age mis a jour.");
    }
    else if(!strcmp(canon, "DEFNAISSANCE"))
    {
        new lieu[32];
        tmp = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        tmp2 = strtok_(cmdtext, idx); // date JJ/MM/AAAA

        while(idx < strlen(cmdtext) && cmdtext[idx] <= ' ') idx++;
        format(lieu, sizeof(lieu), "%s", cmdtext[idx]);

        if(!strlen(tmp) || !strlen(tmp2) || !strlen(lieu) || !IsPlayerConnected(targetid))
            return SendClientMessage(playerid, COLOR_RED, "Utilisation : /definirnaissance [id] [JJ/MM/AAAA] [lieu]");

        format(PlayerInfo[targetid][pDateNaissance], 11, "%s", tmp2);
        format(PlayerInfo[targetid][pLieuNaissance], 32, "%s", lieu);
        SendClientMessage(playerid, COLOR_GREEN, "Date et lieu de naissance mis a jour.");
    }
    else if(!strcmp(canon, "DEFPROFESSION"))
    {
        tmp = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        while(idx < strlen(cmdtext) && cmdtext[idx] <= ' ') idx++;

        if(!strlen(tmp) || !IsPlayerConnected(targetid) || idx >= strlen(cmdtext))
            return SendClientMessage(playerid, COLOR_RED, "Utilisation : /definirprofession [id] [profession]");

        format(PlayerInfo[targetid][pProfession], 32, "%s", cmdtext[idx]);
        SendClientMessage(playerid, COLOR_GREEN, "Profession mise a jour.");
    }
    else if(!strcmp(canon, "DEFARME"))
    {
        tmp = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        tmp2 = strtok_(cmdtext, idx); // type d'arme (un seul mot)
        while(idx < strlen(cmdtext) && cmdtext[idx] <= ' ') idx++;

        if(!strlen(tmp) || !strlen(tmp2) || !IsPlayerConnected(targetid) || idx >= strlen(cmdtext))
            return SendClientMessage(playerid, COLOR_RED, "Utilisation : /definirarme [id] [type] [nom]");

        format(PlayerInfo[targetid][pTypeArme], 32, "%s", tmp2);
        format(PlayerInfo[targetid][pNomArme], 32, "%s", cmdtext[idx]);
        SendClientMessage(playerid, COLOR_GREEN, "Arme mise a jour.");
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
    else if(!strcmp(canon, "DEVCARTE"))
    {
        new p1[64], p2[64], p3[64], p4[64], p5[64], p6[64];
        p1 = strtok_(cmdtext, idx);
        p2 = strtok_(cmdtext, idx);
        p3 = strtok_(cmdtext, idx);
        p4 = strtok_(cmdtext, idx);
        p5 = strtok_(cmdtext, idx);
        p6 = strtok_(cmdtext, idx);

        if(!strlen(p1) || !strlen(p2) || !strlen(p3) || !strlen(p4) || !strlen(p5) || !strlen(p6))
        {
            SendClientMessage(playerid, COLOR_RED, "Utilisation : /devcarte [x] [y] [rotx] [roty] [rotz] [zoom]");
            format(str, sizeof(str), "Valeurs actuelles : x=%f y=%f rotx=%f roty=%f rotz=%f zoom=%f", gCardBaseX, gCardBaseY, gPreviewRotX, gPreviewRotY, gPreviewRotZ, gPreviewZoom);
            SendClientMessage(playerid, COLOR_WHITE, str);
            SendClientMessage(playerid, COLOR_WHITE, "Exemple de depart : /devcarte 180 140 0 0 0 1.0");
            return 1;
        }

        gCardBaseX = floatstr(p1);
        gCardBaseY = floatstr(p2);
        gPreviewRotX = floatstr(p3);
        gPreviewRotY = floatstr(p4);
        gPreviewRotZ = floatstr(p5);
        gPreviewZoom = floatstr(p6);

        new testLabels[MAX_CARD_FIELDS][24], testValues[MAX_CARD_FIELDS][48], testColors[MAX_CARD_FIELDS];
        format(testLabels[0], 24, "NOM ET PRENOM"); format(testValues[0], 48, "Jean Test"); testColors[0] = 0xFFFFFFFF;
        format(testLabels[1], 24, "SEXE"); format(testValues[1], 48, "Homme"); testColors[1] = 0xFFFFFFFF;
        format(testLabels[2], 24, "AGE"); format(testValues[2], 48, "25 ans"); testColors[2] = 0xFFFFFFFF;
        format(testLabels[3], 24, "DATE DE NAISSANCE"); format(testValues[3], 48, "01/01/1990"); testColors[3] = 0xFFFFFFFF;
        format(testLabels[4], 24, "LIEU DE NAISSANCE"); format(testValues[4], 48, "Los Santos"); testColors[4] = 0xFFFFFFFF;
        format(testLabels[5], 24, "DATE DE DELIVRANCE"); format(testValues[5], 48, "13/07/2026"); testColors[5] = 0xFFFFFFFF;
        ShowDocumentCard(playerid, "CARTE D'IDENTITE (TEST)", 0x1A3E8CFF, 123, testLabels, testValues, testColors, 6, GetPlayerSkin(playerid));
        SendClientMessage(playerid, COLOR_GREEN, "Carte rechargee avec les nouveaux reglages. Relance /devcarte avec d'autres valeurs pour ajuster.");
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
        SendClientMessage(playerid, COLOR_WHITE, "[Moderateur] /definirsexe, /definirage, /definirnaissance, /definirprofession, /definirarme");
    if(lvl >= ADMIN_LEVEL_ADMIN)
        SendClientMessage(playerid, COLOR_WHITE, "[Admin] /bannir, /debannir, /apparence, /armes, /dieu");
    if(lvl >= ADMIN_LEVEL_SUPERIOR)
        SendClientMessage(playerid, COLOR_WHITE, "[Admin Sup.] /argent, /donnerargent, /vip, /niveau");
    if(lvl >= ADMIN_LEVEL_SUPERVISOR)
        SendClientMessage(playerid, COLOR_WHITE, "[Superviseur] /definiradmin, /annonce");
    if(lvl >= ADMIN_LEVEL_DEV)
        SendClientMessage(playerid, COLOR_ADMIN, "[Developpeur] /heure, /meteo, /donnerarme, /allercoord, /redemarrer, /cmdrcon (acces complet RCON), /devcarte");
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
