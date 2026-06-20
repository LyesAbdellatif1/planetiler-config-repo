"""
Flatten Overture Maps places GeoJSON to a simplified format
compatible with OMT-style tippecanoe tiling.

Maps Overture categories to OMT subclass values used in the style.
Filters out geographic features and low-confidence entries.
"""

import json, sys

# Categories to completely skip (not POIs - geographic or B2B noise)
EXCLUDE = {
    "structure_and_geography","river","mountain","lake","forest","beach",
    "cave","waterfall","fountain","national_park","nature_reserve","canal",
    "bridge","pier","hiking_trail","mountain_bike_trails","farm","wildlife_sanctuary",
    "agricultural_service","agriculture","environmental_conservation_organization",
    "environmental_conservation_and_ecological_organizations","chemical_plant",
    "mining","geological_services","wood_and_pulp","metal_fabricator",
    "iron_and_steel_industry","plastic_manufacturer","plastic_fabrication_company",
    "plastic_company","food_beverage_service_distribution","freight_and_cargo_service",
    "freight_forwarding_agency","railroad_freight","business_manufacturing_and_supply",
    "industrial_company","commercial_industrial","industrial_equipment",
    "b2b_apparel","b2b_electronic_equipment","b2b_jewelers","b2b_science_and_technology",
    "b2b_textiles","business_to_business","business_to_business_services",
    "business","corporate_office","business_management_services","business_consulting",
    "business_advertising","business_equipment_and_supply","business_to_business_services",
    "advertising_agency","marketing_agency","marketing_consultant","internet_marketing_service",
    "social_media_agency","social_media_company","media_agency","media_news_company",
    "media_news_website","print_media","radio_station","television_service_providers",
    "broadcasting_media_production","mass_media","topic_publisher","game_publisher",
    "record_label","movie_television_studio","video_film_production","videographer",
    "event_photography","photographer","graphic_designer","web_designer",
    "software_development","information_technology_company","it_service_and_computer_repair",
    "computer_coaching","computer_hardware_company","internet_service_provider",
    "telecommunications_company","telecommunications","electric_utility_provider",
    "energy_company","energy_equipment_and_solution","water_supplier","water_treatment_equipment_and_services",
    "public_utility_company","construction_services","contractor","plumbing","electrician",
    "carpenter","masonry_concrete","roofing","hvac_services","hvac_supplier",
    "home_improvement_store","home_developer","home_security","home_staging",
    "property_management","commercial_real_estate","real_estate","real_estate_agent",
    "real_estate_investment","real_estate_service","land_surveying","architect",
    "architectural_designer","engineering_services","civil_engineers","structural_engineer",
    "interior_design","painting","landscaping","gardener","home_cleaning",
    "janitorial_services","garbage_collection_service","recycling_center",
    "elevator_service","garage_door_service","windows_installation","countertop_installation",
    "carpet_store","carpet_cleaning","pool_cleaning","fence_and_gate_sales_service",
    "glass_and_mirror_sales_service","glass_manufacturer","granite_supplier",
    "metal_supplier","metal_plating_service","packing_supply","shipping_center",
    "rental_service","rental_services","storage_facility","immigration_assistance_services",
    "passport_and_visa_services","legal_services","lawyer","immigration_law",
    "wills_trusts_and_probate","employment_law","ip_and_internet_law","notary_public",
    "accountant","financial_advising","investing","currency_exchange","financial_service",
    "insurance_agency","trusts","process_servers","collection_agencies","credit_union",
    "installment_loans","labor_union","charity_organization","social_service_organizations",
    "community_services_non_profits","non_governmental_association","private_association",
    "youth_organizations","political_organization","political_party_office",
    "armed_forces_branch","public_and_government_association","public_service_and_government",
    "housing_authorities","employment_agencies","secretarial_services","translating_and_interpreting_services",
    "printing_services","screen_printing_t_shirt_printing","sign_making","trophy_shop",
    "packing_supply","vending_machine_supplier","appliance_manufacturer","appliance_repair_service",
    "appliance_store","audio_visual_equipment_store","office_equipment","educational_supply_store",
    "restaurant_equipment_and_supply","medical_supply","surgical_appliances_and_supplies",
    "pharmaceutical_companies","biotechnology_company","medical_research_and_development",
    "laboratory_testing","diagnostic_services","prosthetics","agricultural_cooperatives",
    "livestock_breeder","fishmonger","dairy_farm","fish_farm","meat_wholesaler",
    "wholesale_grocer","book_magazine_distribution","educational_research_institute",
    "research_institute","specialty_school","vocational_and_technical_school","cooking_school",
    "flight_school","cosmetology_school","dance_school","art_school","music_school",
    "music_production","bartending_school","nursing_school","computer_coaching",
    "career_counseling","counseling_and_mental_health","psychologist","psychotherapist",
    "psychic","astrologer","life_coach","hypnosis_hypnotherapy","sex_therapist",
    "personal_chef","food_consultant","nutrition","nutritionist","personal_assistant",
    "home_theater_systems_stores","tv_mounting","auto_detailing","auto_glass_service",
    "auto_body_shop","auto_customization","auto_restoration_services","oil_change_station",
    "motorcycle_repair","truck_repair","automotive_services_and_repair","engine_repair_service",
    "fire_protection_service","ambulance_and_ems_services","health_department",
    "medical_service_organizations","community_center","sports_and_fitness_instruction",
    "fitness_trainer","boxing_class","gymnastics_center","yoga_studio","dance_club",
    "martial_arts_club","amateur_sports_team","professional_sports_team","professional_sports_league",
    "esports_league","esports_team","school_sports_team","shooting_range","archery_range",
    "skatark","skate_park","equestrian_facility","horse_riding","horse_trainer","surfing",
    "scuba_diving_center","diving_center","canoe_and_kayak_hire_service","boat_service_and_repair",
    "boat_rental_and_training","boat_dealer","boat_tours","food_tours","historical_tours",
    "sightseeing_tour_agency","bus_tours","motorcycle_rentals","car_stereo_store",
    "automobile_registration_service","automobile_leasing","auto_manufacturers_and_distributors",
    "commercial_vehicle_dealer","truck_dealer","truck_rentals","recreational_vehicle_dealer",
    "rv_park","motorcycle_manufacturer","golf_cart_dealer","bike_repair_maintenance",
    "agricultural_service","travel_company","travel_services","travel_agents","travel",
    "tours","food_delivery_service","home_service","pet_breeder","pet_groomer","pet_services",
    "dog_trainer","animal_rescue_service","hair_removal","laser_hair_removal","waxing",
    "tanning_salon","skin_care","acupuncture","massage","massage_therapy","aromatherapy",
    "naturopathic_holistic","speech_therapist","audiologist","occupational_safety",
    "disability_services_and_support_organization","abuse_and_addiction_treatment",
    "alcohol_and_drug_treatment_centers","health_consultant","weight_loss_center",
    "food_beverage_service_distribution","junkyard","waste_processing",
    "e_cigarette_store","tobacco_shop","adult_entertainment","tattoo_and_piercing",
    "casino","race_track","paintball","atv_recreation_park","go_kart_club",
    "escape_rooms","comedy_club","arcad","arcade","music_venue","topic_concert_venue",
    "opera_and_ballet","performing_arts","drive_in_theater","auditorium","venue_and_event_space",
    "coworking_space","campus_building","flea_market","public_plaza","village_square",
    "petting_zoo","wildlife_sanctuary","national_park","nature_reserve","observatory",
    "planetarium","public_toilet","homeless_shelter","mission","convents_and_monasteries",
    "jehovahs_witness_kingdom_hall","meditation_center","retirement_home","disability",
    "caterer","event_planning","wedding_planning","party_and_event_planning","party_supply",
    "costume_store","luggage_store","bridal_shop","hair_extensions","wig_store",
    "bedding_and_bath_stores","linen","mattress_store","mattress_manufacturing",
    "carpet_cleaning","lumber_store","industrial_equipment","b2b_science_and_technology",
    "importer_and_exporter","exporters","hotel_supply_service","food_stand",
    "duty_free_shop","discount_store","outlet_store","pop_up_shop","thrift_store",
}

# Overture category → OMT subclass mapping
CATEGORY_MAP = {
    # --- FOOD & DRINK ---
    "restaurant": "restaurant", "pizza_restaurant": "restaurant",
    "burger_restaurant": "restaurant", "barbecue_restaurant": "restaurant",
    "seafood_restaurant": "restaurant", "french_restaurant": "restaurant",
    "italian_restaurant": "restaurant", "turkish_restaurant": "restaurant",
    "middle_eastern_restaurant": "restaurant", "arabian_restaurant": "restaurant",
    "moroccan_restaurant": "restaurant", "syrian_restaurant": "restaurant",
    "african_restaurant": "restaurant", "mediterranean_restaurant": "restaurant",
    "chicken_restaurant": "restaurant", "halal_restaurant": "restaurant",
    "asian_restaurant": "restaurant", "chinese_restaurant": "restaurant",
    "japanese_restaurant": "restaurant", "indian_restaurant": "restaurant",
    "korean_restaurant": "restaurant", "thai_restaurant": "restaurant",
    "mexican_restaurant": "restaurant", "american_restaurant": "restaurant",
    "spanish_restaurant": "restaurant", "german_restaurant": "restaurant",
    "belgian_restaurant": "restaurant", "latin_american_restaurant": "restaurant",
    "eastern_european_restaurant": "restaurant", "ethiopian_restaurant": "restaurant",
    "afghan_restaurant": "restaurant", "panamanian_restaurant": "restaurant",
    "honduran_restaurant": "restaurant", "burmese_restaurant": "restaurant",
    "taco_restaurant": "restaurant", "sandwich_shop": "restaurant",
    "diner": "restaurant", "theme_restaurant": "restaurant",
    "buffet_restaurant": "restaurant", "comfort_food_restaurant": "restaurant",
    "brasserie": "restaurant", "salad_bar": "restaurant",
    "soup_restaurant": "restaurant", "fish_and_chips_restaurant": "restaurant",
    "breakfast_and_brunch_restaurant": "restaurant", "food": "restaurant",
    "bar_and_grill_restaurant": "restaurant", "food_truck": "restaurant",
    "steak_restaurant": "restaurant", "steakhouse": "restaurant",
    "pancake_house": "restaurant", "sushi_restaurant": "restaurant",
    "asian_fusion_restaurant": "restaurant", "tapas_bar": "restaurant",
    "gluten_free_restaurant": "restaurant", "health_food_restaurant": "restaurant",
    "doner_kebab": "restaurant", "lebanese_restaurant": "restaurant",
    "eat_and_drink": "restaurant",

    "cafe": "cafe", "coffee_shop": "cafe", "tea_room": "cafe", "internet_cafe": "cafe",

    "bakery": "bakery", "patisserie_cake_shop": "bakery", "cupcake_shop": "bakery",
    "chocolatier": "bakery", "donuts": "bakery", "desserts": "bakery",
    "candy_store": "bakery", "ice_cream_shop": "ice_cream", "gelato": "ice_cream",

    "bar": "bar", "pub": "bar", "lounge": "bar", "hookah_bar": "bar",
    "beer_bar": "bar", "cocktail_bar": "bar", "wine_bar": "bar",
    "gastropub": "bar", "smoothie_juice_bar": "bar", "beer_garden": "bar",

    "butcher_shop": "butcher",

    # --- HEALTH ---
    "hospital": "hospital", "emergency_room": "hospital", "surgical_center": "hospital",
    "medical_center": "hospital",

    "pharmacy": "pharmacy",

    "doctor": "doctors", "family_practice": "doctors", "health_and_medical": "doctors",
    "physical_therapy": "doctors", "cardiologist": "doctors", "dermatologist": "doctors",
    "obstetrician_and_gynecologist": "doctors", "urologist": "doctors",
    "neurologist": "doctors", "pediatrician": "doctors", "pulmonologist": "doctors",
    "endocrinologist": "doctors", "gastroenterologist": "doctors",
    "rheumatologist": "doctors", "nephrologist": "doctors",
    "ear_nose_and_throat": "doctors", "radiologist": "doctors",
    "orthopedist": "doctors", "surgeon": "doctors", "plastic_surgeon": "doctors",
    "oral_surgeon": "doctors", "neuropathologist": "doctors",
    "ophthalmologist": "doctors", "internal_medicine": "doctors",
    "eye_care_clinic": "doctors", "optometrist": "doctors",
    "womens_health_clinic": "doctors", "maternity_centers": "doctors",
    "prenatal_perinatal_care": "doctors", "oncologist": "doctors",
    "nurse_practitioner": "doctors", "chiropractor": "doctors",
    "osteopathic_physician": "doctors", "psychiatrist": "doctors",
    "dialysis_clinic": "doctors", "medical_spa": "doctors",

    "dentist": "dentist", "cosmetic_dentist": "dentist",
    "general_dentistry": "dentist", "orthodontist": "dentist",
    "prosthodontist": "dentist", "periodontist": "dentist",
    "endodontist": "dentist", "cosmetic_dentistry": "dentist",

    "veterinarian": "veterinary",

    "gym": "sports_centre", "swimming_pool": "swimming", "water_park": "swimming",

    # --- EDUCATION ---
    "school": "school", "private_school": "school", "public_school": "school",
    "elementary_school": "school", "middle_school": "school",
    "high_school": "school", "language_school": "school",
    "religious_school": "school", "educational_services": "school",
    "education": "school", "preschool": "kindergarten",
    "day_care_preschool": "kindergarten",

    "college_university": "college", "medical_school": "college",

    "library": "library",

    # --- WORSHIP ---
    "mosque": "mosque",
    "church_cathedral": "church", "catholic_church": "church",
    "religious_organization": "place_of_worship",
    "synagogue": "synagogue",

    # --- LODGING ---
    "hotel": "hotel", "motel": "hotel", "hostel": "hostel",
    "resort": "hotel", "bed_and_breakfast": "hotel",
    "service_apartments": "hotel", "lodge": "hotel",
    "inn": "hotel", "cottage": "hotel", "cabin": "hotel",
    "accommodation": "hotel", "holiday_rental_home": "hotel",

    # --- GOVERNMENT ---
    "town_hall": "town_hall", "central_government_office": "town_hall",
    "courthouse": "town_hall", "public_service_and_government": "town_hall",
    "embassy": "embassy",
    "post_office": "post_office",
    "jail_and_prison": "prison",
    "police_department": "police", "law_enforcement": "police",
    "fire_department": "fire_station",

    # --- FINANCE ---
    "bank_credit_union": "bank", "banks": "bank",
    "atms": "atm",

    # --- TRANSPORT ---
    "gas_station": "fuel",
    "parking": "parking",
    "train_station": "station",
    "bus_station": "bus_station",
    "airport": "aerodrome",
    "car_rental_agency": "car_rental",
    "metro_station": "subway",

    # --- SHOPPING (all map to shop/clothing/grocery etc.) ---
    "shopping": "shop", "retail": "shop",
    "clothing_store": "clothes", "womens_clothing_store": "clothes",
    "mens_clothing_store": "clothes", "childrens_clothing_store": "clothes",
    "boutique": "clothes", "fashion": "clothes", "designer_clothing": "clothes",
    "sports_wear": "clothes", "lingerie_store": "clothes", "bridal_shop": "clothes",
    "shoe_store": "shoes", "jewelry_store": "jewelry",
    "furniture_store": "furniture", "home_goods_store": "shop",
    "appliance_store": "shop", "electronics": "shop",
    "computer_store": "shop", "mobile_phone_store": "shop",
    "hardware_store": "shop", "building_supply_store": "shop",
    "bookstore": "shop", "music_and_dvd_store": "shop",
    "toy_store": "shop", "pet_store": "shop",
    "arts_and_crafts": "shop", "souvenir_shop": "shop",
    "gift_shop": "shop", "flowers_and_gifts_shop": "florist",
    "eyewear_and_optician": "shop",
    "cosmetic_and_beauty_supplies": "shop",
    "vitamins_and_supplements": "shop",
    "health_food_store": "grocery",
    "sporting_goods": "shop", "outdoor_gear": "shop",
    "fabric_store": "shop", "fashion_accessories_store": "shop",
    "antique_store": "shop", "musical_instrument_store": "shop",
    "video_game_store": "shop", "hobby_shop": "shop",
    "art_gallery": "gallery",
    "department_store": "shop", "superstore": "shop",
    "wholesale_store": "shop",
    "shopping_center": "shop",
    "car_dealer": "shop", "automotive_dealer": "shop",
    "used_car_dealer": "shop", "motorcycle_dealer": "shop",
    "bicycle_shop": "bicycle",
    "home_improvement_store": "shop",
    "carpet_store": "shop", "furniture_assembly": "shop",
    "bags_luggage_company": "shop",
    "hair_supply_stores": "shop",
    "camera_store": "shop",
    "fruits_and_vegetables": "grocery",
    "grocery_store": "grocery",
    "convenience_store": "convenience",
    "supermarket": "supermarket",
    "specialty_grocery_store": "grocery",
    "organic_grocery_store": "grocery",
    "farmers_market": "grocery",
    "delicatessen": "grocery",

    # --- SERVICES ---
    "hair_salon": "hairdresser", "beauty_salon": "hairdresser",
    "barber": "hairdresser", "nail_salon": "hairdresser",
    "beauty_and_spa": "hairdresser", "spas": "hairdresser",
    "health_spa": "hairdresser",
    "laundromat": "laundry", "dry_cleaning": "laundry",

    # --- LEISURE / CULTURE ---
    "stadium_arena": "stadium", "soccer_stadium": "stadium",
    "football_stadium": "stadium", "baseball_stadium": "stadium",
    "soccer_field": "pitch", "basketball_court": "pitch",
    "tennis_court": "pitch", "sports_and_recreation_venue": "sports_centre",
    "sports_club_and_league": "sports_centre",

    "museum": "museum", "history_museum": "museum", "art_museum": "museum",
    "computer_museum": "museum", "childrens_museum": "museum",
    "modern_art_museum": "museum", "design_museum": "museum",
    "decorative_arts_museum": "museum",

    "cinema": "cinema",
    "theatre": "theatre", "theaters_and_performance_venues": "theatre",

    "zoo": "zoo", "aquarium": "aquarium",
    "amusement_park": "amusement_ride",
    "water_park": "amusement_ride",

    "park": "park", "public_plaza": "park",
    "playground": "playground",
    "campground": "camp_site",
    "golf_course": "golf_course",

    "landmark_and_historical_building": "attraction",
    "attractions_and_activities": "attraction",
    "arts_and_entertainment": "attraction",
    "cultural_center": "attraction",
    "monument": "monument", "castle": "castle",
    "palace": "castle", "fort": "castle",
    "lighthouse": "lighthouse",
    "national_park": "park",
    "botanical_garden": "garden",
    "marina": "marina",
    "ferry_boat_company": "ferry_terminal",
    "bus_station": "bus_station",

    "professional_services": "office",
    "community_services_non_profits": "office",

    # --- AUTOMOTIVE ---
    "automotive_repair": "car_repair", "automotive_parts_and_accessories": "car_repair",
    "automotive": "car_repair", "car_wash": "car_repair",
    "tire_dealer_and_repair": "car_repair", "auto_company": "car_repair",
    "emissions_inspection": "car_repair", "automotive_consultant": "car_repair",
    "auto_parts_and_supply_store": "car_repair",
    "automotive_wheel_polishing_service": "car_repair",
    "recreation_vehicle_repair": "car_repair",

    # --- FOOD (missed variants) ---
    "fast_food_restaurant": "fast_food",
    "hotel_bar": "bar", "brewery": "bar",
    "cheese_shop": "grocery",
    "russian_restaurant": "restaurant", "ecuadorian_restaurant": "restaurant",
    "fondue_restaurant": "restaurant", "indo_chinese_restaurant": "restaurant",
    "basque_restaurant": "restaurant", "texmex_restaurant": "restaurant",
    "polynesian_restaurant": "restaurant",

    # --- EDUCATION ---
    "driving_school": "school", "tutoring_center": "school",
    "educational_camp": "school", "first_aid_class": "school",

    # --- HEALTH ---
    "allergist": "doctors", "podiatrist": "doctors",
    "fertility": "doctors", "home_health_care": "doctors",
    "senior_citizen_services": "doctors",
    "teeth_whitening": "dentist",

    # --- LEISURE ---
    "active_life": "sports_centre", "pool_billiards": "sports_centre",
    "squash_court": "pitch", "swimming_instructor": "swimming",
    "bowling_alley": "sports_centre",

    # --- SHOPS & SERVICES ---
    "sewing_and_alterations": "shop", "nursery_and_gardening": "shop",
    "hunting_and_fishing_supplies": "shop", "photography_store_and_services": "shop",
    "lighting_store": "shop", "aquatic_pet_store": "shop",
    "home_and_garden": "shop", "key_and_locksmith": "shop",
    "newspaper_and_magazines_store": "shop", "paint_store": "shop",
    "electrical_supply_store": "shop", "shoe_repair": "shop",
    "motorsports_store": "shop", "comic_books_store": "shop",
    "mobile_phone_accessories": "shop", "swimwear_store": "clothes",

    # --- TRANSPORT ---
    "taxi_service": "car_rental",
    "airport_lounge": "aerodrome", "airport_terminal": "aerodrome",
    "airline": "aerodrome", "airlines": "aerodrome",
    "public_transportation": "station",

    # --- CULTURE ---
    "civilization_museum": "museum",

    # --- GOVERNMENT ---
    "department_of_motor_vehicles": "town_hall",
}

# Minimum confidence threshold
MIN_CONFIDENCE = 0.3

def process(input_path, output_path):
    print(f"Loading {input_path}...", flush=True)
    with open(input_path) as f:
        data = json.load(f)

    features = data["features"]
    print(f"Input: {len(features)} features", flush=True)

    out_features = []
    skipped_geo = 0
    skipped_conf = 0
    skipped_nomap = 0

    for feat in features:
        props = feat.get("properties", {})
        cats = props.get("categories") or {}
        primary = cats.get("primary") or ""
        confidence = props.get("confidence") or 0
        names = props.get("names") or {}
        name = names.get("primary") or ""

        # Skip geographic/noise categories
        if primary in EXCLUDE:
            skipped_geo += 1
            continue

        # Skip low confidence
        if confidence < MIN_CONFIDENCE:
            skipped_conf += 1
            continue

        # Map category
        subclass = CATEGORY_MAP.get(primary)
        if not subclass:
            skipped_nomap += 1
            continue

        out_features.append({
            "type": "Feature",
            "geometry": feat["geometry"],
            "properties": {
                "name": name,
                "subclass": subclass,
                "confidence": round(confidence, 3),
                "overture_category": primary,
            }
        })

    print(f"Kept: {len(out_features)}", flush=True)
    print(f"Skipped geographic: {skipped_geo}", flush=True)
    print(f"Skipped low confidence (<{MIN_CONFIDENCE}): {skipped_conf}", flush=True)
    print(f"Skipped unmapped category: {skipped_nomap}", flush=True)

    with open(output_path, "w", encoding="utf-8") as f:
        json.dump({"type": "FeatureCollection", "features": out_features}, f, ensure_ascii=False)

    print(f"Written to {output_path}", flush=True)

if __name__ == "__main__":
    inp = sys.argv[1] if len(sys.argv) > 1 else "/data/algeria-overture.geojson"
    out = sys.argv[2] if len(sys.argv) > 2 else "/data/algeria-overture-flat.geojson"
    process(inp, out)
