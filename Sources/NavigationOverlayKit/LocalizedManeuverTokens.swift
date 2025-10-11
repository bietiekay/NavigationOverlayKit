import Foundation

/// Multilingual keyword mappings for navigation maneuver detection.
/// 
/// ## Why This Mapping Is Necessary
/// 
/// MapKit's `MKRouteStep.instructions` provides only localized, free-text navigation instructions
/// (e.g., "Turn left onto Main Street" in English, "Links abbiegen auf Hauptstraße" in German).
/// Unlike routing SDKs like Mapbox or HERE, MapKit does NOT expose typed maneuver enums
/// (e.g., `ManeuverType.left`, `ManeuverModifier.slight`) that would work consistently across locales.
/// 
/// This creates a fundamental problem: to display appropriate navigation arrows/icons,
/// we must parse the localized text to determine the maneuver type. However, text parsing
/// is inherently fragile and locale-dependent.
/// 
/// ## Our Solution: Hybrid Approach
/// 
/// 1. **Primary**: Multilingual keyword mapping (this file) - robust across supported locales
/// 2. **Fallback**: Geometry-based angle detection between route step polylines
/// 3. **Final fallback**: Default to straight arrow
/// 
/// This approach prioritizes accuracy from MapKit's localized text while providing
/// geometric fallbacks when text parsing fails or is ambiguous.
/// 
/// ## Alternative Approaches (and why we don't use them)
/// 
/// - **Pure geometry**: Unreliable for complex intersections, roundabouts, highway ramps
/// - **English-only parsing**: Breaks completely in non-English locales
/// - **Switch to Mapbox/HERE**: Requires changing the entire routing backend
/// 
/// ## Contributing
/// 
/// To add support for your language:
/// 1. Add tokens to the appropriate arrays below
/// 2. Include common variants, gendered forms, and synonyms
/// 3. Keep tokens lowercase; accents are fine
/// 4. Prefer short substrings that are unlikely to conflict
/// 5. Test with real MapKit instructions from your locale
struct LocalizedManeuverTokens {
    
    // MARK: - U-turn Detection
    
    static let uTurnTokens = [
        // English
        "u-turn", "uturn", "make a u", "make a u turn",
        // German
        "umkehren", "kehr um", "wenden", "umdrehen",
        // French
        "demi-tour", "demi tour",
        // Spanish
        "vuelta en u", "giro en u", "media vuelta", "dar la vuelta",
        // Italian
        "inversione a u", "inversione ad u",
        // Portuguese
        "retorno", "retornar", "inversão de marcha", "inversao de marcha",
        // Dutch
        "keer om", "omkeren", "draai om", "keren",
        // Swedish
        "u-sväng", "u sväng", "vänd", "vänd om",
        // Norwegian
        "u-sving", "u sving", "snu",
        // Danish
        "u-vending", "u vending", "vend om",
        // Finnish
        "u-käännös", "u kaannos",
        // Japanese
        "ユーターン", "uターン", "転回",
        // Chinese (Simplified/Traditional)
        "掉头", "调头", "掉頭", "調頭",
        // Russian
        "разворот", "развернитесь",
        // Polish
        "zawróć", "zawroc", "zawracaj",
        // Czech
        "otočte se", "obrat",
        // Slovak
        "otočte sa",
        // Hungarian
        "forduljon meg", "megfordulás",
        // Romanian
        "întoarcere", "intoarcere", "întoarceți", "intoarceti",
        // Greek
        "αναστροφή", "κάντε αναστροφή",
        // Turkish
        "u dönüşü", "u donusu", "geri dön", "geri don",
        // Ukrainian
        "розворот", "розверніться",
        // Bulgarian
        "обратен завой"
    ]
    
    // MARK: - Arrival Detection
    
    static let arriveTokens = [
        // English
        "arrive", "arrival", "you have arrived",
        // German
        "ankommen", "ziel", "sie haben ihr ziel erreicht",
        // French
        "arrivée", "arriver", "vous êtes arrivé", "vous etes arrive",
        // Spanish
        "llegada", "llegue", "llegar", "ha llegado", "has llegado",
        // Italian
        "arrivo", "arrivare", "sei arrivato", "siete arrivati",
        // Portuguese
        "chegada", "você chegou", "voce chegou", "chegou",
        // Dutch
        "u bent gearriveerd", "aankomst", "u bent aangekomen",
        // Swedish
        "du är framme", "ni är framme", "ankomst",
        // Norwegian
        "du er fremme", "ankomst",
        // Danish
        "du er fremme", "ankomst",
        // Finnish
        "olet perillä", "saapuminen",
        // Japanese
        "到着",
        // Chinese (Simplified/Traditional)
        "到达", "到達", "您已到达", "你已到达", "您已到達", "你已到達",
        // Russian
        "вы прибыли", "прибытие", "прибудете",
        // Polish
        "dotarłeś", "dotarliście", "dojechałeś", "dojechaliście", "jesteś u celu",
        // Czech
        "dorazili jste", "jste v cíli", "dojeli jste", "příjezd",
        // Slovak
        "dorazili ste", "ste v cieli", "príchod",
        // Hungarian
        "megérkeztél", "megérkezett", "érkezés",
        // Romanian
        "ați ajuns", "ati ajuns", "sosire",
        // Greek
        "φτάσατε", "άφιξη", "αφιξη",
        // Turkish
        "vardınız", "ulaştınız", "ulastiniz", "varış",
        // Ukrainian
        "ви прибули", "прибуття",
        // Bulgarian
        "пристигнахте", "пристигане"
    ]
    
    // MARK: - Modifier Detection
    
    static let slightTokens = [
        // English
        "slight", "slightly", "bear right", "bear left", "half",
        // German
        "leicht", "halb",
        // French
        "légère", "legere",
        // Spanish
        "ligera", "ligero", "ligeramente",
        // Italian
        "leggera", "leggermente",
        // Portuguese
        "leve", "levemente", "ligeiramente", "meia",
        // Dutch
        "licht", "half",
        // Swedish/Norwegian/Danish
        "svagt", "svag", "lett", "halv",
        // Japanese
        "やや", "少し",
        // Chinese (Simplified/Traditional)
        "稍向", "略向", "稍微",
        // Russian
        "слегка", "немного",
        // Polish
        "lekko", "nieznacznie", "pół",
        // Czech
        "mírně", "lehce", "půl",
        // Slovak
        "mierne",
        // Hungarian
        "enyhén", "kicsit",
        // Romanian
        "uşor", "usor",
        // Greek
        "ελαφρά", "ελαφριά",
        // Turkish
        "hafif", "biraz",
        // Finnish
        "loivasti", "hieman", "puoli",
        // Ukrainian
        "злегка", "незначно",
        // Bulgarian
        "леко"
    ]
    
    static let sharpTokens = [
        // English
        "sharp",
        // German
        "scharf",
        // French
        "serrée", "serre",
        // Spanish/Portuguese
        "pronunciada", "pronunciado",
        // Spanish
        "cerrada",
        // Italian
        "stretta", "brusca",
        // Dutch/Scandinavian catch
        "scherp", "skarpt",
        // Japanese
        "急",
        // Chinese (Simplified/Traditional)
        "急转", "急轉",
        // Russian
        "резко", "круто",
        // Polish
        "ostro",
        // Czech
        "prudce", "ostře",
        // Slovak
        "prudko", "ostro",
        // Hungarian
        "élesen",
        // Romanian
        "brusc",
        // Greek
        "απότομα",
        // Turkish
        "keskin",
        // Finnish
        "jyrkästi", "jyrkkä",
        // Ukrainian
        "різко", "круто",
        // Bulgarian
        "рязко"
    ]
    
    // MARK: - Direction Detection
    
    static let leftTokens = [
        // English
        "left",
        // German
        "links",
        // French
        "gauche",
        // Spanish
        "izquierda",
        // Italian
        "sinistra",
        // Portuguese
        "esquerda", "à esquerda", "a esquerda",
        // Dutch
        "linksaf", "links af", "links",
        // Nordic
        "venstre", "vänster", "venstre",
        // Japanese
        "左", "ひだり",
        // Chinese (Simplified/Traditional)
        "左转", "左轉", "向左",
        // Russian
        "налево", "лево",
        // Polish
        "w lewo", "lewo",
        // Czech
        "vlevo", "doleva",
        // Slovak
        "vľavo", "doľava",
        // Hungarian
        "balra",
        // Romanian
        "la stânga", "stânga", "la stanga",
        // Greek
        "αριστερά",
        // Turkish
        "sola", "sol",
        // Finnish
        "vasemmalle",
        // Ukrainian
        "наліво", "ліворуч",
        // Bulgarian
        "наляво",
        // Slovenian
        "levo",
        // Croatian/Serbian/Bosnian
        "lijevo", "levo"
    ]
    
    static let rightTokens = [
        // English
        "right",
        // German
        "rechts",
        // French
        "droite",
        // Spanish
        "derecha",
        // Italian
        "destra",
        // Portuguese
        "direita", "à direita", "a direita",
        // Dutch
        "rechtsaf", "rechts af", "rechts",
        // Nordic
        "højre", "höger", "høyre", "hoyre",
        // Japanese
        "右", "みぎ",
        // Chinese (Simplified/Traditional)
        "右转", "右轉", "向右",
        // Russian
        "направо", "право",
        // Polish
        "w prawo", "prawo",
        // Czech
        "vpravo", "doprava",
        // Slovak
        "vpravo", "doprava",
        // Hungarian
        "jobbra",
        // Romanian
        "la dreapta", "dreapta",
        // Greek
        "δεξιά",
        // Turkish
        "sağa", "saga", "sağ", "sag",
        // Finnish
        "oikealle",
        // Ukrainian
        "направо", "праворуч",
        // Bulgarian
        "надясно",
        // Slovenian
        "desno",
        // Croatian/Serbian/Bosnian
        "desno"
    ]
}
