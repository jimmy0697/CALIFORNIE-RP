/*==============================================================
    CALIFORNIE RP - Gamemode principal
    Serveur SA-MP - Roleplay
==============================================================*/

#include <a_samp>
#include "californie.inc"
#include <sampvoice>
#include <a_mysql>
#include <streamer>


#define FILTERSCRIPT

// ------------------------------------------------------------
//  Systeme de Chat Vocal (SAMPVOICE - fork open.mp AmyrAhmady)
//  Necessite le plugin serveur "sampvoice" (sampvoice.dll / .so)
//  + sampvoice.inc dans le dossier includes ; cote client le
//  joueur doit avoir le plugin SAMPVOICE installe.
//  API du fork open.mp : SvCreateDLStreamAtPlayer / SvAttachSpeakerToStream
//  / SvAddKey + callbacks OnPlayerActivationKeyPress/Release
//  (differente de l'ancienne API SvCreateStream/SvSetKey/SvSetTarget).
// ------------------------------------------------------------
#define VOICE_RADIUS          20.0   // portee de la voix en metres (immersion RP)
#define VOICE_PTT_KEY         0x14   // touche Push-To-Talk par defaut : CAPS LOCK
#define VOICE_MAX_LISTENERS   SV_INFINITY // nb d'auditeurs simultanes sur le stream local

new SV_DLSTREAM:gVoiceStream[MAX_PLAYERS]; // stream local dynamique de proximite de chaque joueur
new bool:gVoiceReady[MAX_PLAYERS];        // true si plugin + micro detectes pour ce joueur

main() {}

// ------------------------------------------------------------
//  Connexion MySQL (systeme de spawn multi-villes, porte de LVRP)
//  A adapter avec les identifiants reels de la base californierp.
// ------------------------------------------------------------
#define MYSQL_HOST   "51.38.205.167"
#define MYSQL_USER   "u240874_b2Fj52yTOt"
#define MYSQL_PASS   "TH.z9D@aRL+EGEQKYm@Bpimp"
#define MYSQL_DB     "s240874_Californie1"

new MySQL:g_SQL;

stock MySQLConnect(sqlhost[], sqluser[], sqlpass[], sqldb[])
{
    g_SQL = mysql_connect(sqlhost, sqluser, sqlpass, sqldb);
    if(mysql_errno(g_SQL) == 0)
    {
        print("[MYSQL] Connexion reussie.");
        return 1;
    }
    print("[MYSQL] Connexion echouee, verifiez MYSQL_HOST/USER/PASS/DB.");
    return 0;
}

// ------------------------------------------------------------
//  Systeme de spawn multi-villes (porte de LVRP.pwn)
//  13 villes de San Andreas, positions chargees depuis la table
//  MySQL "spawn_villes" (id, Pos_x, Pos_y, Pos_z, Pos_a).
// ------------------------------------------------------------
#define MAX_CITY 13

enum e_Spawn
{
    Float:pos[4], // x, y, z, angle
    icon,
};
new spawn[MAX_CITY][e_Spawn];

stock GetCityName(id)
{
    new name[32];
    switch(id)
    {
        case 0:  name = "Los Santos";
        case 1:  name = "San Fierro";
        case 2:  name = "Las Venturas";
        case 3:  name = "Fort Carson";
        case 4:  name = "Bayside";
        case 5:  name = "Angel Pine";
        case 6:  name = "Dillimore";
        case 7:  name = "Blueberry";
        case 8:  name = "Montgomery";
        case 9:  name = "Palomino Creek";
        case 10: name = "Las Payasadas";
        case 11: name = "Las Barbancas";
        case 12: name = "El Quebrados";
        default: name = "San Andreas";
    }
    return name;
}

stock spawn_Update(id)
{
    new string[64];
    format(string, sizeof(string), "[Spawn - %s]", GetCityName(id));
    spawn[id][icon] = CreateDynamicMapIcon(spawn[id][pos][0], spawn[id][pos][1], spawn[id][pos][2], 38, 0xFFFFFFFF, -1, -1, -1, 500.0);
    Create3DTextLabel(string, 0xFFFFFFEE, spawn[id][pos][0], spawn[id][pos][1], spawn[id][pos][2] + 0.4, 20.0, 0, 0);
    return 1;
}

forward spawn_Load();
public spawn_Load()
{
    for(new i = 0; i < MAX_CITY; i++)
    {
        cache_get_value_name_float(i, "Pos_x", spawn[i][pos][0]);
        cache_get_value_name_float(i, "Pos_y", spawn[i][pos][1]);
        cache_get_value_name_float(i, "Pos_z", spawn[i][pos][2]);
        cache_get_value_name_float(i, "Pos_a", spawn[i][pos][3]);
        spawn_Update(i);
    }
    print("[Californie RP] Spawns des villes charges depuis la base de donnees.");
    return 1;
}

stock spawn_Save(id)
{
    new query[256];
    format(query, sizeof(query), "UPDATE spawn_villes SET Pos_x=%f, Pos_y=%f, Pos_z=%f, Pos_a=%f WHERE id=%d",
        spawn[id][pos][0], spawn[id][pos][1], spawn[id][pos][2], spawn[id][pos][3], id);
    mysql_pquery(g_SQL, query);
    return 1;
}

// Cree la table spawn_villes si elle n'existe pas encore et l'initialise avec
// les 13 villes (toutes sur le spawn Los Santos par defaut). Appelee une fois
// depuis OnGameModeInit, avant spawn_Load(). Remplace le besoin d'executer un
// fichier .sql a part : tout se fait automatiquement au demarrage du serveur.
stock SpawnVilles_Setup()
{
    mysql_tquery(g_SQL,
        "CREATE TABLE IF NOT EXISTS `spawn_villes` (\
`id` INT NOT NULL, \
`Pos_x` FLOAT NOT NULL DEFAULT 1569.2711, \
`Pos_y` FLOAT NOT NULL DEFAULT -2348.7114, \
`Pos_z` FLOAT NOT NULL DEFAULT 13.5547, \
`Pos_a` FLOAT NOT NULL DEFAULT 0.0, \
PRIMARY KEY (`id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

    new query[900];
    format(query, sizeof(query),
        "INSERT IGNORE INTO `spawn_villes` (`id`, `Pos_x`, `Pos_y`, `Pos_z`, `Pos_a`) VALUES \
(0,1569.2711,-2348.7114,13.5547,0.0),(1,1569.2711,-2348.7114,13.5547,0.0),\
(2,1569.2711,-2348.7114,13.5547,0.0),(3,1569.2711,-2348.7114,13.5547,0.0),\
(4,1569.2711,-2348.7114,13.5547,0.0),(5,1569.2711,-2348.7114,13.5547,0.0),\
(6,1569.2711,-2348.7114,13.5547,0.0),(7,1569.2711,-2348.7114,13.5547,0.0),\
(8,1569.2711,-2348.7114,13.5547,0.0),(9,1569.2711,-2348.7114,13.5547,0.0),\
(10,1569.2711,-2348.7114,13.5547,0.0),(11,1569.2711,-2348.7114,13.5547,0.0),\
(12,1569.2711,-2348.7114,13.5547,0.0)");
    mysql_tquery(g_SQL, query);
    return 1;
}


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
#if !defined DIALOG_BANQUE
    #define DIALOG_BANQUE 9010
#endif
#if !defined DIALOG_BANQUE_DEPOT
    #define DIALOG_BANQUE_DEPOT 9011
#endif
#if !defined DIALOG_BANQUE_RETRAIT
    #define DIALOG_BANQUE_RETRAIT 9012
#endif
#if !defined DIALOG_BANQUE_SOLDE
    #define DIALOG_BANQUE_SOLDE 9013
#endif
#if !defined DIALOG_VILLE
    #define DIALOG_VILLE 9014
#endif

// ------------------------------------------------------------
//  Banque - position et parametres
// ------------------------------------------------------------
#define BANK_POS_X (1487.9711)
#define BANK_POS_Y (-1750.1216)
#define BANK_POS_Z (15.3746)
#define BANK_RADIUS (6.0)

// ------------------------------------------------------------
//  Police Nationale (LSPD / Police de Los Santos)
//  Commissariat central : accueil, bureaux et zone de detention
// ------------------------------------------------------------
// Entree exterieure (point d'acces public)
#define PD_ENTRANCE_X (1553.3020)
#define PD_ENTRANCE_Y (-1675.6410)
#define PD_ENTRANCE_Z (16.1950)
#define PD_RADIUS (6.0)

// Interieur : spawn d'arrivee (halls, bureaux)
#define PD_INTERIOR_X (288.7500)
#define PD_INTERIOR_Y (169.1500)
#define PD_INTERIOR_Z (1007.1800)
#define PD_INTERIOR_INT (3)

// Zone d'incarceration (prison de faction / cellules)
#define PD_CELL_INT (6)
#define PD_CELL1_X (264.6285)
#define PD_CELL1_Y (77.5742)
#define PD_CELL1_Z (1001.0391)
#define PD_CELL2_X (264.1204)
#define PD_CELL2_Y (82.1154)
#define PD_CELL2_Z (1001.0391)
#define PD_CELL3_X (264.2250)
#define PD_CELL3_Y (86.8214)
#define PD_CELL3_Z (1001.0391)

// NOTE : les batiments publics de faction (hopital, FBI, caserne de
// pompiers...) sont geres entierement en jeu, sans toucher a ce fichier.
// Voir proprietes.inc : /creerbatiment, /interieur batiment [id],
// /exterieur batiment [id], /suppbatiment [id], /batimentspublics.

#if !defined SERVER_SITE
    #define SERVER_SITE "www.californie-rp.fr"
#endif
#if !defined SERVER_FORUM
    #define SERVER_FORUM "forum.californie-rp.fr"
#endif

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
#define MAX_CHARSETUP_TDS 23
#define CS_TD_BORDER         0
#define CS_TD_BG             1
#define CS_TD_TITLE_BAR      2
#define CS_TD_TITLE          3
#define CS_TD_GENDER_LABEL   4
#define CS_TD_MALE_BORDER    5
#define CS_TD_MALE_FILL      6
#define CS_TD_MALE_BTN       7
#define CS_TD_FEMALE_BORDER  8
#define CS_TD_FEMALE_FILL    9
#define CS_TD_FEMALE_BTN     10
#define CS_TD_AGE_LABEL      11
#define CS_TD_AGE_BOX        12
#define CS_TD_AGE_MINUS      13
#define CS_TD_AGE_VALUE      14
#define CS_TD_AGE_PLUS       15
#define CS_TD_SKIN_LABEL     16
#define CS_TD_SKIN_BOX       17
#define CS_TD_SKIN_MINUS     18
#define CS_TD_SKIN_VALUE     19
#define CS_TD_SKIN_PLUS      20
#define CS_TD_CONFIRM_BORDER 21
#define CS_TD_CONFIRM_BTN    22

new PlayerText:gCSTD[MAX_PLAYERS][MAX_CHARSETUP_TDS];
new bool:gCharSetupShown[MAX_PLAYERS];
new gCharGender[MAX_PLAYERS];     // 0 = Homme, 1 = Femme
new gCharAge[MAX_PLAYERS];
new gCharSkinIndex[MAX_PLAYERS];
new gPendingPassHash[MAX_PLAYERS];
new gPlayerPassHash[MAX_PLAYERS]; // Hash du mot de passe garde en memoire pendant la session (voir SaveUserData : on ne relit plus jamais le mot de passe depuis le disque, pour eviter de l'ecraser a 0 si la lecture echoue)
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
    pCity,               // Ville de spawn (voir spawn[MAX_CITY], 0 = Los Santos)
    pCash,
    pBank,               // Solde du compte bancaire
    pCarteBancaire,      // 0 = pas encore recuperee a la banque, 1 = recuperee
    pFaction,            // Faction actuelle (voir FACTION_*)
    pGrade,              // Grade 1 a 5 au sein de la faction
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

// ------------------------------------------------------------
//  Besoins vitaux (V2 realiste) - etat annexe par joueur
// ------------------------------------------------------------
new gLastManger[MAX_PLAYERS];      // GetTickCount() du dernier repas (anti-spam)
new gLastBoire[MAX_PLAYERS];       // GetTickCount() de la derniere boisson (anti-spam)
new gLastDormir[MAX_PLAYERS];      // GetTickCount() du dernier sommeil (anti-spam)
new bool:gPlayerOccupied[MAX_PLAYERS]; // true pendant une animation manger/boire/dormir (bloque le spam de commandes)
new gStarvingTicks[MAX_PLAYERS];   // nb de ticks consecutifs a 0 de faim OU soif (mene a l'evanouissement)
new gCritDangerLevel[MAX_PLAYERS]; // 0 = ok, 1 = fatigue lourde (etourdissements), 2 = evanoui recemment (cooldown)

// Le systeme de proprietes (maisons/garages/commerces/meubles) a besoin de
// PlayerInfo, ADMIN_LEVEL_DEV et des couleurs COLOR_* deja declares plus
// haut : il doit donc etre inclus ici, pas avant.
#include "proprietes.inc" // voir ce fichier pour la config MySQL

// ------------------------------------------------------------
//  Forwards utilitaires
// ------------------------------------------------------------
forward UserPath(playerid);
forward LoadUserData(playerid);
forward SaveUserData(playerid);
forward SpawnPlayerAfterLogin(playerid);
forward ShowSpawnSelectionDialog(playerid);
forward FinalizeAccountCreation(playerid);
forward NeedsUpdateTimer();
forward FinishEatingTimer(playerid);
forward FinishDrinkingTimer(playerid);
forward FinishSleepingTimer(playerid);

// ------------------------------------------------------------
//  Systeme de besoins vitaux (soif / faim / stress / moral / fatigue)
//  Tick toutes les 60 secondes pour chaque joueur connecte et spawn.
// ------------------------------------------------------------
#define NEEDS_INTERVAL       60000  // 1 minute
#define NEEDS_FAIM_DECAY     2
#define NEEDS_SOIF_DECAY     3
#define NEEDS_FATIGUE_GAIN   1
#define NEEDS_SEUIL_CRITIQUE 25     // en dessous de ce seuil : impact stress/moral
#define NEEDS_SEUIL_ALERTE   40     // seuil d'alerte precoce (avant le seuil critique)
#define NEEDS_FATIGUE_HAUTE  75     // au dessus : impact stress
#define NEEDS_DEGATS_CRITIQUE 3.0   // degats de sante par tick si faim ou soif a 0
#define NEEDS_STARVING_MAX_TICKS 4  // nb de ticks a 0 avant evanouissement (~4 min)

// --- Anti-spam : delais minimum entre deux actions (en millisecondes) ---
#define MANGER_COOLDOWN   150000  // 2 min 30
#define BOIRE_COOLDOWN    90000   // 1 min 30
#define DORMIR_COOLDOWN   600000  // 10 min

// --- Duree des animations (en secondes) : le joueur est immobilise pendant ce temps ---
#define DUREE_ANIM_MANGER 4
#define DUREE_ANIM_BOIRE  3
#define DUREE_ANIM_DORMIR 8

// --- Activite physique : la soif et la fatigue augmentent plus vite a l'effort ---
#define NEEDS_SOIF_DECAY_COURSE   2  // supplement si le joueur sprinte/nage
#define NEEDS_FATIGUE_GAIN_COURSE 1  // supplement si le joueur sprinte/nage

// ------------------------------------------------------------
//  Points de vente nourriture/boisson (echoppes, epiceries).
//  A ajuster/completer selon les commerces deja presents sur
//  la map ; portee d'interaction courte pour forcer le RP.
// ------------------------------------------------------------
#define SHOP_RADIUS 4.0
#define SHOP_COUNT  4
new Float:gShopPos[SHOP_COUNT][3] = {
    {2100.6584, -1774.6511, 13.5510}, // Epicerie Idlewood
    {2384.1013, -1798.7811, 13.5498}, // Snack Idlewood
    {-1487.6293, 2586.6743, 55.9844}, // Epicerie Las Barrancas
    {1704.5952, -1866.5024, 13.5751}  // Epicerie pres de la Banque
};
new gShopPickup[SHOP_COUNT];
new Text3D:gShopLabel[SHOP_COUNT];

// ------------------------------------------------------------
//  Verifie que le joueur se trouve pres d'un des points de
//  vente nourriture/boisson (obligatoire pour /manger et /boire).
// ------------------------------------------------------------
stock IsPlayerNearShop(playerid)
{
    for(new i = 0; i < SHOP_COUNT; i++)
    {
        if(IsPlayerInRangeOfPoint(playerid, SHOP_RADIUS, gShopPos[i][0], gShopPos[i][1], gShopPos[i][2]))
        {
            return 1;
        }
    }
    return 0;
}

// ------------------------------------------------------------
//  Cree les pickups + panneaux 3D des points de vente. Appele
//  une fois depuis OnGameModeInit.
// ------------------------------------------------------------
stock CreateShopPoints()
{
    for(new i = 0; i < SHOP_COUNT; i++)
    {
        gShopPickup[i] = CreatePickup(1550, 1, gShopPos[i][0], gShopPos[i][1], gShopPos[i][2], -1);
        gShopLabel[i] = Create3DTextLabel("{33CC33}EPICERIE\n{FFFFFF}/manger ou /boire ici", 0xFFFFFFFF,
            gShopPos[i][0], gShopPos[i][1], gShopPos[i][2] + 0.7, 10.0, 0, 0);
    }
    return 1;
}

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
// ------------------------------------------------------------
//  Factions - identifiants, grades, salaires
// ------------------------------------------------------------
#define FACTION_NONE          0
#define FACTION_POLICE        1
#define FACTION_FBI           2
#define FACTION_PENITENCIER   3
#define FACTION_POMPIER       4
#define FACTION_MEDECIN       5
#define FACTION_GOUVERNEUR    6
#define FACTION_JUGE          7
#define FACTION_AVOCAT        8
#define FACTION_GARDE         9
#define FACTION_JOURNALISTE   10
#define FACTION_MECANO        11
#define FACTION_ARMES         12
#define MAX_FACTIONS          13

new gFactionName[MAX_FACTIONS][32] = {
    "Civil",
    "Police",
    "FBI",
    "Administration Penitentiaire",
    "Pompiers",
    "Medecins",
    "Gouvernement",
    "Justice (Juges)",
    "Barreau (Avocats)",
    "Securite Privee",
    "Presse",
    "Mecanique",
    "Armes"
};

// Salaire fixe verse toutes les 30 minutes, par faction (0 = pas de salaire fixe).
new gFactionSalary[MAX_FACTIONS] = {
    0,      // Civil
    80000,  // Police
    80000,  // FBI
    50000,  // Penitentiaire
    40000,  // Pompiers
    60000,  // Medecins
    0,      // Gouverneur (pourcentage, gere a part)
    120000, // Juges
    0,      // Avocats (commission uniquement)
    0,      // Garde du corps (paye a la minute par le client)
    50000,  // Journalistes
    0,      // Mecaniciens (paye a la reparation)
    80000   // Armes
};

// Grades 1 a 5 pour chaque faction (index 0 = non utilise / "Aucun").
new gGradePolice[6][32]      = {"Aucun","Cadet","Agent","Sergent","Lieutenant","Chef de Police"};
new gGradeFBI[6][32]         = {"Aucun","Stagiaire","Agent Special","Agent Senior","Superviseur","Directeur"};
new gGradePenitencier[6][32] = {"Aucun","Surveillant Stagiaire","Surveillant","Surveillant Chef","Sous-Directeur","Directeur"};
new gGradePompier[6][32]     = {"Aucun","Stagiaire","Pompier","Pompier Confirme","Chef d'Equipe","Capitaine"};
new gGradeMedecin[6][32]     = {"Aucun","Interne","Medecin","Medecin Senior","Chirurgien","Chef de Service"};
new gGradeGouverneur[6][32]  = {"Aucun","Adjoint au Maire","Maire","Vice-Gouverneur","Gouverneur","Gouverneur en Chef"};
new gGradeJuge[6][32]        = {"Aucun","Juge Stagiaire","Juge","Juge Senior","Vice-President","President du Tribunal"};
new gGradeAvocat[6][32]      = {"Aucun","Avocat Stagiaire","Avocat","Avocat Senior","Associe","Batonnier"};
new gGradeGarde[6][32]       = {"Aucun","Recrue","Garde du Corps","Garde Senior","Chef d'Equipe","Responsable Securite"};
new gGradeJournaliste[6][32] = {"Aucun","Stagiaire","Journaliste","Journaliste Senior","Redacteur","Redacteur en Chef"};
new gGradeMecano[6][32]      = {"Aucun","Apprenti","Mecanicien","Mecanicien Confirme","Chef d'Atelier","Responsable Garage"};
new gGradeArmes[6][32]       = {"Aucun","Recrue","Membre","Membre Confirme","Bras Droit","Chef"};

// Pourcentage du Tresor de l'Etat verse au Gouverneur/Maire toutes les 30 min, par grade.
new gGouverneurPercent[6] = {0, 5, 10, 15, 25, 35};

// Tresor de l'Etat : alimente par la part de l'Etat sur les honoraires d'avocat
// (20%), sert de base au versement du Gouverneur/Maire. Systeme simplifie en
// attendant un vrai systeme de taxes/proprietes.
new gEtatTresor = 0;

// Primes fixes (utilisees en l'absence de systeme d'incendies/detention complet)
#define PRIME_DETENU_SURVEILLE 5000
#define PRIME_INCENDIE_ETEINT  5000
#define PRIX_SOINS_MEDECIN     2000
#define BONUS_ARTICLE          1000
#define PRIME_COOLDOWN         300 // secondes entre deux primes (anti-spam) pour pompier/penitentiaire

new gLastPrimePompier[MAX_PLAYERS];
new gLastPrimePenitencier[MAX_PLAYERS];

// Garde du corps : client qui a engage chaque garde (-1 = aucun) + tarif/minute
new gGardeClient[MAX_PLAYERS];
new gGardeRate[MAX_PLAYERS];

forward FactionSalaryTimer();
forward GardeDuCorpsTimer();

stock GetGradeName(faction, grade, dest[], destSize)
{
    if(grade < 0 || grade > 5) grade = 0;
    switch(faction)
    {
        case FACTION_POLICE: format(dest, destSize, "%s", gGradePolice[grade]);
        case FACTION_FBI: format(dest, destSize, "%s", gGradeFBI[grade]);
        case FACTION_PENITENCIER: format(dest, destSize, "%s", gGradePenitencier[grade]);
        case FACTION_POMPIER: format(dest, destSize, "%s", gGradePompier[grade]);
        case FACTION_MEDECIN: format(dest, destSize, "%s", gGradeMedecin[grade]);
        case FACTION_GOUVERNEUR: format(dest, destSize, "%s", gGradeGouverneur[grade]);
        case FACTION_JUGE: format(dest, destSize, "%s", gGradeJuge[grade]);
        case FACTION_AVOCAT: format(dest, destSize, "%s", gGradeAvocat[grade]);
        case FACTION_GARDE: format(dest, destSize, "%s", gGradeGarde[grade]);
        case FACTION_JOURNALISTE: format(dest, destSize, "%s", gGradeJournaliste[grade]);
        case FACTION_MECANO: format(dest, destSize, "%s", gGradeMecano[grade]);
        case FACTION_ARMES: format(dest, destSize, "%s", gGradeArmes[grade]);
        default: format(dest, destSize, "%s", "Civil");
    }
    return 1;
}

stock ClampNeed(val)
{
    if(val < 0) return 0;
    if(val > 100) return 100;
    return val;
}

// ------------------------------------------------------------
//  Salaires de faction : verses toutes les 30 minutes.
// ------------------------------------------------------------
public FactionSalaryTimer()
{
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(!IsPlayerConnected(i) || !IsLoggedIn[i]) continue;

        new faction = PlayerInfo[i][pFaction];
        if(faction == FACTION_NONE) continue;

        new montant = 0;
        if(faction == FACTION_GOUVERNEUR)
        {
            new grade = PlayerInfo[i][pGrade];
            if(grade < 0 || grade > 5) grade = 0;
            montant = (gEtatTresor * gGouverneurPercent[grade]) / 100;
            if(montant > gEtatTresor) montant = gEtatTresor;
            gEtatTresor -= montant;
        }
        else
        {
            montant = gFactionSalary[faction];
        }

        if(montant > 0)
        {
            GivePlayerBankMoney(i, montant);
            new str[128], gname[32];
            GetGradeName(faction, PlayerInfo[i][pGrade], gname, 32);
            format(str, sizeof(str), "Salaire verse sur votre compte bancaire : $%d (%s - %s)", montant, gFactionName[faction], gname);
            SendClientMessage(i, COLOR_GREEN, str);
        }
    }
    return 1;
}

// ------------------------------------------------------------
//  Garde du corps : facturation du client toutes les minutes.
// ------------------------------------------------------------
public GardeDuCorpsTimer()
{
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(!IsPlayerConnected(i) || !IsLoggedIn[i]) continue;
        if(PlayerInfo[i][pFaction] != FACTION_GARDE) continue;

        new clientid = gGardeClient[i];
        if(clientid == -1) continue;
        if(!IsPlayerConnected(clientid) || !IsLoggedIn[clientid])
        {
            gGardeClient[i] = -1;
            continue;
        }

        new rate = gGardeRate[i];
        if(PlayerInfo[clientid][pBank] < rate)
        {
            SendClientMessage(clientid, COLOR_RED, "Solde bancaire insuffisant : votre contrat avec votre garde du corps a pris fin.");
            SendClientMessage(i, COLOR_RED, "Votre client n'a plus les moyens de vous payer. Contrat termine.");
            gGardeClient[i] = -1;
            continue;
        }

        GivePlayerBankMoney(clientid, -rate);
        GivePlayerBankMoney(i, rate);

        new str[96];
        format(str, sizeof(str), "Garde du corps : $%d preleves de votre compte pour cette minute.", rate);
        SendClientMessage(clientid, COLOR_YELLOW, str);
        format(str, sizeof(str), "Garde du corps : $%d verses sur votre compte pour cette minute.", rate);
        SendClientMessage(i, COLOR_GREEN, str);
    }
    return 1;
}



// ------------------------------------------------------------
//  Banque : utilitaires
// ------------------------------------------------------------
stock IsPlayerNearBank(playerid)
{
    return IsPlayerInRangeOfPoint(playerid, BANK_RADIUS, BANK_POS_X, BANK_POS_Y, BANK_POS_Z);
}

// ------------------------------------------------------------
//  Police Nationale (LSPD) : utilitaires
// ------------------------------------------------------------
stock IsPlayerNearPD(playerid)
{
    return IsPlayerInRangeOfPoint(playerid, PD_RADIUS, PD_ENTRANCE_X, PD_ENTRANCE_Y, PD_ENTRANCE_Z);
}

// ------------------------------------------------------------
//  Batiments publics de faction : creation des pickups/panneaux
//  et gestion generique de l'entree/sortie via la touche F.
// ------------------------------------------------------------
// Place un joueur dans une des 3 cellules de detention du commissariat
stock JailPlayerAtPD(playerid, cellid = 0)
{
    switch(cellid)
    {
        case 2: SetPlayerPos(playerid, PD_CELL2_X, PD_CELL2_Y, PD_CELL2_Z);
        case 3: SetPlayerPos(playerid, PD_CELL3_X, PD_CELL3_Y, PD_CELL3_Z);
        default: SetPlayerPos(playerid, PD_CELL1_X, PD_CELL1_Y, PD_CELL1_Z);
    }
    SetPlayerInterior(playerid, PD_CELL_INT);
    SetPlayerVirtualWorld(playerid, 0);
    return 1;
}

// Utilisee par tout systeme (salaires de faction, virements, etc.) pour
// crediter directement le compte bancaire d'un joueur, meme hors ligne
// si l'index playerid correspond a un joueur connecte.
stock GivePlayerBankMoney(playerid, amount)
{
    PlayerInfo[playerid][pBank] += amount;
    if(PlayerInfo[playerid][pBank] < 0) PlayerInfo[playerid][pBank] = 0;
    return 1;
}

stock ShowBanqueSoldeDialog(playerid)
{
    new str[128];
    format(str, sizeof(str), "Solde de votre compte bancaire :\n$%d", PlayerInfo[playerid][pBank]);
    ShowPlayerDialog(playerid, DIALOG_BANQUE_SOLDE, DIALOG_STYLE_MSGBOX, "Solde bancaire", str, "OK", "");
    return 1;
}

stock ShowBanqueMenu(playerid)
{
    new str[256];
    if(PlayerInfo[playerid][pCarteBancaire])
    {
        format(str, sizeof(str), "Consulter mon solde ($%d)\nDeposer de l'argent\nRetirer de l'argent", PlayerInfo[playerid][pBank]);
    }
    else
    {
        format(str, sizeof(str), "Recuperer ma carte bancaire\nConsulter mon solde ($%d)\nDeposer de l'argent\nRetirer de l'argent", PlayerInfo[playerid][pBank]);
    }
    ShowPlayerDialog(playerid, DIALOG_BANQUE, DIALOG_STYLE_LIST, "Banque de Californie", str, "Choisir", "Fermer");
    return 1;
}

// ------------------------------------------------------------
//  Callbacks de fin d'action (appeles apres la duree de
//  l'animation manger/boire/dormir) : appliquent l'effet reel
//  et rendent le controle au joueur.
// ------------------------------------------------------------
public FinishEatingTimer(playerid)
{
    if(!IsPlayerConnected(playerid)) return 1;
    gPlayerOccupied[playerid] = false;
    TogglePlayerControllable(playerid, 1);
    ClearAnimations(playerid, true);
    if(!IsLoggedIn[playerid]) return 1;

    PlayerInfo[playerid][pFaim] = ClampNeed(PlayerInfo[playerid][pFaim] + 40);
    SendClientMessage(playerid, COLOR_GREEN, "Vous avez mange. Votre faim diminue. (-$50)");
    return 1;
}

public FinishDrinkingTimer(playerid)
{
    if(!IsPlayerConnected(playerid)) return 1;
    gPlayerOccupied[playerid] = false;
    TogglePlayerControllable(playerid, 1);
    ClearAnimations(playerid, true);
    if(!IsLoggedIn[playerid]) return 1;

    PlayerInfo[playerid][pSoif] = ClampNeed(PlayerInfo[playerid][pSoif] + 40);
    SendClientMessage(playerid, COLOR_GREEN, "Vous avez bu. Votre soif diminue. (-$25)");
    return 1;
}

public FinishSleepingTimer(playerid)
{
    if(!IsPlayerConnected(playerid)) return 1;
    gPlayerOccupied[playerid] = false;
    TogglePlayerControllable(playerid, 1);
    ClearAnimations(playerid, true);
    if(!IsLoggedIn[playerid]) return 1;

    // Le sommeil reduit progressivement la fatigue plutot que de la remettre a
    // zero instantanement : plus realiste (une courte sieste n'efface pas tout).
    PlayerInfo[playerid][pFatigue] = ClampNeed(PlayerInfo[playerid][pFatigue] - 60);
    PlayerInfo[playerid][pStress] = ClampNeed(PlayerInfo[playerid][pStress] - 20);
    SendClientMessage(playerid, COLOR_GREEN, "Vous vous reveillez repose. Votre fatigue a bien diminue et votre stress a baisse.");
    return 1;
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

        // --- Effort physique : le sprint a pied accelere la deshydratation/fatigue ---
        // (SA-MP ne fournit pas d'etat "natation" distinct : les nageurs restent
        // PLAYER_STATE_ONFOOT, donc on se limite au sprint detectable via les touches).
        new bool:enEffort = false;
        if(playerState == PLAYER_STATE_ONFOOT)
        {
            new keys, ud, lr;
            GetPlayerKeys(playerid, keys, ud, lr);
            if((keys & KEY_SPRINT) && ud != 0) enEffort = true;
        }

        // --- Faim / Soif / Fatigue (legere variation aleatoire pour eviter l'effet mecanique) ---
        new soifDecay = NEEDS_SOIF_DECAY + (enEffort ? NEEDS_SOIF_DECAY_COURSE : 0) + random(2);
        new fatigueGain = NEEDS_FATIGUE_GAIN + (enEffort ? NEEDS_FATIGUE_GAIN_COURSE : 0);

        PlayerInfo[playerid][pFaim] = ClampNeed(PlayerInfo[playerid][pFaim] - (NEEDS_FAIM_DECAY + random(2)));
        PlayerInfo[playerid][pSoif] = ClampNeed(PlayerInfo[playerid][pSoif] - soifDecay);
        PlayerInfo[playerid][pFatigue] = ClampNeed(PlayerInfo[playerid][pFatigue] + fatigueGain);

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

        // --- Alertes progressives : d'abord une alerte douce, puis une alerte critique ---
        if(PlayerInfo[playerid][pFaim] == NEEDS_SEUIL_ALERTE)
        {
            SendClientMessage(playerid, COLOR_YELLOW, "Votre ventre gargouille. Il serait temps de manger bientot.");
        }
        else if(PlayerInfo[playerid][pFaim] == NEEDS_SEUIL_CRITIQUE)
        {
            SendClientMessage(playerid, COLOR_RED, "Vous avez tres faim. Rendez-vous a une epicerie (/manger).");
        }
        if(PlayerInfo[playerid][pSoif] == NEEDS_SEUIL_ALERTE)
        {
            SendClientMessage(playerid, COLOR_YELLOW, "Votre gorge est seche. Pensez a boire bientot.");
        }
        else if(PlayerInfo[playerid][pSoif] == NEEDS_SEUIL_CRITIQUE)
        {
            SendClientMessage(playerid, COLOR_RED, "Vous avez tres soif. Rendez-vous a une epicerie (/boire).");
        }
        if(PlayerInfo[playerid][pFatigue] == NEEDS_FATIGUE_HAUTE)
        {
            SendClientMessage(playerid, COLOR_YELLOW, "Vous etes epuise et manquez de reflexes. Pensez a dormir (/dormir).");
        }

        // --- Fatigue extreme : etourdissements visuels (camera secouee) au dela de 90 ---
        if(PlayerInfo[playerid][pFatigue] >= 90 && gCritDangerLevel[playerid] < 1)
        {
            SetPlayerDrunkLevel(playerid, 2000); // effet visuel d'ecran instable, sans toucher aux commandes
            gCritDangerLevel[playerid] = 1;
        }
        else if(PlayerInfo[playerid][pFatigue] < 90 && gCritDangerLevel[playerid] == 1)
        {
            SetPlayerDrunkLevel(playerid, 0);
            gCritDangerLevel[playerid] = 0;
        }

        // --- Consequence realiste de la privation totale : la sante decline puis le joueur s'evanouit ---
        if(PlayerInfo[playerid][pFaim] == 0 || PlayerInfo[playerid][pSoif] == 0)
        {
            gStarvingTicks[playerid]++;

            new Float:health;
            GetPlayerHealth(playerid, health);
            if(health > 1.0)
            {
                health -= NEEDS_DEGATS_CRITIQUE;
                if(health < 1.0) health = 1.0;
                SetPlayerHealth(playerid, health);
                SendClientMessage(playerid, COLOR_RED, "Votre sante decline : vous devez manger et boire d'urgence !");
            }

            // Au bout de plusieurs minutes de privation totale, le personnage s'evanouit
            // (comme un vrai malaise), plutot que de rester indefiniment bloque a 1 PV.
            if(gStarvingTicks[playerid] >= NEEDS_STARVING_MAX_TICKS)
            {
                SendClientMessageToAll(-1, "* Le personnage s'effondre, visiblement epuise par le manque de nourriture/d'eau.");
                SetPlayerHealth(playerid, 0.0); // deces RP -> geree par le systeme medical/hopital existant
                gStarvingTicks[playerid] = 0;
            }
        }
        else
        {
            gStarvingTicks[playerid] = 0;
        }
    }
    return 1;
}

// ==============================================================
//  OnGameModeInit
// ==============================================================
public OnGameModeInit()
{
    // --- Connexion MySQL + initialisation du systeme de spawn multi-villes (porte de LVRP) ---
    MySQLConnect(MYSQL_HOST, MYSQL_USER, MYSQL_PASS, MYSQL_DB);
    SpawnVilles_Setup();
    mysql_pquery(g_SQL, "SELECT * FROM spawn_villes ORDER BY id ASC", "spawn_Load");

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

    // --- Salaires de faction (toutes les 30 minutes) et facturation garde du corps (toutes les minutes) ---
    SetTimer("FactionSalaryTimer", 1800000, true);
    SetTimer("GardeDuCorpsTimer", 60000, true);

    // --- Banque : pickup + panneau 3D sur place, carte bancaire a recuperer sur place ---
    CreatePickup(1274, 1, BANK_POS_X, BANK_POS_Y, BANK_POS_Z, -1);
    Create3DTextLabel("{33CC33}BANQUE\n{FFFFFF}/banque pour interagir", 0xFFFFFFFF, BANK_POS_X, BANK_POS_Y, BANK_POS_Z + 0.7, 15.0, 0, 0);

    // --- Besoins vitaux : points de vente nourriture/boisson ---
    CreateShopPoints();


    // --- Police Nationale (LSPD) : pickup + panneau 3D a l'entree du commissariat central ---
    CreatePickup(1272, 1, PD_ENTRANCE_X, PD_ENTRANCE_Y, PD_ENTRANCE_Z, -1);
    Create3DTextLabel("{3388FF}COMMISSARIAT CENTRAL\n{FFFFFF}Appuyez sur F pour entrer", 0xFFFFFFFF, PD_ENTRANCE_X, PD_ENTRANCE_Y, PD_ENTRANCE_Z + 0.7, 15.0, 0, 0);
    Create3DTextLabel("{3388FF}SORTIE\n{FFFFFF}Appuyez sur F pour sortir", 0xFFFFFFFF, PD_INTERIOR_X, PD_INTERIOR_Y, PD_INTERIOR_Z + 0.7, 15.0, 0, 0);

    // Note : les batiments publics de faction sont charges automatiquement
    // depuis la base de donnees par Prop_Init() ci-dessous.

    // Classes de selection de personnage (spawn Los Santos)
    AddPlayerClass(101, 1569.2711, -2348.7114, 13.5547, 0.0, 0,0,0,0,0,0); // Civil - Los Santos Gare (point d'apparition de depart)
    AddPlayerClass(280, 1569.2711, -2348.7114, 13.5547, 0.0, 0,0,0,0,0,0); // Police (skin par defaut, a changer via faction)
    AddPlayerClass(274, 1569.2711, -2348.7114, 13.5547, 0.0, 0,0,0,0,0,0); // EMS

    // --- Systeme de proprietes : maisons / garages / commerces / meubles ---
    Prop_Init();

    print("==============================================");
    print("   CALIFORNIE RP - Gamemode charge avec succes  ");
    print("==============================================");
    return 1;
}

// ------------------------------------------------------------
//  Touche F (KEY_SECONDARY_ATTACK) : entree/sortie des points
//  d'interet exterieurs/interieurs (commissariat, etc.)
// ------------------------------------------------------------
public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
    if(newkeys & KEY_SECONDARY_ATTACK)
    {
        // Entree dans le commissariat depuis l'exterieur
        if(GetPlayerInterior(playerid) == 0 && IsPlayerNearPD(playerid))
        {
            SetPlayerPos(playerid, PD_INTERIOR_X, PD_INTERIOR_Y, PD_INTERIOR_Z);
            SetPlayerInterior(playerid, PD_INTERIOR_INT);
            SetPlayerVirtualWorld(playerid, 0);
            SendClientMessage(playerid, COLOR_GREEN, "Vous entrez dans le commissariat central.");
            return 1;
        }

        // Sortie du commissariat vers l'entree exterieure
        if(GetPlayerInterior(playerid) == PD_INTERIOR_INT && IsPlayerInRangeOfPoint(playerid, PD_RADIUS, PD_INTERIOR_X, PD_INTERIOR_Y, PD_INTERIOR_Z))
        {
            SetPlayerPos(playerid, PD_ENTRANCE_X, PD_ENTRANCE_Y, PD_ENTRANCE_Z);
            SetPlayerInterior(playerid, 0);
            SetPlayerVirtualWorld(playerid, 0);
            SendClientMessage(playerid, COLOR_GREEN, "Vous sortez du commissariat.");
            return 1;
        }

        // Entree/sortie des maisons, garages, commerces et batiments publics
        if(Prop_OnKeyStateChange(playerid, newkeys))
        {
            return 1;
        }
    }
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
    Prop_Exit();
    return 1;
}

// ==============================================================
//  Connexion / Inscription
// ==============================================================
public OnPlayerConnect(playerid)
{
    IsLoggedIn[playerid] = 0;
    gPlayerTriedPass[playerid] = 0;
    gGardeClient[playerid] = -1;
    gGardeRate[playerid] = 0;
    gLastPrimePompier[playerid] = 0;
    gLastPrimePenitencier[playerid] = 0;
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
    gPlayerPassHash[playerid] = 0;
    gCharDOB[playerid][0] = EOS;
    gCharMarital[playerid][0] = EOS;
    gCharBirthplace[playerid][0] = EOS;

    // --- Valeurs par defaut des besoins vitaux (ecrasees par LoadUserData si presentes dans le fichier) ---
    PlayerInfo[playerid][pFaim] = 100;
    PlayerInfo[playerid][pSoif] = 100;
    PlayerInfo[playerid][pFatigue] = 0;
    PlayerInfo[playerid][pStress] = 0;
    PlayerInfo[playerid][pMoral] = 100;
    PlayerInfo[playerid][pCity] = 0; // Los Santos par defaut (ecrase par LoadUserData si present)
    gLastManger[playerid] = 0;
    gLastBoire[playerid] = 0;
    gLastDormir[playerid] = 0;
    gPlayerOccupied[playerid] = false;
    gStarvingTicks[playerid] = 0;
    gCritDangerLevel[playerid] = 0;

    // --- Systeme de connexion / inscription -----------------------------
    // IMPORTANT : ce bloc doit s'executer AVANT toute fonction qui appelle
    // des natives fournies par un plugin externe (ex: SAMPVOICE). Si le
    // plugin n'est pas charge cote serveur (absent de server.cfg/config.json,
    // mauvaise architecture 32/64 bits, version incompatible), l'appel a une
    // native manquante genere un "Run time error 19" qui arrete net le
    // callback en cours : tout le code place APRES cet appel (donc le
    // systeme de connexion) ne s'executerait alors plus jamais.
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

    // --- Systeme de Chat Vocal (SAMPVOICE) -------------------------------
    // Place en dernier et volontairement isole : si SAMPVOICE echoue ou
    // n'est pas installe cote serveur, ca ne doit plus jamais impacter la
    // connexion, l'inscription ni aucun autre systeme du gamemode.
    SetupPlayerVoice(playerid);

    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    DestroyCardTD(playerid);
    // Si le joueur qui se deconnecte est un garde du corps en contrat, ou le
    // client d'un garde, on coupe la facturation pour eviter tout blocage.
    gGardeClient[playerid] = -1;
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(gGardeClient[i] == playerid) gGardeClient[i] = -1;
    }
    if(IsLoggedIn[playerid])
    {
        SaveUserData(playerid);
    }
    // Nettoyage du chat vocal place en DERNIER, volontairement isole : si
    // SAMPVOICE plante ou n'est pas charge, ca ne doit jamais empecher la
    // sauvegarde des donnees du joueur (meme logique que dans OnPlayerConnect).
    TeardownPlayerVoice(playerid);
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
        if(playertextid == gCSTD[playerid][CS_TD_MALE_BTN] || playertextid == gCSTD[playerid][CS_TD_MALE_FILL] || playertextid == gCSTD[playerid][CS_TD_MALE_BORDER])
        {
            gCharGender[playerid] = 0;
            gCharSkinIndex[playerid] = 0;
            RefreshCharSetupGenderVisual(playerid);
            RefreshCharSetupSkinDisplay(playerid);
            return 1;
        }
        if(playertextid == gCSTD[playerid][CS_TD_FEMALE_BTN] || playertextid == gCSTD[playerid][CS_TD_FEMALE_FILL] || playertextid == gCSTD[playerid][CS_TD_FEMALE_BORDER])
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

    new Float:baseX = 90.0;  // decale a droite pour eviter le HUD debug (FPS/MEM/ID) du client mobile, affiche en haut a gauche
    new Float:baseY = 195.0; // remonte encore un peu pour compenser le nouvel agrandissement

    // --- Bordure exterieure du panneau (liseré bleu, style "Liberty State") ---
    gCSTD[playerid][CS_TD_BORDER] = CreatePlayerTextDraw(playerid, baseX - 8.28, baseY - 8.28, "_");
    PlayerTextDrawTextSize(playerid, gCSTD[playerid][CS_TD_BORDER], baseX + 215.28, baseY + 280.14);
    PlayerTextDrawUseBox(playerid, gCSTD[playerid][CS_TD_BORDER], 1);
    PlayerTextDrawSetProportional(playerid, gCSTD[playerid][CS_TD_BORDER], 1);
    PlayerTextDrawBoxColor(playerid, gCSTD[playerid][CS_TD_BORDER], 0x3C8FE6FF);
    PlayerTextDrawColor(playerid, gCSTD[playerid][CS_TD_BORDER], 0x00000000);
    PlayerTextDrawShow(playerid, gCSTD[playerid][CS_TD_BORDER]);

    // --- Fond principal (opaque, comme sur la reference) ---
    gCSTD[playerid][CS_TD_BG] = CreatePlayerTextDraw(playerid, baseX - 4.14, baseY - 4.14, "_");
    PlayerTextDrawTextSize(playerid, gCSTD[playerid][CS_TD_BG], baseX + 211.14, baseY + 276.0);
    PlayerTextDrawUseBox(playerid, gCSTD[playerid][CS_TD_BG], 1);
    PlayerTextDrawSetProportional(playerid, gCSTD[playerid][CS_TD_BG], 1);
    PlayerTextDrawBoxColor(playerid, gCSTD[playerid][CS_TD_BG], 0x0A0A14EE);
    PlayerTextDrawColor(playerid, gCSTD[playerid][CS_TD_BG], 0x00000000);
    PlayerTextDrawShow(playerid, gCSTD[playerid][CS_TD_BG]);

    // --- Bandeau titre "CHARACTER SETUP" ---
    gCSTD[playerid][CS_TD_TITLE_BAR] = CreatePlayerTextDraw(playerid, baseX - 4.14, baseY - 4.14, "_");
    PlayerTextDrawTextSize(playerid, gCSTD[playerid][CS_TD_TITLE_BAR], baseX + 211.14, baseY + 19.32);
    PlayerTextDrawUseBox(playerid, gCSTD[playerid][CS_TD_TITLE_BAR], 1);
    PlayerTextDrawSetProportional(playerid, gCSTD[playerid][CS_TD_TITLE_BAR], 1);
    PlayerTextDrawBoxColor(playerid, gCSTD[playerid][CS_TD_TITLE_BAR], 0x1E3A66E6);
    PlayerTextDrawColor(playerid, gCSTD[playerid][CS_TD_TITLE_BAR], 0x00000000);
    PlayerTextDrawShow(playerid, gCSTD[playerid][CS_TD_TITLE_BAR]);

    gCSTD[playerid][CS_TD_TITLE] = CreatePlayerTextDraw(playerid, baseX + 5.52, baseY - 4.14, "CHARACTER SETUP");
    PlayerTextDrawFont(playerid, gCSTD[playerid][CS_TD_TITLE], 2);
    PlayerTextDrawSetProportional(playerid, gCSTD[playerid][CS_TD_TITLE], 1);
    PlayerTextDrawLetterSize(playerid, gCSTD[playerid][CS_TD_TITLE], 0.148, 0.965);
    PlayerTextDrawColor(playerid, gCSTD[playerid][CS_TD_TITLE], COLOR_CYAN);
    PlayerTextDrawSetShadow(playerid, gCSTD[playerid][CS_TD_TITLE], 0);
    PlayerTextDrawShow(playerid, gCSTD[playerid][CS_TD_TITLE]);

    // ================= GENDER =================
    gCSTD[playerid][CS_TD_GENDER_LABEL] = CreatePlayerTextDraw(playerid, baseX + 5.52, baseY + 28.98, "GENDER");
    PlayerTextDrawFont(playerid, gCSTD[playerid][CS_TD_GENDER_LABEL], 2);
    PlayerTextDrawSetProportional(playerid, gCSTD[playerid][CS_TD_GENDER_LABEL], 1);
    PlayerTextDrawLetterSize(playerid, gCSTD[playerid][CS_TD_GENDER_LABEL], 0.136, 0.837);
    PlayerTextDrawColor(playerid, gCSTD[playerid][CS_TD_GENDER_LABEL], COLOR_WHITE);
    PlayerTextDrawSetShadow(playerid, gCSTD[playerid][CS_TD_GENDER_LABEL], 0);
    PlayerTextDrawShow(playerid, gCSTD[playerid][CS_TD_GENDER_LABEL]);

    // Liseré MALE (s'allume en blanc quand selectionne)
    gCSTD[playerid][CS_TD_MALE_BORDER] = CreatePlayerTextDraw(playerid, baseX + 4.14, baseY + 45.54, "_");
    PlayerTextDrawTextSize(playerid, gCSTD[playerid][CS_TD_MALE_BORDER], baseX + 104.88, baseY + 71.76);
    PlayerTextDrawUseBox(playerid, gCSTD[playerid][CS_TD_MALE_BORDER], 1);
    PlayerTextDrawSetProportional(playerid, gCSTD[playerid][CS_TD_MALE_BORDER], 1);
    PlayerTextDrawBoxColor(playerid, gCSTD[playerid][CS_TD_MALE_BORDER], 0x0A0A14EE);
    PlayerTextDrawColor(playerid, gCSTD[playerid][CS_TD_MALE_BORDER], 0x00000000);
    PlayerTextDrawSetSelectable(playerid, gCSTD[playerid][CS_TD_MALE_BORDER], 1);
    PlayerTextDrawShow(playerid, gCSTD[playerid][CS_TD_MALE_BORDER]);

    // Remplissage bleu (boite seule, SANS alignment dessus : c'etait le
    // melange UseBox + Alignment sur un meme textdraw qui debordait sur
    // le client mobile). Toujours bleu, que ce soit selectionne ou non,
    // comme sur la reference Liberty State.
    gCSTD[playerid][CS_TD_MALE_FILL] = CreatePlayerTextDraw(playerid, baseX + 6.21, baseY + 47.61, "_");
    PlayerTextDrawTextSize(playerid, gCSTD[playerid][CS_TD_MALE_FILL], baseX + 102.81, baseY + 69.69);
    PlayerTextDrawUseBox(playerid, gCSTD[playerid][CS_TD_MALE_FILL], 1);
    PlayerTextDrawSetProportional(playerid, gCSTD[playerid][CS_TD_MALE_FILL], 1);
    PlayerTextDrawBoxColor(playerid, gCSTD[playerid][CS_TD_MALE_FILL], 0x1544AAFF);
    PlayerTextDrawColor(playerid, gCSTD[playerid][CS_TD_MALE_FILL], 0x00000000);
    PlayerTextDrawSetSelectable(playerid, gCSTD[playerid][CS_TD_MALE_FILL], 1);
    PlayerTextDrawShow(playerid, gCSTD[playerid][CS_TD_MALE_FILL]);

    // Texte "MALE" seul, sans boite : evite de combiner UseBox+Alignment.
    gCSTD[playerid][CS_TD_MALE_BTN] = CreatePlayerTextDraw(playerid, baseX + 54.51, baseY + 51.06, "MALE");
    PlayerTextDrawFont(playerid, gCSTD[playerid][CS_TD_MALE_BTN], 2);
    PlayerTextDrawSetProportional(playerid, gCSTD[playerid][CS_TD_MALE_BTN], 1);
    PlayerTextDrawLetterSize(playerid, gCSTD[playerid][CS_TD_MALE_BTN], 0.101, 0.965);
    PlayerTextDrawColor(playerid, gCSTD[playerid][CS_TD_MALE_BTN], COLOR_WHITE);
    PlayerTextDrawAlignment(playerid, gCSTD[playerid][CS_TD_MALE_BTN], 2);
    PlayerTextDrawSetShadow(playerid, gCSTD[playerid][CS_TD_MALE_BTN], 0);
    PlayerTextDrawSetSelectable(playerid, gCSTD[playerid][CS_TD_MALE_BTN], 1);
    PlayerTextDrawShow(playerid, gCSTD[playerid][CS_TD_MALE_BTN]);

    // Liseré FEMALE (s'allume en blanc quand selectionne)
    gCSTD[playerid][CS_TD_FEMALE_BORDER] = CreatePlayerTextDraw(playerid, baseX + 110.4, baseY + 45.54, "_");
    PlayerTextDrawTextSize(playerid, gCSTD[playerid][CS_TD_FEMALE_BORDER], baseX + 211.14, baseY + 71.76);
    PlayerTextDrawUseBox(playerid, gCSTD[playerid][CS_TD_FEMALE_BORDER], 1);
    PlayerTextDrawSetProportional(playerid, gCSTD[playerid][CS_TD_FEMALE_BORDER], 1);
    PlayerTextDrawBoxColor(playerid, gCSTD[playerid][CS_TD_FEMALE_BORDER], 0x0A0A14EE);
    PlayerTextDrawColor(playerid, gCSTD[playerid][CS_TD_FEMALE_BORDER], 0x00000000);
    PlayerTextDrawSetSelectable(playerid, gCSTD[playerid][CS_TD_FEMALE_BORDER], 1);
    PlayerTextDrawShow(playerid, gCSTD[playerid][CS_TD_FEMALE_BORDER]);

    // Remplissage rose (boite seule, meme principe que MALE_FILL).
    gCSTD[playerid][CS_TD_FEMALE_FILL] = CreatePlayerTextDraw(playerid, baseX + 112.47, baseY + 47.61, "_");
    PlayerTextDrawTextSize(playerid, gCSTD[playerid][CS_TD_FEMALE_FILL], baseX + 209.07, baseY + 69.69);
    PlayerTextDrawUseBox(playerid, gCSTD[playerid][CS_TD_FEMALE_FILL], 1);
    PlayerTextDrawSetProportional(playerid, gCSTD[playerid][CS_TD_FEMALE_FILL], 1);
    PlayerTextDrawBoxColor(playerid, gCSTD[playerid][CS_TD_FEMALE_FILL], 0xCC1F8FFF);
    PlayerTextDrawColor(playerid, gCSTD[playerid][CS_TD_FEMALE_FILL], 0x00000000);
    PlayerTextDrawSetSelectable(playerid, gCSTD[playerid][CS_TD_FEMALE_FILL], 1);
    PlayerTextDrawShow(playerid, gCSTD[playerid][CS_TD_FEMALE_FILL]);

    // Texte "FEMALE" seul, sans boite.
    gCSTD[playerid][CS_TD_FEMALE_BTN] = CreatePlayerTextDraw(playerid, baseX + 160.77, baseY + 52.44, "FEMALE");
    PlayerTextDrawFont(playerid, gCSTD[playerid][CS_TD_FEMALE_BTN], 2);
    PlayerTextDrawSetProportional(playerid, gCSTD[playerid][CS_TD_FEMALE_BTN], 1);
    PlayerTextDrawLetterSize(playerid, gCSTD[playerid][CS_TD_FEMALE_BTN], 0.093, 0.965);
    PlayerTextDrawColor(playerid, gCSTD[playerid][CS_TD_FEMALE_BTN], COLOR_WHITE);
    PlayerTextDrawAlignment(playerid, gCSTD[playerid][CS_TD_FEMALE_BTN], 2);
    PlayerTextDrawSetShadow(playerid, gCSTD[playerid][CS_TD_FEMALE_BTN], 0);
    PlayerTextDrawSetSelectable(playerid, gCSTD[playerid][CS_TD_FEMALE_BTN], 1);
    PlayerTextDrawShow(playerid, gCSTD[playerid][CS_TD_FEMALE_BTN]);


    // ================= AGE =================
    gCSTD[playerid][CS_TD_AGE_LABEL] = CreatePlayerTextDraw(playerid, baseX + 5.52, baseY + 84.18, "AGE");
    PlayerTextDrawFont(playerid, gCSTD[playerid][CS_TD_AGE_LABEL], 2);
    PlayerTextDrawSetProportional(playerid, gCSTD[playerid][CS_TD_AGE_LABEL], 1);
    PlayerTextDrawLetterSize(playerid, gCSTD[playerid][CS_TD_AGE_LABEL], 0.136, 0.837);
    PlayerTextDrawColor(playerid, gCSTD[playerid][CS_TD_AGE_LABEL], COLOR_WHITE);
    PlayerTextDrawSetShadow(playerid, gCSTD[playerid][CS_TD_AGE_LABEL], 0);
    PlayerTextDrawShow(playerid, gCSTD[playerid][CS_TD_AGE_LABEL]);

    gCSTD[playerid][CS_TD_AGE_BOX] = CreatePlayerTextDraw(playerid, baseX + 4.14, baseY + 99.36, "_");
    PlayerTextDrawTextSize(playerid, gCSTD[playerid][CS_TD_AGE_BOX], baseX + 211.14, baseY + 120.06);
    PlayerTextDrawUseBox(playerid, gCSTD[playerid][CS_TD_AGE_BOX], 1);
    PlayerTextDrawSetProportional(playerid, gCSTD[playerid][CS_TD_AGE_BOX], 1);
    PlayerTextDrawBoxColor(playerid, gCSTD[playerid][CS_TD_AGE_BOX], 0x1B1B28E6);
    PlayerTextDrawColor(playerid, gCSTD[playerid][CS_TD_AGE_BOX], 0x00000000);
    PlayerTextDrawShow(playerid, gCSTD[playerid][CS_TD_AGE_BOX]);

    gCSTD[playerid][CS_TD_AGE_MINUS] = CreatePlayerTextDraw(playerid, baseX + 11.04, baseY + 102.12, "<<<");
    PlayerTextDrawFont(playerid, gCSTD[playerid][CS_TD_AGE_MINUS], 2);
    PlayerTextDrawSetProportional(playerid, gCSTD[playerid][CS_TD_AGE_MINUS], 1);
    PlayerTextDrawLetterSize(playerid, gCSTD[playerid][CS_TD_AGE_MINUS], 0.148, 0.965);
    PlayerTextDrawColor(playerid, gCSTD[playerid][CS_TD_AGE_MINUS], COLOR_CYAN);
    PlayerTextDrawSetShadow(playerid, gCSTD[playerid][CS_TD_AGE_MINUS], 0);
    PlayerTextDrawSetSelectable(playerid, gCSTD[playerid][CS_TD_AGE_MINUS], 1);
    PlayerTextDrawShow(playerid, gCSTD[playerid][CS_TD_AGE_MINUS]);

    gCSTD[playerid][CS_TD_AGE_VALUE] = CreatePlayerTextDraw(playerid, baseX + 107.64, baseY + 102.12, "18");
    PlayerTextDrawFont(playerid, gCSTD[playerid][CS_TD_AGE_VALUE], 2);
    PlayerTextDrawSetProportional(playerid, gCSTD[playerid][CS_TD_AGE_VALUE], 1);
    PlayerTextDrawLetterSize(playerid, gCSTD[playerid][CS_TD_AGE_VALUE], 0.155, 0.965);
    PlayerTextDrawColor(playerid, gCSTD[playerid][CS_TD_AGE_VALUE], COLOR_WHITE);
    PlayerTextDrawAlignment(playerid, gCSTD[playerid][CS_TD_AGE_VALUE], 2);
    PlayerTextDrawSetShadow(playerid, gCSTD[playerid][CS_TD_AGE_VALUE], 0);
    PlayerTextDrawShow(playerid, gCSTD[playerid][CS_TD_AGE_VALUE]);

    gCSTD[playerid][CS_TD_AGE_PLUS] = CreatePlayerTextDraw(playerid, baseX + 195.96, baseY + 102.12, ">>>");
    PlayerTextDrawFont(playerid, gCSTD[playerid][CS_TD_AGE_PLUS], 2);
    PlayerTextDrawSetProportional(playerid, gCSTD[playerid][CS_TD_AGE_PLUS], 1);
    PlayerTextDrawLetterSize(playerid, gCSTD[playerid][CS_TD_AGE_PLUS], 0.148, 0.965);
    PlayerTextDrawColor(playerid, gCSTD[playerid][CS_TD_AGE_PLUS], COLOR_CYAN);
    PlayerTextDrawSetShadow(playerid, gCSTD[playerid][CS_TD_AGE_PLUS], 0);
    PlayerTextDrawSetSelectable(playerid, gCSTD[playerid][CS_TD_AGE_PLUS], 1);
    PlayerTextDrawShow(playerid, gCSTD[playerid][CS_TD_AGE_PLUS]);

    // ================= SKIN =================
    gCSTD[playerid][CS_TD_SKIN_LABEL] = CreatePlayerTextDraw(playerid, baseX + 5.52, baseY + 132.48, "SKIN");
    PlayerTextDrawFont(playerid, gCSTD[playerid][CS_TD_SKIN_LABEL], 2);
    PlayerTextDrawSetProportional(playerid, gCSTD[playerid][CS_TD_SKIN_LABEL], 1);
    PlayerTextDrawLetterSize(playerid, gCSTD[playerid][CS_TD_SKIN_LABEL], 0.136, 0.837);
    PlayerTextDrawColor(playerid, gCSTD[playerid][CS_TD_SKIN_LABEL], COLOR_WHITE);
    PlayerTextDrawSetShadow(playerid, gCSTD[playerid][CS_TD_SKIN_LABEL], 0);
    PlayerTextDrawShow(playerid, gCSTD[playerid][CS_TD_SKIN_LABEL]);

    gCSTD[playerid][CS_TD_SKIN_BOX] = CreatePlayerTextDraw(playerid, baseX + 4.14, baseY + 147.66, "_");
    PlayerTextDrawTextSize(playerid, gCSTD[playerid][CS_TD_SKIN_BOX], baseX + 211.14, baseY + 168.36);
    PlayerTextDrawUseBox(playerid, gCSTD[playerid][CS_TD_SKIN_BOX], 1);
    PlayerTextDrawSetProportional(playerid, gCSTD[playerid][CS_TD_SKIN_BOX], 1);
    PlayerTextDrawBoxColor(playerid, gCSTD[playerid][CS_TD_SKIN_BOX], 0x1B1B28E6);
    PlayerTextDrawColor(playerid, gCSTD[playerid][CS_TD_SKIN_BOX], 0x00000000);
    PlayerTextDrawShow(playerid, gCSTD[playerid][CS_TD_SKIN_BOX]);

    gCSTD[playerid][CS_TD_SKIN_MINUS] = CreatePlayerTextDraw(playerid, baseX + 11.04, baseY + 150.42, "<<<");
    PlayerTextDrawFont(playerid, gCSTD[playerid][CS_TD_SKIN_MINUS], 2);
    PlayerTextDrawSetProportional(playerid, gCSTD[playerid][CS_TD_SKIN_MINUS], 1);
    PlayerTextDrawLetterSize(playerid, gCSTD[playerid][CS_TD_SKIN_MINUS], 0.148, 0.965);
    PlayerTextDrawColor(playerid, gCSTD[playerid][CS_TD_SKIN_MINUS], COLOR_CYAN);
    PlayerTextDrawSetShadow(playerid, gCSTD[playerid][CS_TD_SKIN_MINUS], 0);
    PlayerTextDrawSetSelectable(playerid, gCSTD[playerid][CS_TD_SKIN_MINUS], 1);
    PlayerTextDrawShow(playerid, gCSTD[playerid][CS_TD_SKIN_MINUS]);

    gCSTD[playerid][CS_TD_SKIN_VALUE] = CreatePlayerTextDraw(playerid, baseX + 107.64, baseY + 150.42, "1/49");
    PlayerTextDrawFont(playerid, gCSTD[playerid][CS_TD_SKIN_VALUE], 2);
    PlayerTextDrawSetProportional(playerid, gCSTD[playerid][CS_TD_SKIN_VALUE], 1);
    PlayerTextDrawLetterSize(playerid, gCSTD[playerid][CS_TD_SKIN_VALUE], 0.155, 0.965);
    PlayerTextDrawColor(playerid, gCSTD[playerid][CS_TD_SKIN_VALUE], COLOR_WHITE);
    PlayerTextDrawAlignment(playerid, gCSTD[playerid][CS_TD_SKIN_VALUE], 2);
    PlayerTextDrawSetShadow(playerid, gCSTD[playerid][CS_TD_SKIN_VALUE], 0);
    PlayerTextDrawShow(playerid, gCSTD[playerid][CS_TD_SKIN_VALUE]);

    gCSTD[playerid][CS_TD_SKIN_PLUS] = CreatePlayerTextDraw(playerid, baseX + 195.96, baseY + 150.42, ">>>");
    PlayerTextDrawFont(playerid, gCSTD[playerid][CS_TD_SKIN_PLUS], 2);
    PlayerTextDrawSetProportional(playerid, gCSTD[playerid][CS_TD_SKIN_PLUS], 1);
    PlayerTextDrawLetterSize(playerid, gCSTD[playerid][CS_TD_SKIN_PLUS], 0.148, 0.965);
    PlayerTextDrawColor(playerid, gCSTD[playerid][CS_TD_SKIN_PLUS], COLOR_CYAN);
    PlayerTextDrawSetShadow(playerid, gCSTD[playerid][CS_TD_SKIN_PLUS], 0);
    PlayerTextDrawSetSelectable(playerid, gCSTD[playerid][CS_TD_SKIN_PLUS], 1);
    PlayerTextDrawShow(playerid, gCSTD[playerid][CS_TD_SKIN_PLUS]);

    // ================= CONFIRMER =================
    gCSTD[playerid][CS_TD_CONFIRM_BORDER] = CreatePlayerTextDraw(playerid, baseX + 4.14, baseY + 182.16, "_");
    PlayerTextDrawTextSize(playerid, gCSTD[playerid][CS_TD_CONFIRM_BORDER], baseX + 211.14, baseY + 208.38);
    PlayerTextDrawUseBox(playerid, gCSTD[playerid][CS_TD_CONFIRM_BORDER], 1);
    PlayerTextDrawSetProportional(playerid, gCSTD[playerid][CS_TD_CONFIRM_BORDER], 1);
    PlayerTextDrawBoxColor(playerid, gCSTD[playerid][CS_TD_CONFIRM_BORDER], 0x33CC33FF);
    PlayerTextDrawColor(playerid, gCSTD[playerid][CS_TD_CONFIRM_BORDER], 0x00000000);
    PlayerTextDrawShow(playerid, gCSTD[playerid][CS_TD_CONFIRM_BORDER]);

    gCSTD[playerid][CS_TD_CONFIRM_BTN] = CreatePlayerTextDraw(playerid, baseX + 6.9, baseY + 186.3, "CONFIRMER");
    PlayerTextDrawFont(playerid, gCSTD[playerid][CS_TD_CONFIRM_BTN], 2);
    PlayerTextDrawSetProportional(playerid, gCSTD[playerid][CS_TD_CONFIRM_BTN], 1);
    PlayerTextDrawLetterSize(playerid, gCSTD[playerid][CS_TD_CONFIRM_BTN], 0.167, 1.03);
    PlayerTextDrawTextSize(playerid, gCSTD[playerid][CS_TD_CONFIRM_BTN], baseX + 208.38, baseY + 205.62);
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

        gPlayerPassHash[playerid] = gPendingPassHash[playerid];
        format(line, sizeof(line), "Password=%d\r\n", gPlayerPassHash[playerid]);
        fwrite(f, line);
        format(line, sizeof(line), "Cash=100000\r\n");
        fwrite(f, line);
        format(line, sizeof(line), "Bank=0\r\n");
        fwrite(f, line);
        format(line, sizeof(line), "CarteBancaire=0\r\n");
        fwrite(f, line);
        format(line, sizeof(line), "Faction=0\r\n");
        fwrite(f, line);
        format(line, sizeof(line), "Grade=0\r\n");
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
    // --- Systeme de proprietes : maisons / garages / commerces / meubles ---
    if(Prop_OnDialogResponse(playerid, dialogid, response, listitem, inputtext))
    {
        return 1;
    }

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
            gPlayerPassHash[playerid] = storedHash;
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
            case 2: // Spawn par defaut -> choix de la ville
            {
                ShowVilleChoiceDialog(playerid);
                return 1;
            }
        }

        SpawnPlayerAfterLogin(playerid);
        return 1;
    }

    if(dialogid == DIALOG_VILLE)
    {
        if(!response)
        {
            ShowSpawnSelectionDialog(playerid);
            return 1;
        }

        PlayerInfo[playerid][pCity] = listitem;
        SetDefaultSpawnPos(playerid);
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

    if(dialogid == DIALOG_BANQUE_SOLDE)
    {
        return 1;
    }

    if(dialogid == DIALOG_BANQUE)
    {
        if(!response) return 1;
        if(!IsPlayerNearBank(playerid))
        {
            SendClientMessage(playerid, COLOR_RED, "Vous devez etre a la banque pour faire cela.");
            return 1;
        }

        // La liste change selon que le joueur possede deja sa carte ou non,
        // donc listitem 0 signifie des choses differentes dans les deux cas.
        if(!PlayerInfo[playerid][pCarteBancaire])
        {
            switch(listitem)
            {
                case 0: // Recuperer ma carte bancaire
                {
                    PlayerInfo[playerid][pCarteBancaire] = 1;
                    SendClientMessage(playerid, COLOR_GREEN, "Vous avez recupere votre carte bancaire. Vous pouvez desormais consulter votre solde avec /solde.");
                }
                case 1: ShowBanqueSoldeDialog(playerid); // Consulter mon solde
                case 2: ShowPlayerDialog(playerid, DIALOG_BANQUE_DEPOT, DIALOG_STYLE_INPUT, "Depot bancaire", "Entrez le montant a deposer sur votre compte :", "Valider", "Annuler");
                case 3: ShowPlayerDialog(playerid, DIALOG_BANQUE_RETRAIT, DIALOG_STYLE_INPUT, "Retrait bancaire", "Entrez le montant a retirer de votre compte :", "Valider", "Annuler");
            }
        }
        else
        {
            switch(listitem)
            {
                case 0: ShowBanqueSoldeDialog(playerid); // Consulter mon solde
                case 1: ShowPlayerDialog(playerid, DIALOG_BANQUE_DEPOT, DIALOG_STYLE_INPUT, "Depot bancaire", "Entrez le montant a deposer sur votre compte :", "Valider", "Annuler");
                case 2: ShowPlayerDialog(playerid, DIALOG_BANQUE_RETRAIT, DIALOG_STYLE_INPUT, "Retrait bancaire", "Entrez le montant a retirer de votre compte :", "Valider", "Annuler");
            }
        }
        return 1;
    }

    if(dialogid == DIALOG_BANQUE_DEPOT)
    {
        if(!response) return 1;
        if(!IsPlayerNearBank(playerid))
        {
            SendClientMessage(playerid, COLOR_RED, "Vous devez etre a la banque pour faire cela.");
            return 1;
        }
        new montant = strval(inputtext);
        if(montant <= 0)
        {
            SendClientMessage(playerid, COLOR_RED, "Montant invalide.");
            return 1;
        }
        if(GetPlayerMoney(playerid) < montant)
        {
            SendClientMessage(playerid, COLOR_RED, "Vous n'avez pas assez d'argent liquide sur vous.");
            return 1;
        }
        GivePlayerMoney(playerid, -montant);
        GivePlayerBankMoney(playerid, montant);
        new str[96];
        format(str, sizeof(str), "Vous avez depose $%d sur votre compte bancaire. Nouveau solde : $%d", montant, PlayerInfo[playerid][pBank]);
        SendClientMessage(playerid, COLOR_GREEN, str);
        return 1;
    }

    if(dialogid == DIALOG_BANQUE_RETRAIT)
    {
        if(!response) return 1;
        if(!IsPlayerNearBank(playerid))
        {
            SendClientMessage(playerid, COLOR_RED, "Vous devez etre a la banque pour faire cela.");
            return 1;
        }
        if(!PlayerInfo[playerid][pCarteBancaire])
        {
            SendClientMessage(playerid, COLOR_RED, "Vous devez d'abord recuperer votre carte bancaire.");
            return 1;
        }
        new montant = strval(inputtext);
        if(montant <= 0)
        {
            SendClientMessage(playerid, COLOR_RED, "Montant invalide.");
            return 1;
        }
        if(PlayerInfo[playerid][pBank] < montant)
        {
            SendClientMessage(playerid, COLOR_RED, "Solde bancaire insuffisant.");
            return 1;
        }
        GivePlayerBankMoney(playerid, -montant);
        GivePlayerMoney(playerid, montant);
        new str[96];
        format(str, sizeof(str), "Vous avez retire $%d de votre compte bancaire. Nouveau solde : $%d", montant, PlayerInfo[playerid][pBank]);
        SendClientMessage(playerid, COLOR_GREEN, str);
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

// Liste des 13 villes de San Andreas (systeme de spawn multi-villes, porte de LVRP)
public ShowVilleChoiceDialog(playerid)
{
    new items[256], tmp[36];
    items[0] = EOS;
    for(new i = 0; i < MAX_CITY; i++)
    {
        format(tmp, sizeof(tmp), "%s\n", GetCityName(i));
        strcat(items, tmp, sizeof(items));
    }
    ShowPlayerDialog(playerid, DIALOG_VILLE, DIALOG_STYLE_LIST, "Choisissez votre ville de spawn", items, "Choisir", "Retour");
    return 1;
}

// Coordonnees de spawn par defaut : desormais celles de la ville du joueur
// (PlayerInfo[playerid][pCity]), chargees depuis la table MySQL spawn_villes
// via spawn[MAX_CITY] (systeme porte de LVRP.pwn).
stock SetDefaultSpawnPos(playerid)
{
    new city = PlayerInfo[playerid][pCity];
    if(city < 0 || city >= MAX_CITY) city = 0;

    PlayerInfo[playerid][pPosX] = spawn[city][pos][0];
    PlayerInfo[playerid][pPosY] = spawn[city][pos][1];
    PlayerInfo[playerid][pPosZ] = spawn[city][pos][2];
    PlayerInfo[playerid][pPosA] = spawn[city][pos][3];
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
            else if(!strcmp(key, "Bank")) PlayerInfo[playerid][pBank] = strval(val);
            else if(!strcmp(key, "CarteBancaire")) PlayerInfo[playerid][pCarteBancaire] = strval(val);
            else if(!strcmp(key, "Faction")) PlayerInfo[playerid][pFaction] = strval(val);
            else if(!strcmp(key, "Grade")) PlayerInfo[playerid][pGrade] = strval(val);
            else if(!strcmp(key, "Admin")) PlayerInfo[playerid][pAdmin] = strval(val);
            else if(!strcmp(key, "Skin")) PlayerInfo[playerid][pSkin] = strval(val);
            else if(!strcmp(key, "PosX")) PlayerInfo[playerid][pPosX] = floatstr(val);
            else if(!strcmp(key, "PosY")) PlayerInfo[playerid][pPosY] = floatstr(val);
            else if(!strcmp(key, "PosZ")) PlayerInfo[playerid][pPosZ] = floatstr(val);
            else if(!strcmp(key, "PosA")) PlayerInfo[playerid][pPosA] = floatstr(val);
            else if(!strcmp(key, "Int")) PlayerInfo[playerid][pInt] = strval(val);
            else if(!strcmp(key, "World")) PlayerInfo[playerid][pWorld] = strval(val);
            else if(!strcmp(key, "City")) PlayerInfo[playerid][pCity] = strval(val);
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

    // On n'essaie plus de relire le mot de passe depuis le fichier avant de
    // reecrire par-dessus : si cette lecture echouait (ne serait-ce qu'une
    // fois, ex. reouverture du fichier juste apres ecriture), storedHash
    // restait a 0 et ce 0 etait sauvegarde a la place du vrai mot de passe,
    // cassant definitivement la connexion du joueur. On utilise desormais
    // le hash garde en memoire depuis la connexion/inscription.
    new File:fw = fopen(UserPathStr(playerid), io_write);
    if(fw)
    {
        new outLine[128];
        format(outLine, sizeof(outLine), "Password=%d\r\n", gPlayerPassHash[playerid]); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "Cash=%d\r\n", GetPlayerMoney(playerid)); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "Bank=%d\r\n", PlayerInfo[playerid][pBank]); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "CarteBancaire=%d\r\n", PlayerInfo[playerid][pCarteBancaire]); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "Faction=%d\r\n", PlayerInfo[playerid][pFaction]); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "Grade=%d\r\n", PlayerInfo[playerid][pGrade]); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "Admin=%d\r\n", PlayerInfo[playerid][pAdmin]); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "Skin=%d\r\n", GetPlayerSkin(playerid)); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "PosX=%f\r\n", x); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "PosY=%f\r\n", y); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "PosZ=%f\r\n", z); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "PosA=%f\r\n", a); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "Int=%d\r\n", GetPlayerInterior(playerid)); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "World=%d\r\n", GetPlayerVirtualWorld(playerid)); fwrite(fw, outLine);
        format(outLine, sizeof(outLine), "City=%d\r\n", PlayerInfo[playerid][pCity]); fwrite(fw, outLine);
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

    // --- Systeme de proprietes : maisons / garages / commerces / meubles ---
    if(Prop_OnCommand(playerid, cmd, cmdtext, idx))
    {
        return 1;
    }

    if(!strcmp(cmd, "/aide", true))
    {
        SendClientMessage(playerid, COLOR_YELLOW, "== Commandes Californie RP ==");
        SendClientMessage(playerid, COLOR_WHITE, "/me /do /ooc - Roleplay");
        SendClientMessage(playerid, COLOR_WHITE, "/stats /cash /solde /poste - Informations personnelles");
        SendClientMessage(playerid, COLOR_WHITE, "/travail - Voir la liste des factions et des jobs disponibles");
        SendClientMessage(playerid, COLOR_WHITE, "/banque - Gerer votre compte bancaire (sur place)");
        SendClientMessage(playerid, COLOR_WHITE, "/manger /boire /dormir - Gerer vos besoins vitaux");
        SendClientMessage(playerid, COLOR_WHITE, "/sethome - Enregistrer votre position comme domicile");
        SendClientMessage(playerid, COLOR_WHITE, "/car - Faire apparaitre un vehicule");
        SendClientMessage(playerid, COLOR_WHITE, "/engine /lock - Interagir avec un vehicule");
        SendClientMessage(playerid, COLOR_WHITE, "/papiers - Voir votre carte d'identite, permis, port d'armes et recus");
        SendClientMessage(playerid, COLOR_WHITE, "/maisons /garages /commerces - Voir les proprietes disponibles a l'achat");
        SendClientMessage(playerid, COLOR_WHITE, "/batimentspublics - Voir les batiments publics (hopital, FBI, pompiers...)");
        SendClientMessage(playerid, COLOR_WHITE, "A l'entree d'une propriete que vous possedez, appuyez sur F pour entrer/sortir");
        SendClientMessage(playerid, COLOR_WHITE, "/acheter /vendre /fermer /ouvrir - Gerer une propriete (a son entree)");
        SendClientMessage(playerid, COLOR_WHITE, "/rentrer /sortir - Ranger/sortir un vehicule de votre garage");
        SendClientMessage(playerid, COLOR_WHITE, "/caisse - Gerer la caisse de votre commerce");
        SendClientMessage(playerid, COLOR_WHITE, "/meubles /enlevermeuble - Decorer l'interieur de votre maison");
        if(PlayerInfo[playerid][pAdmin] > 0)
        {
            SendClientMessage(playerid, COLOR_ADMIN, "Tapez /aideadmin pour la liste des commandes admin/dev.");
        }
        return 1;
    }

    if(!strcmp(cmd, "/savepos", true))
    {
        if(PlayerInfo[playerid][pAdmin] <= 0)
        {
            SendClientMessage(playerid, COLOR_RED, "Cette commande est reservee aux administrateurs.");
            return 1;
        }
        tmp = strtok_(cmdtext, idx);
        if(!tmp[0])
        {
            SendClientMessage(playerid, COLOR_WHITE, "Usage: /savepos [id 0-12] (0=Los Santos ... 12=El Quebrados, voir /listevilles)");
            return 1;
        }
        new city = strval(tmp);
        if(city < 0 || city >= MAX_CITY)
        {
            SendClientMessage(playerid, COLOR_RED, "ID de ville invalide (0 a 12).");
            return 1;
        }
        new Float:x, Float:y, Float:z, Float:a;
        GetPlayerPos(playerid, x, y, z);
        GetPlayerFacingAngle(playerid, a);
        spawn[city][pos][0] = x;
        spawn[city][pos][1] = y;
        spawn[city][pos][2] = z;
        spawn[city][pos][3] = a;
        spawn_Save(city);
        spawn_Update(city);

        new str[96];
        format(str, sizeof(str), "Spawn de %s mis a jour a votre position actuelle.", GetCityName(city));
        SendClientMessage(playerid, COLOR_GREEN, str);
        return 1;
    }

    if(!strcmp(cmd, "/listevilles", true))
    {
        new str[512];
        str[0] = EOS;
        for(new i = 0; i < MAX_CITY; i++)
        {
            new line[40];
            format(line, sizeof(line), "%d - %s\n", i, GetCityName(i));
            strcat(str, line, sizeof(str));
        }
        SendClientMessage(playerid, COLOR_YELLOW, "== Villes disponibles (id - nom) ==");
        ShowPlayerDialog(playerid, DIALOG_VILLE + 1000, DIALOG_STYLE_MSGBOX, "Liste des villes", str, "OK", "");
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
        if(PlayerInfo[playerid][pCarteBancaire])
        {
            format(str, sizeof(str), "Banque : $%d", PlayerInfo[playerid][pBank]);
        }
        else
        {
            format(str, sizeof(str), "Banque : carte bancaire non recuperee (rendez-vous a la banque)");
        }
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
        if(gPlayerOccupied[playerid])
        {
            SendClientMessage(playerid, COLOR_YELLOW, "Vous etes deja occupe.");
            return 1;
        }
        if(PlayerInfo[playerid][pFaim] >= 100)
        {
            SendClientMessage(playerid, COLOR_YELLOW, "Vous n'avez pas faim.");
            return 1;
        }
        if(!IsPlayerNearShop(playerid))
        {
            SendClientMessage(playerid, COLOR_RED, "Vous devez etre pres d'une epicerie pour manger (voir la carte).");
            return 1;
        }
        if(GetPlayerState(playerid) != PLAYER_STATE_ONFOOT)
        {
            SendClientMessage(playerid, COLOR_RED, "Vous devez etre a pied pour manger.");
            return 1;
        }
        if(GetTickCount() - gLastManger[playerid] < MANGER_COOLDOWN)
        {
            new resteSec = (MANGER_COOLDOWN - (GetTickCount() - gLastManger[playerid])) / 1000;
            new str[80];
            format(str, sizeof(str), "Vous n'avez pas encore assez faim pour remanger (%d sec).", resteSec);
            SendClientMessage(playerid, COLOR_YELLOW, str);
            return 1;
        }
        new const PRIX_REPAS = 50;
        if(GetPlayerMoney(playerid) < PRIX_REPAS)
        {
            SendClientMessage(playerid, COLOR_RED, "Vous n'avez pas assez d'argent pour manger ($50).");
            return 1;
        }
        GivePlayerMoney(playerid, -PRIX_REPAS);
        gLastManger[playerid] = GetTickCount();
        gPlayerOccupied[playerid] = true;
        ApplyAnimation(playerid, "FOOD", "EAT_BURGER", 4.1, true, false, false, false, 0, true);
        TogglePlayerControllable(playerid, 0);
        SendClientMessage(playerid, COLOR_GREEN, "Vous achetez de quoi manger et prenez le temps de vous restaurer...");
        SetTimerEx("FinishEatingTimer", DUREE_ANIM_MANGER * 1000, false, "d", playerid);
        return 1;
    }

    if(!strcmp(cmd, "/boire", true))
    {
        if(gPlayerOccupied[playerid])
        {
            SendClientMessage(playerid, COLOR_YELLOW, "Vous etes deja occupe.");
            return 1;
        }
        if(PlayerInfo[playerid][pSoif] >= 100)
        {
            SendClientMessage(playerid, COLOR_YELLOW, "Vous n'avez pas soif.");
            return 1;
        }
        if(!IsPlayerNearShop(playerid))
        {
            SendClientMessage(playerid, COLOR_RED, "Vous devez etre pres d'une epicerie pour boire (voir la carte).");
            return 1;
        }
        if(GetPlayerState(playerid) != PLAYER_STATE_ONFOOT)
        {
            SendClientMessage(playerid, COLOR_RED, "Vous devez etre a pied pour boire.");
            return 1;
        }
        if(GetTickCount() - gLastBoire[playerid] < BOIRE_COOLDOWN)
        {
            new resteSec = (BOIRE_COOLDOWN - (GetTickCount() - gLastBoire[playerid])) / 1000;
            new str[80];
            format(str, sizeof(str), "Vous n'avez pas encore assez soif pour reboire (%d sec).", resteSec);
            SendClientMessage(playerid, COLOR_YELLOW, str);
            return 1;
        }
        new const PRIX_BOISSON = 25;
        if(GetPlayerMoney(playerid) < PRIX_BOISSON)
        {
            SendClientMessage(playerid, COLOR_RED, "Vous n'avez pas assez d'argent pour boire ($25).");
            return 1;
        }
        GivePlayerMoney(playerid, -PRIX_BOISSON);
        gLastBoire[playerid] = GetTickCount();
        gPlayerOccupied[playerid] = true;
        ApplyAnimation(playerid, "FOOD", "EAT_Drink_Beer", 4.1, true, false, false, false, 0, true);
        TogglePlayerControllable(playerid, 0);
        SendClientMessage(playerid, COLOR_GREEN, "Vous achetez a boire et prenez le temps de vous desalterer...");
        SetTimerEx("FinishDrinkingTimer", DUREE_ANIM_BOIRE * 1000, false, "d", playerid);
        return 1;
    }

    if(!strcmp(cmd, "/dormir", true))
    {
        if(gPlayerOccupied[playerid])
        {
            SendClientMessage(playerid, COLOR_YELLOW, "Vous etes deja occupe.");
            return 1;
        }
        if(PlayerInfo[playerid][pFatigue] <= 0)
        {
            SendClientMessage(playerid, COLOR_YELLOW, "Vous n'etes pas fatigue.");
            return 1;
        }
        if(GetPlayerState(playerid) != PLAYER_STATE_ONFOOT)
        {
            SendClientMessage(playerid, COLOR_RED, "Vous devez etre a pied, dans un endroit sur, pour dormir.");
            return 1;
        }
        if(GetTickCount() - gLastDormir[playerid] < DORMIR_COOLDOWN)
        {
            new resteMin = (DORMIR_COOLDOWN - (GetTickCount() - gLastDormir[playerid])) / 60000 + 1;
            new str[80];
            format(str, sizeof(str), "Vous ne pouvez pas redormir tout de suite (encore ~%d min).", resteMin);
            SendClientMessage(playerid, COLOR_YELLOW, str);
            return 1;
        }
        gLastDormir[playerid] = GetTickCount();
        gPlayerOccupied[playerid] = true;
        ApplyAnimation(playerid, "CRIB", "CRIB_Sleep_LOOP", 4.1, true, false, false, false, 0, true);
        TogglePlayerControllable(playerid, 0);
        SendClientMessage(playerid, COLOR_GREEN, "Vous vous installez et fermez les yeux...");
        SetTimerEx("FinishSleepingTimer", DUREE_ANIM_DORMIR * 1000, false, "d", playerid);
        return 1;
    }

    if(!strcmp(cmd, "/cash", true))
    {
        new str[64];
        format(str, sizeof(str), "Vous possedez $%d", GetPlayerMoney(playerid));
        SendClientMessage(playerid, COLOR_GREEN, str);
        return 1;
    }

    if(!strcmp(cmd, "/banque", true))
    {
        if(!IsPlayerNearBank(playerid))
        {
            SendClientMessage(playerid, COLOR_RED, "Vous devez vous rendre a la banque pour utiliser cette commande.");
            return 1;
        }
        ShowBanqueMenu(playerid);
        return 1;
    }

    if(!strcmp(cmd, "/solde", true))
    {
        if(!PlayerInfo[playerid][pCarteBancaire])
        {
            SendClientMessage(playerid, COLOR_RED, "Vous devez d'abord recuperer votre carte bancaire a la banque.");
            return 1;
        }
        new str[64];
        format(str, sizeof(str), "Solde de votre compte bancaire : $%d", PlayerInfo[playerid][pBank]);
        SendClientMessage(playerid, COLOR_GREEN, str);
        return 1;
    }

    if(!strcmp(cmd, "/poste", true) || !strcmp(cmd, "/monposte", true))
    {
        new faction = PlayerInfo[playerid][pFaction];
        new str[128], gname[32];
        if(faction == FACTION_NONE)
        {
            SendClientMessage(playerid, COLOR_YELLOW, "Vous n'occupez actuellement aucun poste (Civil).");
            return 1;
        }
        GetGradeName(faction, PlayerInfo[playerid][pGrade], gname, 32);
        format(str, sizeof(str), "Poste actuel : %s - %s", gFactionName[faction], gname);
        SendClientMessage(playerid, COLOR_YELLOW, str);
        return 1;
    }

    if(!strcmp(cmd, "/travail", true))
    {
        SendClientMessage(playerid, COLOR_YELLOW, "== Factions et Jobs disponibles ==");
        SendClientMessage(playerid, COLOR_WHITE, "Faction Service Public : Police, FBI, Administration Penitentiaire, Pompiers, Medecins, Gouvernement, Justice (Juges)");
        SendClientMessage(playerid, COLOR_WHITE, "Faction Service Prive : Barreau (Avocats), Securite Privee, Presse, Mecanique, Armes");
        return 1;
    }

    if(!strcmp(cmd, "/listepostes", true))
    {
        if(PlayerInfo[playerid][pAdmin] <= 0)
        {
            SendClientMessage(playerid, COLOR_RED, "Cette commande est reservee aux administrateurs.");
            return 1;
        }
        SendClientMessage(playerid, COLOR_YELLOW, "== Factions disponibles (ID a utiliser avec /setfaction) ==");
        for(new f = 0; f < MAX_FACTIONS; f++)
        {
            new str[96];
            format(str, sizeof(str), "%d - %s", f, gFactionName[f]);
            SendClientMessage(playerid, COLOR_WHITE, str);
        }
        SendClientMessage(playerid, COLOR_YELLOW, "Grades : de 1 (le plus bas) a 5 (le plus haut), 0 = aucun/civil.");
        return 1;
    }

    if(!strcmp(cmd, "/setfaction", true))
    {
        if(PlayerInfo[playerid][pAdmin] < 3)
        {
            SendClientMessage(playerid, COLOR_RED, "Cette commande est reservee aux administrateurs (niveau 3+).");
            return 1;
        }
        tmp = strtok_(cmdtext, idx);
        new tmp2[64] = "";
        tmp2 = strtok_(cmdtext, idx);
        new tmp3[64] = "";
        tmp3 = strtok_(cmdtext, idx);
        if(!strlen(tmp) || !strlen(tmp2) || !strlen(tmp3))
        {
            SendClientMessage(playerid, COLOR_RED, "Utilisation : /setfaction [id joueur] [id faction] [grade 0-5]");
            SendClientMessage(playerid, COLOR_YELLOW, "Tapez /listepostes pour voir les ID de faction.");
            return 1;
        }
        new targetid = strval(tmp);
        new faction = strval(tmp2);
        new grade = strval(tmp3);
        if(!IsPlayerConnected(targetid) || !IsLoggedIn[targetid])
        {
            SendClientMessage(playerid, COLOR_RED, "Joueur introuvable ou non connecte.");
            return 1;
        }
        if(faction < 0 || faction >= MAX_FACTIONS)
        {
            SendClientMessage(playerid, COLOR_RED, "ID de faction invalide. Tapez /listepostes.");
            return 1;
        }
        if(grade < 0 || grade > 5)
        {
            SendClientMessage(playerid, COLOR_RED, "Grade invalide (0 a 5).");
            return 1;
        }
        PlayerInfo[targetid][pFaction] = faction;
        PlayerInfo[targetid][pGrade] = grade;

        new str[128], gname[32], tname[MAX_PLAYER_NAME];
        GetGradeName(faction, grade, gname, 32);
        GetPlayerName(targetid, tname, sizeof(tname));
        format(str, sizeof(str), "Vous occupez desormais le poste : %s - %s", gFactionName[faction], gname);
        SendClientMessage(targetid, COLOR_GREEN, str);
        format(str, sizeof(str), "%s a ete affecte au poste : %s - %s", tname, gFactionName[faction], gname);
        SendClientMessage(playerid, COLOR_GREEN, str);
        return 1;
    }

    if(!strcmp(cmd, "/soins", true) || !strcmp(cmd, "/therapie", true))
    {
        new isTherapie = !strcmp(cmd, "/therapie", true);
        if(PlayerInfo[playerid][pFaction] != FACTION_MEDECIN)
        {
            SendClientMessage(playerid, COLOR_RED, "Seul un medecin peut utiliser cette commande.");
            return 1;
        }
        tmp = strtok_(cmdtext, idx);
        if(!strlen(tmp))
        {
            SendClientMessage(playerid, COLOR_RED, isTherapie ? "Utilisation : /therapie [id joueur]" : "Utilisation : /soins [id joueur]");
            return 1;
        }
        new targetid = strval(tmp);
        if(!IsPlayerConnected(targetid) || !IsLoggedIn[targetid])
        {
            SendClientMessage(playerid, COLOR_RED, "Joueur introuvable ou non connecte.");
            return 1;
        }
        new Float:mx, Float:my, Float:mz;
        GetPlayerPos(playerid, mx, my, mz);
        if(!IsPlayerInRangeOfPoint(targetid, 4.0, mx, my, mz))
        {
            SendClientMessage(playerid, COLOR_RED, "Ce joueur n'est pas assez proche de vous.");
            return 1;
        }
        if(!PlayerInfo[targetid][pCarteBancaire] || PlayerInfo[targetid][pBank] < PRIX_SOINS_MEDECIN)
        {
            SendClientMessage(playerid, COLOR_RED, "Le patient n'a pas les fonds necessaires sur son compte bancaire.");
            return 1;
        }

        GivePlayerBankMoney(targetid, -PRIX_SOINS_MEDECIN);
        GivePlayerBankMoney(playerid, PRIX_SOINS_MEDECIN);

        new str[128];
        if(isTherapie)
        {
            PlayerInfo[targetid][pStress] = ClampNeed(PlayerInfo[targetid][pStress] - 40);
            PlayerInfo[targetid][pMoral] = ClampNeed(PlayerInfo[targetid][pMoral] + 40);
            SendClientMessage(targetid, COLOR_GREEN, "Vous avez suivi une seance de therapie. Votre stress diminue et votre moral remonte.");
        }
        else
        {
            SetPlayerHealth(targetid, 100.0);
            SendClientMessage(targetid, COLOR_GREEN, "Vous avez ete soigne par un medecin.");
        }
        format(str, sizeof(str), "-$%d preleves sur votre compte bancaire pour les soins.", PRIX_SOINS_MEDECIN);
        SendClientMessage(targetid, COLOR_YELLOW, str);
        format(str, sizeof(str), "Vous recevez $%d sur votre compte bancaire pour ces soins.", PRIX_SOINS_MEDECIN);
        SendClientMessage(playerid, COLOR_GREEN, str);
        return 1;
    }

    if(!strcmp(cmd, "/honoraires", true))
    {
        if(PlayerInfo[playerid][pFaction] != FACTION_AVOCAT)
        {
            SendClientMessage(playerid, COLOR_RED, "Seul un avocat peut utiliser cette commande.");
            return 1;
        }
        tmp = strtok_(cmdtext, idx);
        new tmp2[64] = "";
        tmp2 = strtok_(cmdtext, idx);
        if(!strlen(tmp) || !strlen(tmp2))
        {
            SendClientMessage(playerid, COLOR_RED, "Utilisation : /honoraires [id client] [montant]");
            return 1;
        }
        new targetid = strval(tmp);
        new montant = strval(tmp2);
        if(!IsPlayerConnected(targetid) || !IsLoggedIn[targetid])
        {
            SendClientMessage(playerid, COLOR_RED, "Client introuvable ou non connecte.");
            return 1;
        }
        if(montant <= 0)
        {
            SendClientMessage(playerid, COLOR_RED, "Montant invalide.");
            return 1;
        }
        if(!PlayerInfo[targetid][pCarteBancaire] || PlayerInfo[targetid][pBank] < montant)
        {
            SendClientMessage(playerid, COLOR_RED, "Le client n'a pas les fonds necessaires sur son compte bancaire.");
            return 1;
        }

        new partAvocat = (montant * 80) / 100;
        new partEtat = montant - partAvocat;
        GivePlayerBankMoney(targetid, -montant);
        GivePlayerBankMoney(playerid, partAvocat);
        gEtatTresor += partEtat;

        new str[128];
        format(str, sizeof(str), "-$%d preleves sur votre compte pour vos honoraires d'avocat.", montant);
        SendClientMessage(targetid, COLOR_YELLOW, str);
        format(str, sizeof(str), "Honoraires percus : $%d (80%%) - $%d reverses a l'Etat (20%%).", partAvocat, partEtat);
        SendClientMessage(playerid, COLOR_GREEN, str);
        return 1;
    }

    if(!strcmp(cmd, "/reparer", true))
    {
        if(PlayerInfo[playerid][pFaction] != FACTION_MECANO)
        {
            SendClientMessage(playerid, COLOR_RED, "Seul un mecanicien peut utiliser cette commande.");
            return 1;
        }
        tmp = strtok_(cmdtext, idx);
        new tmp2[64] = "";
        tmp2 = strtok_(cmdtext, idx);
        if(!strlen(tmp) || !strlen(tmp2))
        {
            SendClientMessage(playerid, COLOR_RED, "Utilisation : /reparer [id client] [montant]");
            return 1;
        }
        new targetid = strval(tmp);
        new montant = strval(tmp2);
        if(!IsPlayerConnected(targetid) || !IsLoggedIn[targetid])
        {
            SendClientMessage(playerid, COLOR_RED, "Client introuvable ou non connecte.");
            return 1;
        }
        if(montant <= 0)
        {
            SendClientMessage(playerid, COLOR_RED, "Montant invalide.");
            return 1;
        }
        new Float:mx2, Float:my2, Float:mz2;
        GetPlayerPos(playerid, mx2, my2, mz2);
        if(!IsPlayerInRangeOfPoint(targetid, 6.0, mx2, my2, mz2))
        {
            SendClientMessage(playerid, COLOR_RED, "Ce client n'est pas assez proche de vous.");
            return 1;
        }
        if(!PlayerInfo[targetid][pCarteBancaire] || PlayerInfo[targetid][pBank] < montant)
        {
            SendClientMessage(playerid, COLOR_RED, "Le client n'a pas les fonds necessaires sur son compte bancaire.");
            return 1;
        }

        GivePlayerBankMoney(targetid, -montant);
        GivePlayerBankMoney(playerid, montant);

        if(IsPlayerInAnyVehicle(targetid))
        {
            new veh = GetPlayerVehicleID(targetid);
            RepairVehicle(veh);
        }

        new str[96];
        format(str, sizeof(str), "-$%d preleves sur votre compte pour la reparation.", montant);
        SendClientMessage(targetid, COLOR_YELLOW, str);
        format(str, sizeof(str), "Reparation payee : $%d verses sur votre compte.", montant);
        SendClientMessage(playerid, COLOR_GREEN, str);
        return 1;
    }

    if(!strcmp(cmd, "/publier", true))
    {
        if(PlayerInfo[playerid][pFaction] != FACTION_JOURNALISTE)
        {
            SendClientMessage(playerid, COLOR_RED, "Seul un journaliste peut utiliser cette commande.");
            return 1;
        }
        tmp = strtok_(cmdtext, idx);
        if(!strlen(tmp))
        {
            SendClientMessage(playerid, COLOR_RED, "Utilisation : /publier [texte de l'article/annonce]");
            return 1;
        }
        new name[MAX_PLAYER_NAME], str[300];
        GetPlayerName(playerid, name, sizeof(name));
        format(str, sizeof(str), "[PRESSE] %s : %s", name, tmp);
        SendClientMessageToAll(COLOR_YELLOW, str);

        GivePlayerBankMoney(playerid, BONUS_ARTICLE);
        format(str, sizeof(str), "Article/annonce publie ! Bonus recu : $%d sur votre compte bancaire.", BONUS_ARTICLE);
        SendClientMessage(playerid, COLOR_GREEN, str);
        return 1;
    }

    if(!strcmp(cmd, "/surveiller", true))
    {
        if(PlayerInfo[playerid][pFaction] != FACTION_PENITENCIER)
        {
            SendClientMessage(playerid, COLOR_RED, "Seul un membre de l'administration penitentiaire peut utiliser cette commande.");
            return 1;
        }
        tmp = strtok_(cmdtext, idx);
        if(!strlen(tmp))
        {
            SendClientMessage(playerid, COLOR_RED, "Utilisation : /surveiller [id detenu]");
            return 1;
        }
        new targetid = strval(tmp);
        if(!IsPlayerConnected(targetid) || !IsLoggedIn[targetid])
        {
            SendClientMessage(playerid, COLOR_RED, "Joueur introuvable ou non connecte.");
            return 1;
        }
        if((gettime() - gLastPrimePenitencier[playerid]) < PRIME_COOLDOWN)
        {
            SendClientMessage(playerid, COLOR_RED, "Vous devez attendre avant de toucher une nouvelle prime de surveillance.");
            return 1;
        }
        gLastPrimePenitencier[playerid] = gettime();
        GivePlayerBankMoney(playerid, PRIME_DETENU_SURVEILLE);

        new str[96];
        format(str, sizeof(str), "Prime de surveillance de detenu : +$%d sur votre compte bancaire.", PRIME_DETENU_SURVEILLE);
        SendClientMessage(playerid, COLOR_GREEN, str);
        return 1;
    }

    if(!strcmp(cmd, "/extinction", true))
    {
        if(PlayerInfo[playerid][pFaction] != FACTION_POMPIER)
        {
            SendClientMessage(playerid, COLOR_RED, "Seul un pompier peut utiliser cette commande.");
            return 1;
        }
        if((gettime() - gLastPrimePompier[playerid]) < PRIME_COOLDOWN)
        {
            SendClientMessage(playerid, COLOR_RED, "Vous devez attendre avant de toucher une nouvelle prime d'extinction.");
            return 1;
        }
        gLastPrimePompier[playerid] = gettime();
        GivePlayerBankMoney(playerid, PRIME_INCENDIE_ETEINT);

        new str[96];
        format(str, sizeof(str), "Prime d'incendie eteint : +$%d sur votre compte bancaire.", PRIME_INCENDIE_ETEINT);
        SendClientMessage(playerid, COLOR_GREEN, str);
        return 1;
    }

    if(!strcmp(cmd, "/engager", true))
    {
        tmp = strtok_(cmdtext, idx);
        new tmp2[64] = "";
        tmp2 = strtok_(cmdtext, idx);
        if(!strlen(tmp) || !strlen(tmp2))
        {
            SendClientMessage(playerid, COLOR_RED, "Utilisation : /engager [id garde du corps] [tarif par minute]");
            return 1;
        }
        new targetid = strval(tmp);
        new tarif = strval(tmp2);
        if(!IsPlayerConnected(targetid) || !IsLoggedIn[targetid])
        {
            SendClientMessage(playerid, COLOR_RED, "Joueur introuvable ou non connecte.");
            return 1;
        }
        if(PlayerInfo[targetid][pFaction] != FACTION_GARDE)
        {
            SendClientMessage(playerid, COLOR_RED, "Ce joueur n'est pas garde du corps.");
            return 1;
        }
        if(tarif <= 0)
        {
            SendClientMessage(playerid, COLOR_RED, "Tarif invalide.");
            return 1;
        }
        if(gGardeClient[targetid] != -1)
        {
            SendClientMessage(playerid, COLOR_RED, "Ce garde du corps est deja engage par quelqu'un d'autre.");
            return 1;
        }
        gGardeClient[targetid] = playerid;
        gGardeRate[targetid] = tarif;

        new str[128], name[MAX_PLAYER_NAME];
        GetPlayerName(playerid, name, sizeof(name));
        format(str, sizeof(str), "Vous avez engage votre garde du corps pour $%d/minute (preleve sur votre compte).", tarif);
        SendClientMessage(playerid, COLOR_GREEN, str);
        format(str, sizeof(str), "%s vous a engage comme garde du corps pour $%d/minute.", name, tarif);
        SendClientMessage(targetid, COLOR_GREEN, str);
        return 1;
    }

    if(!strcmp(cmd, "/renvoyer", true))
    {
        tmp = strtok_(cmdtext, idx);
        if(!strlen(tmp))
        {
            SendClientMessage(playerid, COLOR_RED, "Utilisation : /renvoyer [id garde du corps]");
            return 1;
        }
        new targetid = strval(tmp);
        if(!IsPlayerConnected(targetid) || !IsLoggedIn[targetid] || gGardeClient[targetid] != playerid)
        {
            SendClientMessage(playerid, COLOR_RED, "Vous n'avez pas de contrat en cours avec ce garde du corps.");
            return 1;
        }
        gGardeClient[targetid] = -1;
        SendClientMessage(playerid, COLOR_YELLOW, "Vous avez mis fin au contrat de votre garde du corps.");
        SendClientMessage(targetid, COLOR_YELLOW, "Votre client a mis fin au contrat.");
        return 1;
    }

    if(!strcmp(cmd, "/demission", true))
    {
        if(PlayerInfo[playerid][pFaction] != FACTION_GARDE || gGardeClient[playerid] == -1)
        {
            SendClientMessage(playerid, COLOR_RED, "Vous n'avez aucun contrat en cours.");
            return 1;
        }
        new clientid = gGardeClient[playerid];
        gGardeClient[playerid] = -1;
        SendClientMessage(playerid, COLOR_YELLOW, "Vous avez mis fin a votre contrat en cours.");
        if(IsPlayerConnected(clientid))
        {
            SendClientMessage(clientid, COLOR_YELLOW, "Votre garde du corps a mis fin au contrat.");
        }
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
    if(!strcmp(cmd, "/mapos", true)) { canon = "MYPOS"; level = ADMIN_LEVEL_DEV; return 1; }
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
        TeardownPlayerVoice(targetid); // coupe aussi le chat vocal SAMPVOICE
        SendClientMessage(targetid, COLOR_RED, "Vous avez ete reduit au silence.");
        SendClientMessage(playerid, COLOR_GREEN, "Joueur muet.");
    }
    else if(!strcmp(canon, "UNMUTE"))
    {
        tmp = strtok_(cmdtext, idx);
        targetid = strval(tmp);
        if(!strlen(tmp) || !IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_RED, "Utilisation : /demuet [id]");
        gMuted[targetid] = 0;
        SetupPlayerVoice(targetid); // redonne le chat vocal SAMPVOICE
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
        JailPlayerAtPD(targetid, 1 + random(3)); // repartit le detenu sur l'une des 3 cellules
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
    else if(!strcmp(canon, "MYPOS"))
    {
        new Float:x, Float:y, Float:z, Float:a, str[144];
        GetPlayerPos(playerid, x, y, z);
        GetPlayerFacingAngle(playerid, a);
        format(str, sizeof(str), "Pos: %f, %f, %f, %f | Interieur: %d | Monde: %d", x, y, z, a, GetPlayerInterior(playerid), GetPlayerVirtualWorld(playerid));
        SendClientMessage(playerid, COLOR_GREEN, str);
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
        SendClientMessage(playerid, COLOR_WHITE, "[Admin] /bannir, /debannir, /apparence, /armes, /dieu, /setfaction, /listepostes");
    if(lvl >= ADMIN_LEVEL_ADMIN)
        SendClientMessage(playerid, COLOR_WHITE, "[Admin] /savepos [id], /listevilles - Configurer les spawns du systeme multi-villes");
    if(lvl >= ADMIN_LEVEL_SUPERIOR)
        SendClientMessage(playerid, COLOR_WHITE, "[Admin Sup.] /argent, /donnerargent, /vip, /niveau");
    if(lvl >= ADMIN_LEVEL_SUPERVISOR)
        SendClientMessage(playerid, COLOR_WHITE, "[Superviseur] /definiradmin, /annonce");
    if(lvl >= ADMIN_LEVEL_DEV)
    {
        SendClientMessage(playerid, COLOR_ADMIN, "[Developpeur] /heure, /meteo, /donnerarme, /allercoord, /mapos, /redemarrer, /cmdrcon (acces complet RCON), /devcarte");
        SendClientMessage(playerid, COLOR_ADMIN, "[Developpeur] /creermaison, /creergarage [prix] [capacite], /creercommerce, /creerbatiment [nom], /interieur [maison/garage/commerce/batiment] [id], /exterieur [maison/garage/commerce/batiment] [id], /suppmaison, /suppgarage, /suppcommerce, /suppbatiment, /garagecapacite [id] [1-3], /objetid [modelid]");
    }
    return 1;
}

// ==============================================================
//  Systeme de Chat Vocal (SAMPVOICE) - fonctions utilitaires
// ==============================================================

// Cree le stream local dynamique de proximite d'un joueur (voix entendue
// par les joueurs proches, distance = VOICE_RADIUS) et lui assigne la
// touche PTT (activee/desactivee via OnPlayerActivationKeyPress/Release).
// Appelee a la connexion, et lors du /demuet pour redonner la voix.
stock SetupPlayerVoice(playerid)
{
    gVoiceStream[playerid] = SV_DLSTREAM:SV_NULL;
    gVoiceReady[playerid] = false;

    if(SvGetVersion(playerid) == 0)
    {
        // Plugin SAMPVOICE non detecte chez ce joueur : chat vocal indisponible pour lui.
        return 0;
    }
    if(SvHasMicro(playerid) == SV_FALSE)
    {
        SendClientMessage(playerid, COLOR_WHITE, "(( Chat vocal : aucun microphone detecte. ))");
        return 0;
    }

    gVoiceStream[playerid] = SvCreateDLStreamAtPlayer(VOICE_RADIUS, VOICE_MAX_LISTENERS, playerid, 0xFFFFFFFF, "Local");
    if(gVoiceStream[playerid] != SV_DLSTREAM:SV_NULL)
    {
        SvAddKey(playerid, VOICE_PTT_KEY);
        gVoiceReady[playerid] = true;

        if(!gMuted[playerid])
        {
            SendClientMessage(playerid, COLOR_GREEN, "(( Chat vocal active : maintenez CAPS LOCK pour parler aux joueurs proches. ))");
        }
    }
    return 1;
}

// Detruit proprement le stream vocal d'un joueur (deconnexion ou mise en muet).
stock TeardownPlayerVoice(playerid)
{
    if(gVoiceStream[playerid] != SV_DLSTREAM:SV_NULL)
    {
        SvDeleteStream(gVoiceStream[playerid]);
        gVoiceStream[playerid] = SV_DLSTREAM:SV_NULL;
    }
    gVoiceReady[playerid] = false;
    return 1;
}

// Appele par le plugin quand un joueur appuie sur une touche qui lui a ete
// assignee via SvAddKey. On y attache le joueur comme "speaker" de son
// propre stream local le temps que la touche PTT reste enfoncee.
public SV_VOID:OnPlayerActivationKeyPress(SV_UINT:playerid, SV_UINT:keyid)
{
    if(keyid == VOICE_PTT_KEY && gVoiceReady[playerid] && !gMuted[playerid] && gVoiceStream[playerid] != SV_DLSTREAM:SV_NULL)
    {
        SvAttachSpeakerToStream(gVoiceStream[playerid], playerid);
    }
    return;
}

// Appele quand la touche PTT est relachee : on detache le joueur en tant
// que speaker pour qu'il arrete d'emettre.
public SV_VOID:OnPlayerActivationKeyRelease(SV_UINT:playerid, SV_UINT:keyid)
{
    if(keyid == VOICE_PTT_KEY && gVoiceStream[playerid] != SV_DLSTREAM:SV_NULL)
    {
        SvDetachSpeakerFromStream(gVoiceStream[playerid], playerid);
    }
    return;
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
