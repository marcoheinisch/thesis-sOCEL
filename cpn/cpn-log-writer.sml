(* reuses code from https://doi.org/10.5281/zenodo.8289899 **)


(***********************)
(* helper              *)
(***********************)

fun str_pointer_str(letter, id_str) = "(Pointer-"^letter^"-"^id_str^")"
fun str_pointer(letter, id) = str_pointer_str(letter, (Int.toString id))

(* generic function for writing a list of strings to .csv *)
fun write_record(file_id, l) = 
let
   val file = TextIO.openAppend(file_id)
   val _ = TextIO.output(file, list2string(l))
   val _ = TextIO.output(file, "\n")
in
   TextIO.closeOut(file)
end;

(* write event to table "event" and respective event type table *)
fun write_event(event_id, et: EventType, ea_values: string list) = 
let
	val event_file_id = OUTPUT_PATH ^ "event.csv"
	val event_type_file_id = OUTPUT_PATH ^ "event_" ^ event_map_type(et) ^ ".csv"
	val time = t2s(Mtime())
	val _ = write_record(event_file_id, [event_id, et])
	val _ = write_record(event_type_file_id, [event_id,time]^^ea_values)
in
   event_id
end;


(* Function to sum up all elements in the list of strings, handling both int and real values *)
fun stringToReal s =
    case Real.fromString s of
         SOME r => SOME r
       | NONE => (case Int.fromString s of
                      SOME i => SOME (Real.fromInt i)
                    | NONE => NONE)

fun sumCalls (strList : string list) : real =
    let
        val realListOption = List.map stringToReal strList
        val realList = List.mapPartial (fn SOME x => SOME x | NONE => NONE) realListOption
    in
        List.foldl (op +) 0.0 realList
    end

(* helper Relations    *)

fun write_relations_recursively(file, []) = TextIO.closeOut(file) | 
write_relations_recursively(file, [obj_id1, obj_id2, qualifier]::qualified_pairs) = 
   (TextIO.output(file, list2string([obj_id1, obj_id2, qualifier]));
   TextIO.output(file, "\n");
   write_relations_recursively(file, qualified_pairs));

fun write_e2o_relations(qualified_pairs) =
let
   val file = TextIO.openAppend(OUTPUT_PATH ^ "event_object.csv")
in
   write_relations_recursively(file, qualified_pairs)
end;

(* write qualified relations to table "object_object" *)
fun write_o2o_relations(qualified_pairs) =
let
   val file = TextIO.openAppend(OUTPUT_PATH ^ "object_object.csv")
in
   write_relations_recursively(file, qualified_pairs)
end;

(* helper OBJECTS      *)

(* write object to table "object" and respective object type table *)
fun initialize_objects_recursively(object_file, object_type_file, object_type, []) = (TextIO.closeOut(object_file); TextIO.closeOut(object_type_file)) |
initialize_objects_recursively(object_file, object_type_file, object_type, (object_id::oa_values)::objects_with_attribute_values) =
let
	val ocel_time = t2s(Mtime())
	val changed_field = ""
in
   (TextIO.output(object_file, list2string([object_id, object_type]));
   TextIO.output(object_file, "\n");
   TextIO.output(object_type_file, list2string([object_id, ocel_time, changed_field]^^oa_values));
   TextIO.output(object_type_file, "\n");  
   initialize_objects_recursively(object_file, object_type_file, object_type, objects_with_attribute_values))
end;

fun initialize_objects(object_type, objects_with_attribute_values) = 
let
   val object_file_id = OUTPUT_PATH ^ "object.csv"
   val object_type_file_id = OUTPUT_PATH ^ "object_" ^ object_map_type(object_type) ^ ".csv"
   val object_file = TextIO.openAppend(object_file_id)
   val object_type_file = TextIO.openAppend(object_type_file_id)
in
   initialize_objects_recursively(object_file, object_type_file, object_type, objects_with_attribute_values)
end;

(* object attribute change *)
fun concat([], ys) = ys
  | concat(x::xs, ys) = x :: concat(xs, ys);

fun change_oat(ocel_id, object, changed_oat_field, fields) =
let
   val ocel_time = t2s(Mtime())
   val change_entry = concat([ocel_id, ocel_time, changed_oat_field], fields)
   val object_type_file_id = OUTPUT_PATH ^ "object_" ^ object ^ ".csv"
in
   write_record(object_type_file_id, change_entry)
end;


(***********************)
(* Object initializers *)
(***********************)

val MATERIAL_STEEL = "DC01"

fun id_of_SteelCoil(id) = "o_steelcoil_"^(Int.toString id);
fun id_of_SteelPin(id) = "o_steelpin_"^(Int.toString id);
fun id_of_FormedPart(id) = "o_formedpart_"^(Int.toString id);
fun id_of_SteelSheet(id) = "o_steelsheet_"^(Int.toString id);
fun id_of_MalePart(id) = "o_malepart_"^(Int.toString id);
fun id_of_FemalePart(id) = "o_femalepart_"^(Int.toString id);
fun id_of_Hinge(id3) = "o_hinge_"^(Int.toString id3);
fun id_of_HingePack(id) = "o_hingepack_"^(Int.toString id);
fun id_of_Workstation(id) = "o_workstation_"^(Int.toString id);
fun id_of_Machine(id_str) = "o_machine_"^id_str;
fun id_of_Facility(id) = "o_facility_"^(Int.toString id);
fun id_of_Worker(id) = "o_worker_"^(Int.toString id);


(* "p_mass[kg]", "p_init-len[cm]", "p_width[cm]", "i_material-cold-rolled-steel-coil[kg]", "s_co2e[kg]" *)
fun initialize_SteelCoil((id, m1, len1, wid1):SteelCoil) = 
let
	val objects_id = id_of_SteelCoil(id)
	val p_mass = (Real.toString m1)
   val p_init_len = (Real.toString len1)
   val p_width = (Real.toString wid1)
   val i_material = p_mass
   val i_steel_waste = "?"

   val s_co2e = call("id_material-cold-rolled-steel-coil", p_mass)
   val objects_with_attribute_values = [(objects_id)::[p_mass, MATERIAL_STEEL, p_init_len, p_width, i_material, s_co2e, i_steel_waste]]
in
   initialize_objects("SteelCoil", objects_with_attribute_values)
end;

(* "p_mass[kg]", "i_material-steel-pin[kg]","s_co2e[kg]" *)
fun initialize_SteelPin((id, m1):SteelPin) = 
let
	val objects_id = id_of_SteelPin(id)
	val p_mass = (Real.toString m1)
   val i_material = p_mass
   val s_co2e = call("id_steel_rivets[kg]", p_mass)
   val objects_with_attribute_values = [(objects_id)::[p_mass, MATERIAL_STEEL, i_material, s_co2e]]
in
   initialize_objects("SteelPin", objects_with_attribute_values)
end;

(* "p_mass[kg]", "s_co2e[kg]" *)
fun initialize_SteelSheet((id, m1, len1, wid1):SteelSheet) = 
let
   val objects_id = id_of_SteelSheet(id)
	val p_mass = (Real.toString m1)
   val s_co2e = "0"
   val objects_with_attribute_values = [objects_id::[p_mass, MATERIAL_STEEL, s_co2e]]
in
   initialize_objects("SteelSheet", objects_with_attribute_values)
end;

(* "p_mass[kg]", "s_co2e[kg]" *)
fun initialize_FormedPart((id, m1,wid1):FormedPart) = 
let
   val objects_id = id_of_FormedPart(id)
	val p_mass = "?" (* -> simulate unknown data *)
   val s_co2e = "0"
   val objects_with_attribute_values = [objects_id::[p_mass, MATERIAL_STEEL, s_co2e]]
in
   initialize_objects("FormedPart", objects_with_attribute_values)
end;

(* "p_mass[kg]", "s_co2e[kg]" *)
fun initialize_MalePart((id, m1,wid1):MalePart) = 
let
   val objects_id = id_of_MalePart(id)
	val p_mass = "?"
   val s_co2e = "?"
	val i_mass_waste = "?"
   val objects_with_attribute_values = [objects_id::[p_mass, MATERIAL_STEEL, s_co2e, i_mass_waste]]
in
   initialize_objects("MalePart", objects_with_attribute_values)
end;

(* "p_mass[kg]", "s_co2e[kg]" *)
fun initialize_FemalePart((id, m1,wid1):FemalePart) = 
let
   val objects_id = id_of_FemalePart(id)
	val p_mass = "?"
   val s_co2e = "?"
	val i_mass_waste = "?"
   val objects_with_attribute_values = [objects_id::[p_mass, MATERIAL_STEEL, s_co2e, i_mass_waste]]
in
   initialize_objects("FemalePart", objects_with_attribute_values)
end;

(* "p_mass[kg]", "s_co2e[kg]" *)
fun initialize_Hinge((id, m1): Hinge) = 
let
   val objects_id = id_of_Hinge(id)
	val p_mass = (Real.toString m1)
   val s_co2e = "0"
   val objects_with_attribute_values = [objects_id::[p_mass, MATERIAL_STEEL, s_co2e]]
in
   initialize_objects("Hinge", objects_with_attribute_values)
end;

(* "p_mass[kg]", "s_co2e[kg]" *)
fun initialize_HingePack(id) =
let 
   val objects_id = "o_hingepack_"^(Int.toString id)
	val p_mass = "?"
   val s_co2e = "0"
   val objects_with_attribute_values = [objects_id::[p_mass, MATERIAL_STEEL, s_co2e]]
in
   initialize_objects("HingePack", objects_with_attribute_values)
end;

(***********************)
(* object initializers - non cpn*)
(***********************)

fun initialize_Facility(id) =
let 
   val objects_id = id_of_Facility(id)
   val metadaata = "DE01"
   val objects_with_attribute_values = [objects_id::[metadaata]]
in
   initialize_objects("Facility", objects_with_attribute_values)
end;

fun initialize_Workstation(id, facility_id) =
let 
   val objects_id = id_of_Workstation(id)
   val p_electricity = str_pointer("W-E", id)
   val p_compressed_air = str_pointer("W-A", id)
   val objects_with_attribute_values = [objects_id::[objects_id, p_compressed_air]]
   val o2o_relations = [[objects_id,id_of_Facility(facility_id), "located at"]]
in
   initialize_objects("Workstation", objects_with_attribute_values);
   write_o2o_relations(o2o_relations)
end;

fun initialize_Machine(id, id_ws) =
let 
   val objects_id = id_of_Machine(id)
   val p_electricity = str_pointer_str("M-electr", id)
   val p_gas = str_pointer_str("M-gas", id)
   val objects_with_attribute_values = [objects_id::[p_electricity, p_gas]]
   val o2o_relations = [[objects_id,id_of_Workstation(id_ws), "located at"]] 
in
   initialize_objects("Machine", objects_with_attribute_values);
   write_o2o_relations(o2o_relations)
end;

fun initialize_Worker(id) =
let 
   val objects_id = id_of_Worker(id)
   val objects_with_attribute_values = [objects_id::["?"]]
in
   initialize_objects("Worker", objects_with_attribute_values)
end;

(***********************)
(* Event PRE CPN        *) 
(***********************)  

fun initialize_meta_objects() = (
   initialize_Facility(1);
   initialize_Workstation(1, 1);
   initialize_Workstation(2, 1);
   initialize_Workstation(3, 1);
   initialize_Machine("splitter01",1);
   initialize_Machine("oven01",1);
   initialize_Machine("former02",1);
   initialize_Machine("coater03",1);
   initialize_Machine("cutter01",2);
   initialize_Machine("assembler01",3);
   initialize_Machine("packer01",3);
   initialize_Worker(1)
);

(***********************)
(* Event in CPN        *)
(***********************)

(*"s_co2e[kg]", "i_electric-from-grid-de[J]", "i_steel-waste-to-recycle[kg]"*)
fun write_SplitSteelSheet(coil_id:int, (id1, m1, len1, wid1):SteelSheet, mWaste:real) = 
let
   val event_id = "e_split_"^(Int.toString id1)
   val event_coil = [[event_id, id_of_SteelCoil(coil_id), "on"]]
	val event_sp = [[event_id, id_of_SteelSheet(id1), "output"]]
	val event_machine = [[event_id, id_of_Machine("splitter01"), "with"]]
	val event_location = [[event_id, id_of_Workstation(1), "located at"]]
   val e2o_relations = event_coil^^event_sp^^event_location^^event_machine
   val duration_s = DelaySplitSteelCoil()

   val p_duration = Real.toString duration_s
   val i_electric = Real.toString (p_electricity_laser_a(0.0, duration_s, "on"))
   val i_steel_waste = Real.toString mWaste
   
   val calls = [call("id_waste-type_scrap_metal-open", i_steel_waste), call("id_electric_kwh", i_electric)]
   val s_co2e = Real.toString (sumCalls(calls))
   
   val o2o_relations = [[id_of_SteelSheet(id1),id_of_SteelCoil(coil_id), "created from"]]
in
	write_event(event_id, "SplitSteelSheet", [p_duration, s_co2e, i_electric, i_steel_waste]);
	initialize_SteelSheet((id1, m1, len1, wid1));
   write_e2o_relations(e2o_relations);
   write_o2o_relations(o2o_relations)
end;

(*"s_co2e[kg]", "i_electric-from-grid-de[J]", "i_gas[m3]", "i_burn-emission-to-nature[kg]"*)
fun write_HeatSteelSheet((id1, m1, len1, wid1): SteelSheet) = 
let
   val event_id = "e_heat_"^(Int.toString id1)
   val event_s = [[event_id, id_of_SteelSheet(id1), "on"]]
	val event_location = [[event_id, id_of_Workstation(1), "located at"]]
	val event_machine = [[event_id, id_of_Machine("oven01"), "with"]]
   val e2o_relations = event_s^^event_location^^event_machine

   val duration_s = DurationHeating()
   
   val i_electric = Real.toString (sim_electricity_heating(duration_s))
   val i_gas = Real.toString (p_gas_heating(0.0, duration_s, "on"))
   val p_duration = Real.toString (duration_s)
   val i_emission_du_gas = i_gas
   
   val calls = [call("id_gas_upstream_kwh[Wh]", i_gas), call("id_gas_combustion_Wh", i_emission_du_gas), call("id_electric_kwh", i_electric)]
   val s_co2e = Real.toString (sumCalls(calls))
in
	write_event(event_id, "HeatSteelSheet", [p_duration, s_co2e, i_electric, i_gas, i_emission_du_gas]);
   write_e2o_relations(e2o_relations)
end;

fun write_FormSteelSheet((id1, m1, len1, wid1): SteelSheet, (id2, m2, wid2):FormedPart) = 
let
   val event_id = "e_form_"^(Int.toString id2)
   val event_s = [[event_id, id_of_SteelSheet(id1), "input"]]
   val event_fs = [[event_id, id_of_FormedPart(id2), "output"]]
	val event_location = [[event_id, id_of_Workstation(1), "located at"]]
	val event_machine = [[event_id, id_of_Machine("former02"), "with"]]
   val e2o_relations = event_s^^event_fs^^event_location^^event_machine

   val p_duration = Real.toString FORMING_TIME
   val i_electric = Real.toString (p_electricity_forming(0.0, FORMING_TIME, "on"))

   val calls = [call("id_electric_kwh", i_electric)]
   val s_co2e = Real.toString (sumCalls(calls))

   val o2o_relations = [[id_of_FormedPart(id2),id_of_SteelSheet(id1), "created from"]]
in
	write_event(event_id, "FormSteelSheet", [p_duration, s_co2e, i_electric]);
	initialize_FormedPart((id2, m2, wid2));
   write_e2o_relations(e2o_relations);
   write_o2o_relations(o2o_relations)
end;

fun write_CoatPart((id1, m1, wid1): FormedPart) = 
let
   val part_id = id_of_FormedPart(id1)
   val event_id = "e_coat_"^(Int.toString id1)
   val event_s = [[event_id, part_id, "on"]]
	val event_location = [[event_id, id_of_Workstation(1), "located at"]]
	val event_machine = [[event_id, id_of_Machine("coater03"), "with"]]
   val e2o_relations = event_s^^event_location^^event_machine

   val p_duration = Real.toString COATING_TIME
   val i_electric = Real.toString (p_electricity_coating(0.0, COATING_TIME, "on"))
   val (i_coating, i_coating_waste, surface_m2) = sim_coat_usage()

   (* TODO Add coatings, FIX litre vs kilogramm*)

   val calls = [call("id_electric_kwh", i_electric), call("id_coating[m2]", (Real.toString surface_m2)), call("id_industrial-waste[kg]", (Real.toString i_coating_waste))]
   val s_co2e = Real.toString (sumCalls(calls))
in
	write_event(event_id, "CoatPart", [p_duration, s_co2e, i_electric, (Real.toString i_coating), (Real.toString i_coating_waste)]);
   write_e2o_relations(e2o_relations);
   change_oat(part_id, "FormedPart", "p_mass[kg]", [(Real.toString m1), "", ""])
end;

(*"s_co2e[kg]", "i_electric-from-grid-de[J]", "i_compressed-air[m3]", "i_gas-n2-used[m3]","i_gas-n2-emiited-to-air[m3]", "i_steel-waste[kg]"*)
fun write_CuttMalePart((id1, m1, wid1): FormedPart, (id2, m2, wid2):MalePart) =
let
   val event_id = "e_formmale_"^(Int.toString id2)
   val event_male = [[event_id, id_of_MalePart(id2), "output"]]
   val event_fs = [[event_id, id_of_FormedPart(id1), "input"]]
	val event_location = [[event_id, id_of_Workstation(2), "located at"]]
	val event_machine = [[event_id, id_of_Machine("cutter01"), "with"]]
   val e2o_relations = event_male^^event_fs^^event_location^^event_machine

   val duration_s = DelayCuttPartMale()
   val compressed_air_m3 = sim_compressed_air(duration_s)

   val p_duration = Real.toString duration_s
   val i_electric = Real.toString (p_electricity_laser_a(0.0, duration_s, "on"))
   val i_compressed = Real.toString compressed_air_m3
   val i_gas_n2 = Real.toString (sim_gas_n2(duration_s))
   val i_gas_n2_emitted = i_gas_n2
   val i_steel_waste = "?"
   (*val i_steel_waste = Real.toString (roundNth(m1-m2, 5)) <-- Implicit given, must be minded*)

   val electric_from_air = Real.toString (electric_from_compressed_air(compressed_air_m3))
   val calls = [call("id_electric_kwh", i_electric), call("id_electric_kwh", electric_from_air), call("id_n2_gas", i_gas_n2)]
   val s_co2e = Real.toString (sumCalls(calls))
   
   val o2o_relations = [[id_of_MalePart(id2),id_of_FormedPart(id1), "created from"]]
in
	write_event(event_id, "CuttMalePart", [p_duration, s_co2e, i_electric, i_compressed, i_gas_n2, i_gas_n2_emitted, i_steel_waste]);
   initialize_MalePart((id2, m2, wid2));
   write_e2o_relations(e2o_relations);
   write_o2o_relations(o2o_relations)
end; 

fun write_CuttFemalePart((id1, m1, wid1): FormedPart, (id2, m2, wid2):FemalePart) =
let
   val event_id = "e_formfemale_"^(Int.toString id2)
   val event_female = [[event_id, id_of_FemalePart(id2), "output"]]
   val event_fs = [[event_id, id_of_FormedPart(id1), "input"]]
	val event_location = [[event_id, id_of_Workstation(2), "located at"]]
	val event_machine = [[event_id, id_of_Machine("cutter01"), "with"]]
   val e2o_relations = event_female^^event_fs^^event_location^^event_machine

   val duration_s = DelayCuttPartFemale() 
   val compressed_air_m3 = sim_compressed_air(duration_s)

   val p_duration = Real.toString duration_s
   val i_electric = Real.toString (p_electricity_laser_a(0.0, duration_s, "on"))
   val i_compressed = Real.toString compressed_air_m3
   val i_gas_n2 = Real.toString (sim_gas_n2(duration_s))
   val i_gas_n2_emitted = i_gas_n2 (* no impact *)
   val i_steel_waste = Real.toString (roundNth(m1-m2, 5))

   val electric_from_air = Real.toString (electric_from_compressed_air(compressed_air_m3))
   val calls = [call("id_electric_kwh", i_electric), call("id_electric_kwh", electric_from_air), call("id_n2_gas", i_gas_n2)]
   val s_co2e = Real.toString (sumCalls(calls))
   
   val o2o_relations = [[id_of_FemalePart(id2),id_of_FormedPart(id1), "created from"]]
in
	write_event(event_id, "CuttFemalePart", [p_duration, s_co2e, i_electric, i_compressed, i_gas_n2, i_gas_n2_emitted, i_steel_waste]);
   initialize_FemalePart((id2, m2, wid2));
   write_e2o_relations(e2o_relations);
   write_o2o_relations(o2o_relations)
end; 

(*TODO: Add steel waste object*)

(*"s_co2e[kg]", "i_compressed-air[m3]", "i_steel-waste[kg]"*)
fun write_CheckMalePart((id1, m1, wid1), ok) = 
let
   val event_id = "e_checkMale_"^(Int.toString id1)^">"^(Bool.toString ok)
   val objects_id_mp = id_of_MalePart(id1)
   val event_male = [[event_id, objects_id_mp, "on"]]
	val event_location = [[event_id, id_of_Workstation(2), "located at"]]
	val event_worker = [[event_id, id_of_Worker(1), "with"]]
	val e2o_relations = event_male^^event_location^^event_worker

   val p_duration = "?" (* unknown time *)
   val i_compressed = Real.toString (sim_compressed_air(3.0))
   val calls = [call("id_compressed-air[m3]", i_compressed)] 
   val s_co2e = Real.toString (sumCalls(calls))
in
	write_event(event_id, "CheckMalePart", [p_duration, s_co2e,i_compressed]);
   write_e2o_relations(e2o_relations);
   change_oat(id_of_MalePart(id1), "MalePart", "p_mass[kg]", [(Real.toString m1), "", "", ""])
end;

fun write_CheckFemalePart((id1, m1, wid1), ok) = 
let
   val event_id = "e_checkFemale_"^(Int.toString id1)^">"^(Bool.toString ok)
   val objects_id_mp = id_of_FemalePart(id1)
   val event_female = [[event_id, objects_id_mp, "on"]]
	val event_location = [[event_id, id_of_Workstation(2), "located at"]]
	val event_worker = [[event_id, id_of_Worker(1), "with"]]
	val e2o_relations = event_female^^event_location^^event_worker

   val p_duration = "?" (* unknown time *)
   val i_compressed = Real.toString (sim_compressed_air(3.0))
   val calls = [call("id_compressed-air[m3]", i_compressed)]  (*call("id_waste-type_scrap_metal-open")*)
   val s_co2e = Real.toString (sumCalls(calls))
in
	write_event(event_id, "CheckFemalePart", [p_duration, s_co2e,i_compressed]);
   write_e2o_relations(e2o_relations);
   change_oat(id_of_MalePart(id1), "FemalePart", "p_mass[kg]", [(Real.toString m1), "", "", ""])
end;

fun write_AssembleHinge((id1, m1, wid1):MalePart, (id2, m2, wid2):FemalePart, (id3, m3):SteelPin) =
let
   val event_id = "e_assembly_"^(Int.toString id2)
   val part1 = [[event_id, id_of_MalePart(id1), "input"]]
	val part2 = [[event_id, id_of_FemalePart(id2), "input"]]
   val part3 = [[event_id, id_of_SteelPin(id3), "input"]]
   val part = [[event_id, id_of_Hinge(id2), "output"]]
	val event_location = [[event_id, id_of_Workstation(3), "located at"]]
	val event_machine = [[event_id, id_of_Machine("assembler01"), "with"]]
	val e2o_relations = part1^^part2^^part3^^part^^event_location^^event_machine

   val p_duration = Real.toString ASSEMBLE_TIME (* Assumed time *)
   val mass = m1+m2+m3
   
   val s_co2e = "?"

   val o2o_male = [[id_of_Hinge(id2), id_of_MalePart(id1), "created from"]]
   val o2o_female = [[id_of_Hinge(id2), id_of_FemalePart(id2), "created from"]]
   val o2o_pin = [[id_of_Hinge(id2), id_of_SteelPin(id3), "created from"]]
   val o2o_relations = o2o_male^^o2o_female^^o2o_pin
in
	write_event(event_id, "AssembleHinge", [p_duration, s_co2e]);
   initialize_Hinge((id2, mass));
   write_e2o_relations(e2o_relations)
   (*write_o2o_relations(o2o_relations)  <-- Implicit given, must be minded*)
end; 

fun write_PackHinges(hinge_list, id) =
let
   val event_id = "e_packhinges_"^(Int.toString id)
   val pack = [[event_id, id_of_HingePack(id), "output"]]
   val pack_items = map (fn (id1,_) => [event_id, id_of_Hinge(id1), "input"]) hinge_list
	val event_location = [[event_id, id_of_Workstation(3), "located at"]]
	val event_machine = [[event_id, id_of_Machine("packer01"), "with"]]
	val e2o_relations = pack^^pack_items^^event_location^^event_machine

   val i_cardboard = Real.toString (sim_cardboard_mass())
   val p_duration = Real.toString (DelayPackHinges())

   val calls = [call("id_cardboard_material", i_cardboard)]
   val s_co2e = Real.toString (sumCalls(calls))
   
   val o2o_relations = map (fn (id1,_) => [id_of_HingePack(id), id_of_Hinge(id1),"created from"]) hinge_list
in
	write_event(event_id, "PackHinges", [p_duration, s_co2e, i_cardboard]);
   initialize_HingePack(id);
   write_e2o_relations(e2o_relations);
   write_o2o_relations(o2o_relations)
end

fun write_MoveParts(id2, parts) =
let
   val (id1, _, _) = hd parts
   val event_id = "e_moveparts_"^(Int.toString id1)
	val event_worker = [[event_id, id_of_Worker(id2), "with"]]
	val event_location = [[event_id, id_of_Facility(1), "located at"]]
	val e2o_relations = event_worker^^event_location   

   val p_duration = Real.toString MOVE_TIME (* Assumed time *)
in
	write_event(event_id, "MoveParts", [p_duration]);
   write_e2o_relations(e2o_relations)
end

