/*==============================================================
    CALIFORNIE RP - Systeme de Proprietes
    Maisons / Garages / Commerces / Meubles-Objets
    Persistance : MySQL (plugin BlueG a_mysql, R41+)

    Ce fichier est concu pour etre inclus depuis californierp.pwn :
        #include <a_mysql>
        #include "proprietes.inc"

    Integration minimale a faire dans californierp.pwn (voir le
    fichier LISEZMOI_PROPRIETES.md) :
        - Prop_Init()               dans OnGameModeInit
        - Prop_Exit()                dans OnGameModeExit
        - Prop_OnCommand(...)        au debut de OnPlayerCommandText
        - Prop_OnDialogResponse(...) au debut de OnDialogResponse
        - Prop_OnKeyStateChange(...) dans OnPlayerKeyStateChange (touche F,
          entree/sortie des proprietes)
        - OnObjectEdit : nouveau callback natif, deja entierement
          defini dans ce fichier.
==============================================================*/

#tryinclude <a_mysql>
#if !defined mysql_included
    #error "Le plugin MySQL (a_mysql.inc, BlueG R41+) est requis par proprietes.inc"
#endif

// ------------------------------------------------------------
//  Connexion MySQL - a adapter a votre serveur
// ------------------------------------------------------------
#if !defined MYSQL_HOST
    #define MYSQL_HOST   "127.0.0.1"
#endif
#if !defined MYSQL_USER
    #define MYSQL_USER   "root"
#endif
#if !defined MYSQL_PASS
    #define MYSQL_PASS   ""
#endif
#if !defined MYSQL_DB
    #define MYSQL_DB     "californierp"
#endif

new MySQL:gSQL;

// ------------------------------------------------------------
//  Constantes generales
// ------------------------------------------------------------
#define MAX_HOUSES              500
#define MAX_GARAGES              300
#define MAX_BUSINESSES            200
#define MAX_FURNITURE            4000
#define MAX_FURNITURE_PER_HOUSE   40
#define MAX_GARAGE_SLOTS           3   // nombre max d'emplacements vehicule par garage

#define HOUSE_WORLD_BASE    10000   // virtual world d'une maison = BASE + id
#define GARAGE_WORLD_BASE   20000
#define BUSINESS_WORLD_BASE 30000

#define PICKUP_HOUSE_MODEL     1273
#define PICKUP_GARAGE_MODEL    1273
#define PICKUP_BUSINESS_MODEL  1272
#define PICKUP_EXIT_MODEL      1318

#define PROP_TYPE_NONE      0
#define PROP_TYPE_HOUSE     1
#define PROP_TYPE_GARAGE    2
#define PROP_TYPE_BUSINESS  3

// Dialog IDs reserves a ce systeme : 9100-9199 (libre dans le gamemode existant)
#define DIALOG_PROP_HOUSES_LIST       9100
#define DIALOG_PROP_GARAGES_LIST      9101
#define DIALOG_PROP_BUSINESS_LIST     9102
#define DIALOG_PROP_FURNITURE_CATALOG 9103
#define DIALOG_PROP_FURNITURE_REMOVE  9104
#define DIALOG_PROP_CAISSE            9105
#define DIALOG_PROP_CAISSE_DEPOT      9106
#define DIALOG_PROP_CAISSE_RETRAIT    9107
#define DIALOG_PROP_CREATE_HOUSE_NOM  9108
#define DIALOG_PROP_CREATE_BIZ_NOM    9109
#define DIALOG_PROP_GARAGE_SORTIR     9110

// ==============================================================
//  Structures de donnees (chargees en RAM depuis MySQL au demarrage)
// ==============================================================
enum e_house
{
    bool:hExists,
    hOwner[MAX_PLAYER_NAME],     // "" = inhabitee
    Float:hEntX, Float:hEntY, Float:hEntZ, Float:hEntA,
    hInteriorID,                  // ID d'interieur SA-MP (SetPlayerInterior)
    Float:hIntX, Float:hIntY, Float:hIntZ, Float:hIntA,
    hPrice,
    bool:hLocked,
    hFurnitureCount,
    houseOutPickup,
    houseInPickup,
    Text3D:houseOutLabel,
    Text3D:houseInLabel
}
new gHouse[MAX_HOUSES][e_house];
new gHouseCount = 0;

enum e_garage
{
    bool:gaExists,
    gaOwner[MAX_PLAYER_NAME],
    Float:gaEntX, Float:gaEntY, Float:gaEntZ, Float:gaEntA,
    gaInteriorID,
    Float:gaIntX, Float:gaIntY, Float:gaIntZ, Float:gaIntA,
    gaPrice,
    gaCapacity,                                       // nombre d'emplacements actifs (1 a MAX_GARAGE_SLOTS)
    gaStoredModel[MAX_GARAGE_SLOTS],                   // 0 = emplacement vide
    gaStoredColor1[MAX_GARAGE_SLOTS], gaStoredColor2[MAX_GARAGE_SLOTS],
    garageOutPickup,
    garageInPickup,
    Text3D:garageOutLabel,
    Text3D:garageInLabel
}
new gGarage[MAX_GARAGES][e_garage];
new gGarageCount = 0;

enum e_biz
{
    bool:bzExists,
    bzOwner[MAX_PLAYER_NAME],
    bzName[32],
    Float:bzEntX, Float:bzEntY, Float:bzEntZ, Float:bzEntA,
    bzInteriorID,
    Float:bzIntX, Float:bzIntY, Float:bzIntZ, Float:bzIntA,
    bzPrice,
    bzTill,                        // caisse du commerce
    bizOutPickup,
    bizInPickup,
    Text3D:bizOutLabel,
    Text3D:bizInLabel
}
new gBiz[MAX_BUSINESSES][e_biz];
new gBizCount = 0;

enum e_furniture
{
    bool:fExists,
    fHouseID,
    fModel,
    Float:fX, Float:fY, Float:fZ,
    Float:fRX, Float:fRY, Float:fRZ,
    fObjectID                      // handle de l'objet global cree en jeu (-1 si non spawn)
}
new gFurniture[MAX_FURNITURE][e_furniture];
new gFurnitureCount = 0;

// Etat temporaire par joueur (creation / edition en cours)
new gPropEditType[MAX_PLAYERS];    // PROP_TYPE_* : type d'objet en cours d'edition via EditObject
new gPropEditIndex[MAX_PLAYERS];   // index dans gFurniture, ou -1 si c'est une preview dev
new gDevPreviewObject[MAX_PLAYERS] = {-1, ...};
new gCreatePendingPrice[MAX_PLAYERS]; // prix en attente de saisie du nom (creation maison/commerce)

// Catalogue de meubles/objets placables (nom affiche + ID de modele GTA SA).
// Liste de depart facilement extensible : ajouter une ligne suffit.
new const gFurnitureCatalog[][2][32] = {
    {"Chaise en bois",        "1721"},
    {"Chaise de bureau",      "1712"},
    {"Table basse",           "1710"},
    {"Table a manger",        "1811"},
    {"Canape",                "2100"},
    {"Televiseur",            "2717"},
    {"Lit simple",            "1712"},
    {"Lit double",            "1774"},
    {"Frigo",                 "2422"},
    {"Cuisiniere",            "2423"},
    {"Evier",                 "2400"},
    {"Etagere",               "1687"},
    {"Armoire",               "2116"},
    {"Lampe de bureau",       "2214"},
    {"Lampadaire",            "1691"},
    {"Plante en pot",         "1685"},
    {"Miroir",                "2233"},
    {"Tapis",                 "19832"},
    {"Bibliotheque",          "2206"},
    {"Bureau",                "1751"}
};
#define FURNITURE_CATALOG_COUNT (sizeof(gFurnitureCatalog))

forward Prop_OnHousesLoaded(dummyid);
forward Prop_OnGaragesLoaded(dummyid);
forward Prop_OnBusinessesLoaded(dummyid);
forward Prop_OnFurnitureLoaded(dummyid);

// ==============================================================
//  Initialisation / arret
// ==============================================================
stock Prop_Init()
{
    gSQL = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_PASS, MYSQL_DB);
    if(mysql_errno(gSQL) != 0)
    {
        print("[PROPRIETES] ERREUR : connexion MySQL echouee. Verifiez MYSQL_HOST/USER/PASS/DB.");
        return 0;
    }
    print("[PROPRIETES] Connexion MySQL etablie.");

    // Creation automatique des tables si elles n'existent pas encore
    mysql_tquery(gSQL,
        "CREATE TABLE IF NOT EXISTS `houses` (\
        `id` INT AUTO_INCREMENT PRIMARY KEY,\
        `owner` VARCHAR(24) NOT NULL DEFAULT '',\
        `ent_x` FLOAT NOT NULL, `ent_y` FLOAT NOT NULL, `ent_z` FLOAT NOT NULL, `ent_a` FLOAT NOT NULL DEFAULT 0,\
        `interior_id` INT NOT NULL DEFAULT 0,\
        `int_x` FLOAT NOT NULL DEFAULT 0, `int_y` FLOAT NOT NULL DEFAULT 0, `int_z` FLOAT NOT NULL DEFAULT 0, `int_a` FLOAT NOT NULL DEFAULT 0,\
        `price` INT NOT NULL DEFAULT 0,\
        `locked` TINYINT NOT NULL DEFAULT 1)");

    mysql_tquery(gSQL,
        "CREATE TABLE IF NOT EXISTS `garages` (\
        `id` INT AUTO_INCREMENT PRIMARY KEY,\
        `owner` VARCHAR(24) NOT NULL DEFAULT '',\
        `ent_x` FLOAT NOT NULL, `ent_y` FLOAT NOT NULL, `ent_z` FLOAT NOT NULL, `ent_a` FLOAT NOT NULL DEFAULT 0,\
        `interior_id` INT NOT NULL DEFAULT 0,\
        `int_x` FLOAT NOT NULL DEFAULT 0, `int_y` FLOAT NOT NULL DEFAULT 0, `int_z` FLOAT NOT NULL DEFAULT 0, `int_a` FLOAT NOT NULL DEFAULT 0,\
        `price` INT NOT NULL DEFAULT 0,\
        `capacity` INT NOT NULL DEFAULT 3,\
        `slot1_model` INT NOT NULL DEFAULT 0, `slot1_color1` INT NOT NULL DEFAULT -1, `slot1_color2` INT NOT NULL DEFAULT -1,\
        `slot2_model` INT NOT NULL DEFAULT 0, `slot2_color1` INT NOT NULL DEFAULT -1, `slot2_color2` INT NOT NULL DEFAULT -1,\
        `slot3_model` INT NOT NULL DEFAULT 0, `slot3_color1` INT NOT NULL DEFAULT -1, `slot3_color2` INT NOT NULL DEFAULT -1)");

    mysql_tquery(gSQL,
        "CREATE TABLE IF NOT EXISTS `businesses` (\
        `id` INT AUTO_INCREMENT PRIMARY KEY,\
        `owner` VARCHAR(24) NOT NULL DEFAULT '',\
        `name` VARCHAR(32) NOT NULL DEFAULT 'Commerce',\
        `ent_x` FLOAT NOT NULL, `ent_y` FLOAT NOT NULL, `ent_z` FLOAT NOT NULL, `ent_a` FLOAT NOT NULL DEFAULT 0,\
        `interior_id` INT NOT NULL DEFAULT 0,\
        `int_x` FLOAT NOT NULL DEFAULT 0, `int_y` FLOAT NOT NULL DEFAULT 0, `int_z` FLOAT NOT NULL DEFAULT 0, `int_a` FLOAT NOT NULL DEFAULT 0,\
        `price` INT NOT NULL DEFAULT 0,\
        `till` INT NOT NULL DEFAULT 0)");

    mysql_tquery(gSQL,
        "CREATE TABLE IF NOT EXISTS `furniture` (\
        `id` INT AUTO_INCREMENT PRIMARY KEY,\
        `house_id` INT NOT NULL,\
        `model` INT NOT NULL,\
        `x` FLOAT NOT NULL, `y` FLOAT NOT NULL, `z` FLOAT NOT NULL,\
        `rx` FLOAT NOT NULL DEFAULT 0, `ry` FLOAT NOT NULL DEFAULT 0, `rz` FLOAT NOT NULL DEFAULT 0)");

    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        gPropEditType[i] = PROP_TYPE_NONE;
        gPropEditIndex[i] = -1;
        gDevPreviewObject[i] = -1;
    }

    // Chargement des donnees (asynchrone : les pickups apparaissent des que la reponse arrive)
    mysql_tquery(gSQL, "SELECT * FROM `houses`", "Prop_OnHousesLoaded", "i", 0);
    mysql_tquery(gSQL, "SELECT * FROM `garages`", "Prop_OnGaragesLoaded", "i", 0);
    mysql_tquery(gSQL, "SELECT * FROM `businesses`", "Prop_OnBusinessesLoaded", "i", 0);
    mysql_tquery(gSQL, "SELECT * FROM `furniture`", "Prop_OnFurnitureLoaded", "i", 0);
    return 1;
}

stock Prop_Exit()
{
    mysql_close(gSQL);
    return 1;
}

// ------------------------------------------------------------
//  Callbacks de chargement initial
// ------------------------------------------------------------
public Prop_OnHousesLoaded(dummyid)
{
    new rows = cache_num_rows();
    new tmp[32];
    for(new i = 0; i < rows; i++)
    {
        cache_get_value_name(i, "id", tmp);
        new id = strval(tmp);
        if(id < 0 || id >= MAX_HOUSES) continue; // au-dela de MAX_HOUSES, augmentez la constante

        gHouse[id][hExists] = true;
        cache_get_value_name(i, "owner", gHouse[id][hOwner], MAX_PLAYER_NAME);
        cache_get_value_name_float(i, "ent_x", gHouse[id][hEntX]);
        cache_get_value_name_float(i, "ent_y", gHouse[id][hEntY]);
        cache_get_value_name_float(i, "ent_z", gHouse[id][hEntZ]);
        cache_get_value_name_float(i, "ent_a", gHouse[id][hEntA]);
        cache_get_value_name(i, "interior_id", tmp); gHouse[id][hInteriorID] = strval(tmp);
        cache_get_value_name_float(i, "int_x", gHouse[id][hIntX]);
        cache_get_value_name_float(i, "int_y", gHouse[id][hIntY]);
        cache_get_value_name_float(i, "int_z", gHouse[id][hIntZ]);
        cache_get_value_name_float(i, "int_a", gHouse[id][hIntA]);
        cache_get_value_name(i, "price", tmp); gHouse[id][hPrice] = strval(tmp);
        cache_get_value_name(i, "locked", tmp); gHouse[id][hLocked] = bool:strval(tmp);
        gHouse[id][hFurnitureCount] = 0;
        Prop_CreateHousePickups(id);
        if(id + 1 > gHouseCount) gHouseCount = id + 1;
    }
    printf("[PROPRIETES] %d maison(s) chargee(s).", rows);
    return 1;
}

public Prop_OnGaragesLoaded(dummyid)
{
    new rows = cache_num_rows();
    new tmp[32];
    for(new i = 0; i < rows; i++)
    {
        cache_get_value_name(i, "id", tmp);
        new id = strval(tmp);
        if(id < 0 || id >= MAX_GARAGES) continue;

        gGarage[id][gaExists] = true;
        cache_get_value_name(i, "owner", gGarage[id][gaOwner], MAX_PLAYER_NAME);
        cache_get_value_name_float(i, "ent_x", gGarage[id][gaEntX]);
        cache_get_value_name_float(i, "ent_y", gGarage[id][gaEntY]);
        cache_get_value_name_float(i, "ent_z", gGarage[id][gaEntZ]);
        cache_get_value_name_float(i, "ent_a", gGarage[id][gaEntA]);
        cache_get_value_name(i, "interior_id", tmp); gGarage[id][gaInteriorID] = strval(tmp);
        cache_get_value_name_float(i, "int_x", gGarage[id][gaIntX]);
        cache_get_value_name_float(i, "int_y", gGarage[id][gaIntY]);
        cache_get_value_name_float(i, "int_z", gGarage[id][gaIntZ]);
        cache_get_value_name_float(i, "int_a", gGarage[id][gaIntA]);
        cache_get_value_name(i, "price", tmp); gGarage[id][gaPrice] = strval(tmp);
        cache_get_value_name(i, "capacity", tmp); gGarage[id][gaCapacity] = strval(tmp);
        if(gGarage[id][gaCapacity] < 1) gGarage[id][gaCapacity] = 1;
        if(gGarage[id][gaCapacity] > MAX_GARAGE_SLOTS) gGarage[id][gaCapacity] = MAX_GARAGE_SLOTS;
        cache_get_value_name(i, "slot1_model", tmp); gGarage[id][gaStoredModel][0] = strval(tmp);
        cache_get_value_name(i, "slot1_color1", tmp); gGarage[id][gaStoredColor1][0] = strval(tmp);
        cache_get_value_name(i, "slot1_color2", tmp); gGarage[id][gaStoredColor2][0] = strval(tmp);
        cache_get_value_name(i, "slot2_model", tmp); gGarage[id][gaStoredModel][1] = strval(tmp);
        cache_get_value_name(i, "slot2_color1", tmp); gGarage[id][gaStoredColor1][1] = strval(tmp);
        cache_get_value_name(i, "slot2_color2", tmp); gGarage[id][gaStoredColor2][1] = strval(tmp);
        cache_get_value_name(i, "slot3_model", tmp); gGarage[id][gaStoredModel][2] = strval(tmp);
        cache_get_value_name(i, "slot3_color1", tmp); gGarage[id][gaStoredColor1][2] = strval(tmp);
        cache_get_value_name(i, "slot3_color2", tmp); gGarage[id][gaStoredColor2][2] = strval(tmp);
        Prop_CreateGaragePickups(id);
        if(id + 1 > gGarageCount) gGarageCount = id + 1;
    }
    printf("[PROPRIETES] %d garage(s) charge(s).", rows);
    return 1;
}

public Prop_OnBusinessesLoaded(dummyid)
{
    new rows = cache_num_rows();
    new tmp[32];
    for(new i = 0; i < rows; i++)
    {
        cache_get_value_name(i, "id", tmp);
        new id = strval(tmp);
        if(id < 0 || id >= MAX_BUSINESSES) continue;

        gBiz[id][bzExists] = true;
        cache_get_value_name(i, "owner", gBiz[id][bzOwner], MAX_PLAYER_NAME);
        cache_get_value_name(i, "name", gBiz[id][bzName], 32);
        cache_get_value_name_float(i, "ent_x", gBiz[id][bzEntX]);
        cache_get_value_name_float(i, "ent_y", gBiz[id][bzEntY]);
        cache_get_value_name_float(i, "ent_z", gBiz[id][bzEntZ]);
        cache_get_value_name_float(i, "ent_a", gBiz[id][bzEntA]);
        cache_get_value_name(i, "interior_id", tmp); gBiz[id][bzInteriorID] = strval(tmp);
        cache_get_value_name_float(i, "int_x", gBiz[id][bzIntX]);
        cache_get_value_name_float(i, "int_y", gBiz[id][bzIntY]);
        cache_get_value_name_float(i, "int_z", gBiz[id][bzIntZ]);
        cache_get_value_name_float(i, "int_a", gBiz[id][bzIntA]);
        cache_get_value_name(i, "price", tmp); gBiz[id][bzPrice] = strval(tmp);
        cache_get_value_name(i, "till", tmp); gBiz[id][bzTill] = strval(tmp);
        Prop_CreateBizPickups(id);
        if(id + 1 > gBizCount) gBizCount = id + 1;
    }
    printf("[PROPRIETES] %d commerce(s) charge(s).", rows);
    return 1;
}

public Prop_OnFurnitureLoaded(dummyid)
{
    new rows = cache_num_rows();
    new tmp[32];
    for(new i = 0; i < rows; i++)
    {
        cache_get_value_name(i, "id", tmp);
        new id = strval(tmp);
        if(id < 0 || id >= MAX_FURNITURE) continue;

        gFurniture[id][fExists] = true;
        cache_get_value_name(i, "house_id", tmp); gFurniture[id][fHouseID] = strval(tmp);
        cache_get_value_name(i, "model", tmp); gFurniture[id][fModel] = strval(tmp);
        cache_get_value_name_float(i, "x", gFurniture[id][fX]);
        cache_get_value_name_float(i, "y", gFurniture[id][fY]);
        cache_get_value_name_float(i, "z", gFurniture[id][fZ]);
        cache_get_value_name_float(i, "rx", gFurniture[id][fRX]);
        cache_get_value_name_float(i, "ry", gFurniture[id][fRY]);
        cache_get_value_name_float(i, "rz", gFurniture[id][fRZ]);
        gFurniture[id][fObjectID] = -1;

        new hid = gFurniture[id][fHouseID];
        if(hid >= 0 && hid < MAX_HOUSES && gHouse[hid][hExists])
        {
            gFurniture[id][fObjectID] = CreateObject(gFurniture[id][fModel],
                gFurniture[id][fX], gFurniture[id][fY], gFurniture[id][fZ],
                gFurniture[id][fRX], gFurniture[id][fRY], gFurniture[id][fRZ], 300.0);
            // NB: SA-MP natif n'a pas de "monde virtuel" pour les objets globaux
            // (contrairement aux joueurs/vehicules) : cet objet sera visible par
            // quiconque se trouve physiquement au meme endroit/interieur, meme
            // dans un autre monde virtuel. Voir la note en tete de fichier.
            gHouse[hid][hFurnitureCount]++;
        }
        gFurnitureCount++;
    }
    printf("[PROPRIETES] %d meuble(s) charge(s).", rows);
    return 1;
}

// ==============================================================
//  Creation des pickups / labels 3D (entree exterieure + sortie interieure)
// ==============================================================
stock Prop_CreateHousePickups(id)
{
    new str[96];
    gHouse[id][houseOutPickup] = CreatePickup(PICKUP_HOUSE_MODEL, 1, gHouse[id][hEntX], gHouse[id][hEntY], gHouse[id][hEntZ], -1);
    if(strlen(gHouse[id][hOwner]))
        format(str, sizeof(str), "{33CC33}MAISON #%d\n{FFFFFF}Proprietaire : %s\nAppuyez sur F pour entrer", id, gHouse[id][hOwner]);
    else
        format(str, sizeof(str), "{33CC33}MAISON #%d\n{FFFFFF}A vendre : $%d\n/acheter", id, gHouse[id][hPrice]);
    gHouse[id][houseOutLabel] = Create3DTextLabel(str, 0xFFFFFFFF, gHouse[id][hEntX], gHouse[id][hEntY], gHouse[id][hEntZ] + 0.7, 15.0, 0, 0);

    gHouse[id][houseInPickup] = CreatePickup(PICKUP_EXIT_MODEL, 1, gHouse[id][hIntX], gHouse[id][hIntY], gHouse[id][hIntZ], HOUSE_WORLD_BASE + id);
    gHouse[id][houseInLabel] = Create3DTextLabel("{3388FF}SORTIE\n{FFFFFF}Appuyez sur F pour sortir", 0xFFFFFFFF, gHouse[id][hIntX], gHouse[id][hIntY], gHouse[id][hIntZ] + 0.7, 15.0, HOUSE_WORLD_BASE + id, 0);
    return 1;
}

stock Prop_CreateGaragePickups(id)
{
    new str[96];
    gGarage[id][garageOutPickup] = CreatePickup(PICKUP_GARAGE_MODEL, 1, gGarage[id][gaEntX], gGarage[id][gaEntY], gGarage[id][gaEntZ], -1);
    if(strlen(gGarage[id][gaOwner]))
        format(str, sizeof(str), "{FF8000}GARAGE #%d\n{FFFFFF}Proprietaire : %s\nAppuyez sur F pour entrer", id, gGarage[id][gaOwner]);
    else
        format(str, sizeof(str), "{FF8000}GARAGE #%d\n{FFFFFF}A vendre : $%d\n/acheter", id, gGarage[id][gaPrice]);
    gGarage[id][garageOutLabel] = Create3DTextLabel(str, 0xFFFFFFFF, gGarage[id][gaEntX], gGarage[id][gaEntY], gGarage[id][gaEntZ] + 0.7, 15.0, 0, 0);

    gGarage[id][garageInPickup] = CreatePickup(PICKUP_EXIT_MODEL, 1, gGarage[id][gaIntX], gGarage[id][gaIntY], gGarage[id][gaIntZ], GARAGE_WORLD_BASE + id);
    gGarage[id][garageInLabel] = Create3DTextLabel("{3388FF}SORTIE\n{FFFFFF}Appuyez sur F pour sortir", 0xFFFFFFFF, gGarage[id][gaIntX], gGarage[id][gaIntY], gGarage[id][gaIntZ] + 0.7, 15.0, GARAGE_WORLD_BASE + id, 0);
    return 1;
}

stock Prop_CreateBizPickups(id)
{
    new str[96];
    gBiz[id][bizOutPickup] = CreatePickup(PICKUP_BUSINESS_MODEL, 1, gBiz[id][bzEntX], gBiz[id][bzEntY], gBiz[id][bzEntZ], -1);
    if(strlen(gBiz[id][bzOwner]))
        format(str, sizeof(str), "{00CCFF}%s\n{FFFFFF}Proprietaire : %s\nAppuyez sur F pour entrer", gBiz[id][bzName], gBiz[id][bzOwner]);
    else
        format(str, sizeof(str), "{00CCFF}%s\n{FFFFFF}A vendre : $%d\n/acheter", gBiz[id][bzName], gBiz[id][bzPrice]);
    gBiz[id][bizOutLabel] = Create3DTextLabel(str, 0xFFFFFFFF, gBiz[id][bzEntX], gBiz[id][bzEntY], gBiz[id][bzEntZ] + 0.7, 15.0, 0, 0);

    gBiz[id][bizInPickup] = CreatePickup(PICKUP_EXIT_MODEL, 1, gBiz[id][bzIntX], gBiz[id][bzIntY], gBiz[id][bzIntZ], BUSINESS_WORLD_BASE + id);
    gBiz[id][bizInLabel] = Create3DTextLabel("{3388FF}SORTIE\n{FFFFFF}Appuyez sur F pour sortir", 0xFFFFFFFF, gBiz[id][bzIntX], gBiz[id][bzIntY], gBiz[id][bzIntZ] + 0.7, 15.0, BUSINESS_WORLD_BASE + id, 0);
    return 1;
}

// Rafraichit le texte du panneau exterieur (apres achat/vente/renommage)
stock Prop_RefreshHouseLabel(id)
{
    new str[96];
    if(strlen(gHouse[id][hOwner]))
        format(str, sizeof(str), "{33CC33}MAISON #%d\n{FFFFFF}Proprietaire : %s\nAppuyez sur F pour entrer", id, gHouse[id][hOwner]);
    else
        format(str, sizeof(str), "{33CC33}MAISON #%d\n{FFFFFF}A vendre : $%d\n/acheter", id, gHouse[id][hPrice]);
    Update3DTextLabelText(gHouse[id][houseOutLabel], 0xFFFFFFFF, str);
    return 1;
}
stock Prop_RefreshGarageLabel(id)
{
    new str[96];
    if(strlen(gGarage[id][gaOwner]))
        format(str, sizeof(str), "{FF8000}GARAGE #%d\n{FFFFFF}Proprietaire : %s\nAppuyez sur F pour entrer", id, gGarage[id][gaOwner]);
    else
        format(str, sizeof(str), "{FF8000}GARAGE #%d\n{FFFFFF}A vendre : $%d\n/acheter", id, gGarage[id][gaPrice]);
    Update3DTextLabelText(gGarage[id][garageOutLabel], 0xFFFFFFFF, str);
    return 1;
}

// Fait apparaitre a l'entree du garage le vehicule stocke dans l'emplacement
// "slot" (0-based) et vide cet emplacement. N'effectue aucune verification
// de propriete/occupation : c'est a l'appelant de s'en assurer.
stock Prop_SpawnGarageVehicle(id, slot)
{
    new vehicleid = CreateVehicle(gGarage[id][gaStoredModel][slot], gGarage[id][gaEntX] + 3.0, gGarage[id][gaEntY], gGarage[id][gaEntZ], gGarage[id][gaEntA], gGarage[id][gaStoredColor1][slot], gGarage[id][gaStoredColor2][slot], -1, false);
    LinkVehicleToInterior(vehicleid, 0);
    SetVehicleVirtualWorld(vehicleid, 0);
    gGarage[id][gaStoredModel][slot] = 0;

    new q[100], col[16];
    format(col, sizeof(col), "slot%d", slot + 1);
    format(q, sizeof(q), "UPDATE `garages` SET %s_model=0 WHERE id=%d", col, id);
    mysql_tquery(gSQL, q);
    return vehicleid;
}

// SA-MP n'a pas de native "GetVehicleModelName" (seulement GetVehicleModel,
// qui renvoie l'ID) : cette table donne le nom pour chaque ID de 400 a 611.
new const gVehicleModelNames[212][22] = {
    "Landstalker","Bravura","Buffalo","Linerunner","Perennial","Sentinel","Dumper","Firetruck","Trashmaster","Stretch",
    "Manana","Infernus","Voodoo","Pony","Mule","Cheetah","Ambulance","Leviathan","Moonbeam","Esperanto",
    "Taxi","Washington","Bobcat","Mr Whoopee","BF Injection","Hunter","Premier","Enforcer","Securicar","Banshee",
    "Predator","Bus","Rhino","Barracks","Hotknife","Trailer","Previon","Coach","Cabbie","Stallion",
    "Rumpo","RC Bandit","Romero","Packer","Monster","Admiral","Squalo","Seasparrow","Pizzaboy","Tram",
    "Trailer","Turismo","Speeder","Reefer","Tropic","Flatbed","Yankee","Caddy","Solair","Berkley's RC Van",
    "Skimmer","PCJ-600","Faggio","Freeway","RC Baron","RC Raider","Glendale","Oceanic","Sanchez","Sparrow",
    "Patriot","Quad","Coastguard","Dinghy","Hermes","Sabre","Rustler","ZR-350","Walton","Regina",
    "Comet","BMX","Burrito","Camper","Marquis","Baggage","Dozer","Maverick","News Chopper","Rancher",
    "FBI Rancher","Virgo","Greenwood","Jetmax","Hotring Racer","Sandking","Blista Compact","Police Maverick","Boxville","Benson",
    "Mesa","RC Goblin","Hotring Racer A","Hotring Racer B","Bloodring Banger","Rancher","Super GT","Elegant","Journey","Bike",
    "Mountain Bike","Beagle","Cropduster","Stunt Plane","Tanker","Roadtrain","Nebula","Majestic","Buccaneer","Shamal",
    "Hydra","FCR-900","NRG-500","HPV1000","Cement Truck","Tow Truck","Fortune","Cadrona","FBI Truck","Willard",
    "Forklift","Tractor","Combine","Feltzer","Remington","Slamvan","Blade","Freight","Streak","Vortex",
    "Vincent","Bullet","Clover","Sadler","Firetruck LA","Hustler","Intruder","Primo","Cargobob","Tampa",
    "Sunrise","Merit","Utility","Nevada","Yosemite","Windsor","Monster A","Monster B","Uranus","Jester",
    "Sultan","Stratum","Elegy","Raindance","RC Tiger","Flash","Tahoma","Savanna","Bandito","Freight Flat",
    "Streak Carriage","Kart","Mower","Duneride","Sweeper","Broadway","Tornado","AT-400","DFT-30","Huntley",
    "Stafford","BF-400","Newsvan","Tug","Trailer","Emperor","Wayfarer","Euros","Hotdog","Club",
    "Trailer","Trailer","Andromada","Dodo","RC Cam","Launch","Police LS","Police SF","Police LV","Police Ranger",
    "Picador","S.W.A.T.","Alpha","Phoenix","Glendale","Sadler","Luggage Trailer A","Luggage Trailer B","Stair Trailer","Boxville",
    "Farm Plow","Utility Trailer"
};

stock Prop_GetVehicleModelName(modelid, name[], len)
{
    if(modelid < 400 || modelid > 611)
    {
        format(name, len, "%s", "Vehicule inconnu");
        return 0;
    }
    format(name, len, "%s", gVehicleModelNames[modelid - 400]);
    return 1;
}

stock Prop_RefreshBizLabel(id)
{
    new str[96];
    if(strlen(gBiz[id][bzOwner]))
        format(str, sizeof(str), "{00CCFF}%s\n{FFFFFF}Proprietaire : %s\nAppuyez sur F pour entrer", gBiz[id][bzName], gBiz[id][bzOwner]);
    else
        format(str, sizeof(str), "{00CCFF}%s\n{FFFFFF}A vendre : $%d\n/acheter", gBiz[id][bzName], gBiz[id][bzPrice]);
    Update3DTextLabelText(gBiz[id][bizOutLabel], 0xFFFFFFFF, str);
    return 1;
}

// ==============================================================
//  Recherche de proximite (pas de streamer : verification par distance)
// ==============================================================
#define PROP_ENTER_RADIUS 4.0

stock Prop_FindNearHouse(playerid, &type, &id)
{
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);
    for(new i = 0; i < MAX_HOUSES; i++)
    {
        if(!gHouse[i][hExists]) continue;
        if(IsPlayerInRangeOfPoint(playerid, PROP_ENTER_RADIUS, gHouse[i][hEntX], gHouse[i][hEntY], gHouse[i][hEntZ]) && GetPlayerVirtualWorld(playerid) == 0 && GetPlayerInterior(playerid) == 0)
        { type = PROP_TYPE_HOUSE; id = i; return 1; }
    }
    for(new i = 0; i < MAX_GARAGES; i++)
    {
        if(!gGarage[i][gaExists]) continue;
        if(IsPlayerInRangeOfPoint(playerid, PROP_ENTER_RADIUS, gGarage[i][gaEntX], gGarage[i][gaEntY], gGarage[i][gaEntZ]) && GetPlayerVirtualWorld(playerid) == 0 && GetPlayerInterior(playerid) == 0)
        { type = PROP_TYPE_GARAGE; id = i; return 1; }
    }
    for(new i = 0; i < MAX_BUSINESSES; i++)
    {
        if(!gBiz[i][bzExists]) continue;
        if(IsPlayerInRangeOfPoint(playerid, PROP_ENTER_RADIUS, gBiz[i][bzEntX], gBiz[i][bzEntY], gBiz[i][bzEntZ]) && GetPlayerVirtualWorld(playerid) == 0 && GetPlayerInterior(playerid) == 0)
        { type = PROP_TYPE_BUSINESS; id = i; return 1; }
    }
    type = PROP_TYPE_NONE; id = -1;
    return 0;
}

// ==============================================================
//  Commandes joueur / dev - appelee depuis OnPlayerCommandText
//  Retourne 1 si la commande a ete geree (le dispatcher principal
//  doit alors s'arreter), 0 sinon.
// ==============================================================
stock Prop_OnCommand(playerid, cmd[], cmdtext[], idx)
{
    // ---------- DEV : creation / edition des interieurs ----------
    if(!strcmp(cmd, "/creermaison", true))
    {
        if(PlayerInfo[playerid][pAdmin] < ADMIN_LEVEL_DEV) return Prop_NoPerm(playerid);
        new tmp[64] = "0";
        tmp = strtok_(cmdtext, idx);
        new price = strlen(tmp) ? strval(tmp) : 50000;

        if(gHouseCount >= MAX_HOUSES) { SendClientMessage(playerid, COLOR_RED, "Nombre maximum de maisons atteint."); return 1; }

        new id = gHouseCount;
        new Float:x, Float:y, Float:z, Float:a;
        GetPlayerPos(playerid, x, y, z);
        GetPlayerFacingAngle(playerid, a);

        gHouse[id][hExists] = true;
        gHouse[id][hOwner][0] = EOS;
        gHouse[id][hEntX] = x; gHouse[id][hEntY] = y; gHouse[id][hEntZ] = z; gHouse[id][hEntA] = a;
        gHouse[id][hInteriorID] = 0;
        gHouse[id][hIntX] = x; gHouse[id][hIntY] = y; gHouse[id][hIntZ] = z; gHouse[id][hIntA] = a;
        gHouse[id][hPrice] = price;
        gHouse[id][hLocked] = true;
        gHouse[id][hFurnitureCount] = 0;
        Prop_CreateHousePickups(id);
        gHouseCount++;

        new q[400];
        mysql_format(gSQL, q, sizeof(q),
            "INSERT INTO `houses` (id, owner, ent_x, ent_y, ent_z, ent_a, interior_id, int_x, int_y, int_z, int_a, price, locked) VALUES (%d, '', %f, %f, %f, %f, 0, %f, %f, %f, %f, %d, 1)",
            id, x, y, z, a, x, y, z, a, price);
        mysql_tquery(gSQL, q);

        new str[128];
        format(str, sizeof(str), "Maison #%d creee ici (prix $%d). Utilisez /interieur maison %d une fois a l'interieur souhaite pour le lier.", id, price, id);
        SendClientMessage(playerid, COLOR_ADMIN, str);
        return 1;
    }

    if(!strcmp(cmd, "/creergarage", true))
    {
        if(PlayerInfo[playerid][pAdmin] < ADMIN_LEVEL_DEV) return Prop_NoPerm(playerid);
        new tmp[64], tmp2[64];
        tmp = strtok_(cmdtext, idx);
        new price = strlen(tmp) ? strval(tmp) : 15000;
        tmp2 = strtok_(cmdtext, idx);
        new capacity = strlen(tmp2) ? strval(tmp2) : MAX_GARAGE_SLOTS;
        if(capacity < 1) capacity = 1;
        if(capacity > MAX_GARAGE_SLOTS) capacity = MAX_GARAGE_SLOTS;

        if(gGarageCount >= MAX_GARAGES) { SendClientMessage(playerid, COLOR_RED, "Nombre maximum de garages atteint."); return 1; }

        new id = gGarageCount;
        new Float:x, Float:y, Float:z, Float:a;
        GetPlayerPos(playerid, x, y, z);
        GetPlayerFacingAngle(playerid, a);

        gGarage[id][gaExists] = true;
        gGarage[id][gaOwner][0] = EOS;
        gGarage[id][gaEntX] = x; gGarage[id][gaEntY] = y; gGarage[id][gaEntZ] = z; gGarage[id][gaEntA] = a;
        gGarage[id][gaInteriorID] = 0;
        gGarage[id][gaIntX] = x; gGarage[id][gaIntY] = y; gGarage[id][gaIntZ] = z; gGarage[id][gaIntA] = a;
        gGarage[id][gaPrice] = price;
        gGarage[id][gaCapacity] = capacity;
        for(new s = 0; s < MAX_GARAGE_SLOTS; s++)
        {
            gGarage[id][gaStoredModel][s] = 0;
            gGarage[id][gaStoredColor1][s] = -1;
            gGarage[id][gaStoredColor2][s] = -1;
        }
        Prop_CreateGaragePickups(id);
        gGarageCount++;

        new q[400];
        mysql_format(gSQL, q, sizeof(q),
            "INSERT INTO `garages` (id, owner, ent_x, ent_y, ent_z, ent_a, interior_id, int_x, int_y, int_z, int_a, price, capacity) VALUES (%d, '', %f, %f, %f, %f, 0, %f, %f, %f, %f, %d, %d)",
            id, x, y, z, a, x, y, z, a, price, capacity);
        mysql_tquery(gSQL, q);

        new str[150];
        format(str, sizeof(str), "Garage #%d cree ici (prix $%d, %d emplacement(s)). Utilisez /interieur garage %d une fois a l'emplacement de parking voulu.", id, price, capacity, id);
        SendClientMessage(playerid, COLOR_ADMIN, str);
        return 1;
    }

    if(!strcmp(cmd, "/creercommerce", true))
    {
        if(PlayerInfo[playerid][pAdmin] < ADMIN_LEVEL_DEV) return Prop_NoPerm(playerid);
        new tmp[64], nom[32];
        tmp = strtok_(cmdtext, idx);
        new price = strlen(tmp) ? strval(tmp) : 30000;

        // Le reste de la ligne (apres le prix) sert de nom au commerce.
        while(idx < strlen(cmdtext) && cmdtext[idx] == ' ') idx++;
        if(idx < strlen(cmdtext))
            format(nom, sizeof(nom), "%s", cmdtext[idx]);
        else
            format(nom, sizeof(nom), "Commerce");

        if(gBizCount >= MAX_BUSINESSES) { SendClientMessage(playerid, COLOR_RED, "Nombre maximum de commerces atteint."); return 1; }

        new id = gBizCount;
        new Float:x, Float:y, Float:z, Float:a;
        GetPlayerPos(playerid, x, y, z);
        GetPlayerFacingAngle(playerid, a);

        gBiz[id][bzExists] = true;
        gBiz[id][bzOwner][0] = EOS;
        format(gBiz[id][bzName], 32, "%s", nom);
        gBiz[id][bzEntX] = x; gBiz[id][bzEntY] = y; gBiz[id][bzEntZ] = z; gBiz[id][bzEntA] = a;
        gBiz[id][bzInteriorID] = 0;
        gBiz[id][bzIntX] = x; gBiz[id][bzIntY] = y; gBiz[id][bzIntZ] = z; gBiz[id][bzIntA] = a;
        gBiz[id][bzPrice] = price;
        gBiz[id][bzTill] = 0;
        Prop_CreateBizPickups(id);
        gBizCount++;

        new q[500], esc[64];
        mysql_escape_string(nom, esc, sizeof(esc), gSQL);
        mysql_format(gSQL, q, sizeof(q),
            "INSERT INTO `businesses` (id, owner, name, ent_x, ent_y, ent_z, ent_a, interior_id, int_x, int_y, int_z, int_a, price, till) VALUES (%d, '', '%s', %f, %f, %f, %f, 0, %f, %f, %f, %f, %d, 0)",
            id, esc, x, y, z, a, x, y, z, a, price);
        mysql_tquery(gSQL, q);

        new str[160];
        format(str, sizeof(str), "Commerce #%d \"%s\" cree ici (prix $%d). Utilisez /interieur commerce %d a l'interieur voulu.", id, nom, price, id);
        SendClientMessage(playerid, COLOR_ADMIN, str);
        return 1;
    }

    // /interieur <maison|garage|commerce> <id>
    // Capture la position/interieur ACTUELS du developpeur comme point
    // d'arrivee interieur de la propriete indiquee. C'est la commande
    // reservee au dev pour lier chaque propriete a son ID d'interieur.
    if(!strcmp(cmd, "/interieur", true))
    {
        if(PlayerInfo[playerid][pAdmin] < ADMIN_LEVEL_DEV) return Prop_NoPerm(playerid);

        new typeStr[64], idStr[64];
        typeStr = strtok_(cmdtext, idx);
        idStr = strtok_(cmdtext, idx);

        if(!strlen(typeStr) || !strlen(idStr))
        {
            SendClientMessage(playerid, COLOR_WHITE, "Utilisation : /interieur [maison/garage/commerce] [id]");
            SendClientMessage(playerid, COLOR_WHITE, "Placez-vous d'abord a l'interieur voulu (interieur SA-MP + position), puis lancez la commande.");
            return 1;
        }
        new id = strval(idStr);
        new Float:x, Float:y, Float:z, Float:a;
        GetPlayerPos(playerid, x, y, z);
        GetPlayerFacingAngle(playerid, a);
        new interiorid = GetPlayerInterior(playerid);

        if(!strcmp(typeStr, "maison", true))
        {
            if(id < 0 || id >= MAX_HOUSES || !gHouse[id][hExists]) { SendClientMessage(playerid, COLOR_RED, "Maison introuvable."); return 1; }

            // Detruit l'ancien pickup/label de sortie et l'ensemble des meubles
            // deja affiches (ils seront recrees dans le nouveau monde/interieur).
            DestroyPickup(gHouse[id][houseInPickup]);
            Delete3DTextLabel(gHouse[id][houseInLabel]);

            gHouse[id][hInteriorID] = interiorid;
            gHouse[id][hIntX] = x; gHouse[id][hIntY] = y; gHouse[id][hIntZ] = z; gHouse[id][hIntA] = a;

            gHouse[id][houseInPickup] = CreatePickup(PICKUP_EXIT_MODEL, 1, x, y, z, HOUSE_WORLD_BASE + id);
            gHouse[id][houseInLabel] = Create3DTextLabel("{3388FF}SORTIE\n{FFFFFF}Appuyez sur F pour sortir", 0xFFFFFFFF, x, y, z + 0.7, 15.0, HOUSE_WORLD_BASE + id, 0);

            new q[300];
            mysql_format(gSQL, q, sizeof(q), "UPDATE `houses` SET interior_id=%d, int_x=%f, int_y=%f, int_z=%f, int_a=%f WHERE id=%d", interiorid, x, y, z, a, id);
            mysql_tquery(gSQL, q);

            SendClientMessage(playerid, COLOR_GREEN, "Interieur de la maison mis a jour a votre position actuelle.");
            return 1;
        }
        else if(!strcmp(typeStr, "garage", true))
        {
            if(id < 0 || id >= MAX_GARAGES || !gGarage[id][gaExists]) { SendClientMessage(playerid, COLOR_RED, "Garage introuvable."); return 1; }

            DestroyPickup(gGarage[id][garageInPickup]);
            Delete3DTextLabel(gGarage[id][garageInLabel]);

            gGarage[id][gaInteriorID] = interiorid;
            gGarage[id][gaIntX] = x; gGarage[id][gaIntY] = y; gGarage[id][gaIntZ] = z; gGarage[id][gaIntA] = a;

            gGarage[id][garageInPickup] = CreatePickup(PICKUP_EXIT_MODEL, 1, x, y, z, GARAGE_WORLD_BASE + id);
            gGarage[id][garageInLabel] = Create3DTextLabel("{3388FF}SORTIE\n{FFFFFF}Appuyez sur F pour sortir", 0xFFFFFFFF, x, y, z + 0.7, 15.0, GARAGE_WORLD_BASE + id, 0);

            new q[300];
            mysql_format(gSQL, q, sizeof(q), "UPDATE `garages` SET interior_id=%d, int_x=%f, int_y=%f, int_z=%f, int_a=%f WHERE id=%d", interiorid, x, y, z, a, id);
            mysql_tquery(gSQL, q);

            SendClientMessage(playerid, COLOR_GREEN, "Interieur du garage mis a jour a votre position actuelle.");
            return 1;
        }
        else if(!strcmp(typeStr, "commerce", true))
        {
            if(id < 0 || id >= MAX_BUSINESSES || !gBiz[id][bzExists]) { SendClientMessage(playerid, COLOR_RED, "Commerce introuvable."); return 1; }

            DestroyPickup(gBiz[id][bizInPickup]);
            Delete3DTextLabel(gBiz[id][bizInLabel]);

            gBiz[id][bzInteriorID] = interiorid;
            gBiz[id][bzIntX] = x; gBiz[id][bzIntY] = y; gBiz[id][bzIntZ] = z; gBiz[id][bzIntA] = a;

            gBiz[id][bizInPickup] = CreatePickup(PICKUP_EXIT_MODEL, 1, x, y, z, BUSINESS_WORLD_BASE + id);
            gBiz[id][bizInLabel] = Create3DTextLabel("{3388FF}SORTIE\n{FFFFFF}Appuyez sur F pour sortir", 0xFFFFFFFF, x, y, z + 0.7, 15.0, BUSINESS_WORLD_BASE + id, 0);

            new q[300];
            mysql_format(gSQL, q, sizeof(q), "UPDATE `businesses` SET interior_id=%d, int_x=%f, int_y=%f, int_z=%f, int_a=%f WHERE id=%d", interiorid, x, y, z, a, id);
            mysql_tquery(gSQL, q);

            SendClientMessage(playerid, COLOR_GREEN, "Interieur du commerce mis a jour a votre position actuelle.");
            return 1;
        }
        SendClientMessage(playerid, COLOR_RED, "Type invalide. Utilisez : maison, garage ou commerce.");
        return 1;
    }

    if(!strcmp(cmd, "/exterieur", true))
    {
        if(PlayerInfo[playerid][pAdmin] < ADMIN_LEVEL_DEV) return Prop_NoPerm(playerid);

        new typeStr[64], idStr[64];
        typeStr = strtok_(cmdtext, idx);
        idStr = strtok_(cmdtext, idx);

        if(!strlen(typeStr) || !strlen(idStr))
        {
            SendClientMessage(playerid, COLOR_WHITE, "Utilisation : /exterieur [maison/garage/commerce] [id]");
            SendClientMessage(playerid, COLOR_WHITE, "Placez-vous d'abord a l'endroit exterieur voulu, puis lancez la commande.");
            return 1;
        }
        new id = strval(idStr);
        new Float:x, Float:y, Float:z, Float:a;
        GetPlayerPos(playerid, x, y, z);
        GetPlayerFacingAngle(playerid, a);

        if(!strcmp(typeStr, "maison", true))
        {
            if(id < 0 || id >= MAX_HOUSES || !gHouse[id][hExists]) { SendClientMessage(playerid, COLOR_RED, "Maison introuvable."); return 1; }

            DestroyPickup(gHouse[id][houseOutPickup]);
            Delete3DTextLabel(gHouse[id][houseOutLabel]);

            gHouse[id][hEntX] = x; gHouse[id][hEntY] = y; gHouse[id][hEntZ] = z; gHouse[id][hEntA] = a;

            new str[96];
            gHouse[id][houseOutPickup] = CreatePickup(PICKUP_HOUSE_MODEL, 1, x, y, z, -1);
            if(strlen(gHouse[id][hOwner]))
                format(str, sizeof(str), "{33CC33}MAISON #%d\n{FFFFFF}Proprietaire : %s\nAppuyez sur F pour entrer", id, gHouse[id][hOwner]);
            else
                format(str, sizeof(str), "{33CC33}MAISON #%d\n{FFFFFF}A vendre : $%d\n/acheter", id, gHouse[id][hPrice]);
            gHouse[id][houseOutLabel] = Create3DTextLabel(str, 0xFFFFFFFF, x, y, z + 0.7, 15.0, 0, 0);

            new q[300];
            mysql_format(gSQL, q, sizeof(q), "UPDATE `houses` SET ent_x=%f, ent_y=%f, ent_z=%f, ent_a=%f WHERE id=%d", x, y, z, a, id);
            mysql_tquery(gSQL, q);

            SendClientMessage(playerid, COLOR_GREEN, "Exterieur de la maison mis a jour a votre position actuelle.");
            return 1;
        }
        else if(!strcmp(typeStr, "garage", true))
        {
            if(id < 0 || id >= MAX_GARAGES || !gGarage[id][gaExists]) { SendClientMessage(playerid, COLOR_RED, "Garage introuvable."); return 1; }

            DestroyPickup(gGarage[id][garageOutPickup]);
            Delete3DTextLabel(gGarage[id][garageOutLabel]);

            gGarage[id][gaEntX] = x; gGarage[id][gaEntY] = y; gGarage[id][gaEntZ] = z; gGarage[id][gaEntA] = a;

            new str[96];
            gGarage[id][garageOutPickup] = CreatePickup(PICKUP_GARAGE_MODEL, 1, x, y, z, -1);
            if(strlen(gGarage[id][gaOwner]))
                format(str, sizeof(str), "{FF8000}GARAGE #%d\n{FFFFFF}Proprietaire : %s\nAppuyez sur F pour entrer", id, gGarage[id][gaOwner]);
            else
                format(str, sizeof(str), "{FF8000}GARAGE #%d\n{FFFFFF}A vendre : $%d\n/acheter", id, gGarage[id][gaPrice]);
            gGarage[id][garageOutLabel] = Create3DTextLabel(str, 0xFFFFFFFF, x, y, z + 0.7, 15.0, 0, 0);

            new q[300];
            mysql_format(gSQL, q, sizeof(q), "UPDATE `garages` SET ent_x=%f, ent_y=%f, ent_z=%f, ent_a=%f WHERE id=%d", x, y, z, a, id);
            mysql_tquery(gSQL, q);

            SendClientMessage(playerid, COLOR_GREEN, "Exterieur du garage mis a jour a votre position actuelle.");
            return 1;
        }
        else if(!strcmp(typeStr, "commerce", true))
        {
            if(id < 0 || id >= MAX_BUSINESSES || !gBiz[id][bzExists]) { SendClientMessage(playerid, COLOR_RED, "Commerce introuvable."); return 1; }

            DestroyPickup(gBiz[id][bizOutPickup]);
            Delete3DTextLabel(gBiz[id][bizOutLabel]);

            gBiz[id][bzEntX] = x; gBiz[id][bzEntY] = y; gBiz[id][bzEntZ] = z; gBiz[id][bzEntA] = a;

            new str[96];
            gBiz[id][bizOutPickup] = CreatePickup(PICKUP_BUSINESS_MODEL, 1, x, y, z, -1);
            if(strlen(gBiz[id][bzOwner]))
                format(str, sizeof(str), "{00CCFF}%s\n{FFFFFF}Proprietaire : %s\nAppuyez sur F pour entrer", gBiz[id][bzName], gBiz[id][bzOwner]);
            else
                format(str, sizeof(str), "{00CCFF}%s\n{FFFFFF}A vendre : $%d\n/acheter", gBiz[id][bzName], gBiz[id][bzPrice]);
            gBiz[id][bizOutLabel] = Create3DTextLabel(str, 0xFFFFFFFF, x, y, z + 0.7, 15.0, 0, 0);

            new q[300];
            mysql_format(gSQL, q, sizeof(q), "UPDATE `businesses` SET ent_x=%f, ent_y=%f, ent_z=%f, ent_a=%f WHERE id=%d", x, y, z, a, id);
            mysql_tquery(gSQL, q);

            SendClientMessage(playerid, COLOR_GREEN, "Exterieur du commerce mis a jour a votre position actuelle.");
            return 1;
        }
        SendClientMessage(playerid, COLOR_RED, "Type invalide. Utilisez : maison, garage ou commerce.");
        return 1;
    }

    if(!strcmp(cmd, "/suppmaison", true) || !strcmp(cmd, "/suppgarage", true) || !strcmp(cmd, "/suppcommerce", true))
    {
        if(PlayerInfo[playerid][pAdmin] < ADMIN_LEVEL_DEV) return Prop_NoPerm(playerid);
        new idStr[64];
        idStr = strtok_(cmdtext, idx);
        if(!strlen(idStr)) { SendClientMessage(playerid, COLOR_WHITE, "Utilisation : /suppmaison|suppgarage|suppcommerce [id]"); return 1; }
        new id = strval(idStr);

        if(!strcmp(cmd, "/suppmaison", true))
        {
            if(id < 0 || id >= MAX_HOUSES || !gHouse[id][hExists]) { SendClientMessage(playerid, COLOR_RED, "Maison introuvable."); return 1; }
            DestroyPickup(gHouse[id][houseOutPickup]); Delete3DTextLabel(gHouse[id][houseOutLabel]);
            DestroyPickup(gHouse[id][houseInPickup]); Delete3DTextLabel(gHouse[id][houseInLabel]);
            for(new i = 0; i < MAX_FURNITURE; i++)
                if(gFurniture[i][fExists] && gFurniture[i][fHouseID] == id)
                {
                    if(gFurniture[i][fObjectID] != -1) DestroyObject(gFurniture[i][fObjectID]);
                    gFurniture[i][fExists] = false;
                }
            gHouse[id][hExists] = false;
            new q[64]; format(q, sizeof(q), "DELETE FROM `houses` WHERE id=%d", id); mysql_tquery(gSQL, q);
            format(q, sizeof(q), "DELETE FROM `furniture` WHERE house_id=%d", id); mysql_tquery(gSQL, q);
            SendClientMessage(playerid, COLOR_ADMIN, "Maison supprimee.");
        }
        else if(!strcmp(cmd, "/suppgarage", true))
        {
            if(id < 0 || id >= MAX_GARAGES || !gGarage[id][gaExists]) { SendClientMessage(playerid, COLOR_RED, "Garage introuvable."); return 1; }
            DestroyPickup(gGarage[id][garageOutPickup]); Delete3DTextLabel(gGarage[id][garageOutLabel]);
            DestroyPickup(gGarage[id][garageInPickup]); Delete3DTextLabel(gGarage[id][garageInLabel]);
            gGarage[id][gaExists] = false;
            new q[64]; format(q, sizeof(q), "DELETE FROM `garages` WHERE id=%d", id); mysql_tquery(gSQL, q);
            SendClientMessage(playerid, COLOR_ADMIN, "Garage supprime.");
        }
        else
        {
            if(id < 0 || id >= MAX_BUSINESSES || !gBiz[id][bzExists]) { SendClientMessage(playerid, COLOR_RED, "Commerce introuvable."); return 1; }
            DestroyPickup(gBiz[id][bizOutPickup]); Delete3DTextLabel(gBiz[id][bizOutLabel]);
            DestroyPickup(gBiz[id][bizInPickup]); Delete3DTextLabel(gBiz[id][bizInLabel]);
            gBiz[id][bzExists] = false;
            new q[64]; format(q, sizeof(q), "DELETE FROM `businesses` WHERE id=%d", id); mysql_tquery(gSQL, q);
            SendClientMessage(playerid, COLOR_ADMIN, "Commerce supprime.");
        }
        return 1;
    }

    if(!strcmp(cmd, "/garagecapacite", true))
    {
        if(PlayerInfo[playerid][pAdmin] < ADMIN_LEVEL_DEV) return Prop_NoPerm(playerid);
        new idStr[64], capStr[64];
        idStr = strtok_(cmdtext, idx);
        capStr = strtok_(cmdtext, idx);
        if(!strlen(idStr) || !strlen(capStr))
        {
            SendClientMessage(playerid, COLOR_WHITE, "Utilisation : /garagecapacite [id] [1 a 3]");
            return 1;
        }
        new id = strval(idStr);
        new cap = strval(capStr);
        if(id < 0 || id >= MAX_GARAGES || !gGarage[id][gaExists]) { SendClientMessage(playerid, COLOR_RED, "Garage introuvable."); return 1; }
        if(cap < 1 || cap > MAX_GARAGE_SLOTS) { SendClientMessage(playerid, COLOR_RED, "Capacite invalide (1 a 3)."); return 1; }

        // Si on reduit la capacite, on refuse tant qu'un vehicule occupe un
        // emplacement qui serait supprime, pour eviter de perdre un vehicule.
        for(new s = cap; s < gGarage[id][gaCapacity]; s++)
        {
            if(gGarage[id][gaStoredModel][s] != 0)
            {
                SendClientMessage(playerid, COLOR_RED, "Impossible : un vehicule occupe un emplacement qui serait supprime. Videz-le d'abord (/sortir).");
                return 1;
            }
        }

        gGarage[id][gaCapacity] = cap;
        new q[100]; format(q, sizeof(q), "UPDATE `garages` SET capacity=%d WHERE id=%d", cap, id); mysql_tquery(gSQL, q);
        Prop_RefreshGarageLabel(id);
        new str[100];
        format(str, sizeof(str), "Garage #%d : capacite fixee a %d emplacement(s).", id, cap);
        SendClientMessage(playerid, COLOR_ADMIN, str);
        return 1;
    }

    // ---------- JOUEUR : achat / vente / verrouillage ----------
    if(!strcmp(cmd, "/maisons", true)) { Prop_ShowHousesList(playerid); return 1; }
    if(!strcmp(cmd, "/garages", true)) { Prop_ShowGaragesList(playerid); return 1; }
    if(!strcmp(cmd, "/commerces", true)) { Prop_ShowBusinessList(playerid); return 1; }

    if(!strcmp(cmd, "/acheter", true))
    {
        new type, id;
        if(!Prop_FindNearHouse(playerid, type, id)) { SendClientMessage(playerid, COLOR_RED, "Aucune propriete a vendre a proximite."); return 1; }

        new name[MAX_PLAYER_NAME];
        GetPlayerName(playerid, name, sizeof(name));

        if(type == PROP_TYPE_HOUSE)
        {
            if(strlen(gHouse[id][hOwner])) { SendClientMessage(playerid, COLOR_RED, "Cette maison a deja un proprietaire."); return 1; }
            if(GetPlayerMoney(playerid) < gHouse[id][hPrice]) { SendClientMessage(playerid, COLOR_RED, "Fonds insuffisants."); return 1; }
            GivePlayerMoney(playerid, -gHouse[id][hPrice]);
            format(gHouse[id][hOwner], MAX_PLAYER_NAME, "%s", name);
            gHouse[id][hLocked] = true;
            Prop_RefreshHouseLabel(id);
            new q[200], esc[MAX_PLAYER_NAME];
            mysql_escape_string(name, esc, sizeof(esc), gSQL);
            mysql_format(gSQL, q, sizeof(q), "UPDATE `houses` SET owner='%s', locked=1 WHERE id=%d", esc, id);
            mysql_tquery(gSQL, q);
            SendClientMessage(playerid, COLOR_GREEN, "Felicitations, vous etes desormais proprietaire de cette maison !");
        }
        else if(type == PROP_TYPE_GARAGE)
        {
            if(strlen(gGarage[id][gaOwner])) { SendClientMessage(playerid, COLOR_RED, "Ce garage a deja un proprietaire."); return 1; }
            if(GetPlayerMoney(playerid) < gGarage[id][gaPrice]) { SendClientMessage(playerid, COLOR_RED, "Fonds insuffisants."); return 1; }
            GivePlayerMoney(playerid, -gGarage[id][gaPrice]);
            format(gGarage[id][gaOwner], MAX_PLAYER_NAME, "%s", name);
            Prop_RefreshGarageLabel(id);
            new q[200], esc[MAX_PLAYER_NAME];
            mysql_escape_string(name, esc, sizeof(esc), gSQL);
            mysql_format(gSQL, q, sizeof(q), "UPDATE `garages` SET owner='%s' WHERE id=%d", esc, id);
            mysql_tquery(gSQL, q);
            SendClientMessage(playerid, COLOR_GREEN, "Felicitations, vous etes desormais proprietaire de ce garage !");
        }
        else
        {
            if(strlen(gBiz[id][bzOwner])) { SendClientMessage(playerid, COLOR_RED, "Ce commerce a deja un proprietaire."); return 1; }
            if(GetPlayerMoney(playerid) < gBiz[id][bzPrice]) { SendClientMessage(playerid, COLOR_RED, "Fonds insuffisants."); return 1; }
            GivePlayerMoney(playerid, -gBiz[id][bzPrice]);
            format(gBiz[id][bzOwner], MAX_PLAYER_NAME, "%s", name);
            Prop_RefreshBizLabel(id);
            new q[200], esc[MAX_PLAYER_NAME];
            mysql_escape_string(name, esc, sizeof(esc), gSQL);
            mysql_format(gSQL, q, sizeof(q), "UPDATE `businesses` SET owner='%s' WHERE id=%d", esc, id);
            mysql_tquery(gSQL, q);
            SendClientMessage(playerid, COLOR_GREEN, "Felicitations, vous etes desormais proprietaire de ce commerce !");
        }
        return 1;
    }

    if(!strcmp(cmd, "/vendre", true))
    {
        new type, id;
        if(!Prop_FindNearHouse(playerid, type, id)) { SendClientMessage(playerid, COLOR_RED, "Vous devez etre a l'entree de votre propriete pour la vendre."); return 1; }

        new name[MAX_PLAYER_NAME];
        GetPlayerName(playerid, name, sizeof(name));

        if(type == PROP_TYPE_HOUSE)
        {
            if(strcmp(gHouse[id][hOwner], name, true)) { SendClientMessage(playerid, COLOR_RED, "Vous n'etes pas proprietaire de cette maison."); return 1; }
            GivePlayerMoney(playerid, gHouse[id][hPrice] / 2);
            gHouse[id][hOwner][0] = EOS;
            gHouse[id][hLocked] = false;
            // Retire les meubles places par l'ancien proprietaire
            for(new i = 0; i < MAX_FURNITURE; i++)
                if(gFurniture[i][fExists] && gFurniture[i][fHouseID] == id)
                {
                    if(gFurniture[i][fObjectID] != -1) DestroyObject(gFurniture[i][fObjectID]);
                    gFurniture[i][fExists] = false;
                }
            new q[100]; format(q, sizeof(q), "DELETE FROM `furniture` WHERE house_id=%d", id); mysql_tquery(gSQL, q);
            Prop_RefreshHouseLabel(id);
            format(q, sizeof(q), "UPDATE `houses` SET owner='' WHERE id=%d", id); mysql_tquery(gSQL, q);
            SendClientMessage(playerid, COLOR_GREEN, "Vous avez revendu votre maison (50%% du prix rembourse).");
        }
        else if(type == PROP_TYPE_GARAGE)
        {
            if(strcmp(gGarage[id][gaOwner], name, true)) { SendClientMessage(playerid, COLOR_RED, "Vous n'etes pas proprietaire de ce garage."); return 1; }
            new hasVehicle = 0;
            for(new s = 0; s < gGarage[id][gaCapacity]; s++)
                if(gGarage[id][gaStoredModel][s] != 0) hasVehicle = 1;
            if(hasVehicle) { SendClientMessage(playerid, COLOR_RED, "Videz d'abord le garage (/sortir) avant de le revendre."); return 1; }

            GivePlayerMoney(playerid, gGarage[id][gaPrice] / 2);
            gGarage[id][gaOwner][0] = EOS;
            Prop_RefreshGarageLabel(id);
            new q[150]; format(q, sizeof(q), "UPDATE `garages` SET owner='' WHERE id=%d", id); mysql_tquery(gSQL, q);
            SendClientMessage(playerid, COLOR_GREEN, "Vous avez revendu votre garage (50%% du prix rembourse).");
        }
        else
        {
            if(strcmp(gBiz[id][bzOwner], name, true)) { SendClientMessage(playerid, COLOR_RED, "Vous n'etes pas proprietaire de ce commerce."); return 1; }
            new refund = gBiz[id][bzPrice] / 2 + gBiz[id][bzTill];
            GivePlayerMoney(playerid, refund);
            gBiz[id][bzOwner][0] = EOS;
            gBiz[id][bzTill] = 0;
            Prop_RefreshBizLabel(id);
            new q[150]; format(q, sizeof(q), "UPDATE `businesses` SET owner='', till=0 WHERE id=%d", id); mysql_tquery(gSQL, q);
            SendClientMessage(playerid, COLOR_GREEN, "Vous avez revendu votre commerce (50%% du prix + caisse rembourses).");
        }
        return 1;
    }

    if(!strcmp(cmd, "/fermer", true) || !strcmp(cmd, "/ouvrir", true))
    {
        new type, id;
        if(!Prop_FindNearHouse(playerid, type, id) || type != PROP_TYPE_HOUSE)
        {
            SendClientMessage(playerid, COLOR_RED, "Vous devez etre a l'entree de votre maison.");
            return 1;
        }
        new name[MAX_PLAYER_NAME];
        GetPlayerName(playerid, name, sizeof(name));
        if(strcmp(gHouse[id][hOwner], name, true)) { SendClientMessage(playerid, COLOR_RED, "Vous n'etes pas proprietaire de cette maison."); return 1; }

        gHouse[id][hLocked] = !strcmp(cmd, "/fermer", true) ? true : false;
        new q[100]; format(q, sizeof(q), "UPDATE `houses` SET locked=%d WHERE id=%d", gHouse[id][hLocked], id); mysql_tquery(gSQL, q);
        SendClientMessage(playerid, COLOR_GREEN, gHouse[id][hLocked] ? "Maison verrouillee." : "Maison deverrouillee.");
        return 1;
    }

    // ---------- GARAGE : stockage vehicule ----------
    if(!strcmp(cmd, "/rentrer", true))
    {
        new type, id;
        if(!Prop_FindNearHouse(playerid, type, id) || type != PROP_TYPE_GARAGE)
        {
            SendClientMessage(playerid, COLOR_RED, "Vous devez etre a l'entree de votre garage.");
            return 1;
        }
        new name[MAX_PLAYER_NAME];
        GetPlayerName(playerid, name, sizeof(name));
        if(strcmp(gGarage[id][gaOwner], name, true)) { SendClientMessage(playerid, COLOR_RED, "Vous n'etes pas proprietaire de ce garage."); return 1; }
        if(!IsPlayerInAnyVehicle(playerid)) { SendClientMessage(playerid, COLOR_RED, "Vous devez etre dans un vehicule pour le ranger."); return 1; }

        new slot = -1;
        for(new s = 0; s < gGarage[id][gaCapacity]; s++)
        {
            if(gGarage[id][gaStoredModel][s] == 0) { slot = s; break; }
        }
        if(slot == -1) { SendClientMessage(playerid, COLOR_RED, "Ce garage est plein. Sortez un vehicule avec /sortir avant d'en ranger un autre."); return 1; }

        new vehicleid = GetPlayerVehicleID(playerid);
        gGarage[id][gaStoredModel][slot] = GetVehicleModel(vehicleid);
        // NB: SA-MP n'a pas de native pour LIRE la couleur actuelle d'un
        // vehicule (seulement ChangeVehicleColor pour la definir). La
        // couleur d'origine (peinture) n'est donc pas conservee ; le
        // vehicule ressortira avec une couleur aleatoire par defaut.
        gGarage[id][gaStoredColor1][slot] = -1;
        gGarage[id][gaStoredColor2][slot] = -1;
        RemovePlayerFromVehicle(playerid);
        DestroyVehicle(vehicleid);

        new q[150], col[16];
        format(col, sizeof(col), "slot%d", slot + 1);
        mysql_format(gSQL, q, sizeof(q), "UPDATE `garages` SET %s_model=%d, %s_color1=%d, %s_color2=%d WHERE id=%d",
            col, gGarage[id][gaStoredModel][slot], col, gGarage[id][gaStoredColor1][slot], col, gGarage[id][gaStoredColor2][slot], id);
        mysql_tquery(gSQL, q);
        SendClientMessage(playerid, COLOR_GREEN, "Vehicule range dans le garage.");
        return 1;
    }

    if(!strcmp(cmd, "/sortir", true))
    {
        new type, id;
        if(!Prop_FindNearHouse(playerid, type, id) || type != PROP_TYPE_GARAGE)
        {
            SendClientMessage(playerid, COLOR_RED, "Vous devez etre a l'entree de votre garage.");
            return 1;
        }
        new name[MAX_PLAYER_NAME];
        GetPlayerName(playerid, name, sizeof(name));
        if(strcmp(gGarage[id][gaOwner], name, true)) { SendClientMessage(playerid, COLOR_RED, "Vous n'etes pas proprietaire de ce garage."); return 1; }

        new occupied = 0, onlySlot = -1;
        for(new s = 0; s < gGarage[id][gaCapacity]; s++)
        {
            if(gGarage[id][gaStoredModel][s] != 0) { occupied++; onlySlot = s; }
        }
        if(occupied == 0) { SendClientMessage(playerid, COLOR_RED, "Ce garage est vide."); return 1; }

        if(occupied == 1)
        {
            Prop_SpawnGarageVehicle(id, onlySlot);
            SendClientMessage(playerid, COLOR_GREEN, "Vehicule sorti du garage.");
            return 1;
        }

        // Plusieurs vehicules stockes : on demande lequel sortir
        new list[300] = "";
        for(new s = 0; s < gGarage[id][gaCapacity]; s++)
        {
            if(gGarage[id][gaStoredModel][s] == 0) continue;
            new mname[32], line[48];
            Prop_GetVehicleModelName(gGarage[id][gaStoredModel][s], mname, sizeof(mname));
            format(line, sizeof(line), "%s (emplacement %d)\n", mname, s + 1);
            strcat(list, line);
        }
        gPropEditIndex[playerid] = id;
        ShowPlayerDialog(playerid, DIALOG_PROP_GARAGE_SORTIR, DIALOG_STYLE_LIST, "Sortir un vehicule", list, "Sortir", "Annuler");
        return 1;
    }

    // ---------- COMMERCE : caisse ----------
    if(!strcmp(cmd, "/caisse", true))
    {
        new type, id;
        if(!Prop_FindNearHouse(playerid, type, id) || type != PROP_TYPE_BUSINESS)
        {
            SendClientMessage(playerid, COLOR_RED, "Vous devez etre a l'entree de votre commerce.");
            return 1;
        }
        new name[MAX_PLAYER_NAME];
        GetPlayerName(playerid, name, sizeof(name));
        if(strcmp(gBiz[id][bzOwner], name, true)) { SendClientMessage(playerid, COLOR_RED, "Vous n'etes pas proprietaire de ce commerce."); return 1; }

        new str[160];
        format(str, sizeof(str), "Caisse actuelle : $%d", gBiz[id][bzTill]);
        ShowPlayerDialog(playerid, DIALOG_PROP_CAISSE, DIALOG_STYLE_LIST, gBiz[id][bzName], "Deposer de l'argent\nRetirer de l'argent", "Choisir", "Annuler");
        gPropEditIndex[playerid] = id; // reutilise ce slot pour retenir l'id du commerce
        SendClientMessage(playerid, COLOR_YELLOW, str);
        return 1;
    }

    // ---------- MEUBLES / OBJETS ----------
    if(!strcmp(cmd, "/meubles", true))
    {
        new hid = Prop_GetOwnedHouseAtPosition(playerid);
        if(hid == -1) { SendClientMessage(playerid, COLOR_RED, "Vous devez etre a l'interieur de votre propre maison."); return 1; }
        if(gHouse[hid][hFurnitureCount] >= MAX_FURNITURE_PER_HOUSE) { SendClientMessage(playerid, COLOR_RED, "Nombre maximum de meubles atteint pour cette maison."); return 1; }

        new list[600] = "";
        for(new i = 0; i < FURNITURE_CATALOG_COUNT; i++)
        {
            strcat(list, gFurnitureCatalog[i][0]);
            if(i < FURNITURE_CATALOG_COUNT - 1) strcat(list, "\n");
        }
        gPropEditIndex[playerid] = hid;
        ShowPlayerDialog(playerid, DIALOG_PROP_FURNITURE_CATALOG, DIALOG_STYLE_LIST, "Catalogue de meubles", list, "Placer", "Annuler");
        return 1;
    }

    if(!strcmp(cmd, "/enlevermeuble", true))
    {
        new hid = Prop_GetOwnedHouseAtPosition(playerid);
        if(hid == -1) { SendClientMessage(playerid, COLOR_RED, "Vous devez etre a l'interieur de votre propre maison."); return 1; }

        new list[800] = "", count = 0;
        new idxList[MAX_FURNITURE_PER_HOUSE];
        for(new i = 0; i < MAX_FURNITURE && count < MAX_FURNITURE_PER_HOUSE; i++)
        {
            if(gFurniture[i][fExists] && gFurniture[i][fHouseID] == hid)
            {
                new line[48];
                format(line, sizeof(line), "Meuble #%d (modele %d)\n", i, gFurniture[i][fModel]);
                strcat(list, line);
                idxList[count] = i;
                count++;
            }
        }
        if(count == 0) { SendClientMessage(playerid, COLOR_RED, "Aucun meuble place dans cette maison."); return 1; }
        gPropEditIndex[playerid] = hid;
        ShowPlayerDialog(playerid, DIALOG_PROP_FURNITURE_REMOVE, DIALOG_STYLE_LIST, "Retirer un meuble", list, "Supprimer", "Annuler");
        return 1;
    }

    // ---------- DEV : test d'ID d'objet ----------
    if(!strcmp(cmd, "/objetid", true))
    {
        if(PlayerInfo[playerid][pAdmin] < ADMIN_LEVEL_DEV) return Prop_NoPerm(playerid);
        new tmp[64];
        tmp = strtok_(cmdtext, idx);
        if(!strlen(tmp))
        {
            SendClientMessage(playerid, COLOR_WHITE, "Utilisation : /objetid [modelid] (0 pour retirer l'objet de test actuel)");
            return 1;
        }
        new modelid = strval(tmp);

        if(gDevPreviewObject[playerid] != -1)
        {
            DestroyObject(gDevPreviewObject[playerid]);
            gDevPreviewObject[playerid] = -1;
        }
        if(modelid == 0) { SendClientMessage(playerid, COLOR_GREEN, "Objet de test retire."); return 1; }

        new Float:x, Float:y, Float:z, Float:a;
        GetPlayerPos(playerid, x, y, z);
        GetPlayerFacingAngle(playerid, a);
        gDevPreviewObject[playerid] = CreateObject(modelid, x, y, z + 0.5, 0.0, 0.0, 0.0, 300.0);

        gPropEditType[playerid] = PROP_TYPE_NONE; // preview seule, non liee a une maison
        gPropEditIndex[playerid] = -1;
        EditObject(playerid, gDevPreviewObject[playerid]);
        SendClientMessage(playerid, COLOR_GREEN, "Objet de test cree. Deplacez-le/tournez-le pour l'inspecter, ou refermez l'edition.");
        return 1;
    }

    return 0; // commande non geree par le systeme de proprietes
}

stock Prop_NoPerm(playerid)
{
    SendClientMessage(playerid, COLOR_RED, "Cette commande est reservee aux developpeurs.");
    return 1;
}

// Retourne l'ID de la maison si le joueur se trouve actuellement a l'interieur
// d'une maison DONT IL EST PROPRIETAIRE, sinon -1.
stock Prop_GetOwnedHouseAtPosition(playerid)
{
    new world = GetPlayerVirtualWorld(playerid);
    if(world < HOUSE_WORLD_BASE || world >= HOUSE_WORLD_BASE + MAX_HOUSES) return -1;
    new hid = world - HOUSE_WORLD_BASE;
    if(!gHouse[hid][hExists]) return -1;
    new name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof(name));
    if(strcmp(gHouse[hid][hOwner], name, true)) return -1;
    return hid;
}

// ==============================================================
//  Listes (dialogs) achat
// ==============================================================
stock Prop_ShowHousesList(playerid)
{
    new list[1200] = "ID\tPrix\tProprietaire\n";
    for(new i = 0; i < MAX_HOUSES; i++)
    {
        if(!gHouse[i][hExists]) continue;
        new line[80], ownerStr[MAX_PLAYER_NAME];
        if(strlen(gHouse[i][hOwner])) format(ownerStr, sizeof(ownerStr), "%s", gHouse[i][hOwner]);
        else format(ownerStr, sizeof(ownerStr), "Libre");
        format(line, sizeof(line), "%d\t$%d\t%s\n", i, gHouse[i][hPrice], ownerStr);
        strcat(list, line);
    }
    ShowPlayerDialog(playerid, DIALOG_PROP_HOUSES_LIST, DIALOG_STYLE_TABLIST_HEADERS, "Maisons", list, "Fermer", "");
    return 1;
}
stock Prop_ShowGaragesList(playerid)
{
    new list[1200] = "ID\tPrix\tPlaces\tProprietaire\n";
    for(new i = 0; i < MAX_GARAGES; i++)
    {
        if(!gGarage[i][gaExists]) continue;
        new line[90], ownerStr[MAX_PLAYER_NAME];
        if(strlen(gGarage[i][gaOwner])) format(ownerStr, sizeof(ownerStr), "%s", gGarage[i][gaOwner]);
        else format(ownerStr, sizeof(ownerStr), "Libre");
        format(line, sizeof(line), "%d\t$%d\t%d\t%s\n", i, gGarage[i][gaPrice], gGarage[i][gaCapacity], ownerStr);
        strcat(list, line);
    }
    ShowPlayerDialog(playerid, DIALOG_PROP_GARAGES_LIST, DIALOG_STYLE_TABLIST_HEADERS, "Garages", list, "Fermer", "");
    return 1;
}
stock Prop_ShowBusinessList(playerid)
{
    new list[1200] = "ID\tNom\tPrix\tProprietaire\n";
    for(new i = 0; i < MAX_BUSINESSES; i++)
    {
        if(!gBiz[i][bzExists]) continue;
        new line[100], ownerStr[MAX_PLAYER_NAME];
        if(strlen(gBiz[i][bzOwner])) format(ownerStr, sizeof(ownerStr), "%s", gBiz[i][bzOwner]);
        else format(ownerStr, sizeof(ownerStr), "Libre");
        format(line, sizeof(line), "%d\t%s\t$%d\t%s\n", i, gBiz[i][bzName], gBiz[i][bzPrice], ownerStr);
        strcat(list, line);
    }
    ShowPlayerDialog(playerid, DIALOG_PROP_BUSINESS_LIST, DIALOG_STYLE_TABLIST_HEADERS, "Commerces", list, "Fermer", "");
    return 1;
}

// ==============================================================
//  Dialogs - appelee depuis OnDialogResponse
//  Retourne 1 si le dialogid a ete gere.
// ==============================================================
stock Prop_OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    if(dialogid == DIALOG_PROP_HOUSES_LIST || dialogid == DIALOG_PROP_GARAGES_LIST || dialogid == DIALOG_PROP_BUSINESS_LIST)
        return 1; // listes en lecture seule

    if(dialogid == DIALOG_PROP_FURNITURE_CATALOG)
    {
        if(!response) return 1;
        new hid = gPropEditIndex[playerid];
        if(hid < 0 || hid >= MAX_HOUSES || !gHouse[hid][hExists]) return 1;
        if(listitem < 0 || listitem >= FURNITURE_CATALOG_COUNT) return 1;

        new modelid = strval(gFurnitureCatalog[listitem][1]);
        new Float:x, Float:y, Float:z, Float:a;
        GetPlayerPos(playerid, x, y, z);
        GetPlayerFacingAngle(playerid, a);
        // Placement initial 1.5m devant le joueur ; EditObject permet ensuite
        // un positionnement precis (deplacement/rotation en jeu).
        x += 1.5 * floatsin(-a, degrees);
        y += 1.5 * floatcos(-a, degrees);

        // Trouve un slot libre dans le tableau global de meubles
        new slot = -1;
        for(new i = 0; i < MAX_FURNITURE; i++) { if(!gFurniture[i][fExists]) { slot = i; break; } }
        if(slot == -1) { SendClientMessage(playerid, COLOR_RED, "Limite globale de meubles atteinte sur le serveur."); return 1; }

        new objectid = CreateObject(modelid, x, y, z, 0.0, 0.0, 0.0, 300.0);

        gFurniture[slot][fExists] = true;
        gFurniture[slot][fHouseID] = hid;
        gFurniture[slot][fModel] = modelid;
        gFurniture[slot][fX] = x; gFurniture[slot][fY] = y; gFurniture[slot][fZ] = z;
        gFurniture[slot][fRX] = 0.0; gFurniture[slot][fRY] = 0.0; gFurniture[slot][fRZ] = 0.0;
        gFurniture[slot][fObjectID] = objectid;
        gHouse[hid][hFurnitureCount]++;

        new q[300];
        mysql_format(gSQL, q, sizeof(q), "INSERT INTO `furniture` (id, house_id, model, x, y, z, rx, ry, rz) VALUES (%d, %d, %d, %f, %f, %f, 0, 0, 0)", slot, hid, modelid, x, y, z);
        mysql_tquery(gSQL, q);

        gPropEditType[playerid] = PROP_TYPE_HOUSE;
        gPropEditIndex[playerid] = slot;
        EditObject(playerid, objectid);
        SendClientMessage(playerid, COLOR_GREEN, "Meuble place. Ajustez sa position puis validez l'edition.");
        return 1;
    }

    if(dialogid == DIALOG_PROP_FURNITURE_REMOVE)
    {
        if(!response) return 1;
        new hid = gPropEditIndex[playerid];
        new count = 0;
        for(new i = 0; i < MAX_FURNITURE; i++)
        {
            if(gFurniture[i][fExists] && gFurniture[i][fHouseID] == hid)
            {
                if(count == listitem)
                {
                    if(gFurniture[i][fObjectID] != -1) DestroyObject(gFurniture[i][fObjectID]);
                    gFurniture[i][fExists] = false;
                    gHouse[hid][hFurnitureCount]--;
                    new q[64]; format(q, sizeof(q), "DELETE FROM `furniture` WHERE id=%d", i); mysql_tquery(gSQL, q);
                    SendClientMessage(playerid, COLOR_GREEN, "Meuble retire.");
                    break;
                }
                count++;
            }
        }
        return 1;
    }

    if(dialogid == DIALOG_PROP_GARAGE_SORTIR)
    {
        if(!response) return 1;
        new id = gPropEditIndex[playerid];
        if(id < 0 || id >= MAX_GARAGES || !gGarage[id][gaExists]) return 1;

        new count = 0;
        for(new s = 0; s < gGarage[id][gaCapacity]; s++)
        {
            if(gGarage[id][gaStoredModel][s] == 0) continue;
            if(count == listitem)
            {
                Prop_SpawnGarageVehicle(id, s);
                SendClientMessage(playerid, COLOR_GREEN, "Vehicule sorti du garage.");
                break;
            }
            count++;
        }
        return 1;
    }

    if(dialogid == DIALOG_PROP_CAISSE)
    {
        if(!response) return 1;
        if(listitem == 0)
            ShowPlayerDialog(playerid, DIALOG_PROP_CAISSE_DEPOT, DIALOG_STYLE_INPUT, "Deposer", "Montant a deposer :", "Valider", "Annuler");
        else
            ShowPlayerDialog(playerid, DIALOG_PROP_CAISSE_RETRAIT, DIALOG_STYLE_INPUT, "Retirer", "Montant a retirer :", "Valider", "Annuler");
        return 1;
    }

    if(dialogid == DIALOG_PROP_CAISSE_DEPOT)
    {
        if(!response) return 1;
        new id = gPropEditIndex[playerid];
        if(id < 0 || id >= MAX_BUSINESSES || !gBiz[id][bzExists]) return 1;
        new montant = strval(inputtext);
        if(montant <= 0 || montant > GetPlayerMoney(playerid)) { SendClientMessage(playerid, COLOR_RED, "Montant invalide."); return 1; }
        GivePlayerMoney(playerid, -montant);
        gBiz[id][bzTill] += montant;
        new q[100]; format(q, sizeof(q), "UPDATE `businesses` SET till=%d WHERE id=%d", gBiz[id][bzTill], id); mysql_tquery(gSQL, q);
        SendClientMessage(playerid, COLOR_GREEN, "Depot effectue.");
        return 1;
    }

    if(dialogid == DIALOG_PROP_CAISSE_RETRAIT)
    {
        if(!response) return 1;
        new id = gPropEditIndex[playerid];
        if(id < 0 || id >= MAX_BUSINESSES || !gBiz[id][bzExists]) return 1;
        new montant = strval(inputtext);
        if(montant <= 0 || montant > gBiz[id][bzTill]) { SendClientMessage(playerid, COLOR_RED, "Montant invalide."); return 1; }
        GivePlayerMoney(playerid, montant);
        gBiz[id][bzTill] -= montant;
        new q[100]; format(q, sizeof(q), "UPDATE `businesses` SET till=%d WHERE id=%d", gBiz[id][bzTill], id); mysql_tquery(gSQL, q);
        SendClientMessage(playerid, COLOR_GREEN, "Retrait effectue.");
        return 1;
    }

    return 0; // dialogid non gere par le systeme de proprietes
}

// ==============================================================
//  Callback natif SA-MP : validation/annulation d'un EditObject
//  (utilise pour le placement des meubles ET la preview /objetid)
// ==============================================================
public OnObjectEdit(playerid, objectid, response, Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz)
{
    // Cas 1 : objet de preview dev (/objetid), non lie a une maison
    if(gDevPreviewObject[playerid] == objectid)
    {
        if(response == EDIT_RESPONSE_CANCEL)
        {
            DestroyObject(objectid);
            gDevPreviewObject[playerid] = -1;
        }
        else
        {
            SetObjectPos(objectid, x, y, z);
            SetObjectRot(objectid, rx, ry, rz);
        }
        return 1;
    }

    // Cas 2 : meuble en cours de placement
    if(gPropEditType[playerid] == PROP_TYPE_HOUSE && gPropEditIndex[playerid] != -1)
    {
        new slot = gPropEditIndex[playerid];
        if(gFurniture[slot][fExists] && gFurniture[slot][fObjectID] == objectid)
        {
            if(response == EDIT_RESPONSE_CANCEL)
            {
                DestroyObject(objectid);
                new hid = gFurniture[slot][fHouseID];
                gFurniture[slot][fExists] = false;
                gHouse[hid][hFurnitureCount]--;
                new q[64]; format(q, sizeof(q), "DELETE FROM `furniture` WHERE id=%d", slot); mysql_tquery(gSQL, q);
            }
            else
            {
                SetObjectPos(objectid, x, y, z);
                SetObjectRot(objectid, rx, ry, rz);
                gFurniture[slot][fX] = x; gFurniture[slot][fY] = y; gFurniture[slot][fZ] = z;
                gFurniture[slot][fRX] = rx; gFurniture[slot][fRY] = ry; gFurniture[slot][fRZ] = rz;
                new q[300];
                mysql_format(gSQL, q, sizeof(q), "UPDATE `furniture` SET x=%f, y=%f, z=%f, rx=%f, ry=%f, rz=%f WHERE id=%d", x, y, z, rx, ry, rz, slot);
                mysql_tquery(gSQL, q);
            }
            gPropEditIndex[playerid] = -1;
        }
    }
    return 1;
}

// ==============================================================
//  Callback natif SA-MP : entree/sortie via les pickups
// ==============================================================
// ==============================================================
//  Entree/sortie des proprietes : touche F (comme le commissariat)
//  Prop_OnKeyStateChange est appelee depuis OnPlayerKeyStateChange
//  dans californierp.pwn. Les pickups/labels crees plus haut restent
//  de simples marqueurs visuels (icone sur la carte) ; le teleport se
//  declenche uniquement sur pression de F, jamais au simple contact.
// ==============================================================
stock Prop_OnKeyStateChange(playerid, newkeys)
{
    if(!(newkeys & KEY_SECONDARY_ATTACK)) return 0;

    new name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof(name));

    // --- Depuis l'exterieur : entree dans une propriete a proximite ---
    if(GetPlayerInterior(playerid) == 0 && GetPlayerVirtualWorld(playerid) == 0)
    {
        new type, id;
        if(!Prop_FindNearHouse(playerid, type, id)) return 0;

        if(type == PROP_TYPE_HOUSE)
        {
            if(!strlen(gHouse[id][hOwner]))
            {
                SendClientMessage(playerid, COLOR_YELLOW, "Cette maison est a vendre. Utilisez /acheter pour l'acquerir.");
                return 1;
            }
            if(strcmp(gHouse[id][hOwner], name, true) && gHouse[id][hLocked])
            {
                SendClientMessage(playerid, COLOR_RED, "Cette maison est verrouillee.");
                return 1;
            }
            SetPlayerPos(playerid, gHouse[id][hIntX], gHouse[id][hIntY], gHouse[id][hIntZ]);
            SetPlayerFacingAngle(playerid, gHouse[id][hIntA]);
            SetPlayerInterior(playerid, gHouse[id][hInteriorID]);
            SetPlayerVirtualWorld(playerid, HOUSE_WORLD_BASE + id);
            return 1;
        }
        else if(type == PROP_TYPE_GARAGE)
        {
            if(!strlen(gGarage[id][gaOwner]))
            {
                SendClientMessage(playerid, COLOR_YELLOW, "Ce garage est a vendre. Utilisez /acheter pour l'acquerir.");
                return 1;
            }
            SetPlayerPos(playerid, gGarage[id][gaIntX], gGarage[id][gaIntY], gGarage[id][gaIntZ]);
            SetPlayerFacingAngle(playerid, gGarage[id][gaIntA]);
            SetPlayerInterior(playerid, gGarage[id][gaInteriorID]);
            SetPlayerVirtualWorld(playerid, GARAGE_WORLD_BASE + id);
            return 1;
        }
        else // PROP_TYPE_BUSINESS
        {
            if(!strlen(gBiz[id][bzOwner]))
            {
                SendClientMessage(playerid, COLOR_YELLOW, "Ce commerce est a vendre. Utilisez /acheter pour l'acquerir.");
                return 1;
            }
            SetPlayerPos(playerid, gBiz[id][bzIntX], gBiz[id][bzIntY], gBiz[id][bzIntZ]);
            SetPlayerFacingAngle(playerid, gBiz[id][bzIntA]);
            SetPlayerInterior(playerid, gBiz[id][bzInteriorID]);
            SetPlayerVirtualWorld(playerid, BUSINESS_WORLD_BASE + id);
            return 1;
        }
    }

    // --- Depuis l'interieur : sortie vers l'entree exterieure ---
    new world = GetPlayerVirtualWorld(playerid);

    if(world >= HOUSE_WORLD_BASE && world < HOUSE_WORLD_BASE + MAX_HOUSES)
    {
        new id = world - HOUSE_WORLD_BASE;
        if(gHouse[id][hExists] && IsPlayerInRangeOfPoint(playerid, PROP_ENTER_RADIUS, gHouse[id][hIntX], gHouse[id][hIntY], gHouse[id][hIntZ]))
        {
            SetPlayerPos(playerid, gHouse[id][hEntX], gHouse[id][hEntY], gHouse[id][hEntZ]);
            SetPlayerFacingAngle(playerid, gHouse[id][hEntA]);
            SetPlayerInterior(playerid, 0);
            SetPlayerVirtualWorld(playerid, 0);
            return 1;
        }
    }
    else if(world >= GARAGE_WORLD_BASE && world < GARAGE_WORLD_BASE + MAX_GARAGES)
    {
        new id = world - GARAGE_WORLD_BASE;
        if(gGarage[id][gaExists] && IsPlayerInRangeOfPoint(playerid, PROP_ENTER_RADIUS, gGarage[id][gaIntX], gGarage[id][gaIntY], gGarage[id][gaIntZ]))
        {
            SetPlayerPos(playerid, gGarage[id][gaEntX], gGarage[id][gaEntY], gGarage[id][gaEntZ]);
            SetPlayerFacingAngle(playerid, gGarage[id][gaEntA]);
            SetPlayerInterior(playerid, 0);
            SetPlayerVirtualWorld(playerid, 0);
            return 1;
        }
    }
    else if(world >= BUSINESS_WORLD_BASE && world < BUSINESS_WORLD_BASE + MAX_BUSINESSES)
    {
        new id = world - BUSINESS_WORLD_BASE;
        if(gBiz[id][bzExists] && IsPlayerInRangeOfPoint(playerid, PROP_ENTER_RADIUS, gBiz[id][bzIntX], gBiz[id][bzIntY], gBiz[id][bzIntZ]))
        {
            SetPlayerPos(playerid, gBiz[id][bzEntX], gBiz[id][bzEntY], gBiz[id][bzEntZ]);
            SetPlayerFacingAngle(playerid, gBiz[id][bzEntA]);
            SetPlayerInterior(playerid, 0);
            SetPlayerVirtualWorld(playerid, 0);
            return 1;
        }
    }

    return 0;
}
