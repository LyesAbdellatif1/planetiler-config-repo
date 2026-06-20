"""
Audit unmapped Overture categories: find all category values that
- are not in the EXCLUDE list
- pass the confidence threshold
- are not in the current CATEGORY_MAP
Print them sorted by count.
"""
import json, sys
from collections import Counter

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
    "business_advertising","business_equipment_and_supply",
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
    "petting_zoo","wildlife_sanctuary","observatory",
    "planetarium","public_toilet","homeless_shelter","mission","convents_and_monasteries",
    "jehovahs_witness_kingdom_hall","meditation_center","retirement_home","disability",
    "caterer","event_planning","wedding_planning","party_and_event_planning","party_supply",
    "costume_store","luggage_store","bridal_shop","hair_extensions","wig_store",
    "bedding_and_bath_stores","linen","mattress_store","mattress_manufacturing",
    "carpet_cleaning","lumber_store",
    "importer_and_exporter","exporters","hotel_supply_service","food_stand",
    "duty_free_shop","discount_store","outlet_store","pop_up_shop","thrift_store",
}

CATEGORY_MAP_KEYS = {
    "restaurant","pizza_restaurant","burger_restaurant","barbecue_restaurant","seafood_restaurant",
    "french_restaurant","italian_restaurant","turkish_restaurant","middle_eastern_restaurant",
    "arabian_restaurant","moroccan_restaurant","syrian_restaurant","african_restaurant",
    "mediterranean_restaurant","chicken_restaurant","halal_restaurant","asian_restaurant",
    "chinese_restaurant","japanese_restaurant","indian_restaurant","korean_restaurant",
    "thai_restaurant","mexican_restaurant","american_restaurant","spanish_restaurant",
    "german_restaurant","belgian_restaurant","latin_american_restaurant","eastern_european_restaurant",
    "ethiopian_restaurant","afghan_restaurant","panamanian_restaurant","honduran_restaurant",
    "burmese_restaurant","taco_restaurant","sandwich_shop","diner","theme_restaurant",
    "buffet_restaurant","comfort_food_restaurant","brasserie","salad_bar","soup_restaurant",
    "fish_and_chips_restaurant","breakfast_and_brunch_restaurant","food","bar_and_grill_restaurant",
    "food_truck","steak_restaurant","steakhouse","pancake_house","sushi_restaurant",
    "asian_fusion_restaurant","tapas_bar","gluten_free_restaurant","health_food_restaurant",
    "doner_kebab","lebanese_restaurant","eat_and_drink","cafe","coffee_shop","tea_room",
    "internet_cafe","bakery","patisserie_cake_shop","cupcake_shop","chocolatier","donuts",
    "desserts","candy_store","ice_cream_shop","gelato","bar","pub","lounge","hookah_bar",
    "beer_bar","cocktail_bar","wine_bar","gastropub","smoothie_juice_bar","beer_garden",
    "butcher_shop","hospital","emergency_room","surgical_center","medical_center","pharmacy",
    "doctor","family_practice","health_and_medical","physical_therapy","cardiologist",
    "dermatologist","obstetrician_and_gynecologist","urologist","neurologist","pediatrician",
    "pulmonologist","endocrinologist","gastroenterologist","rheumatologist","nephrologist",
    "ear_nose_and_throat","radiologist","orthopedist","surgeon","plastic_surgeon","oral_surgeon",
    "neuropathologist","ophthalmologist","internal_medicine","eye_care_clinic","optometrist",
    "womens_health_clinic","maternity_centers","prenatal_perinatal_care","oncologist",
    "nurse_practitioner","chiropractor","osteopathic_physician","psychiatrist","dialysis_clinic",
    "medical_spa","dentist","cosmetic_dentist","general_dentistry","orthodontist","prosthodontist",
    "periodontist","endodontist","cosmetic_dentistry","veterinarian","gym","swimming_pool",
    "water_park","school","private_school","public_school","elementary_school","middle_school",
    "high_school","language_school","religious_school","educational_services","education",
    "preschool","day_care_preschool","college_university","medical_school","library","mosque",
    "church_cathedral","catholic_church","religious_organization","synagogue","hotel","motel",
    "hostel","resort","bed_and_breakfast","service_apartments","lodge","inn","cottage","cabin",
    "accommodation","holiday_rental_home","town_hall","central_government_office","courthouse",
    "public_service_and_government","embassy","post_office","jail_and_prison","police_department",
    "law_enforcement","fire_department","bank_credit_union","banks","atms","gas_station",
    "parking","train_station","bus_station","airport","car_rental_agency","metro_station",
    "shopping","retail","clothing_store","womens_clothing_store","mens_clothing_store",
    "childrens_clothing_store","boutique","fashion","designer_clothing","sports_wear",
    "lingerie_store","shoe_store","jewelry_store","furniture_store",
    "home_goods_store","electronics","computer_store","mobile_phone_store",
    "hardware_store","building_supply_store","bookstore","music_and_dvd_store","toy_store",
    "pet_store","arts_and_crafts","souvenir_shop","gift_shop","flowers_and_gifts_shop",
    "eyewear_and_optician","cosmetic_and_beauty_supplies","vitamins_and_supplements",
    "health_food_store","sporting_goods","outdoor_gear","fabric_store","fashion_accessories_store",
    "antique_store","musical_instrument_store","video_game_store","hobby_shop","art_gallery",
    "department_store","superstore","wholesale_store","shopping_center","car_dealer",
    "automotive_dealer","used_car_dealer","motorcycle_dealer","bicycle_shop",
    "furniture_assembly","bags_luggage_company","hair_supply_stores","camera_store",
    "fruits_and_vegetables","grocery_store","convenience_store","supermarket","specialty_grocery_store",
    "organic_grocery_store","farmers_market","delicatessen","hair_salon","beauty_salon","barber",
    "nail_salon","beauty_and_spa","spas","health_spa","laundromat","dry_cleaning","stadium_arena",
    "soccer_stadium","football_stadium","baseball_stadium","soccer_field","basketball_court",
    "tennis_court","sports_and_recreation_venue","sports_club_and_league","museum","history_museum",
    "art_museum","computer_museum","childrens_museum","modern_art_museum","design_museum",
    "decorative_arts_museum","cinema","theatre","theaters_and_performance_venues","zoo","aquarium",
    "amusement_park","park","playground","campground","golf_course",
    "landmark_and_historical_building","attractions_and_activities","arts_and_entertainment",
    "cultural_center","monument","castle","palace","fort","lighthouse",
    "botanical_garden","marina","ferry_boat_company","professional_services",
    "community_services_non_profits",
}

MIN_CONFIDENCE = 0.3

input_path = sys.argv[1] if len(sys.argv) > 1 else "/data/algeria-overture.geojson"
print(f"Loading {input_path}...", flush=True)
with open(input_path) as f:
    data = json.load(f)

counts = Counter()
for feat in data["features"]:
    props = feat.get("properties", {})
    cats = props.get("categories") or {}
    primary = cats.get("primary") or ""
    confidence = props.get("confidence") or 0
    if primary in EXCLUDE:
        continue
    if confidence < MIN_CONFIDENCE:
        continue
    if primary not in CATEGORY_MAP_KEYS:
        counts[primary] += 1

print("TOP UNMAPPED CATEGORIES (passed confidence filter, not excluded, not in CATEGORY_MAP):")
print(f"{'COUNT':>6}  CATEGORY")
print("-" * 50)
for cat, cnt in sorted(counts.items(), key=lambda x: -x[1]):
    print(f"{cnt:6d}  {cat}")
print("-" * 50)
print(f"TOTAL: {sum(counts.values())} features across {len(counts)} categories")
