// ==============================================================================
//  lyd2_locations.inc
//  Objets, pickups, panneaux 3D, vehicules et zones recuperes depuis lyd2.pwn.
//  Genere automatiquement a partir des coordonnees litterales trouvees dans lyd2.
//  Necessite le plugin/include Streamer (#include <streamer> dans le .pwn principal).
// ==============================================================================

#if !defined _streamer_included
    #error lyd2_locations.inc necessite #include <streamer> AVANT son inclusion
#endif

// ---- Macros de couleur utilisees dans les textes des panneaux 3D ci-dessous (issues de lyd2.pwn) ----
#if !defined COLOR_HEX_WHITE
    #define COLOR_HEX_WHITE     "{FFFFFE}"
#endif
#if !defined COLOR_HEX_ORANGE
    #define COLOR_HEX_ORANGE    "{FF6731}"
#endif
#if !defined COLOR_HEX_RED
    #define COLOR_HEX_RED       "{FF1705}"
#endif
#if !defined COLOR_HEX_LIGHTBLUE
    #define COLOR_HEX_LIGHTBLUE "{2E94D0}"
#endif
#if !defined COLOR_HEX_BLUE
    #define COLOR_HEX_BLUE      "{0077FF}"
#endif
#if !defined COLOR_HEX_GREEN
    #define COLOR_HEX_GREEN     "{15951F}"
#endif
#if !defined COLOR_HEX_GREENA
    #define COLOR_HEX_GREENA    "{00CC00}"
#endif
#if !defined COLOR_HEX_YELLOW
    #define COLOR_HEX_YELLOW    "{FFFF00}"
#endif
#if !defined COLOR_HEX_BLACK
    #define COLOR_HEX_BLACK     "{000000}"
#endif
#if !defined COLOR_HEX_PINK
    #define COLOR_HEX_PINK      "{AF00FF}"
#endif
#if !defined COLOR_HEX_GRAU
    #define COLOR_HEX_GRAU      "{555555}"
#endif
#if !defined COLOR_HEX_DARKRED
    #define COLOR_HEX_DARKRED   "{A52A2A}"
#endif

#if !defined COLOR_BLUE
    #define COLOR_BLUE 0x3592D7FF
#endif

// ---- Objets de decor (283 elements) ----
stock Lyd2_LoadObjects()
{
    CreateDynamicObject(2332, 1686.8259, -1031.4426, 1333.7956, 0.0000, 0.0000, -90.0000); // L38187 (lyd2)
    CreateDynamicObject(2332, 1689.5681, -1019.7673, 1340.2413, 0.0000, 0.0000, 0.0000); // L38188 (lyd2)
    CreateDynamicObject(2332, 1684.2133, -1035.0657, 1333.7956, 0.0000, 0.0000, 180.0000); // L38189 (lyd2)
    CreateDynamicObject(2332, 1695.2431, -1019.7673, 1340.2413, 0.0000, 0.0000, 0.0000); // L38190 (lyd2)
    CreateDynamicObject(2332, 1691.2214, -1035.0546, 1333.7956, 0.0000, 0.0000, 180.0000); // L38191 (lyd2)
    CreateDynamicObject(2332, 1688.9193, -1030.3500, 1333.7956, 0.0000, 0.0000, 90.0000); // L38192 (lyd2)
    CreateDynamicObject(1829, 1686.8259, -1031.4426, 1333.7956, 0.0000, 0.0000, -90.0000); // L46545 (lyd2)
    CreateDynamicObject(1829, 1689.5681, -1019.7673, 1340.2413, 0.0000, 0.0000, 0.0000); // L46548 (lyd2)
    CreateDynamicObject(1829, 1684.2133, -1035.0657, 1333.7956, 0.0000, 0.0000, 180.0000); // L46551 (lyd2)
    CreateDynamicObject(1829, 1695.2431, -1019.7673, 1340.2413, 0.0000, 0.0000, 0.0000); // L46554 (lyd2)
    CreateDynamicObject(1829, 1691.2214, -1035.0546, 1333.7956, 0.0000, 0.0000, 180.0000); // L46557 (lyd2)
    CreateDynamicObject(1829, 1688.9193, -1030.3500, 1333.7956, 0.0000, 0.0000, 90.0000); // L46560 (lyd2)
    CreateDynamicObject(1829, 1494.256835, -1522.610107, 1001.687805, 0.0, 0.0, 180.0); // L46601 (lyd2)
    CreateDynamicObject(1344, 1575.32, -1860.68, 13.33, 0.00, 0.00, -90.00); // L47768 (lyd2)
    CreateDynamicObject(1344, 1575.31, -1794.34, 13.24, 0.00, 0.00, -90.00); // L47769 (lyd2)
    CreateDynamicObject(1344, 1575.25, -1743.08, 13.33, 0.00, 0.00, -90.00); // L47770 (lyd2)
    CreateDynamicObject(1344, 1372.86, -1726.57, 13.32, 0.00, 0.00, 0.00); // L47771 (lyd2)
    CreateDynamicObject(1344, 1319.92, -1724.81, 13.33, 0.00, 0.00, -43.00); // L47772 (lyd2)
    CreateDynamicObject(1344, 1318.34, -1673.26, 13.33, 0.00, 0.00, -90.00); // L47773 (lyd2)
    CreateDynamicObject(1344, 1318.24, -1625.49, 13.33, 0.00, 0.00, -90.00); // L47774 (lyd2)
    CreateDynamicObject(1344, 1318.29, -1583.30, 13.33, 0.00, 0.00, -90.00); // L47775 (lyd2)
    CreateDynamicObject(1344, 1319.13, -1556.67, 13.32, 0.00, 0.00, -98.69); // L47776 (lyd2)
    CreateDynamicObject(1344, 1354.74, -1476.45, 13.33, 0.00, 0.00, 256.31); // L47777 (lyd2)
    CreateDynamicObject(1344, 1363.24, -1420.69, 13.33, 0.00, 0.00, -93.00); // L47778 (lyd2)
    CreateDynamicObject(1344, 1291.04, -1389.49, 13.20, 0.00, 0.00, 0.00); // L47779 (lyd2)
    CreateDynamicObject(1344, 1266.28, -1360.01, 13.26, 0.00, 0.00, -90.00); // L47780 (lyd2)
    CreateDynamicObject(1344, 1266.27, -1308.70, 13.28, 0.00, 0.00, -90.00); // L47781 (lyd2)
    CreateDynamicObject(1344, 1223.79, -1156.61, 23.43, 0.00, 0.00, -142.00); // L47782 (lyd2)
    CreateDynamicObject(1344, 1268.74, -1127.32, 23.80, 0.00, 3.53, -90.00); // L47783 (lyd2)
    CreateDynamicObject(1344, 1268.72, -1070.70, 28.36, 0.00, 7.80, -92.00); // L47784 (lyd2)
    CreateDynamicObject(1344, 1268.90, -981.15, 36.95, 0.00, 6.88, -90.00); // L47785 (lyd2)
    CreateDynamicObject(1344, 1254.53, -920.78, 42.56, 0.00, 0.00, 11.41); // L47786 (lyd2)
    CreateDynamicObject(1344, 1230.39, -913.43, 42.88, 0.00, 0.00, -80.00); // L47787 (lyd2)
    CreateDynamicObject(1344, 1143.15, -938.38, 42.80, 0.00, 0.00, 5.00); // L47788 (lyd2)
    CreateDynamicObject(1344, 1065.78, -944.34, 42.78, 0.00, 0.00, 8.00); // L47789 (lyd2)
    CreateDynamicObject(1344, 1004.78, -952.55, 41.96, 0.00, -0.69, 7.12); // L47790 (lyd2)
    CreateDynamicObject(1344, 878.50, -980.15, 36.11, 0.00, -5.45, 32.00); // L47791 (lyd2)
    CreateDynamicObject(1344, 833.05, -1021.84, 25.96, 0.00, -9.27, 42.00); // L47792 (lyd2)
    CreateDynamicObject(1344, 787.50, -1036.63, 24.42, 0.00, 0.00, 41.00); // L47793 (lyd2)
    CreateDynamicObject(1344, 488.16, -1276.06, 15.49, 0.00, -0.49, 39.00); // L47794 (lyd2)
    CreateDynamicObject(1344, 436.02, -1315.29, 14.87, 0.00, 0.00, 35.00); // L47795 (lyd2)
    CreateDynamicObject(1344, 336.44, -1375.30, 14.11, 0.00, 0.00, 29.00); // L47796 (lyd2)
    CreateDynamicObject(1344, 230.99, -1433.80, 13.15, 0.00, 0.00, 43.00); // L47797 (lyd2)
    CreateDynamicObject(1344, 168.37, -1514.36, 12.15, 0.00, -0.59, 59.00); // L47798 (lyd2)
    CreateDynamicObject(1344, 107.49, -1630.59, 10.10, 0.00, -0.39, 82.00); // L47799 (lyd2)
    CreateDynamicObject(1344, 113.44, -1694.20, 9.38, 0.00, -0.69, 103.00); // L47800 (lyd2)
    CreateDynamicObject(1344, 181.91, -1741.32, 4.13, 0.00, 0.29, -176.00); // L47801 (lyd2)
    CreateDynamicObject(1344, 237.01, -1738.04, 3.99, 0.00, 0.00, -177.00); // L47802 (lyd2)
    CreateDynamicObject(1344, 289.05, -1742.17, 4.12, 0.00, 0.20, 172.57); // L47803 (lyd2)
    CreateDynamicObject(1344, 335.57, -1747.85, 4.43, 0.00, 0.00, 139.00); // L47804 (lyd2)
    CreateDynamicObject(1344, 459.64, -1767.67, 5.44, 0.00, 1.47, -129.00); // L47805 (lyd2)
    CreateDynamicObject(1344, 499.18, -1732.62, 11.29, 0.00, 0.78, 170.00); // L47806 (lyd2)
    CreateDynamicObject(1344, 563.40, -1740.97, 12.62, 0.00, 1.27, 171.31); // L47807 (lyd2)
    CreateDynamicObject(1344, 631.54, -1752.13, 13.14, 0.00, -0.59, 169.00); // L47808 (lyd2)
    CreateDynamicObject(1344, 713.01, -1775.15, 13.42, 0.00, 0.69, 160.00); // L47809 (lyd2)
    CreateDynamicObject(1344, 804.34, -1789.93, 13.26, 0.00, 0.78, -180.00); // L47810 (lyd2)
    CreateDynamicObject(1344, 938.16, -1796.69, 13.65, 0.00, 1.47, 168.00); // L47811 (lyd2)
    CreateDynamicObject(1344, 1030.30, -1825.45, 13.64, 0.00, -0.49, 128.00); // L47812 (lyd2)
    CreateDynamicObject(1344, 1096.22, -1858.12, 13.34, 0.00, 0.00, -180.51); // L47813 (lyd2)
    CreateDynamicObject(1344, 1157.66, -1858.00, 13.33, 0.00, 0.00, 180.00); // L47814 (lyd2)
    CreateDynamicObject(1344, 1234.37, -1857.95, 13.33, 0.00, 0.00, 180.00); // L47815 (lyd2)
    CreateDynamicObject(1344, 1415.44, -1878.07, 13.33, 0.00, 0.00, 180.00); // L47816 (lyd2)
    CreateDynamicObject(16442, -125.96608, 60.06145, 3.79410, 0.00000, 0.00000, 0.00000); // L48126 (lyd2)
    CreateDynamicObject(16442, -136.70894, 45.77469, 3.79410, 0.00000, 0.00000, -84.84000); // L48127 (lyd2)
    CreateDynamicObject(16442, -142.35411, 59.64023, 3.79410, 0.00000, 0.00000, -123.77999); // L48128 (lyd2)
    CreateDynamicObject(16442, -189.92209, 78.36684, 3.79410, 0.00000, 0.00000, -151.01997); // L48129 (lyd2)
    CreateDynamicObject(16442, -142.78531, 26.97668, 3.79410, 0.00000, 0.00000, -202.07996); // L48130 (lyd2)
    CreateDynamicObject(16442, -156.97450, 32.99458, 3.79410, 0.00000, 0.00000, -155.76006); // L48131 (lyd2)
    CreateDynamicObject(16442, -153.67236, 44.32209, 3.79410, 0.00000, 0.00000, -55.14002); // L48132 (lyd2)
    CreateDynamicObject(16442, -162.36833, 59.40239, 3.79410, 0.00000, 0.00000, -55.14002); // L48133 (lyd2)
    CreateDynamicObject(16442, -167.94984, 46.01622, 3.79410, 0.00000, 0.00000, -194.39999); // L48134 (lyd2)
    CreateDynamicObject(16442, -169.17175, 74.79633, 3.79410, 0.00000, 0.00000, -194.39999); // L48135 (lyd2)
    CreateDynamicObject(16442, -186.03668, 64.81738, 3.79410, 0.00000, 0.00000, -166.13998); // L48136 (lyd2)
    CreateDynamicObject(16442, -177.28195, 56.27567, 3.79410, 0.00000, 0.00000, -65.28000); // L48137 (lyd2)
    CreateDynamicObject(16442, -177.15005, 32.90548, 3.79410, 0.00000, 0.00000, -118.25998); // L48138 (lyd2)
    CreateDynamicObject(16442, -170.76878, 20.71162, 3.79410, 0.00000, 0.00000, -118.25998); // L48139 (lyd2)
    CreateDynamicObject(16442, -155.91841, 15.99560, 3.79410, 0.00000, 0.00000, -63.23999); // L48140 (lyd2)
    CreateDynamicObject(16442, -164.42017, 1.40912, 3.79410, 0.00000, 0.00000, 52.20001); // L48141 (lyd2)
    CreateDynamicObject(16442, -151.31874, -6.77877, 3.79410, 0.00000, 0.00000, 119.40004); // L48142 (lyd2)
    CreateDynamicObject(16442, -180.38377, 2.73226, 3.79410, 0.00000, 0.00000, 119.40004); // L48143 (lyd2)
    CreateDynamicObject(16442, -189.64589, 19.43103, 3.79410, 0.00000, 0.00000, -25.97997); // L48144 (lyd2)
    CreateDynamicObject(16442, -189.44766, 37.67817, 3.79410, 0.00000, 0.00000, -281.81985); // L48145 (lyd2)
    CreateDynamicObject(16442, -195.65918, 54.06594, 3.79410, 0.00000, 0.00000, -216.53981); // L48146 (lyd2)
    CreateDynamicObject(16442, -203.63411, 33.18205, 3.79410, 0.00000, 0.00000, -209.63980); // L48147 (lyd2)
    CreateDynamicObject(16442, -207.05188, 16.92773, 3.79410, 0.00000, 0.00000, -125.81982); // L48148 (lyd2)
    CreateDynamicObject(16442, -199.79311, 4.35569, 3.79410, 0.00000, 0.00000, -49.07981); // L48149 (lyd2)
    CreateDynamicObject(16442, -184.25958, -8.11793, 3.79410, 0.00000, 0.00000, -135.41980); // L48150 (lyd2)
    CreateDynamicObject(16442, -167.08412, -11.64091, 3.79410, 0.00000, 0.00000, -226.43982); // L48151 (lyd2)
    CreateDynamicObject(16442, -163.65929, -28.10913, 3.79410, 0.00000, 0.00000, -159.89984); // L48152 (lyd2)
    CreateDynamicObject(16442, -178.11102, -19.60854, 3.79410, 0.00000, 0.00000, -69.47988); // L48153 (lyd2)
    CreateDynamicObject(16442, -198.38930, -9.75505, 3.79410, 0.00000, 0.00000, -163.37994); // L48154 (lyd2)
    CreateDynamicObject(16442, -216.46967, 2.87481, 3.79410, 0.00000, 0.00000, -163.37994); // L48155 (lyd2)
    CreateDynamicObject(16442, -217.98761, 27.46272, 3.79410, 0.00000, 0.00000, -201.83995); // L48156 (lyd2)
    CreateDynamicObject(16442, -211.16953, 46.68614, 3.79410, 0.00000, 0.00000, -201.83995); // L48157 (lyd2)
    CreateDynamicObject(16442, -203.40834, 67.33411, 3.79410, 0.00000, 0.00000, -357.23990); // L48158 (lyd2)
    CreateDynamicObject(16442, -209.08920, 83.95598, 3.79410, 0.00000, 0.00000, -400.67978); // L48159 (lyd2)
    CreateDynamicObject(16442, -220.10411, 66.67113, 3.79410, 0.00000, 0.00000, -513.71991); // L48160 (lyd2)
    CreateDynamicObject(16442, -225.33287, 46.97904, 3.79410, 0.00000, 0.00000, -443.93997); // L48161 (lyd2)
    CreateDynamicObject(16442, -230.53523, 18.26859, 3.79410, 0.00000, 0.00000, -409.62006); // L48162 (lyd2)
    CreateDynamicObject(16442, -176.35732, -35.41095, 3.79410, 0.00000, 0.00000, -138.83987); // L48163 (lyd2)
    CreateDynamicObject(16442, -192.73196, -28.26979, 3.79410, 0.00000, 0.00000, -42.23987); // L48164 (lyd2)
    CreateDynamicObject(16442, -211.92059, -13.80678, 3.79410, 0.00000, 0.00000, -19.67987); // L48165 (lyd2)
    CreateDynamicObject(16442, -228.34785, -6.93035, 3.79410, 0.00000, 0.00000, 18.60013); // L48166 (lyd2)
    CreateDynamicObject(16442, -234.40105, 5.73009, 3.79410, 0.00000, 0.00000, -248.69977); // L48167 (lyd2)
    CreateDynamicObject(16442, -237.71082, 35.86252, 3.79410, 0.00000, 0.00000, -248.69977); // L48168 (lyd2)
    CreateDynamicObject(16442, -247.81337, 17.44417, 3.79410, 0.00000, 0.00000, -178.55975); // L48169 (lyd2)
    CreateDynamicObject(16442, -246.63646, -1.44542, 3.79410, 0.00000, 0.00000, -178.55975); // L48170 (lyd2)
    CreateDynamicObject(16442, -241.43004, -19.83572, 3.79410, 0.00000, 0.00000, -325.13980); // L48171 (lyd2)
    CreateDynamicObject(16442, -224.37344, -25.81573, 3.79410, 0.00000, 0.00000, -347.75980); // L48172 (lyd2)
    CreateDynamicObject(16442, -208.56688, -33.83857, 3.79410, 0.00000, 0.00000, -435.83975); // L48173 (lyd2)
    CreateDynamicObject(16442, -192.42683, -42.66315, 3.79410, 0.00000, 0.00000, -435.83975); // L48174 (lyd2)
    CreateDynamicObject(16442, -182.66054, -63.79105, 3.79410, 0.00000, 0.00000, -480.53967); // L48175 (lyd2)
    CreateDynamicObject(16442, -176.47409, -49.94964, 3.79410, 0.00000, 0.00000, -538.67987); // L48176 (lyd2)
    CreateDynamicObject(16442, -198.60461, -55.33841, 3.79410, 0.00000, 0.00000, -538.67987); // L48177 (lyd2)
    CreateDynamicObject(16442, -217.00060, -50.44470, 3.79410, 0.00000, 0.00000, -445.97980); // L48178 (lyd2)
    CreateDynamicObject(16442, -228.46001, -38.65093, 3.79410, 0.00000, 0.00000, -358.79971); // L48179 (lyd2)
    CreateDynamicObject(16442, -241.26224, -31.79682, 3.79410, 0.00000, 0.00000, -512.57983); // L48180 (lyd2)
    CreateDynamicObject(16442, -254.79425, -13.62565, 3.79410, 0.00000, 0.00000, -510.83990); // L48181 (lyd2)
    CreateDynamicObject(16442, -256.67801, -30.15676, 3.79410, 0.00000, 0.00000, -510.83990); // L48182 (lyd2)
    CreateDynamicObject(16442, -245.45988, -46.40671, 3.79410, 0.00000, 0.00000, -388.49979); // L48183 (lyd2)
    CreateDynamicObject(16442, -227.45573, -59.87135, 3.79410, 0.00000, 0.00000, -411.77975); // L48184 (lyd2)
    CreateDynamicObject(16442, -209.08817, -63.18591, 3.79410, 0.00000, 0.00000, -442.19977); // L48185 (lyd2)
    CreateDynamicObject(16442, -193.53641, -73.94958, 3.79410, 0.00000, 0.00000, -442.19977); // L48186 (lyd2)
    CreateDynamicObject(16442, -210.03889, -74.42095, 3.79410, 0.00000, 0.00000, -337.43976); // L48187 (lyd2)
    CreateDynamicObject(16442, -227.86240, -73.47112, 3.79410, 0.00000, 0.00000, -414.41974); // L48188 (lyd2)
    CreateDynamicObject(16442, -239.99902, -61.39411, 3.79410, 0.00000, 0.00000, -307.73984); // L48189 (lyd2)
    CreateDynamicObject(16442, -259.56262, -51.51152, 3.79410, 0.00000, 0.00000, -254.87981); // L48190 (lyd2)
    CreateDynamicObject(16442, -249.32695, -56.90627, 3.79410, 0.00000, 0.00000, -254.87981); // L48191 (lyd2)
    CreateDynamicObject(16442, -120.97840, 98.95062, 3.79410, 0.00000, 0.00000, 0.00000); // L48192 (lyd2)
    CreateDynamicObject(16442, -119.09953, 114.50349, 3.79410, 0.00000, 0.00000, 121.74000); // L48193 (lyd2)
    CreateDynamicObject(16442, -110.85193, 133.16795, 3.79410, 0.00000, 0.00000, 74.10000); // L48194 (lyd2)
    CreateDynamicObject(16442, -119.25746, 145.32318, 3.79410, 0.00000, 0.00000, 47.46000); // L48195 (lyd2)
    CreateDynamicObject(16442, -130.21591, 126.46263, 3.79410, 0.00000, 0.00000, -5.04000); // L48196 (lyd2)
    CreateDynamicObject(16442, -131.05293, 110.43054, 3.79410, 0.00000, 0.00000, -5.04000); // L48197 (lyd2)
    CreateDynamicObject(16442, -142.77469, 108.09543, 3.89481, 0.00000, 0.00000, -31.44000); // L48198 (lyd2)
    CreateDynamicObject(16442, -140.56607, 119.21395, 4.09187, 0.00000, 0.00000, -188.63998); // L48199 (lyd2)
    CreateDynamicObject(16442, -130.43369, 137.11520, 4.20977, 0.00000, 0.00000, -188.63998); // L48200 (lyd2)
    CreateDynamicObject(16442, -132.40044, 153.83987, 4.85039, 0.00000, 0.00000, -155.34000); // L48201 (lyd2)
    CreateDynamicObject(16442, -140.95828, 146.12637, 4.85039, 0.00000, 0.00000, -155.34000); // L48202 (lyd2)
    CreateDynamicObject(16442, -144.22665, 132.24455, 4.85039, 0.00000, 0.00000, -345.29999); // L48203 (lyd2)
    CreateDynamicObject(16442, -157.28069, 119.55559, 4.17385, 0.00000, 0.00000, -465.65994); // L48204 (lyd2)
    CreateDynamicObject(16442, -172.40321, 124.76702, 4.29686, 0.00000, 0.00000, -505.37997); // L48205 (lyd2)
    CreateDynamicObject(16442, -159.88194, 133.50537, 4.26611, 0.00000, 0.00000, -549.83997); // L48206 (lyd2)
    CreateDynamicObject(16442, -154.25711, 147.40797, 5.06773, 0.00000, 0.00000, -629.16003); // L48207 (lyd2)
    CreateDynamicObject(16442, -149.42297, 159.71071, 6.14143, 0.00000, 0.00000, -697.79980); // L48208 (lyd2)
    CreateDynamicObject(16442, -167.93280, 142.32567, 5.26359, 0.00000, 0.00000, -697.79980); // L48209 (lyd2)
    CreateDynamicObject(16442, -164.26904, 157.79172, 6.64802, 0.00000, 0.00000, -867.89978); // L48210 (lyd2)
    CreateDynamicObject(16442, -177.29436, 151.29977, 6.64802, 0.00000, 0.00000, -867.89978); // L48211 (lyd2)
    CreateDynamicObject(16442, -182.19092, 137.17256, 5.41141, 0.00000, 0.00000, -721.07971); // L48212 (lyd2)
    CreateDynamicObject(16442, -202.92041, 143.22769, 5.41141, 0.00000, 0.00000, -721.07971); // L48213 (lyd2)
    CreateDynamicObject(16442, -190.84160, 151.50127, 6.33961, 0.00000, 0.00000, -659.63989); // L48214 (lyd2)
    CreateDynamicObject(16442, -181.28932, 163.01686, 8.06141, 0.00000, 0.00000, -731.99969); // L48215 (lyd2)
    CreateDynamicObject(16442, -196.45894, 162.49364, 7.30664, 0.00000, 0.00000, -877.49963); // L48216 (lyd2)
    CreateDynamicObject(16442, -195.89185, 135.60809, 4.51406, 0.00000, 0.00000, -877.49963); // L48217 (lyd2)
    CreateDynamicObject(19278, 385.37869, -2127.62549, 59.5, 0.00000, 180.00000, 0.00000); // L48867 (lyd2)
    CreateDynamicObject(19277, 385.24939, -2133.14404, 8.55, 0.00000, 0.00000, 0.00000); // L48869 (lyd2)
    CreateDynamicObject(19277, 380.04660, -2127.43018, 8.55, 0.00000, 0.00000, 272.58011); // L48870 (lyd2)
    CreateDynamicObject(19277, 385.24939, -2122.27832, 8.55, 0.00000, 0.00000, 180.00000); // L48871 (lyd2)
    CreateDynamicObject(19277, 390.41589, -2127.43018, 8.55, 0.00000, 0.00000, 90.00000); // L48872 (lyd2)
    CreateDynamicObject(19300, 385.24939, -2133.14404, 8.29360, 0.00000, 0.00000, 0.00000); // L48875 (lyd2)
    CreateDynamicObject(19300, 380.04660, -2127.43018, 8.29360, 0.00000, 0.00000, 272.58011); // L48876 (lyd2)
    CreateDynamicObject(19300, 385.24939, -2122.27832, 8.29360, 0.00000, 0.00000, 180.00000); // L48877 (lyd2)
    CreateDynamicObject(19300, 390.41589, -2127.43018, 8.29360, 0.00000, 0.00000, 90.00000); // L48878 (lyd2)
    CreateDynamicObject(8493, 372.10446, -2175.82153, 20.05120, 0.00000, 0.00000, 86.0); // L48908 (lyd2)
    CreateDynamicObject(18879, 355.99719, -2153.05029, 10.65203, 0.00000, 0.00000, 39.35999); // L48956 (lyd2)
    CreateDynamicObject(18879, 358.37784, -2152.10815, 10.65203, 0.00000, 0.00000, -3.96001); // L48957 (lyd2)
    CreateDynamicObject(18879, 360.97186, -2151.81274, 10.65203, 0.00000, 0.00000, -29.04001); // L48958 (lyd2)
    CreateDynamicObject(18879, 363.17868, -2153.27148, 10.65203, 0.00000, 0.00000, -49.92001); // L48959 (lyd2)
    CreateDynamicObject(18879, 364.26526, -2155.45947, 10.65203, 0.00000, 0.00000, -96.48002); // L48960 (lyd2)
    CreateDynamicObject(18879, 364.21054, -2158.06372, 10.65203, 0.00000, 0.00000, -121.14003); // L48961 (lyd2)
    CreateDynamicObject(18879, 362.63095, -2160.13013, 10.65203, 0.00000, 0.00000, -149.87991); // L48962 (lyd2)
    CreateDynamicObject(18879, 360.36526, -2161.11035, 10.65203, 0.00000, 0.00000, -191.03987); // L48963 (lyd2)
    CreateDynamicObject(18879, 357.87384, -2160.74023, 10.65203, 0.00000, 0.00000, -214.49988); // L48964 (lyd2)
    CreateDynamicObject(18879, 356.06296, -2159.25684, 10.65203, 0.00000, 0.00000, -258.89969); // L48965 (lyd2)
    CreateDynamicObject(18879, 355.16202, -2157.21045, 10.65203, 0.00000, 0.00000, -258.05984); // L48966 (lyd2)
    CreateDynamicObject(18879, 355.09671, -2155.01904, 10.65203, 0.00000, 0.00000, -286.43948); // L48967 (lyd2)
    CreateDynamicObject(1324, -1753.73096, -619.88928, 17.60860, 0.00000, 0.00000, -90.00000); // L49392 (lyd2)
    CreateDynamicObject(1324, -1768.81104, -619.88928, 17.60860, 0.00000, 0.00000, 90.00000); // L49393 (lyd2)
    CreateDynamicObject(1324, -2001.11462, 145.46530, 28.14950, 0.00000, 0.00000, -90.00000); // L49394 (lyd2)
    CreateDynamicObject(1324, -2011.87463, 145.46530, 28.14950, 0.00000, 0.00000, -90.00000); // L49395 (lyd2)
    CreateDynamicObject(1324, -2350.88452, -75.34860, 35.76590, 0.00000, 0.00000, 180.00000); // L49396 (lyd2)
    CreateDynamicObject(1324, -2350.88452, -65.20860, 35.78590, 0.00000, 0.00000, 0.00000); // L49397 (lyd2)
    CreateDynamicObject(1324, -2711.35205, 2.09120, 4.80350, 0.00000, 0.00000, 90.00000); // L49398 (lyd2)
    CreateDynamicObject(1324, -2701.61206, 2.09120, 4.78350, 0.00000, 0.00000, -90.00000); // L49399 (lyd2)
    CreateDynamicObject(1324, -1564.04590, 482.17050, 7.65400, 0.10000, 0.00000, -130.00000); // L49400 (lyd2)
    CreateDynamicObject(1324, -1576.31860, 490.28519, 7.65400, 0.10000, 0.00000, 60.00000); // L49401 (lyd2)
    CreateDynamicObject(1324, 1798.60059, 679.34583, 16.93130, 0.00000, 0.00000, -97.30000); // L49402 (lyd2)
    CreateDynamicObject(1324, 1769.11023, 684.26971, 17.29130, 0.00000, 0.00000, 90.30000); // L49403 (lyd2)
    CreateDynamicObject(1324, 1917.70923, 638.44830, 11.27390, 0.00000, 0.00000, 0.00000); // L49404 (lyd2)
    CreateDynamicObject(1324, 1917.70923, 628.00830, 11.27390, 0.00000, 0.00000, 180.00000); // L49405 (lyd2)
    CreateDynamicObject(1324, 1917.09058, 768.03497, 11.27390, 0.00000, 0.00000, 180.00000); // L49406 (lyd2)
    CreateDynamicObject(1324, 1917.09058, 778.45502, 11.27390, 0.00000, 0.00000, 0.00000); // L49407 (lyd2)
    CreateDynamicObject(1324, 2152.63867, 692.86243, 11.27390, 0.00000, 0.00000, -90.00000); // L49408 (lyd2)
    CreateDynamicObject(1324, 2142.19873, 692.86243, 11.27390, 0.00000, 0.00000, 90.00000); // L49409 (lyd2)
    CreateDynamicObject(1324, 2077.63306, 1393.56421, 11.27390, 0.00000, 0.00000, -90.00000); // L49410 (lyd2)
    CreateDynamicObject(1324, 2037.17310, 1393.56421, 11.27390, 0.00000, 0.00000, 90.00000); // L49411 (lyd2)
    CreateDynamicObject(1324, 1812.34973, 1993.14111, 5.13390, 0.00000, 0.00000, -90.00000); // L49412 (lyd2)
    CreateDynamicObject(1324, 1782.38965, 1993.14111, 5.13390, 0.00000, 0.00000, 90.00000); // L49413 (lyd2)
    CreateDynamicObject(1324, 2732.60010, 1662.03870, 7.11390, 0.00000, 0.00000, -90.00000); // L49414 (lyd2)
    CreateDynamicObject(1324, 2702.70020, 1662.03870, 7.11390, 0.00000, 0.00000, -90.00000); // L49415 (lyd2)
    CreateDynamicObject(1324, 1927.11963, 2543.57422, 7.11390, 0.00000, 0.00000, 20.00000); // L49416 (lyd2)
    CreateDynamicObject(1324, 1927.11963, 7.11390, 7.11390, 0.00000, 0.00000, 20.00000); // L49417 (lyd2)
    CreateDynamicObject(1324, 1934.44995, 2514.51904, 7.11390, 0.00000, 0.00000, -180.00000); // L49418 (lyd2)
    CreateDynamicObject(1324, 2037.72705, 2649.45410, 11.29370, 0.00000, 0.00000, 0.00000); // L49419 (lyd2)
    CreateDynamicObject(1324, 2037.72705, 2639.03418, 11.29370, 0.00000, 0.00000, 180.00000); // L49420 (lyd2)
    CreateDynamicObject(1324, 2027.75183, 2736.95947, 11.27110, 0.00000, 0.00000, 180.00000); // L49421 (lyd2)
    CreateDynamicObject(1324, 2027.75183, 2747.41943, 11.25110, 0.00000, 0.00000, 0.00000); // L49422 (lyd2)
    CreateDynamicObject(1324, 1597.07214, 2728.07520, 11.23400, 0.00000, 0.00000, 180.00000); // L49423 (lyd2)
    CreateDynamicObject(1324, 1597.07214, 2738.41528, 11.23400, 0.00000, 0.00000, 0.00000); // L49424 (lyd2)
    CreateDynamicObject(1324, 1527.04846, 2584.65723, 11.24970, 0.00000, 0.00000, 0.00000); // L49425 (lyd2)
    CreateDynamicObject(1324, 1527.12854, 2594.97729, 11.24970, 0.00000, 0.00000, 180.00000); // L49426 (lyd2)
    CreateDynamicObject(1324, 1327.00073, 2594.97803, 11.27760, 0.00000, 0.00000, 0.00000); // L49427 (lyd2)
    CreateDynamicObject(1324, 1327.00073, 2584.61792, 11.27760, 0.00000, 0.00000, 180.00000); // L49428 (lyd2)
    CreateDynamicObject(1324, 2498.3999, -2303, 25.2, 0, 0, 134); // L49430 (lyd2)
    CreateDynamicObject(1324, 2506.3999, -2295.8, 25.1, 0, 0, 314); // L49431 (lyd2)
    CreateDynamicObject(1324, 1967, -2094.5, 14, 0, 0, 270); // L49432 (lyd2)
    CreateDynamicObject(1324, 1956.3, -2094.7, 14, 0, 0, 89.5); // L49433 (lyd2)
    CreateDynamicObject(1324, 2027.2, -1927.1, 14, 0, 0, 0); // L49434 (lyd2)
    CreateDynamicObject(1324, 2026.7, -1942.6, 14, 0, 0, 178); // L49435 (lyd2)
    CreateDynamicObject(1324, 2320, -1653.5, 14.6, 0, 0, 0); // L49436 (lyd2)
    CreateDynamicObject(1324, 2320.2, -1664.4, 14.6, 0, 0, 182); // L49437 (lyd2)
    CreateDynamicObject(1324, 2033.1, -1747, 14, 0, 0, 0); // L49438 (lyd2)
    CreateDynamicObject(1324, 2032.5, -1757.5, 14, 0, 0, 180); // L49439 (lyd2)
    CreateDynamicObject(1324, 2112.8999, -1295.5, 24.5, 0, 0, 0); // L49440 (lyd2)
    CreateDynamicObject(1324, 2113, -1306.2, 24.5, 0, 0, 182); // L49441 (lyd2)
    CreateDynamicObject(1324, 1773.4, -1727.1, 14, 0, 0, 0); // L49442 (lyd2)
    CreateDynamicObject(1324, 1773, -1737.4, 14, 0, 0, 180); // L49443 (lyd2)
    CreateDynamicObject(1324, 1370.8, -1727, 14, 0, 0, 0); // L49444 (lyd2)
    CreateDynamicObject(1324, 1370.8, -1737.5, 14, 0, 0, 178); // L49445 (lyd2)
    CreateDynamicObject(1324, 1524.6, -1954.2, 20.5, 0, 0, 86); // L49446 (lyd2)
    CreateDynamicObject(1324, 1535.3, -1954, 20.3, 0, 0, 272); // L49447 (lyd2)
    CreateDynamicObject(1324, 1156.3, -1846.9, 14, 0, 0, 0); // L49448 (lyd2)
    CreateDynamicObject(1324, 1156, -1857.5, 14, 0, 0, 178); // L49449 (lyd2)
    CreateDynamicObject(1324, 1100.1, -1707, 14, 0, 0, 0); // L49450 (lyd2)
    CreateDynamicObject(1324, 1099.9, -1717.5, 14, 0, 0, 180); // L49451 (lyd2)
    CreateDynamicObject(1324, 1043.7, -2302, 13.6, 0, 0, 118); // L49452 (lyd2)
    CreateDynamicObject(1324, 1066.3, -2289.7, 13.6, 0, 0, 298); // L49453 (lyd2)
    CreateDynamicObject(1324, 655.29999, -1730.4, 14.4, 0, 0, 350); // L49454 (lyd2)
    CreateDynamicObject(1324, 648.70001, -1755.2, 13.9, 0, 0, 166); // L49455 (lyd2)
    CreateDynamicObject(1324, 546.29999, -1508.9, 15, 0, 0, 272); // L49456 (lyd2)
    CreateDynamicObject(1324, 524.29999, -1508.9, 15, 0, 0, 90); // L49457 (lyd2)
    CreateDynamicObject(1324, 514.79999, -1255.2, 16.7, 0, 0, 38); // L49458 (lyd2)
    CreateDynamicObject(1324, 526.5, -1272.1, 16.8, 0, 0, 216); // L49459 (lyd2)
    CreateDynamicObject(1324, 1090.1, -1577.5, 14, 0, 0, 180); // L49460 (lyd2)
    CreateDynamicObject(1324, 1090.3, -1567.1, 14, 0, 0, 2); // L49461 (lyd2)
    CreateDynamicObject(1324, 1013.6, -1390.1, 13.8, 0, 0, 0); // L49462 (lyd2)
    CreateDynamicObject(1324, 1013.5, -1411.1, 13.7, 0, 0, 180); // L49463 (lyd2)
    CreateDynamicObject(1324, 1337.4, -1374.9, 14.1, 0, 0, 90); // L49464 (lyd2)
    CreateDynamicObject(1324, 1362.9, -1375.1, 14.1, 0, 0, 270); // L49465 (lyd2)
    CreateDynamicObject(1324, 1373.8, -1058.3, 27.3, 0, 0, 266); // L49466 (lyd2)
    CreateDynamicObject(1324, 1347.9, -1056.4, 27.3, 0, 0, 84); // L49467 (lyd2)
    CreateDynamicObject(1324, 1258, -721.59998, 94.6, 0, 0, 24); // L49468 (lyd2)
    CreateDynamicObject(1324, 1261.2, -730.59998, 94.7, 0, 0, 202); // L49469 (lyd2)
    CreateDynamicObject(1324, 1125.5, -940, 43.4, 0, 0, 0); // L49470 (lyd2)
    CreateDynamicObject(1324, 1126.8, -961, 43.2, 0, 0, 184); // L49471 (lyd2)
    CreateDynamicObject(1324, 1141.1, -1033.9, 32.5, 0, 0, 0); // L49472 (lyd2)
    CreateDynamicObject(1324, 1140.7, -1044.7, 32.4, 0, 0, 178); // L49473 (lyd2)
    CreateDynamicObject(1324, 1000, -1135.4, 24.3, 0, 0, 0); // L49474 (lyd2)
    CreateDynamicObject(1324, 998.79999, -1154.8, 24.3, 0, 0, 182); // L49475 (lyd2)
    CreateDynamicObject(1324, 791.79999, -1370.4, 14, 0, 0, 88); // L49476 (lyd2)
    CreateDynamicObject(1324, 802.70001, -1370.7, 14, 0, 0, 272); // L49477 (lyd2)
    CreateDynamicObject(1324, 2902.2, -856.79999, 11.5, 0, 0, 268); // L49478 (lyd2)
    CreateDynamicObject(1324, 2866, -856.40002, 11.6, 0, 0, 88); // L49479 (lyd2)
    CreateDynamicObject(1323, 1480.6, -967.70001, 37.1, 0, 0, 152); // L49480 (lyd2)
    CreateDynamicObject(1323, 1717.5, -692, 46.3, 0, 0, 264); // L49481 (lyd2)
    CreateDynamicObject(1323, 1692, -688.20001, 46.3, 0, 0, 80); // L49482 (lyd2)
    CreateDynamicObject(1323, 1594.1, -1760.7, 28.3, 0, 0, 102); // L49483 (lyd2)
    CreateDynamicObject(1323, 1624.6, -1756.2, 28.4, 0, 0, 280); // L49484 (lyd2)
    CreateDynamicObject(1323, 1963.8, -1492.6, 4, 0, 0, 0); // L49485 (lyd2)
    CreateDynamicObject(1323, 1963.7, -1522.6, 4, 0, 0, 182); // L49486 (lyd2)
    CreateDynamicObject(8548, 1558.15564, -1737.48230, 13.75410, 0.00000, 0.00000, 265.49109); // L49488 (lyd2)
    CreateDynamicObject(8548, 1558.15564, -1726.94690, 13.75410, 0.00000, 0.00000, 85.52088); // L49489 (lyd2)
    CreateDynamicObject(8548, 1434.65601, -1662.11084, 13.75410, 0.00000, 0.00000, 0.00000); // L49490 (lyd2)
    CreateDynamicObject(8548, 1424.29236, -1662.36926, 13.75410, 0.00000, 0.00000, -178.00000); // L49491 (lyd2)
    CreateDynamicObject(8548, 1447.63989, -1597.48877, 13.75410, 0.00000, 0.00000, 268.51483); // L49492 (lyd2)
    CreateDynamicObject(8548, 1447.63989, -1587.06335, 13.75410, 0.00000, 0.00000, 85.34580); // L49493 (lyd2)
    CreateDynamicObject(8548, 1543.63818, -1597.68958, 13.75410, 0.00000, 0.00000, 272.20981); // L49494 (lyd2)
    CreateDynamicObject(8548, 1543.63818, -1586.82422, 13.75410, 0.00000, 0.00000, 85.25610); // L49495 (lyd2)
    CreateDynamicObject(8548, 1418.56360, -1726.93066, 13.68501, 0.00000, 0.00000, 86.50762); // L49496 (lyd2)
    CreateDynamicObject(8548, 1418.56360, -1737.53503, 13.68500, 0.00000, 0.00000, 264.23343); // L49497 (lyd2)
    CreateDynamicObject(963, 1351.64575, -1270.84008, 13.41868, 90.00000, 0.00000, 0.00000); // L49541 (lyd2)
    CreateDynamicObject(963, 1523.273559, -1799.463867, 13.636719, 89.699981, 89.302856, 179.996978); // L49542 (lyd2)
    CreateDynamicObject(963, 1431.887084, -1798.368774, 13.632292, 89.699981, 89.302856, 0.597012); // L49543 (lyd2)
    return 1;
}

// ---- Pickups (86 elements) ----
stock Lyd2_LoadPickups()
{
    CreateDynamicPickup(1239, 1, -38.4148, 56.1184, 3.1172); // L6095 (lyd2)
    CreateDynamicPickup(1239, 1, 1678.1671, 2358.7722, 10.8203); // L6096 (lyd2)
    CreateDynamicPickup(1239, 1, 2348.1086, -2302.4243, 13.5469); // L6098 (lyd2)
    CreateDynamicPickup(19346, 23, -824.9174, 1915.1334, 22.9245); // L6416 (lyd2)
    CreateDynamicPickup(19197, 1, 377.213928, -192.850128, 1000.640100); // L6419 (lyd2)
    CreateDynamicPickup(19197, 1, 1038.3171, -1339.7793, 13.7266); // L6420 (lyd2)
    CreateDynamicPickup(19197, 1, 2305.8259, -16.1325, 26.7496); // L6421 (lyd2)
    CreateDynamicPickup(1318, 1, 2127.5486, 2378.9626, 10.8203); // L6423 (lyd2)
    CreateDynamicPickup(1318, 1, -2636.6230, 1403.3202, 906.4609); // L6424 (lyd2)
    CreateDynamicPickup(19197, 1, 1571.2114, -1336.6027, 16.4844); // L6426 (lyd2)
    CreateDynamicPickup(19197, 1, 1726.6801, -1638.5601, 20.2233); // L6428 (lyd2)
    CreateDynamicPickup(19197, 1, 1489.0573, -1771.7749, 18.7958); // L6429 (lyd2)
    CreateDynamicPickup(19197, 1, -2029.8124, -119.0646, 1035.1719); // L6430 (lyd2)
    CreateDynamicPickup(19197, 1, -2026.8407, -104.1143, 1035.1719); // L6431 (lyd2)
    CreateDynamicPickup(19197, 1, 305.3869, -158.9812, 999.5938); // L6432 (lyd2)
    CreateDynamicPickup(19197, 1, 1221.9672, -1812.2772, 16.5938); // L6433 (lyd2)
    CreateDynamicPickup(19197, 1, 1234.1289, -1784.0337, 33.6312); // L6434 (lyd2)
    CreateDynamicPickup(18635, 1, -382.0342, -1426.4521, 26.0822); // L6436 (lyd2)
    CreateDynamicPickup(18635, 1, -1632.7894, -2239.3267, 31.4766); // L6437 (lyd2)
    CreateDynamicPickup(19197, 1, 285.79, -85.8, 1001.52); // L6438 (lyd2)
    CreateDynamicPickup(19197, 1, 316.42, -169.41, 999.59); // L6439 (lyd2)
    CreateDynamicPickup(19197, 1, 286.14, -40.63, 1001.52); // L6440 (lyd2)
    CreateDynamicPickup(1239, 1, 808.8542, -1347.3077, 13.5416); // L6444 (lyd2)
    CreateDynamicPickup(1239, 1, 1754.412963, -1592.894897, 13.532833); // L6447 (lyd2)
    CreateDynamicPickup(1239, 1, 1683.024658, -1022.939270, 1340.750854); // L6450 (lyd2)
    CreateDynamicPickup(1239, 1, 822.3183, 1.8747, 1004.1797); // L6454 (lyd2)
    CreateDynamicPickup(1239, 1, 2316.4529, -12.6540, 26.7422); // L6455 (lyd2)
    CreateDynamicPickup(1239, 1, 2316.3318, -9.9532, 26.7422); // L6456 (lyd2)
    CreateDynamicPickup(1239, 1, -2158.7920, 642.9232, 1052.3750); // L6457 (lyd2)
    CreateDynamicPickup(1247, 1, 2268.1128, 2448.0073, 3.5313); // L6458 (lyd2)
    CreateDynamicPickup(1239, 1, -2656.1047, 1416.0248, 906.2734); // L6460 (lyd2)
    CreateDynamicPickup(1240, 1, -2653.5183, 1413.5085, 906.2734); // L6462 (lyd2)
    CreateDynamicPickup(1239, 1, -1857.7711, -1616.8975, 21.8372); // L6463 (lyd2)
    CreateDynamicPickup(1239, 1, -258.9534, -2181.9905, 29.0150); // L6464 (lyd2)
    CreateDynamicPickup(1318, 1, -1548.0554, 125.1203, 3.5547); // L6466 (lyd2)
    CreateDynamicPickup(1239, 1, 1412.1915, -1700.3817, 13.5395); // L6467 (lyd2)
    CreateDynamicPickup(1239, 1, 2008.1722, 1169.3364, 10.8203); // L6468 (lyd2)
    CreateDynamicPickup(1239, 1, 2160.4111, -98.0815, 2.8239); // L6469 (lyd2)
    CreateDynamicPickup(1239, 1, -2033.1216, -117.4597, 1035.1719); // L6470 (lyd2)
    CreateDynamicPickup(1239, 1, 1248.3843, -1833.8750, 13.3930); // L6471 (lyd2)
    CreateDynamicPickup(1239, 1, 1138.9730, -1820.9103, 33.6354); // L6472 (lyd2)
    CreateDynamicPickup(1239, 1, 1.5613, -2510.2061, 36.6555); // L6473 (lyd2)
    CreateDynamicPickup(3798, 1, 2571.6233, -2226.6980, 13.3550); // L6475 (lyd2)
    CreateDynamicPickup(3798, 1, 2187.6926, -2263.8967, 13.4674); // L6476 (lyd2)
    CreateDynamicPickup(3798, 1, -1034.6223, -626.2365, 32.0078); // L6477 (lyd2)
    CreateDynamicPickup(3798, 1, 2482.8813, -2084.2239, 13.5469); // L6478 (lyd2)
    CreateDynamicPickup(1299, 1, 577.4390, 1221.7273, 11.2689); // L6479 (lyd2)
    CreateDynamicPickup(1650, 1, 268.9609, 1384.2981, 10.1610); // L6480 (lyd2)
    CreateDynamicPickup(1277, 1, 764.9532, 347.7378, 20.0458); // L6483 (lyd2)
    CreateDynamicPickup(1275, 1, -90.4999, -10.3628, 3.1094); // L6491 (lyd2)
    CreateDynamicPickup(1275, 1, 2046.2723, -1913.2064, 13.5469); // L6492 (lyd2)
    CreateDynamicPickup(1275, 1, 2118.6157, -2085.0828, 13.5544); // L6493 (lyd2)
    CreateDynamicPickup(1275, 1, 831.2045, 865.6005, 12.5911); // L6495 (lyd2)
    CreateDynamicPickup(1275, 1, 1551.5492, -1005.0830, 24.0781); // L6496 (lyd2)
    CreateDynamicPickup(1275, 1, 1021.9334, -1371.0099, 13.5585); // L6497 (lyd2)
    CreateDynamicPickup(1275, 1, 2117.3662, -1790.0100, 13.5547); // L6498 (lyd2)
    CreateDynamicPickup(1275, 1, 2417.1555, -1220.1472, 25.3914); // L6499 (lyd2)
    CreateDynamicPickup(1275, 1, 1735.0045, -1944.0450, 13.5681); // L6500 (lyd2)
    CreateDynamicPickup(1275, 1, 2384.0181, -1915.5509, 13.5469); // L6501 (lyd2)
    CreateDynamicPickup(1275, 1, 980.6174, -933.2461, 41.3419); // L6503 (lyd2)
    CreateDynamicPickup(1275, 1, 1945.9237, -1793.6355, 13.5469); // L6504 (lyd2)
    CreateDynamicPickup(1275, 1, 662.6830, -579.0665, 16.3359); // L6505 (lyd2)
    CreateDynamicPickup(1275, 1, -93.9144, -1196.9713, 2.4775); // L6506 (lyd2)
    CreateDynamicPickup(19627, 1, 1782.8275, -1702.7240, 13.5096); // L6510 (lyd2)
    CreateDynamicPickup(1240, 1, 373.7167, -119.1190, 1001.4922); // L6511 (lyd2)
    CreateDynamicPickup(1240, 1, 377.1597, -67.7632, 1001.5151); // L6516 (lyd2)
    CreateDynamicPickup(1240, 1, 376.5080, -67.6393, 1001.5151); // L6521 (lyd2)
    CreateDynamicPickup(1239, 1, 2.2396, -29.0123, 1003.5494); // L6527 (lyd2)
    CreateDynamicPickup(1239, 1, 296.4476, -37.9833, 1001.5156); // L6532 (lyd2)
    CreateDynamicPickup(1239, 1, 312.1370, -165.9137, 999.6010); // L6533 (lyd2)
    CreateDynamicPickup(1239, 1, 295.5200, -80.3668, 1001.5156); // L6534 (lyd2)
    CreateDynamicPickup(1239, 1, 206.3740, -8.2494, 1001.2109); // L6536 (lyd2)
    CreateDynamicPickup(1239, 1, 161.4726, -83.2517, 1001.8047); // L6537 (lyd2)
    CreateDynamicPickup(1239, 1, 207.7187, -100.5032, 1005.2578); // L6538 (lyd2)
    CreateDynamicPickup(1239, 1, 1702.9427, -1470.3704, 13.5469); // L6539 (lyd2)
    CreateDynamicPickup(1239, 1, 1763.4915, 2080.2959, 10.8203); // L6540 (lyd2)
    CreateDynamicPickup(1239, 1, -2653.6023, 1407.0844, 906.2734); // L6541 (lyd2)
    CreateDynamicPickup(1239, 1, 2309.3276, -8.2968, 26.7422); // L6542 (lyd2)
    CreateDynamicPickup(1239, 1, 1455.8802, -1741.8704, 13.5469); // L6543 (lyd2)
    CreateDynamicPickup(1239, 1, 1151.7448, -1203.0283, 19.5159); // L6545 (lyd2)
    CreateDynamicPickup(1279, 1, 645.3646, -521.5663, 16.3359); // L6549 (lyd2)
    CreateDynamicPickup(1279, 1, 635.8752, 862.5970, -42.6892); // L6550 (lyd2)
    CreateDynamicPickup(1279, 1, 607.7939, 863.4465, -42.0452); // L6551 (lyd2)
    CreateDynamicPickup(1279, 1, 382.3929, 871.6203, 21.9523); // L6552 (lyd2)
    CreateDynamicPickup(1239, 1, -111.0688, 1133.3749, 19.7422); // L6679 (lyd2)
    CreateDynamicPickup(1239, 1, -66.3187, -1121.1329, 0.6501); // L6681 (lyd2)
    return 1;
}

// ---- Panneaux 3D (102 elements) ----
stock Lyd2_LoadLabels()
{
    // Panneau L6094 omis : le texte d'origine ("lagerstr") est genere dynamiquement dans lyd2
    // (stock de pieces d'armes en temps reel) et ne peut pas etre reproduit tel quel ici.
    CreateDynamic3DTextLabel(COLOR_HEX_BLUE"Waffenteile-Pakete\n"COLOR_HEX_WHITE"Tippe /WPakete um Pakete zu entnehmen", COLOR_WHITE, 1678.1671, 2358.7722, 10.8203, 15.0); // L6097 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_BLUE"Waffenteile-Pakete\n"COLOR_HEX_WHITE"Tippe /Paketeinladen um Pakete zu entnehmen", COLOR_WHITE, 2348.1086, -2302.4243, 13.5469, 15.0); // L6099 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Starterpack\n"COLOR_HEX_WHITE"Tippe /Starterpack", COLOR_WHITE, 808.8542, -1347.3077, 13.5416, 8.0); // L6443 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Asservatenkammer - Illegale Gegenstände abgeben\n"COLOR_HEX_WHITE"Tippe /Abgeben [Waffenteile/Spice/Drogen/WCodes]", COLOR_WHITE, 1754.412963, -1592.894897, 13.532833, 8.0); // L6446 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Bankschalter\n"COLOR_HEX_WHITE"Tippe /Bank\nTippe /Kredit\nTippe /Ueberweisen", COLOR_WHITE, 1683.024658, -1022.939270, 1340.750854, 8.0); // L6449 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Staats-Reparatur\n"COLOR_HEX_WHITE"Tippe /Staatrepair", COLOR_WHITE, 2288.5466, 2444.9841, 3.2734, 10.0); // L6554 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Staats-Reparatur\n"COLOR_HEX_WHITE"Tippe /Staatrepair", COLOR_WHITE, 621.3207, -584.6555, 17.2330, 10.0); // L6555 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Staats-Reparatur\n"COLOR_HEX_WHITE"Tippe /Staatrepair", COLOR_WHITE, 1248.3843, -1833.8750, 13.3930, 10.0); // L6556 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Staats-Reparatur\n"COLOR_HEX_WHITE"Tippe /Staatrepair", COLOR_WHITE, 1138.9730, -1820.9103, 33.6354, 10.0); // L6557 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Staats-Reparatur\n"COLOR_HEX_WHITE"Tippe /Staatrepair", COLOR_WHITE, 1.5613, -2510.2061, 36.6555, 10.0); // L6558 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Fahrgeschäft: Fallturm\n"COLOR_HEX_WHITE"Tippe /Ticketkaufen\n"COLOR_HEX_BLUE"Ticketpreis: 300$", COLOR_WHITE, 374.6658, -2121.6416, 7.8820, 10.0); // L6562 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Fahrgeschäft: Autosscooter\n"COLOR_HEX_WHITE"Tippe /Ticketkaufen\n"COLOR_HEX_BLUE"Ticketpreis: 300$", COLOR_WHITE, 373.8057, -2056.3586, 7.9260, 10.0); // L6563 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Fahrgeschäft:  Breakdancer\n"COLOR_HEX_WHITE"Tippe /Ticketkaufen\n"COLOR_HEX_BLUE"Ticketpreis: 300$", COLOR_WHITE, 356.7114, -2149.5613, 7.8779, 10.0); // L6564 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Fahrgeschäft: Schaukelschiff\n"COLOR_HEX_WHITE"Tippe /Ticketkaufen\n"COLOR_HEX_BLUE"Ticketpreis: 300$", COLOR_WHITE, 382.0282, -2165.8818, 7.8511, 10.0); // L6565 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Fahrgeschäft: Wasserbahn\n"COLOR_HEX_WHITE"Tippe /Ticketkaufen\n"COLOR_HEX_BLUE"Ticketpreis: 300$", COLOR_WHITE, 396.3516, -2152.5928, 7.8399, 10.0); // L6566 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Sprungturm\n"COLOR_HEX_BLUE"Drück 'Enter'\n", COLOR_WHITE, 361.7136, -2107.5913, 7.8340, 10.0); // L6567 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Arbeitskleidung für Bauern\n"COLOR_HEX_WHITE"Tippe /Jobkleidung", COLOR_WHITE, -90.4999, -10.3628, 3.1094, 25.0); // L6570 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Arbeitskleidung für Straßenreiniger\n"COLOR_HEX_WHITE"Tippe /Jobkleidung", COLOR_WHITE, 2046.2723, -1913.2064, 13.5469, 25.0); // L6571 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Arbeitskleidung für Müllmann\n"COLOR_HEX_WHITE"Tippe /Jobkleidung", COLOR_WHITE, 2118.6157, -2085.0828, 13.5544, 25.0); // L6572 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Arbeitskleidung für Bauarbeiter\n"COLOR_HEX_WHITE"Tippe /Jobkleidung", COLOR_WHITE, 831.2045, 865.6005, 12.5911, 25.0); // L6573 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Arbeitskleidung für Geldtransportfahrer\n"COLOR_HEX_WHITE"Tippe /Jobkleidung", COLOR_WHITE, 1551.5492, -1005.0830, 24.0781, 25.0); // L6574 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Arbeitskleidung für Eisverkäufer\n"COLOR_HEX_WHITE"Tippe /Jobkleidung", COLOR_WHITE, 1021.9334, -1371.0099, 13.5585, 25.0); // L6575 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Arbeitskleidung für Pizzalieferrant\n"COLOR_HEX_WHITE"Tippe /Jobkleidung", COLOR_WHITE, 2117.3662, -1790.0100, 13.5547, 25.0); // L6576 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Arbeitskleidung für Prostituierte\n"COLOR_HEX_WHITE"Tippe /Jobkleidung", COLOR_WHITE, 2417.1555, -1220.1472, 25.3914, 25.0); // L6577 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Arbeitskleidung für Zugfahrer\n"COLOR_HEX_WHITE"Tippe /Jobkleidung", COLOR_WHITE, 1735.0045, -1944.0450, 13.5681, 25.0); // L6578 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Arbeitskleidung für Hotdog Verkäufer\n"COLOR_HEX_WHITE"Tippe /Jobkleidung", COLOR_WHITE, 2384.0181, -1915.5509, 13.5469, 25.0); // L6579 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Arbeitskleidung für Mechaniker\n"COLOR_HEX_WHITE"Tippe /Jobkleidung", COLOR_WHITE, 980.6174, -933.2461, 41.3419, 25.0); // L6580 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Arbeitskleidung für Mechaniker\n"COLOR_HEX_WHITE"Tippe /Jobkleidung", COLOR_WHITE, 1945.9237, -1793.6355, 13.5469, 25.0); // L6581 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Arbeitskleidung für Mechaniker\n"COLOR_HEX_WHITE"Tippe /Jobkleidung", COLOR_WHITE, 662.6830, -579.0665, 16.3359, 25.0); // L6582 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Arbeitskleidung für Mechaniker\n"COLOR_HEX_WHITE"Tippe /Jobkleidung", COLOR_WHITE, -93.9144, -1196.9713, 2.4775, 25.0); // L6583 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_BLUE"Bauarbeiter\n"COLOR_HEX_WHITE"Tippe /Steineladen", COLOR_WHITE, 635.8752, 862.5970, -42.6892, 10.0); // L6588 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_BLUE"Bauarbeiter\n"COLOR_HEX_WHITE"Tippe /Steineladen", COLOR_WHITE, 607.7939, 863.4465, -42.0452, 10.0); // L6589 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_BLUE"Bauarbeiter\n"COLOR_HEX_WHITE"Tippe /Steineentladen", COLOR_WHITE, 382.3929, 871.6203, 21.9523, 10.0); // L6590 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_BLUE"Waren-Vergabe Las Venturas\n"COLOR_HEX_WHITE"Tippe /Loadwaren", COLOR_WHITE, 577.4390, 1221.7273, 11.2689, 20.0); // L6591 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_BLUE"Öl-Raffinerie Las Venturas\n"COLOR_HEX_WHITE"Tippe /Loadbenzin", COLOR_WHITE, 268.9609, 1384.2981, 10.1610, 20.0); // L6592 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_BLUE"Terroristen Spawn\n"COLOR_HEX_WHITE"Tippe /Terrorwaffen zum Ausrüsten\nTippe /Gheilen zum heilen", COLOR_WHITE, 969.3871, 2056.1943, 10.8203, 15.0); // L6594 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_BLUE"Fahrschule\n"COLOR_HEX_WHITE"Gebäude betreten mit 'Enter'", COLOR_WHITE, 1489.0573, -1771.7749, 18.7958, 20.0); // L6597 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Paintball - Anlage\n"COLOR_HEX_WHITE"Gebäude betreten mit 'Enter'", COLOR_WHITE, 1738.5869, -1586.3961, 13.5555, 8.0); // L6598 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Spritlager der Nine Demons\n"COLOR_HEX_WHITE"Tippe /Spritlager", COLOR_WHITE, 764.9532, 347.7378, 20.0458, 8.0); // L6601 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"SERVER - EXPERTE\nFreischalten mit:"COLOR_HEX_WHITE"/Experte", COLOR_WHITE, 808.7208, -1350.4906, 13.5418, 15.0); // L6604 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"OSTER-AKTION im LyD-Shop\n"COLOR_HEX_GREEN"Es erwarten dich tolle Preise!\n"COLOR_HEX_WHITE"Weitere Informationen im Forum!", COLOR_WHITE, 1480.9296, -1613.7988, 14.0979, 25.0); // L6605 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"POSTHAUS - Eingang\n"COLOR_HEX_WHITE"Betreten mit 'Enter'", COLOR_WHITE, 914.3174, -1004.0942, 37.9902, 25.0); // L6606 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_BLUE"POSTHAUS\n"COLOR_HEX_WHITE"Tippe /Post", COLOR_WHITE, 822.3183, 1.8747, 1004.1797, 15.0); // L6607 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_BLUE"Schmied (Befreit von Handschellen)\n"COLOR_HEX_WHITE"Tippe /Zerbrechen\n"COLOR_HEX_ORANGE"Preis: 500$", COLOR_WHITE, -382.0342, -1426.4521, 26.0822, 25.0); // L6608 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_GREENA"Werbeagentur\n"COLOR_HEX_WHITE"Tippe /Werbung", COLOR_WHITE, 1412.1915, -1700.3817, 13.5395, 15.0); // L6609 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_GREENA"Werbeagentur\n"COLOR_HEX_WHITE"Tippe /Werbung", COLOR_WHITE, 2008.1722, 1169.3364, 10.8203, 15.0); // L6610 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Motorradlackiererei\n"COLOR_HEX_ORANGE"Preis: 2.000$\n"COLOR_HEX_WHITE"Tippe /Bikefarbe", COLOR_WHITE, 1702.9427, -1470.3704, 13.5469, 20.0); // L6611 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Autolackiererei\n"COLOR_HEX_ORANGE"Preis: 1.500$\n"COLOR_HEX_WHITE"Tippe /Autofarbe", COLOR_WHITE, 1763.4915, 2080.2959, 10.8203, 20.0); // L6612 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Abbauwerkstatt\nfür Auto- u. Motorradtuning\n"COLOR_HEX_ORANGE"Preis: 3.000$\n"COLOR_HEX_WHITE"Tippe /Tuningabbauen", COLOR_WHITE, 1782.8275, -1702.7240, 13.5096, 20.0); // L6613 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_BLUE"Entladungspunkt\n"COLOR_HEX_WHITE"Tippe /Paketentladen", COLOR_WHITE, -1857.7711, -1616.8975, 21.8372, 10.0); // L6615 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_BLUE"Entladungspunkt\n"COLOR_HEX_WHITE"Tippe /Samenpaketentladen", COLOR_WHITE, -258.9534, -2181.9905, 29.0150, 10.0); // L6616 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Fahrschule Los Santos\n"COLOR_HEX_WHITE"Tippe /Fahrpruefung\nTippe /Sperrefreikaufen", COLOR_WHITE, -2033.1216, -117.4597, 1035.1719, 40.0); // L6617 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Paintball - Anlage\nGebäude verlassen mit 'Enter'", COLOR_BLUE, 2169.8208, 1618.7504, 999.9766, 15.0); // L6618 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_BLUE"Gangjail\n"COLOR_HEX_WHITE"Tippe /Gangjail um einzusperren\nTippe /Aufbrechen um zu befreien", COLOR_WHITE, 2160.4111, -98.0815, 2.8239, 13.0); // L6620 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_GREENA"Die Clubvilla\n"COLOR_HEX_WHITE"Zutritt nur für Clubmitglieder", COLOR_WHITE, 2127.5486, 2378.9626, 10.8203, 20.0); // L6621 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_BLUE"Informationen zum Stadtamt\n"COLOR_HEX_WHITE"Tippe /Stadtamtinfo", COLOR_WHITE, 1481.7039, -1740.6183, 13.5469, 30.0); // L6623 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Los Santos 4 Sterne Hotel\n"COLOR_HEX_WHITE"Miete Dir günstig ein schönes Hotelzimmer", COLOR_WHITE, 1722.5425, -1650.1168, 20.2289, 20.0); // L6624 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Fahrzeug Zulassungsstelle\n"COLOR_HEX_WHITE"Schalter 1\nTippe /Zulassungsstelle", COLOR_WHITE, 2316.4529, -12.6540, 26.7422, 15.0); // L6625 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Fahrzeug Zulassungsstelle\n"COLOR_HEX_WHITE"Schalter 2\nTippe /Zulassungsstelle", COLOR_WHITE, 2316.3318, -9.9532, 26.7422, 15.0); // L6626 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Einwohnermeldeamt\n"COLOR_HEX_WHITE"Schalter 1", COLOR_WHITE, 359.0863, 210.2258, 1008.3828, 15.0); // L6627 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Einwohnermeldeamt\n"COLOR_HEX_WHITE"Schalter 2", COLOR_WHITE, 358.2361, 184.5094, 1008.3828, 15.0); // L6628 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"LOS SANTOS - FAHRSCHULE", COLOR_WHITE, 1270.0138, -1846.0366, 13.3906, 20.0); // L6629 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_BLUE"Las Venturas - Bahnhof NORD\n"COLOR_HEX_WHITE"Bitte halten Sie Abstand von der Bahnsteigkante und\n"COLOR_HEX_WHITE"betreten Sie erst den Bahnsteig nach Halt des Zuges!", COLOR_WHITE, 1433.3264, 2640.8018, 11.3926, 18.0); // L6630 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_BLUE"Las Venturas - Bahnhof OST\n"COLOR_HEX_WHITE"Bitte halten Sie Abstand von der Bahnsteigkante und\n"COLOR_HEX_WHITE"betreten Sie erst den Bahnsteig nach Halt des Zuges!", COLOR_WHITE, 2859.5542, 1290.5511, 11.3906, 18.0); // L6631 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_BLUE"San Fierro - Hauptbahnhof\n"COLOR_HEX_WHITE"Bitte halten Sie Abstand von der Bahnsteigkante und\n"COLOR_HEX_WHITE"betreten Sie erst den Bahnsteig nach Halt des Zuges!", COLOR_WHITE, -1952.0848, 137.6278, 26.2813, 18.0); // L6632 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_BLUE"Los Santos - Bahnhof NORD\n"COLOR_HEX_WHITE"Bitte halten Sie Abstand von der Bahnsteigkante und\n"COLOR_HEX_WHITE"betreten Sie erst den Bahnsteig nach Halt des Zuges!", COLOR_WHITE, 816.9464, -1362.2501, -0.5078, 18.0); // L6633 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_BLUE"Los Santos - Hauptbahnhof\n"COLOR_HEX_WHITE"Bitte halten Sie Abstand von der Bahnsteigkante und\n"COLOR_HEX_WHITE"betreten Sie erst den Bahnsteig nach Halt des Zuges!", COLOR_WHITE, 1738.0658, -1949.8571, 14.1172, 18.0); // L6634 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_BLUE"Clubvilla Bar\n"COLOR_HEX_WHITE"Tippe /Getraenk", COLOR_WHITE, -2653.6023, 1407.0844, 906.2734, 10.0); // L6637 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Getränkestand\n"COLOR_HEX_WHITE"Tippe /Getraenk", COLOR_WHITE, 1455.8802, -1741.8704, 13.5469, 10.0); // L6639 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Club Waffenshop\n"COLOR_HEX_WHITE"Tippe /Clubwaffen", COLOR_WHITE, -2656.1047, 1416.0248, 906.2734, 8.0); // L6640 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Club Kueche\n"COLOR_HEX_WHITE"Tippe /Clubheal", COLOR_WHITE, -2653.5183, 1413.5085, 906.2734, 8.0); // L6641 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_BLUE"KFZ-Versicherung\n"COLOR_HEX_WHITE"Keine Reparaturkosten für 7 Tage! Preis: $50.000\nTippe /Kfzversicherung", COLOR_WHITE, 2309.3276, -8.2968, 26.7422, 25.0); // L6642 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_BLUE"Flugzeugverkauf - Las Venturas\n"COLOR_HEX_WHITE"Steige in ein beliebiges Flugzeug deiner Wahl ein!", COLOR_WHITE, 1310.9393, 1342.6803, 10.8203, 30.0); // L6643 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_BLUE"Kleidungs Shop\n"COLOR_HEX_WHITE"Tippe /Kleidung", COLOR_WHITE, 206.3740, -8.2494, 1001.2109, 11.0); // L6646 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_BLUE"Kleidungs Shop\n"COLOR_HEX_WHITE"Tippe /Kleidung", COLOR_WHITE, 161.4726, -83.2517, 1001.8047, 11.0); // L6647 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_BLUE"Kleidungs Shop\n"COLOR_HEX_WHITE"Tippe /Kleidung", COLOR_WHITE, 207.7187, -100.5032, 1005.2578, 11.0); // L6648 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_BLUE"CLUB Waffenshop\n"COLOR_HEX_WHITE"Tippe /Cwmenu", COLOR_WHITE, -2165.6643, 646.1125, 1052.3750, 10.0); // L6649 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_BLUE"Waffen Laden\n"COLOR_HEX_WHITE"Tippe /Wmenu", COLOR_WHITE, 313.3604, -139.3339, 1004.0625, 10.0); // L6650 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_BLUE"Waffen Laden\n"COLOR_HEX_WHITE"Tippe /Wmenu", COLOR_WHITE, 296.4476, -37.9833, 1001.5156, 10.0); // L6651 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_BLUE"Waffen Laden\n"COLOR_HEX_WHITE"Tippe /Wmenu", COLOR_WHITE, 312.1370, -165.9137, 999.6010, 10.0); // L6652 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_BLUE"Waffen Laden\n"COLOR_HEX_WHITE"Tippe /Wmenu", COLOR_WHITE, 295.5200, -80.3668, 1001.5156, 10.0); // L6653 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_BLUE"CLUB Küche\n"COLOR_HEX_WHITE"Tippe /Cheilen", COLOR_WHITE, -2160.3027, 638.3347, 1057.5861, 10.0); // L6654 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_BLUE"Super Markt\n"COLOR_HEX_WHITE"Tippe /Supermarkt", COLOR_WHITE, 2.2396, -29.0123, 1003.5494, 10.0); // L6655 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_BLUE"Pizza Stack\n"COLOR_HEX_WHITE"Tippe /Essen\n"COLOR_HEX_ORANGE"Preis: 50$", COLOR_WHITE, 373.7167, -119.1190, 1001.4922, 10.0); // L6661 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_BLUE"Cluckin Bell\n"COLOR_HEX_WHITE"Tippe /Essen\n"COLOR_HEX_ORANGE"Preis: 50$", COLOR_WHITE, 368.1664, -6.0193, 1001.8516, 10.0); // L6666 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_BLUE"Burger Shot\n"COLOR_HEX_WHITE"Tippe /Essen\n"COLOR_HEX_ORANGE"Preis: 50$", COLOR_WHITE, 376.5080, -67.6393, 1001.5151, 10.0); // L6671 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_BLUE"Subway\n"COLOR_HEX_WHITE"Tippe /Essen\n"COLOR_HEX_ORANGE"Preis: 50$", COLOR_WHITE, 376.5080, -67.6393, 1001.5151, 10.0); // L6676 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_BLUE"Samen-Pakete\n"COLOR_HEX_WHITE"Tippe /Paketeinladen um Pakete zu entnehmen", COLOR_WHITE, -111.0688, 1133.3749, 19.7422, 15.0); // L6680 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_BLUE"Samen-Pakete\n"COLOR_HEX_WHITE"Tippe /Paketentladen um Pakete auszuladen", COLOR_WHITE, -66.3187, -1121.1329, 0.6501, 15.0); // L6682 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_BLUE"Peilsender-Verkauf\n"COLOR_HEX_WHITE"Tippe /Peilsender", COLOR_WHITE, 1151.7448, -1203.0283, 19.5159, 25.0); // L6684 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Schwarzmarkt: Waffenteile\n"COLOR_HEX_WHITE"Tippe /Schwarzmarkt", COLOR_WHITE, -1101.9084, -2861.1260, 61.1270, 5.0); // L6687 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Schwarzmarkt: Drogen\n"COLOR_HEX_WHITE"Tippe /Schwarzmarkt", COLOR_WHITE, -1104.9402, -2861.1267, 61.1270, 5.0); // L6688 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Schwarzmarkt: Spice\n"COLOR_HEX_WHITE"Tippe /Schwarzmarkt", COLOR_WHITE, -1098.8091, -2861.1267, 61.1270, 5.0); // L6689 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Schwarzmarkt: Wantedcodes\n"COLOR_HEX_WHITE"Tippe /Schwarzmarkt", COLOR_WHITE, -1098.1770, -2858.3450, 61.1270, 5.0); // L6690 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Schwarzmarkt: Waffen\n"COLOR_HEX_WHITE"Tippe /Schwarzmarkt", COLOR_WHITE, -1098.1770, -2855.7100, 61.1270, 5.0); // L6691 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Schwarzmarkt: Illegale Gegenstände\n"COLOR_HEX_WHITE"Tippe /Schwarzmarkt", COLOR_WHITE, -1098.7355, -2854.2180, 61.1343, 5.0); // L6692 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Schwarzmarkt: Kennzeichen\n"COLOR_HEX_WHITE"Tippe /Schwarzmarkt", COLOR_WHITE, -1101.9292, -2854.2185, 61.1343, 5.0); // L6693 (lyd2)
    CreateDynamic3DTextLabel(COLOR_HEX_YELLOW"Schwarzmarkt: SIM-Karten\n"COLOR_HEX_WHITE"Tippe /Schwarzmarkt", COLOR_WHITE, -1105.0177, -2854.2180, 61.1343, 5.0); // L6694 (lyd2)
    CreateDynamic3DTextLabel("-> NEULING <-\nKILL-SCHUTZ", 0xFFFF00FF, 0.0, 0.0, 0.4, 12.0); // L7347 (lyd2)
    // Panneau L45542 omis : le texte d'origine ("String") est genere dynamiquement dans lyd2
    // et les coordonnees (0,0,1) suggerent un objet attache plutot qu'un emplacement fixe.
    CreateDynamic3DTextLabel(COLOR_HEX_GREEN"Bratwurst Tag, 21.08.2019\n"COLOR_HEX_RED"Mach ein Screen und poste ihn ins Forum!", COLOR_WHITE, -824.9174, 1915.1334, 22.9245, 10.0); // L6417 (lyd2)
    return 1;
}

// ---- Vehicules statiques (71 elements) : a appeler UNIQUEMENT depuis OnGameModeInit ----
stock Lyd2_LoadStaticVehicles()
{
    AddStaticVehicleEx(482, 311.2510, -47.8946, 1.6779, 180.0258, 34, 34, 60*10); // L6121 (lyd2)
    AddStaticVehicleEx(482, 314.6620, -47.8846, 1.6602, 181.2968, 87, 87, 60*10); // L6122 (lyd2)
    AddStaticVehicleEx(482, 328.7251, -45.3317, 1.5990, 89.8018, 51, 1, 60*10); // L6123 (lyd2)
    AddStaticVehicleEx(482, 328.6741, -48.6964, 1.5664, 90.7113, 31, 34, 60*10); // L6124 (lyd2)
    AddStaticVehicleEx(482, 328.6540, -52.0104, 1.5976, 90.2421, 6, 34, 60*10); // L6125 (lyd2)
    AddStaticVehicleEx(482, 328.6812, -55.3923, 1.6008, 90.0675, 5, 5, 60*10); // L6126 (lyd2)
    AddStaticVehicleEx(538, 1810.9481, -1957.9902, 13.5469, 268.9864, 1, 1, 60*10); // L6130 (lyd2)
    AddStaticVehicleEx(538, 1724.2969, -1957.7959, 13.5391, 173.4324, 1, 1, 60*10); // L6131 (lyd2)
    AddStaticVehicleEx(538, 1654.6897, -1957.9625, 13.5469, 270.8898, 1, 1, 60*10); // L6132 (lyd2)
    AddStaticVehicleEx(482, 2282.6243, -2351.6001, 13.6290, 226.3535, 6, 3, 60*10); // L6136 (lyd2)
    AddStaticVehicleEx(482, 2290.0530, -2343.9314, 13.6311, 225.6010, 4, 4, 60*10); // L6137 (lyd2)
    AddStaticVehicleEx(482, 2297.5593, -2336.3022, 13.6220, 227.2437, 9, 9, 60*10); // L6138 (lyd2)
    AddStaticVehicleEx(482, 2290.8293, -2329.9988, 13.6274, 226.5028, 85, 84, 60*10); // L6139 (lyd2)
    AddStaticVehicleEx(482, 2283.5171, -2337.6597, 13.6266, 227.1544, 108, 108, 60*10); // L6140 (lyd2)
    AddStaticVehicleEx(482, 2276.0869, -2345.1609, 13.6405, 225.8990, 3, 38, 60*10); // L6141 (lyd2)
    AddStaticVehicleEx(532, -29.79999924, -1.29999995, 4.19999981, 66.24993896, -1, -1, 60*10); // L6144 (lyd2)
    AddStaticVehicleEx(532, -34.09999847, -10.39999962, 4.19999981, 66.24755859, -1, -1, 60*10); // L6145 (lyd2)
    AddStaticVehicleEx(532, -38.29999924, -19.79999924, 4.19999981, 66.24755859, -1, -1, 60*10); // L6146 (lyd2)
    AddStaticVehicleEx(532, -72.90000153, 5.59999990, 4.19999981, 158.49755859, -1, -1, 60*10); // L6147 (lyd2)
    AddStaticVehicleEx(532, -83.30000305, -20.39999962, 4.19999981, 338.49414062, -1, -1, 60*10); // L6148 (lyd2)
    AddStaticVehicleEx(532, -89.80000305, 32.29999924, 4.19999981, 248.49414062, -1, -1, 60*10); // L6149 (lyd2)
    AddStaticVehicleEx(552, 1941.2205, -1790.8042, 13.0758, 271.9213, 1, 79, 60*10); // L6152 (lyd2)
    AddStaticVehicleEx(552, 982.5037, -929.1548, 41.3965, 267.4868, 1, 79, 60*10); // L6153 (lyd2)
    AddStaticVehicleEx(552, 982.7092, -924.4758, 41.4802, 269.6549, 1, 79, 60*10); // L6154 (lyd2)
    AddStaticVehicleEx(552, 667.0059, -580.8707, 16.0361, 90.2695, 1, 79, 60*10); // L6155 (lyd2)
    AddStaticVehicleEx(552, -90.1938, -1196.0406, 1.9958, 345.7256, 1, 79, 60*10); // L6156 (lyd2)
    AddStaticVehicleEx(552, -86.8948, -1196.8789, 2.0065, 345.7235, 1, 79, 60*10); // L6157 (lyd2)
    AddStaticVehicleEx(448, 2122.7878, -1784.4783, 12.9871, 15.4276, 3, 5, 60*10); // L6160 (lyd2)
    AddStaticVehicleEx(448, 2121.1492, -1784.9320, 13.0122, 15.4396, 3, 5, 60*10); // L6161 (lyd2)
    AddStaticVehicleEx(448, 2118.9297, -1785.0514, 12.9817, 15.4484, 3, 5, 60*10); // L6162 (lyd2)
    AddStaticVehicleEx(448, 2116.8140, -1785.0240, 12.9760, 15.4484, 3, 5, 60*10); // L6163 (lyd2)
    AddStaticVehicleEx(448, 2114.5076, -1784.9103, 12.9863, 15.4576, 3, 5, 60*10); // L6164 (lyd2)
    AddStaticVehicleEx(448, 2112.3501, -1785.1090, 13.0096, 15.4682, 3, 5, 60*10); // L6165 (lyd2)
    AddStaticVehicleEx(448, 2108.7300, -1784.7393, 12.9869, 20.0269, 3, 5, 60*10); // L6166 (lyd2)
    AddStaticVehicleEx(448, 2105.5789, -1784.8358, 12.9815, 20.0102, 3, 5, 60*10); // L6167 (lyd2)
    AddStaticVehicleEx(574, 2065.6135, -1903.0514, 13.2720, 180.3510, 1, 3, 60*10); // L6176 (lyd2)
    AddStaticVehicleEx(574, 2062.4521, -1903.0706, 13.2972, 180.3509, 1, 3, 60*10); // L6177 (lyd2)
    AddStaticVehicleEx(574, 2059.1306, -1903.0906, 13.2974, 180.3509, 1, 3, 60*10); // L6178 (lyd2)
    AddStaticVehicleEx(574, 2055.6692, -1903.1121, 13.2593, 180.3509, 1, 3, 60*10); // L6179 (lyd2)
    AddStaticVehicleEx(574, 2052.7971, -1903.1295, 13.2850, 180.3509, 1, 3, 60*10); // L6180 (lyd2)
    AddStaticVehicleEx(574, 2062.2500, -1920.5278, 13.2720, 359.5535, 1, 3, 60*10); // L6181 (lyd2)
    AddStaticVehicleEx(574, 2065.2402, -1920.5510, 13.2972, 359.5535, 1, 3, 60*10); // L6182 (lyd2)
    AddStaticVehicleEx(423, 1000.8613, -1368.5023, 13.2883, 14.3345, 1, 5, 60*10); // L6185 (lyd2)
    AddStaticVehicleEx(423, 1005.3301, -1368.3827, 13.3348, 16.2586, 1, 3, 60*10); // L6186 (lyd2)
    AddStaticVehicleEx(423, 1015.1770, -1369.0472, 13.4086, 15.4217, 2, 1, 60*10); // L6187 (lyd2)
    AddStaticVehicleEx(423, 1010.4574, -1368.8745, 13.3912, 14.7082, 3, 2, 60*10); // L6188 (lyd2)
    AddStaticVehicleEx(588, 2370.6411, -1928.0067, 13.3064, 359.5818, 8, 8, 60*10); // L6191 (lyd2)
    AddStaticVehicleEx(588, 2377.0818, -1928.0540, 13.3332, 359.5819, 8, 8, 60*10); // L6192 (lyd2)
    AddStaticVehicleEx(588, 2383.5793, -1928.1016, 13.3400, 359.5818, 8, 8, 60*10); // L6193 (lyd2)
    AddStaticVehicleEx(486, 823.8465, 886.6324, 13.5834, 276.7267, 1, 1, 60*10); // L6196 (lyd2)
    AddStaticVehicleEx(486, 823.3401, 890.9330, 13.5920, 276.7213, 1, 1, 60*10); // L6197 (lyd2)
    AddStaticVehicleEx(486, 822.8735, 894.8936, 13.6017, 276.7277, 1, 1, 60*10); // L6198 (lyd2)
    AddStaticVehicleEx(486, 822.3878, 899.0094, 13.6016, 276.7277, 1, 1, 60*10); // L6199 (lyd2)
    AddStaticVehicleEx(486, 821.9666, 902.5806, 13.6016, 276.7277, 1, 1, 60*10); // L6200 (lyd2)
    AddStaticVehicleEx(486, 821.4063, 907.3297, 13.6016, 276.7277, 1, 1, 60*10); // L6201 (lyd2)
    AddStaticVehicleEx(486, 820.8406, 912.1172, 13.6112, 276.7340, 1, 1, 60*10); // L6202 (lyd2)
    AddStaticVehicleEx(486, 820.3097, 916.6208, 13.5928, 276.7313, 1, 1, 60*10); // L6203 (lyd2)
    AddStaticVehicleEx(428, 1558.4480, -1011.4513, 24.0308, 181.0827, 9, 9, 60*10); // L6206 (lyd2)
    AddStaticVehicleEx(428, 1562.5607, -1011.3737, 24.0687, 181.0817, 9, 9, 60*10); // L6207 (lyd2)
    AddStaticVehicleEx(428, 1567.0750, -1011.2867, 24.0258, 181.0806, 9, 9, 60*10); // L6208 (lyd2)
    AddStaticVehicleEx(428, 1571.5496, -1011.2010, 24.0635, 181.0796, 9, 9, 60*10); // L6209 (lyd2)
    AddStaticVehicleEx(428, 1575.7191, -1011.1234, 24.0285, 181.0806, 9, 9, 60*10); // L6210 (lyd2)
    AddStaticVehicleEx(428, 1555.4271, -1028.2484, 24.0302, 342.9333, 9, 9, 60*10); // L6211 (lyd2)
    AddStaticVehicleEx(428, 1559.6638, -1029.5486, 24.0644, 342.9344, 9, 9, 60*10); // L6212 (lyd2)
    AddStaticVehicleEx(428, 1563.9189, -1030.8583, 24.0202, 342.9335, 9, 9, 60*10); // L6213 (lyd2)
    AddStaticVehicleEx(408, 2119.0425, -2077.1606, 14.0978, 137.4615, 1, 16, 60*10); // L6216 (lyd2)
    AddStaticVehicleEx(408, 2127.0383, -2084.0186, 14.1013, 137.4624, 1, 16, 60*10); // L6217 (lyd2)
    AddStaticVehicleEx(408, 2133.9006, -2090.3154, 14.1523, 137.4605, 1, 16, 60*10); // L6218 (lyd2)
    AddStaticVehicleEx(408, 2141.5610, -2097.3281, 14.0799, 137.4607, 1, 16, 60*10); // L6219 (lyd2)
    AddStaticVehicleEx(408, 2112.6843, -2070.8335, 14.1242, 137.4605, 1, 16, 60*10); // L6220 (lyd2)
    AddStaticVehicleEx(408, 2089.0874, -2084.4946, 14.0993, 179.7765, 1, 16, 60*10); // L6221 (lyd2)
    CreateVehicle(452, 255.1756, 2933.8511, -1.0131, 3.5351, -1, -1, 0); // L14071 (lyd2)
    return 1;
}

// ---- Zones (4 GangZones + 15 rectangles) ----
stock Lyd2_LoadZones()
{
    GangZoneCreate(-2639.5930, 2229.4695, -2218.5574, 2631.8311); // L6072 (lyd2)
    GangZoneCreate(1388.0, -1053.0, 1516.0, -1008.0); // L6076 (lyd2)
    GangZoneCreate(1837.0, 1273.0, 2053.0, 1454.0); // L6077 (lyd2)
    GangZoneCreate(1757.0, -1620.0, 1832.0, -1555.0); // L6078 (lyd2)
    CreateDynamicRectangle(346.0, -2006.0, 415.0, -2191.0); // L6058 (lyd2)
    CreateDynamicRectangle(1284.0, -1776.0, 1157.0, -1846.0); // L6059 (lyd2)
    CreateDynamicRectangle(1614.3436, -1331.6265, 1671.4816, -1403.0798); // L6060 (lyd2)
    CreateDynamicRectangle(882.1005, -1438.1812, 965.1881, -1483.2373); // L6061 (lyd2)
    CreateDynamicRectangle(1486.3165, -1742.7417, 1399.4124, -1862.0428); // L6062 (lyd2)
    CreateDynamicRectangle(908.0503, -1385.3702, 802.8357, -1336.6713); // L6063 (lyd2)
    CreateDynamicRectangle(1602.0, -1864.0, 1419.0, -1581.0); // L6064 (lyd2)
    CreateDynamicRectangle(788.0, -1388.0, 849.0, -1331.0); // L6065 (lyd2)
    CreateDynamicRectangle(2794.0, 2000.0, 2929.0, 1763.0); // L6066 (lyd2)
    CreateDynamicRectangle(1535.1904, -1728.8754, 1628.9525, -1597.0757); // L6067 (lyd2)
    CreateDynamicRectangle(354.321533, -198.249023, 1204.696533, 563.750976); // L6069 (lyd2)
    CreateDynamicRectangle(-2639.5930, 2229.4695, -2218.5574, 2631.8311); // L6073 (lyd2)
    CreateDynamicRectangle(1388.0, -1053.0, 1516.0, -1008.0); // L6079 (lyd2)
    CreateDynamicRectangle(1837.0, 1273.0, 2053.0, 1454.0); // L6080 (lyd2)
    CreateDynamicRectangle(1757.0, -1620.0, 1832.0, -1555.0); // L6081 (lyd2)
    return 1;
}

// ---- Point d'entree unique : appeler Lyd2_LoadAll() depuis OnGameModeInit ----
stock Lyd2_LoadAll()
{
    Lyd2_LoadObjects();
    Lyd2_LoadPickups();
    Lyd2_LoadLabels();
    Lyd2_LoadStaticVehicles(); // ATTENTION : uniquement valable si appele depuis OnGameModeInit
    Lyd2_LoadZones();
    return 1;
}
// ==============================================================================
//  Points d'interet issus de lyd2 (anciens checkpoints / teleportations)
//
//  IMPORTANT : dans lyd2, ces coordonnees etaient utilisees avec
//  SetPlayerCheckpointEx / SetPlayerPos, des fonctions LIEES A UNE LOGIQUE DE JEU
//  precise (objectif de mission, teleportation apres achat, spawn...). Un
//  checkpoint SA-MP est unique par joueur (on ne peut pas en afficher 300 en
//  meme temps) : elles ne sont donc PAS rejouees telles quelles, mais listees
//  ici comme repertoire consultable/teleportable pour les admins, a brancher
//  sur votre propre logique (jobs, maisons, etc.) si vous le souhaitez.
// ==============================================================================
#define LYD2_POI_COUNT 297
new Float:gLyd2POI[LYD2_POI_COUNT][3] = {
    {-1650.4489, -157.8306, 15.4847}, // L13273 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, -1650.4489,-157.8306,15.4847, 7.0, CP_
    {1476.7418, 1694.5992, 12.1470}, // L13283 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1476.7418,1694.5992,12.1470, 7.0, CP_P
    {2045.5306, -2593.0469, 14.8793}, // L13293 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 2045.5306,-2593.0469,14.8793, 7.0, CP_
    {1467.4915, -1163.5656, 23.7634}, // L13407 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1467.4915,-1163.5656,23.7634, 5.0, CP_
    {1445.7449, -1031.4774, 23.6563}, // L13418 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1445.7449,-1031.4774,23.6563, 5.0, CP_
    {1326.7566, -921.7914, 36.9193}, // L13427 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1326.7566,-921.7914,36.9193, 5.0, CP_B
    {1143.1387, -941.4471, 42.7462}, // L13438 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1143.1387,-941.4471,42.7462, 5.0, CP_B
    {939.6364, -1237.1488, 16.4456}, // L13449 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 939.6364,-1237.1488,16.4456, 5.0, CP_B
    {1148.8563, -1408.9939, 13.5536}, // L13460 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1148.8563,-1408.9939,13.5536, 5.0, CP_
    {1262.7012, -1346.5897, 13.2076}, // L13471 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1262.7012,-1346.5897,13.2076, 5.0, CP_
    {1244.7290, -1849.5387, 13.3828}, // L13500 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1244.7290,-1849.5387,13.3828, 5.0, CP_
    {430.7518, -1700.3645, 9.9467}, // L13511 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 430.7518,-1700.3645,9.9467, 5.0, CP_BU
    {439.0800, -1502.6467, 30.9004}, // L13522 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 439.0800,-1502.6467,30.9004, 5.0, CP_B
    {800.6288, -1355.1935, 13.3828}, // L13533 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 800.6288,-1355.1935,13.3828, 5.0, CP_B
    {1283.5902, -1408.5476, 13.1148}, // L13544 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1283.5902,-1408.5476,13.1148, 5.0, CP_
    {1818.3822, -1873.9189, 13.4141}, // L13584 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1818.3822,-1873.9189,13.4141, 5.0, CP_
    {1981.3246, -2169.5681, 13.3765}, // L13595 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1981.3246,-2169.5681,13.3765, 5.0, CP_
    {2685.8232, -2466.1296, 13.5261}, // L13606 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 2685.8232,-2466.1296,13.5261, 5.0, CP_
    {2204.0122, -1629.6177, 15.6174}, // L13617 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 2204.0122,-1629.6177,15.6174, 5.0, CP_
    {2013.3904, -1458.8781, 13.3906}, // L13628 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 2013.3904,-1458.8781,13.3906, 5.0, CP_
    {1818.7804, -1676.5504, 13.3828}, // L13639 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1818.7804,-1676.5504,13.3828, 5.0, CP_
    {-133.1354, -192.5380, 1.8781}, // L13679 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, -133.1354,-192.5380,1.8781, 5.0, CP_BU
    {638.5032, -576.7302, 16.1875}, // L13690 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 638.5032,-576.7302,16.1875, 5.0, CP_BU
    {927.5668, -981.8544, 38.2044}, // L13701 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 927.5668,-981.8544,38.2044, 5.0, CP_BU
    {1020.6340, -1151.9069, 23.6563}, // L13712 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1020.6340,-1151.9069,23.6563, 5.0, CP_
    {1550.7195, -1305.7834, 16.4186}, // L13723 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1550.7195,-1305.7834,16.4186, 5.0, CP_
    {1791.2203, -1926.6321, 13.3893}, // L13761 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1791.2203,-1926.6321,13.3893, 5.0, CP_
    {1403.8307, 2636.3823, 10.8203}, // L13879 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1403.8307,2636.3823,10.8203, 7.0, CP_Z
    {-1948.2856, 99.1580, 25.7186}, // L13890 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, -1948.2856,99.1580,25.7186, 7.0, CP_ZU
    {839.5412, -1389.2937, -1.6202}, // L13901 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 839.5412,-1389.2937,-1.6202, 7.0, CP_Z
    {1587.7872, -1953.6045, 13.5469}, // L13912 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1587.7872,-1953.6045,13.5469, 7.0, CP_
    {1479.9335, -1746.1074, 13.5469}, // L13969 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid,1479.9335,-1746.1074,13.5469,3.0, CP_TU
    {2846.3262, 983.5958, 10.7500}, // L14009 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 2846.3262,983.5958,10.7500,3.0, CP_WT_
    {266.2877, 2904.2700, 7.8635}, // L14046 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(e, 266.2877,2904.2700,7.8635,3.0, CP_WT_STEG);
    {258.4050, 2933.7964, 1.7734}, // L14112 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 258.4050,2933.7964,1.7734, 3.0, CP_WT_
    {251.3709, 3277.9836, 0.2690}, // L14132 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(i, 251.3709,3277.9836,0.2690, 3.0, CP_WT_BOOTPLA
    {248.9509, 3282.2927, 2.8503}, // L14155 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 248.9509,3282.2927,2.8503, 3.0, CP_WT_
    {252.2882, 3295.4624, 10.4789}, // L14165 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 252.2882,3295.4624,10.4789, 3.0, CP_WT
    {255.1756, 2933.8511, -1.0131}, // L14211 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(i, 255.1756,2933.8511,-1.0131, 3.0, CP_WT_GOBACK
    {966.6749, 2071.1108, 10.8203}, // L14272 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 966.6749,2071.1108,10.8203, 3.0, CP_WT
    {1480.7660, -1805.3538, 15.3578}, // L14551 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1480.7660,-1805.3538,15.3578, 5.0, CP_
    {1270.0138, -1846.0366, 13.3906}, // L14556 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1270.0138,-1846.0366,13.3906, 5.0, CP_
    {1427.3734, -1721.5665, 13.2578}, // L14633 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1427.3734,-1721.5665,13.2578, 5.0, CP_
    {1513.7784, -1734.6387, 13.2577}, // L14650 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1513.7784,-1734.6387,13.2577, 5.0, CP_
    {1531.9985, -1607.7494, 13.2577}, // L14667 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1531.9985,-1607.7494,13.2577, 5.0, CP_
    {1647.6162, -1594.5996, 13.2730}, // L14684 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1647.6162,-1594.5996,13.2730, 5.0, CP_
    {1660.4186, -1449.8710, 13.2624}, // L14701 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1660.4186,-1449.8710,13.2624, 5.0, CP_
    {1618.2543, -1438.7881, 13.2577}, // L14718 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1618.2543,-1438.7881,13.2577, 5.0, CP_
    {1468.1348, -1438.7880, 13.2578}, // L14735 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1468.1348,-1438.7880,13.2578, 5.0, CP_
    {1416.2992, -1399.0945, 13.2572}, // L14752 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1416.2992,-1399.0945,13.2572, 5.0, CP_
    {1373.0175, -1397.9915, 13.2633}, // L14769 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1373.0175,-1397.9915,13.2633, 5.0, CP_
    {1273.8141, -1398.1047, 12.9125}, // L14786 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1273.8141,-1398.1047,12.9125, 5.0, CP_
    {1219.6558, -1398.0142, 13.0678}, // L14803 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1219.6558,-1398.0142,13.0678, 5.0, CP_
    {1193.8879, -1557.7451, 13.2578}, // L14820 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1193.8879,-1557.7451,13.2578, 5.0, CP_
    {1164.7354, -1569.3726, 13.1682}, // L14837 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1164.7354,-1569.3726,13.1682, 5.0, CP_
    {1147.9781, -1698.9581, 13.6562}, // L14854 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1147.9781,-1698.9581,13.6562, 5.0, CP_
    {1283.7072, -1714.6350, 13.2579}, // L14871 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1283.7072,-1714.6350,13.2579, 5.0, CP_
    {1299.0903, -1840.0605, 13.2578}, // L14888 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1299.0903,-1840.0605,13.2578, 5.0, CP_
    {1377.8132, -1874.0347, 13.2577}, // L14905 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1377.8132,-1874.0347,13.2577, 5.0, CP_
    {1391.3584, -1741.5569, 13.2578}, // L14922 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1391.3584,-1741.5569,13.2578, 5.0, CP_
    {1420.2920, -1734.8915, 13.2615}, // L14939 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1420.2920,-1734.8915,13.2615, 5.0, CP_
    {1431.5961, -1659.6328, 13.2578}, // L14956 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1431.5961,-1659.6328,13.2578, 5.0, CP_
    {1357.5104, -1665.4655, 13.4834}, // L14973 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1357.5104,-1665.4655,13.4834, 5.0, CP_
    {2060.6467, -1930.0806, 13.3428}, // L15279 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 2060.6467,-1930.0806,13.3428, 5.0, CP_
    {1823.8677, -1829.8912, 13.4141}, // L15284 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1823.8677,-1829.8912,13.4141, 5.0, CP_
    {1573.1659, -1869.9642, 13.3828}, // L15289 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1573.1659,-1869.9642,13.3828, 5.0, CP_
    {1499.3264, -1729.5050, 13.3828}, // L15294 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1499.3264,-1729.5050,13.3828, 5.0, CP_
    {1315.2017, -1715.5406, 13.3828}, // L15299 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1315.2017,-1715.5406,13.3828, 5.0, CP_
    {1358.8210, -1419.3829, 13.3828}, // L15304 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1358.8210,-1419.3829,13.3828, 5.0, CP_
    {1370.0029, -1059.6665, 26.6386}, // L15309 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1370.0029,-1059.6665,26.6386, 5.0, CP_
    {1523.9775, -1042.9404, 23.6289}, // L15314 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1523.9775,-1042.9404,23.6289, 5.0, CP_
    {1749.3524, -1166.4718, 23.6349}, // L15319 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1749.3524,-1166.4718,23.6349, 5.0, CP_
    {1845.8475, -1442.1245, 13.4007}, // L15324 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1845.8475,-1442.1245,13.4007, 5.0, CP_
    {1818.7308, -1844.2803, 13.4141}, // L15329 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1818.7308,-1844.2803,13.4141, 5.0, CP_
    {1951.9484, -1935.0249, 13.3828}, // L15334 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1951.9484,-1935.0249,13.3828, 5.0, CP_
    {2060.4966, -1913.4055, 13.5469}, // L15339 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 2060.4966,-1913.4055,13.5469, 5.0, CP_
    {2777.1758, -2298.5298, 0.1046}, // L15376 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 2777.1758,-2298.5298,0.1046, 5.0, CP_S
    {2867.0911, -2459.2363, -0.6575}, // L15381 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 2867.0911,-2459.2363,-0.6575, 5.0, CP_
    {2702.5842, -2617.2432, -0.9744}, // L15386 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 2702.5842,-2617.2432,-0.9744, 5.0, CP_
    {2517.8804, -2719.8296, 0.6559}, // L15391 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 2517.8804,-2719.8296,0.6559, 5.0, CP_S
    {2344.5002, -2647.9712, 0.1132}, // L15396 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 2344.5002,-2647.9712,0.1132, 5.0, CP_S
    {2388.0242, -2396.9143, -0.7216}, // L15404 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 2388.0242,-2396.9143,-0.7216, 5.0, CP_
    {2519.0413, -2290.8799, -0.7085}, // L15409 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 2519.0413,-2290.8799,-0.7085, 5.0, CP_
    {2339.2324, -2493.5034, -0.4512}, // L15444 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 2339.2324,-2493.5034,-0.4512, 5.0, CP_
    {2105.7512, -2812.7639, 0.2630}, // L15451 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 2105.7512,-2812.7639,0.2630, 5.0, CP_S
    {1645.0071, -2903.6633, -0.4597}, // L15458 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1645.0071,-2903.6633,-0.4597, 5.0, CP_
    {1030.9033, -2456.5122, 0.6451}, // L15465 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1030.9033,-2456.5122,0.6451, 5.0, CP_S
    {782.6017, -2065.0051, 0.2658}, // L15472 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 782.6017,-2065.0051,0.2658, 5.0, CP_SC
    {734.4969, -2420.6785, 0.0938}, // L15479 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 734.4969,-2420.6785,0.0938, 5.0, CP_SC
    {1056.4220, -2699.7454, 1.1654}, // L15486 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1056.4220,-2699.7454,1.1654, 5.0, CP_S
    {1821.5258, -2871.8557, 0.2626}, // L15493 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1821.5258,-2871.8557,0.2626, 5.0, CP_S
    {2218.5757, -2801.0981, 0.6510}, // L15500 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 2218.5757,-2801.0981,0.6510, 5.0, CP_S
    {2113.7583, -2098.0005, 13.5469}, // L15587 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid,2113.7583,-2098.0005,13.5469,5.0,CP_MUE
    {1998.7909, -2107.2979, 13.3496}, // L15629 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1998.7909,-2107.2979,13.3496, 5.0, CP_
    {1963.2606, -1942.6835, 13.3970}, // L15634 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1963.2606,-1942.6835,13.3970, 5.0, CP_
    {1924.0662, -1749.1938, 13.3828}, // L15640 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1924.0662,-1749.1938,13.3828, 5.0, CP_
    {1666.4025, -1728.9388, 13.3828}, // L15645 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1666.4025,-1728.9388,13.3828, 5.0, CP_
    {1532.9117, -1721.6056, 13.3828}, // L15650 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1532.9117,-1721.6056,13.3828, 5.0, CP_
    {1475.0117, -1589.7338, 13.3828}, // L15655 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1475.0117,-1589.7338,13.3828, 5.0, CP_
    {1325.8937, -1569.8595, 13.3690}, // L15660 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1325.8937,-1569.8595,13.3690, 5.0, CP_
    {1359.4690, -1418.9095, 13.3828}, // L15665 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1359.4690,-1418.9095,13.3828, 5.0, CP_
    {1360.1733, -1168.4264, 23.7215}, // L15670 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1360.1733,-1168.4264,23.7215, 5.0, CP_
    {1370.2086, -1063.4838, 26.4413}, // L15675 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1370.2086,-1063.4838,26.4413, 5.0, CP_
    {1275.0173, -1036.0787, 31.5611}, // L15680 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1275.0173,-1036.0787,31.5611, 5.0, CP_
    {1258.5132, -1076.1464, 27.7118}, // L15685 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1258.5132,-1076.1464,27.7118, 5.0, CP_
    {1168.0930, -1097.0586, 25.3393}, // L15690 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1168.0930,-1097.0586,25.3393, 5.0, CP_
    {1132.6324, -1032.8380, 31.9016}, // L15695 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1132.6324,-1032.8380,31.9016, 5.0, CP_
    {1076.4883, -1088.9136, 26.0361}, // L15700 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1076.4883,-1088.9136,26.0361, 5.0, CP_
    {1049.2565, -1255.4100, 14.6669}, // L15705 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1049.2565,-1255.4100,14.6669, 5.0, CP_
    {1176.4523, -1410.9448, 13.4452}, // L15710 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1176.4523,-1410.9448,13.4452, 5.0, CP_
    {2106.1296, -2011.5781, 13.5469}, // L15715 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 2106.1296,-2011.5781,13.5469, 5.0, CP_
    {2122.5459, -2096.3967, 13.5469}, // L15721 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 2122.5459,-2096.3967,13.5469, 5.0, CP_
    {799.1427, 836.5533, 8.1336}, // L15755 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 799.1427,836.5533,8.1336, 5.0, CP_BAUA
    {756.7701, 899.0582, -1.2382}, // L15760 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 756.7701,899.0582,-1.2382, 5.0, CP_BAU
    {694.2874, 955.6836, -15.8628}, // L15765 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 694.2874,955.6836,-15.8628, 5.0, CP_BA
    {700.7612, 913.5161, -30.4612}, // L15770 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 700.7612,913.5161,-30.4612, 5.0, CP_BA
    {648.9686, 906.4146, -41.7512}, // L15775 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 648.9686,906.4146,-41.7512, 5.0, CP_BA
    {635.8752, 862.5970, -42.6892}, // L15780 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 635.8752,862.5970,-42.6892, 5.0, CP_BA
    {607.7939, 863.4465, -42.0452}, // L15786 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 607.7939,863.4465,-42.0452, 5.0, CP_BA
    {513.8612, 870.7057, -39.3272}, // L15792 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 513.8612,870.7057,-39.3272, 5.0, CP_BA
    {525.7652, 945.3519, -23.7328}, // L15797 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 525.7652,945.3519,-23.7328, 5.0, CP_BA
    {713.5145, 962.6615, -7.4000}, // L15803 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 713.5145,962.6615,-7.4000, 5.0, CP_BAU
    {834.3851, 851.1645, 12.2650}, // L15808 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 834.3851,851.1645,12.2650, 5.0, CP_BAU
    {832.6885, 1120.3729, 29.9069}, // L15813 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 832.6885,1120.3729,29.9069, 5.0, CP_BA
    {570.8690, 1068.5115, 28.3436}, // L15818 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 570.8690,1068.5115,28.3436, 5.0, CP_BA
    {373.4708, 978.8013, 29.5814}, // L15823 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 373.4708,978.8013,29.5814, 5.0, CP_BAU
    {382.3929, 871.6203, 21.9523}, // L15828 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 382.3929,871.6203,21.9523, 5.0, CP_BAU
    {832.2355, 891.7194, 13.3516}, // L15833 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 832.2355,891.7194,13.3516, 5.0, CP_BAU
    {21.7957, 62.7240, 4.0902}, // L15874 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 21.7957,62.7240,4.0902, 5.0, CP_HARVES
    {62.1695, 30.2543, 1.6882}, // L15879 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 62.1695,30.2543,1.6882, 5.0, CP_HARVES
    {72.4068, -16.7726, 1.8534}, // L15884 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 72.4068,-16.7726,1.8534, 5.0, CP_HARVE
    {32.9849, -69.0399, 2.3693}, // L15889 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 32.9849,-69.0399,2.3693, 5.0, CP_HARVE
    {-22.5727, -71.6361, 4.0950}, // L15894 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, -22.5727,-71.6361,4.0950, 5.0, CP_HARV
    {8.4761, -113.9747, 1.8918}, // L15899 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 8.4761,-113.9747,1.8918, 5.0, CP_HARVE
    {23.1533, -144.0073, 1.5902}, // L15904 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 23.1533,-144.0073,1.5902, 5.0, CP_HARV
    {-71.7287, -134.2719, 4.0992}, // L15909 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, -71.7287,-134.2719,4.0992, 5.0, CP_HAR
    {-112.1627, -69.7551, 4.0957}, // L15914 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, -112.1627,-69.7551,4.0957, 5.0, CP_HAR
    {-79.2461, 72.5799, 4.0954}, // L15919 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, -79.2461,72.5799,4.0954, 5.0, CP_HARVE
    {-38.3087, 72.4932, 4.0946}, // L15924 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, -38.3087,72.4932,4.0946, 5.0, CP_HARVE
    {-38.4621, 56.3233, 3.1172}, // L15971 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, -38.4621,56.3233,3.1172, 1.0, pCheckpo
    {1487.7969, -135.5734, 20.2611}, // L16020 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1487.7969,-135.5734,20.2611, 5.0, CP_G
    {1437.4023, -127.0120, 21.8157}, // L16025 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1437.4023,-127.0120,21.8157, 5.0, CP_G
    {1468.9374, -70.1820, 20.0426}, // L16030 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1468.9374,-70.1820,20.0426, 5.0, CP_GA
    {1495.5052, -15.1224, 24.0091}, // L16035 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1495.5052,-15.1224,24.0091, 5.0, CP_GA
    {1426.9447, -36.2039, 26.8482}, // L16040 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1426.9447,-36.2039,26.8482, 5.0, CP_GA
    {1454.4276, -55.6280, 21.7093}, // L16045 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1454.4276,-55.6280,21.7093, 5.0, CP_GA
    {1488.0676, -63.9454, 20.5155}, // L16050 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1488.0676,-63.9454,20.5155, 5.0, CP_GA
    {1498.8956, -34.1370, 22.3406}, // L16055 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1498.8956,-34.1370,22.3406, 5.0, CP_GA
    {1432.9546, -74.0522, 20.7133}, // L16060 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1432.9546,-74.0522,20.7133, 5.0, CP_GA
    {1472.0958, -110.5212, 19.6172}, // L16065 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1472.0958,-110.5212,19.6172, 5.0, CP_G
    {1528.9442, -61.3342, 20.2440}, // L16070 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1528.9442,-61.3342,20.2440, 5.0, CP_GA
    {1554.9900, 33.2357, 24.1579}, // L16075 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1554.9900,33.2357,24.1579, 5.0, CP_GAR
    {1547.9395, 30.0051, 24.1406}, // L16124 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1547.9395,30.0051,24.1406, 1.0, pCheck
    {2486.6838, 1879.4843, 10.9174}, // L16317 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 2486.6838,1879.4843,10.9174, 7.0, CP_T
    {16.6802, 43.9293, 3.1172}, // L20644 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 16.6802,43.9293,3.1172, 5.0, CP_HARVES
    {914.3174, -1004.0942, 37.9902}, // L29537 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 914.3174,-1004.0942,37.9902, 2.0, CP_N
    {1489.0573, -1771.7749, 18.7958}, // L29614 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1489.0573,-1771.7749,18.7958, 2.0, CP_
    {1470.7415, -2410.9363, 13.5547}, // L29741 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1470.7415,-2410.9363,13.5547, 2.0, CP_
    {817.6655, -1618.9307, 13.7034}, // L29771 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 817.6655,-1618.9307,13.7034,2.0, CP_NA
    {2098.0144, -1806.8236, 13.5541}, // L29776 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 2098.0144,-1806.8236,13.5541,2.0, CP_N
    {925.6447, -1352.1470, 13.3761}, // L29781 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 925.6447,-1352.1470,13.3761,2.0, CP_NA
    {2422.1592, -1508.4604, 23.9922}, // L29786 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 2422.1592,-1508.4604,23.9922,2.0, CP_N
    {2082.9170, 2224.1670, 11.0234}, // L29791 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 2082.9170,2224.1670,11.0234,2.0, CP_NA
    {2102.3757, 2229.0376, 11.0234}, // L29796 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 2102.3757,2229.0376,11.0234,2.0, CP_NA
    {1005.5800, -941.1790, 42.1320}, // L29816 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1005.5800,-941.1790,42.1320,2.0, CP_NA
    {1944.0356, -1771.8125, 13.3906}, // L29821 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1944.0356,-1771.8125,13.3906,2.0, CP_N
    {653.1495, -570.1783, 16.3359}, // L29826 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 653.1495,-570.1783,16.3359,2.0, CP_NAV
    {-99.1346, -1166.1656, 2.5805}, // L29831 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, -99.1346,-1166.1656,2.5805,2.0, CP_NAV
    {-2023.9924, 156.4616, 28.8359}, // L29836 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, -2023.9924,156.4616,28.8359,2.0, CP_NA
    {-1676.5607, 412.4557, 7.1797}, // L29841 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, -1676.5607,412.4557,7.1797,2.0, CP_NAV
    {612.2504, 1694.3873, 6.9922}, // L29846 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 612.2504,1694.3873,6.9922,2.0, CP_NAVI
    {1596.0598, 2198.7400, 10.8203}, // L29851 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1596.0598,2198.7400,10.8203,2.0, CP_NA
    {1380.9908, 457.3878, 19.9316}, // L29856 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1380.9908,457.3878,19.9316,2.0, CP_NAV
    {2201.8096, 2475.6104, 10.8203}, // L29861 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 2201.8096,2475.6104,10.8203,2.0, CP_NA
    {1457.8679, -1140.2852, 24.0735}, // L29881 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1457.8679,-1140.2852,24.0735,2.0, CP_N
    {2244.6521, -1664.0035, 15.4766}, // L29886 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 2244.6521,-1664.0035,15.4766,2.0, CP_N
    {461.0692, -1501.0800, 31.0574}, // L29891 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 461.0692,-1501.0800,31.0574,2.0, CP_NA
    {1022.5134, -1123.2565, 23.8703}, // L29896 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1022.5134,-1123.2565,23.8703,2.0, CP_N
    {2127.5486, 2378.9626, 10.8203}, // L29901 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 2127.5486,2378.9626,10.8203,2.0, CP_NA
    {1350.0214, -1754.2931, 13.3554}, // L29921 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1350.0214,-1754.2931,13.3554,2.0, CP_N
    {1316.0682, -906.5001, 38.3864}, // L29926 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1316.0682,-906.5001,38.3864,2.0, CP_NA
    {2423.7568, -1742.3107, 13.5469}, // L29931 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 2423.7568,-1742.3107,13.5469,2.0, CP_N
    {1154.7301, -1457.9226, 15.7969}, // L29936 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1154.7301,-1457.9226,15.7969,2.0, CP_N
    {1503.8788, -1637.4789, 14.5078}, // L29941 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1503.8788,-1637.4789,14.5078, 2.0, CP_
    {1498.3309, -1585.8683, 13.5469}, // L29961 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1498.3309,-1585.8683,13.5469, 2.0, CP_
    {1930.3031, -2344.5083, 13.5469}, // L30066 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1930.3031,-2344.5083,13.5469,2.0, CP_N
    {2112.8987, -2098.1521, 13.5469}, // L30071 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 2112.8987,-2098.1521,13.5469,2.0, CP_N
    {2059.0566, -1910.7906, 13.5469}, // L30076 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 2059.0566,-1910.7906,13.5469,2.0, CP_N
    {2118.1602, -1775.5365, 13.3916}, // L30081 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 2118.1602,-1775.5365,13.3916,2.0, CP_N
    {1565.7582, 23.2893, 24.1641}, // L30086 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1565.7582,23.2893,24.1641,2.0, CP_NAVI
    {2516.5254, -2253.6462, 13.3321}, // L30091 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 2516.5254,-2253.6462,13.3321,2.0, CP_N
    {1257.3948, -1379.4574, 13.2933}, // L30096 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1257.3948,-1379.4574,13.2933,2.0, CP_N
    {1564.5618, -1020.5309, 23.9063}, // L30106 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1564.5618,-1020.5309,23.9063, 2.0, CP_
    {1003.8848, -1350.9558, 13.3388}, // L30111 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1003.8848,-1350.9558,13.3388, 2.0, CP_
    {-12.3201, 28.1475, 3.1172}, // L30116 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, -12.3201,28.1475,3.1172, 2.0, CP_NAVI6
    {62.1230, -247.9869, 1.5781}, // L30121 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 62.1230,-247.9869,1.5781, 2.0, CP_NAVI
    {846.9400, 885.9145, 13.3516}, // L30126 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 846.9400,885.9145,13.3516, 2.0, CP_NAV
    {2390.9146, -1920.6163, 13.3828}, // L30136 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 2390.9146,-1920.6163,13.3828, 2.0, CP_
    {2160.315186, -97.976898, 3.429407}, // L30176 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 2160.315186, -97.976898, 3.429407, 2.0
    {2298.2554, -2350.6294, 13.5469}, // L30181 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 2298.2554,-2350.6294,13.5469, 2.0, CP_
    {318.9959, -60.6508, 1.5781}, // L30186 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 318.9959,-60.6508,1.5781, 2.0, CP_NAVI
    {-1548.0554, 125.1203, 3.5547}, // L30196 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, -1548.0554,125.1203,3.5547, 2.0, CP_NA
    {-382.0342, -1426.4521, 26.0822}, // L30201 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, -382.0342,-1426.4521,26.0822, 2.0, CP_
    {-1154.0834, -2857.0581, 61.0985}, // L30206 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, -1154.0834,-2857.0581,61.0985, 2.0, CP
    {1702.9427, -1470.3704, 13.5469}, // L30231 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1702.9427,-1470.3704,13.5469, 2.0, CP_
    {1041.0613, -1028.3164, 32.1016}, // L30236 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1041.0613,-1028.3164,32.1016, 2.0, CP_
    {-1935.8890, 236.2874, 34.3125}, // L30241 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, -1935.8890,236.2874,34.3125, 2.0, CP_N
    {2645.2095, -2035.3197, 13.5540}, // L30246 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 2645.2095,-2035.3197,13.5540, 2.0, CP_
    {-2713.5679, 217.3422, 4.2651}, // L30251 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, -2713.5679,217.3422,4.2651, 2.0, CP_NA
    {1763.4915, 2080.2959, 10.8203}, // L30256 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1763.4915,2080.2959,10.8203, 2.0, CP_N
    {1782.8275, -1702.7240, 13.5096}, // L30266 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1782.8275,-1702.7240,13.5096, 2.0, CP_
    {1329.4666, -1559.4634, 13.5469}, // L30286 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1329.4666,-1559.4634,13.5469, 2.0, CP_
    {1365.9547, -1279.0731, 13.5469}, // L30306 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1365.9547,-1279.0731,13.5469, 2.0, CP_
    {2400.5369, -1981.5837, 13.5469}, // L30311 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 2400.5369,-1981.5837,13.5469, 2.0, CP_
    {2159.1836, 943.2106, 10.8203}, // L30316 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 2159.1836,943.2106,10.8203, 2.0, CP_NA
    {1510.7117, -1679.9557, 13.5171}, // L30320 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1510.7117,-1679.9557,13.5171, 2.0, CP_
    {1959.5519, -2180.7378, 13.5469}, // L30340 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1959.5519,-2180.7378,13.5469, 2.0, CP_
    {-1547.0936, -431.9405, 6.0073}, // L30345 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, -1547.0936,-431.9405,6.0073, 2.0, CP_N
    {1711.9429, 1604.6927, 10.0079}, // L30350 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1711.9429,1604.6927,10.0079, 2.0, CP_N
    {268.9609, 1384.2981, 10.1610}, // L30370 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 268.9609,1384.2981,10.1610, 2.0, CP_NA
    {577.4390, 1221.7273, 11.2689}, // L30375 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 577.4390,1221.7273,11.2689, 2.0, CP_NA
    {-1707.6189, 10.5305, 3.6368}, // L30380 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, -1707.6189,10.5305,3.6368, 2.0, CP_NAV
    {1413.4673, -1698.6144, 13.5395}, // L30390 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1413.4673,-1698.6144,13.5395, 2.0, CP_
    {2008.1722, 1169.3364, 10.8203}, // L30395 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 2008.1722,1169.3364,10.8203, 2.0, CP_N
    {1738.5869, -1586.3961, 13.5555}, // L30400 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1738.5869,-1586.3961,13.5555, 2.0, CP_
    {660.3523, -1869.5139, 5.5537}, // L30405 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 660.3523,-1869.5139,5.5537, 2.0, CP_NA
    {807.5915, 843.0824, 9.6279}, // L30425 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 807.5915,843.0824,9.6279, 2.0, CP_NAVI
    {1466.5648, -1729.4851, 13.3828}, // L31508 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1466.5648,-1729.4851,13.3828, 5.0, CP_
    {1360.7312, -1224.7466, 14.2254}, // L31514 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1360.7312,-1224.7466,14.2254, 5.0, CP_
    {1639.4159, -1875.4596, 13.3828}, // L31520 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 1639.4159,-1875.4596,13.3828, 5.0, CP_
    {-111.3457, -1169.6807, 2.7028}, // L31526 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, -111.3457,-1169.6807,2.7028, 5.0, CP_B
    {-1987.7780, 136.9616, 27.5391}, // L31561 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, -1987.7780,136.9616,27.5391, 5.0, CP_S
    {2833.2529, 1290.4922, 10.7771}, // L31566 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 2833.2529,1290.4922,10.7771, 5.0, CP_S
    {2631.2749, -2279.3691, -0.0300}, // L32969 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 2631.2749,-2279.3691,-0.0300, 5.0, CP_
    {2490.5205, -2312.7495, 0.1481}, // L32974 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 2490.5205,-2312.7495,0.1481, 5.0, CP_S
    {764.9532, 347.7378, 20.0458}, // L45467 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid, 764.9532,347.7378,20.0458, 6.0, CP_ROB
    {-12.5640, 47.6324, 3.1172}, // L48251 (SetPlayerCheckpointEx) - SetPlayerCheckpointEx(playerid,-12.5640,47.6324,3.1172,5.0,CP_COW_FINI
    {1486.3573, -1749.6531, 15.4453}, // L6998 (SetPlayerPos) - //SetPlayerPos(playerid, 1486.3573,-1749.6531,15.4453 );
    {257.9847, -41.5232, 1002.0234}, // L8593 (SetPlayerPos) - SetPlayerPos(playerid, 257.9847,-41.5232,1002.0234);
    {2219.4368, 1553.9379, 1004.7188}, // L9173 (SetPlayerPos) - SetPlayerPos(playerid, 2219.4368,1553.9379,1004.7188);
    {2218.3101, 1614.8721, 999.9827}, // L9178 (SetPlayerPos) - SetPlayerPos(playerid, 2218.3101,1614.8721,999.9827);
    {2200.1055, 1613.8082, 999.9735}, // L9183 (SetPlayerPos) - SetPlayerPos(playerid, 2200.1055,1613.8082,999.9735);
    {2189.8403, 1592.9681, 999.9729}, // L9188 (SetPlayerPos) - SetPlayerPos(playerid, 2189.8403,1592.9681,999.9729);
    {2169.8208, 1618.7504, 999.9766}, // L9193 (SetPlayerPos) - SetPlayerPos(playerid, 2169.8208,1618.7504,999.9766);
    {798.4492, -1345.5676, -0.5078}, // L9266 (SetPlayerPos) - SetPlayerPos(playerid, 798.4492,-1345.5676,-0.5078);
    {1515.711791, -1457.327270, 9.5}, // L9327 (SetPlayerPos) - SetPlayerPos(playerid, 1515.711791, -1457.327270, 9.5);
    {162.6819, -25.6529, 1.5781}, // L14584 (SetPlayerPos) - SetPlayerPos(playerid,162.6819,-25.6529,1.5781);
    {-2033.2031, -117.3853, 1035.1719}, // L14609 (SetPlayerPos) - SetPlayerPos(playerid,-2033.2031,-117.3853,1035.1719);
    {381.1510, -1881.4520, 3.7626}, // L16398 (SetPlayerPos) - SetPlayerPos(i, 381.1510, -1881.4520, 3.7626);
    {382.1528, -2166.6685, 7.8510}, // L16440 (SetPlayerPos) - SetPlayerPos(i,382.1528,-2166.6685,7.8510);
    {834.0222, 7.2621, 1004.1870}, // L17796 (SetPlayerPos) - SetPlayerPos(playerid, 834.0222,7.2621,1004.1870);
    {914.0884, -1004.0160, 37.9917}, // L17802 (SetPlayerPos) - SetPlayerPos(playerid, 914.0884,-1004.0160,37.9917);
    {377.2652, -192.6817, 1000.6401}, // L17808 (SetPlayerPos) - SetPlayerPos(playerid, 377.2652,-192.6817,1000.6401);
    {1038.3171, -1339.7793, 13.7266}, // L17814 (SetPlayerPos) - SetPlayerPos(playerid, 1038.3171,-1339.7793,13.7266);
    {-2636.6230, 1403.3202, 906.4609}, // L17822 (SetPlayerPos) - SetPlayerPos(playerid, -2636.6230,1403.3202,906.4609);
    {2127.5486, 2378.9626, 10.8203}, // L17830 (SetPlayerPos) - SetPlayerPos(playerid, 2127.5486,2378.9626,10.8203);
    {1548.4880, -1364.1744, 326.2183}, // L17836 (SetPlayerPos) - SetPlayerPos(playerid, 1548.4880,-1364.1744,326.2183);
    {1571.2114, -1336.6027, 16.4844}, // L17842 (SetPlayerPos) - SetPlayerPos(playerid, 1571.2114,-1336.6027,16.4844);
    {359.5758, -2107.5520, 74.8357}, // L17848 (SetPlayerPos) - SetPlayerPos(playerid, 359.5758,-2107.5520,74.8357);
    {361.7136, -2107.5913, 7.8340}, // L17854 (SetPlayerPos) - SetPlayerPos(playerid, 361.7136,-2107.5913,7.8340);
    {1234.1289, -1784.0337, 33.6312}, // L17860 (SetPlayerPos) - SetPlayerPos(playerid, 1234.1289,-1784.0337,33.6312);
    {1221.9672, -1812.2772, 16.5938}, // L17866 (SetPlayerPos) - SetPlayerPos(playerid, 1221.9672,-1812.2772,16.5938);
    {305.3869, -158.9812, 999.5938}, // L17872 (SetPlayerPos) - SetPlayerPos(playerid, 305.3869,-158.9812,999.5938);
    {-2026.8407, -104.1143, 1035.1719}, // L17880 (SetPlayerPos) - SetPlayerPos(playerid, -2026.8407,-104.1143,1035.1719);
    {-2029.8124, -119.0646, 1035.1719}, // L17890 (SetPlayerPos) - SetPlayerPos(playerid, -2029.8124,-119.0646,1035.1719);
    {1489.0573, -1771.7749, 18.7958}, // L17896 (SetPlayerPos) - SetPlayerPos(playerid, 1489.0573,-1771.7749,18.7958);
    {1480.4305, -1745.5150, 13.6281}, // L27086 (SetPlayerPos) - SetPlayerPos(playerid,  1480.4305,-1745.5150,13.6281);
    {1218.5142, -919.5847, 43.0938}, // L27115 (SetPlayerPos) - SetPlayerPos(playerid, 1218.5142,-919.5847,43.0938);
    {1365.7517, -1288.5110, 13.5469}, // L27144 (SetPlayerPos) - SetPlayerPos(playerid, 1365.7517,-1288.5110,13.5469);
    {666.8114, -1880.4503, 5.4600}, // L27173 (SetPlayerPos) - SetPlayerPos(playerid, 666.8114,-1880.4503,5.4600);
    {1234.4102, -1823.8929, 13.5910}, // L27202 (SetPlayerPos) - SetPlayerPos(playerid, 1234.4102,-1823.8929,13.5910);
    {1804.6133, -1890.9283, 13.4073}, // L27231 (SetPlayerPos) - SetPlayerPos(playerid, 1804.6133,-1890.9283,13.4073);
    {216.247497, -1442.859252, 13.154298}, // L27260 (SetPlayerPos) - SetPlayerPos(playerid, 216.247497,-1442.859252,13.154298);
    {1144.016357, -1330.051025, 13.542300}, // L27289 (SetPlayerPos) - SetPlayerPos(playerid, 1144.016357,-1330.051025,13.542300);
    {1460.0717, -1027.2748, 23.8281}, // L27318 (SetPlayerPos) - SetPlayerPos(playerid, 1460.0717,-1027.2748,23.8281);
    {960.548889, -1598.319702, 13.621998}, // L27347 (SetPlayerPos) - SetPlayerPos(playerid, 960.548889,-1598.319702,13.621998);
    {2509.174804, -1514.432373, 24.000000}, // L27376 (SetPlayerPos) - SetPlayerPos(playerid, 2509.174804,-1514.432373,24.000000);
    {1841.7158, -2568.3242, 13.5469}, // L27405 (SetPlayerPos) - SetPlayerPos(playerid, 1841.7158,-2568.3242,13.5469);
    {805.7107, -1335.6899, 13.5469}, // L27434 (SetPlayerPos) - SetPlayerPos(playerid, 805.7107,-1335.6899,13.5469);
    {1023.3541, -1134.1473, 23.8203}, // L27463 (SetPlayerPos) - SetPlayerPos(playerid, 1023.3541,-1134.1473,23.8203);
    {1310.3245, -1383.1377, 13.7432}, // L27492 (SetPlayerPos) - SetPlayerPos(playerid, 1310.3245,-1383.1377,13.7432);
    {483.1288, -1762.5616, 7.1238}, // L31367 (SetPlayerPos) - SetPlayerPos(playerid, 483.1288, -1762.5616, 7.1238);
    {1416.5498, -806.5092, 85.0357}, // L39615 (SetPlayerPos) - SetPlayerPos(playerid,1416.5498,-806.5092,85.0357);
    {1490.6090, -1741.4506, 13.5469}, // L44725 (SetPlayerPos) - SetPlayerPos(playerid,1490.6090,-1741.4506,13.5469);
    {1541.2928, -1661.9829, 13.5523}, // L44741 (SetPlayerPos) - SetPlayerPos(playerid,1541.2928,-1661.9829,13.5523);
    {2010.0386, -1438.3197, 13.5547}, // L44759 (SetPlayerPos) - SetPlayerPos(playerid,2010.0386,-1438.3197,13.5547);
    {1455.5131, -1024.8951, 23.8281}, // L44778 (SetPlayerPos) - SetPlayerPos(playerid,1455.5131,-1024.8951,23.8281);
    {376.7904, -2020.4138, 7.8301}, // L44794 (SetPlayerPos) - SetPlayerPos(playerid,376.7904,-2020.4138,7.8301);
    {-1403.6885, -254.3693, 1043.6117}, // L47924 (SetPlayerPos) - SetPlayerPos(playerid,-1403.6885,-254.3693,1043.6117);
    {396.3516, -2152.5928, 7.8399}, // L48394 (SetPlayerPos) - SetPlayerPos(playerid,396.3516,-2152.5928,7.8399);
    {373.5172, -2059.1106, 7.8831}, // L48489 (SetPlayerPos) - SetPlayerPos(playerid,373.5172,-2059.1106,7.8831);
    {-2038.8239, -97.9802, 35.1641}, // L48584 (SetPlayerPos) - SetPlayerPos(playerid,-2038.8239,-97.9802,35.1641);
    {356.7114, -2149.5613, 7.8779}, // L48994 (SetPlayerPos) - //SetPlayerPos(i,356.7114,-2149.5613,7.8779);
    {264.7464, 109.6102, 1004.6172}, // L9240 (SetPlayerPosEx) - SetPlayerPosEx(playerid, 264.7464, 109.6102, 1004.6172, 10, 0);
    {2162.6523, -102.3127, 2.7500}, // L9247 (SetPlayerPosEx) - SetPlayerPosEx(playerid, 2162.6523, -102.3127, 2.7500, 0, 0);
    {1152.8165, -1341.2827, 13.9058}, // L9405 (SetPlayerPosEx) - SetPlayerPosEx(playerid, 1152.8165, -1341.2827, 13.9058, 0, 0);
    {960.7043, -1580.0457, 13.5469}, // L14369 (SetPlayerPosEx) - SetPlayerPosEx(playerid, 960.7043, -1580.0457, 13.5469, MAPS_LSPDEXTER
};

// /lyd2poi [numero] : (admin) teleporte vers le point d'interet numero, ou
// liste les 10 plus proches si aucun numero n'est fourni.
stock Lyd2_GotoPOI(playerid, index)
{
    if(index < 0 || index >= LYD2_POI_COUNT) return 0;
    SetPlayerPos(playerid, gLyd2POI[index][0], gLyd2POI[index][1], gLyd2POI[index][2]);
    return 1;
}